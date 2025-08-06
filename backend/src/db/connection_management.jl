using LibPQ
using SQLStrings

# Thread-safe connection pool management
mutable struct ConnectionPool
    connections::Vector{LibPQ.Connection}
    available::Vector{Bool}
    conn_string::String
    max_connections::Int
    lock::ReentrantLock
    
    function ConnectionPool(conn_string::String, max_connections::Int=10)
        new(LibPQ.Connection[], Bool[], conn_string, max_connections, ReentrantLock())
    end
end

# Global connection pool instance
const _POOL = Ref{Union{Nothing, ConnectionPool}}(nothing)

"""
Initialize the connection pool with the given connection string
"""
function initialize_connection(conn_string::String, max_connections::Int=10)
    if _POOL[] !== nothing
        error("Connection pool is already initialized.")
    end
    
    pool = ConnectionPool(conn_string, max_connections)
    
    # Pre-create initial connections
    lock(pool.lock) do
        for i in 1:min(3, max_connections)  # Start with 3 connections
            try
                conn = LibPQ.Connection(conn_string)
                push!(pool.connections, conn)
                push!(pool.available, true)
                @info "Created database connection $i"
            catch e
                @error "Failed to create initial database connection $i" exception=(e, catch_backtrace())
                if i == 1  # If we can't create even the first connection, fail
                    rethrow(e)
                end
            end
        end
    end
    
    _POOL[] = pool
    @info "Database connection pool initialized with $(length(pool.connections)) connections"
end

"""
Get a connection from the pool (thread-safe)
"""
function get_connection()::LibPQ.Connection
    pool = _POOL[]
    if pool === nothing
        error("Connection pool is not initialized.")
    end
    
    lock(pool.lock) do
        # Find an available connection
        for i in 1:length(pool.connections)
            if pool.available[i]
                conn = pool.connections[i]
                
                # Test connection health
                if _is_connection_healthy(conn)
                    pool.available[i] = false
                    return conn
                else
                    # Connection is unhealthy, recreate it
                    @warn "Recreating unhealthy database connection $i"
                    try
                        LibPQ.close(conn)
                    catch
                        # Ignore errors when closing unhealthy connection
                    end
                    
                    try
                        new_conn = LibPQ.Connection(pool.conn_string)
                        pool.connections[i] = new_conn
                        pool.available[i] = false
                        return new_conn
                    catch e
                        @error "Failed to recreate database connection $i" exception=(e, catch_backtrace())
                        # Mark as unavailable and continue looking
                        pool.available[i] = true
                        continue
                    end
                end
            end
        end
        
        # No available connections, try to create a new one if under limit
        if length(pool.connections) < pool.max_connections
            try
                new_conn = LibPQ.Connection(pool.conn_string)
                push!(pool.connections, new_conn)
                push!(pool.available, false)  # Mark as in use
                @info "Created new database connection, pool size: $(length(pool.connections))"
                return new_conn
            catch e
                @error "Failed to create new database connection" exception=(e, catch_backtrace())
            end
        end
        
        # Pool is exhausted, wait for a connection or fail
        error("No available database connections (pool size: $(length(pool.connections)), max: $(pool.max_connections))")
    end
end

"""
Return a connection to the pool
"""
function return_connection(conn::LibPQ.Connection)
    pool = _POOL[]
    if pool === nothing
        return  # Pool not initialized, ignore
    end
    
    lock(pool.lock) do
        # Find the connection in the pool and mark as available
        for i in 1:length(pool.connections)
            if pool.connections[i] === conn
                pool.available[i] = true
                return
            end
        end
        @warn "Attempted to return unknown connection to pool"
    end
end

"""
Execute a function with a database connection, automatically handling return to pool
"""
function with_connection(f::Function)
    conn = get_connection()
    try
        return f(conn)
    finally
        return_connection(conn)
    end
end

"""
Execute a function within a database transaction with proper cleanup
Automatically commits on success and rolls back on failure
"""
function with_transaction(f::Function)
    return with_connection() do conn
        LibPQ.execute(conn, "BEGIN")
        
        try
            result = f(conn)
            LibPQ.execute(conn, "COMMIT")
            @debug "Transaction committed successfully"
            return result
        catch e
            try
                LibPQ.execute(conn, "ROLLBACK")
                @debug "Transaction rolled back due to error"
            catch rollback_error
                @error "Failed to rollback transaction" exception=(rollback_error, catch_backtrace())
            end
            
            # Re-throw original exception
            rethrow(e)
        end
    end
end

"""
Execute a function within a savepoint (nested transaction)
Useful for partial rollbacks within larger transactions
"""
function with_savepoint(f::Function, savepoint_name::String="sp1")
    return with_connection() do conn
        # Create savepoint
        LibPQ.execute(conn, "SAVEPOINT $savepoint_name")
        
        try
            result = f(conn)
            LibPQ.execute(conn, "RELEASE SAVEPOINT $savepoint_name")
            @debug "Savepoint $savepoint_name released successfully"
            return result
        catch e
            try
                LibPQ.execute(conn, "ROLLBACK TO SAVEPOINT $savepoint_name")
                @debug "Rolled back to savepoint $savepoint_name"
            catch rollback_error
                @error "Failed to rollback to savepoint $savepoint_name" exception=(rollback_error, catch_backtrace())
            end
            
            # Re-throw original exception
            rethrow(e)
        end
    end
end

"""
Execute multiple operations in a single transaction
Takes a vector of functions that each take a connection parameter
"""
function batch_transaction(operations::Vector{Function})
    return with_transaction() do conn
        results = []
        for (i, op) in enumerate(operations)
            try
                result = op(conn)
                push!(results, result)
                @debug "Batch operation $i completed successfully"
            catch e
                @error "Batch operation $i failed" exception=(e, catch_backtrace())
                throw(e)  # This will trigger rollback of entire transaction
            end
        end
        return results
    end
end

"""
Check if a database connection is healthy
"""
function _is_connection_healthy(conn::LibPQ.Connection)::Bool
    try
        # Simple query to test connection
        result = LibPQ.execute(conn, "SELECT 1")
        return !isempty(result)
    catch
        return false
    end
end

"""
Close all connections in the pool (for shutdown)
"""
function close_connection_pool()
    pool = _POOL[]
    if pool === nothing
        return
    end
    
    lock(pool.lock) do
        for conn in pool.connections
            try
                LibPQ.close(conn)
            catch e
                @warn "Error closing database connection" exception=(e, catch_backtrace())
            end
        end
        empty!(pool.connections)
        empty!(pool.available)
    end
    
    _POOL[] = nothing
    @info "Database connection pool closed"
end

"""
Get pool statistics for monitoring
"""
function get_pool_stats()::Dict{String, Any}
    pool = _POOL[]
    if pool === nothing
        return Dict("status" => "not_initialized")
    end
    
    lock(pool.lock) do
        available_count = count(pool.available)
        return Dict(
            "status" => "initialized",
            "total_connections" => length(pool.connections),
            "available_connections" => available_count,
            "in_use_connections" => length(pool.connections) - available_count,
            "max_connections" => pool.max_connections
        )
    end
end

"""
Execute a parameterized query and return results
Used by marketplace functionality for flexible database operations

SECURITY NOTE: This function properly handles parameterized queries to prevent SQL injection.
Use ? placeholders in queries and pass parameters separately.
"""
function execute_query(query::String, params::Vector{Any}=Any[])
    return with_connection() do conn
        if isempty(params)
            # No parameters - use query as-is but still validate
            _validate_query_safety(query)
            return LibPQ.execute(conn, query)
        else
            # Convert ? placeholders to PostgreSQL $1, $2, etc. format safely
            parameterized_query, param_count = _convert_placeholders_safely(query)
            
            if length(params) != param_count
                throw(ArgumentError("Parameter count mismatch: expected $param_count, got $(length(params))"))
            end
            
            # Validate parameter types for safety
            validated_params = _validate_and_convert_params(params)
            
            return LibPQ.execute(conn, parameterized_query, validated_params)
        end
    end
end

"""
Safely convert ? placeholders to PostgreSQL $1, $2, etc. format
Returns the converted query and the number of parameters found
"""
function _convert_placeholders_safely(query::String)::Tuple{String, Int}
    # Use a more robust approach that handles quoted strings and comments
    result = IOBuffer()
    i = 1
    param_count = 0
    in_single_quote = false
    in_double_quote = false
    in_comment = false
    
    while i <= length(query)
        char = query[i]
        
        # Handle single quotes (string literals)
        if char == '\'' && !in_double_quote && !in_comment
            if i < length(query) && query[i+1] == '\''
                # Escaped single quote
                write(result, "''")
                i += 2
                continue
            else
                in_single_quote = !in_single_quote
            end
        # Handle double quotes (identifiers)
        elseif char == '"' && !in_single_quote && !in_comment
            in_double_quote = !in_double_quote
        # Handle comments
        elseif char == '-' && i < length(query) && query[i+1] == '-' && !in_single_quote && !in_double_quote
            in_comment = true
        elseif char == '\n' && in_comment
            in_comment = false
        # Handle parameter placeholder
        elseif char == '?' && !in_single_quote && !in_double_quote && !in_comment
            param_count += 1
            write(result, "\$$(param_count)")
            i += 1
            continue
        end
        
        write(result, char)
        i += 1
    end
    
    return String(take!(result)), param_count
end

"""
Validate and convert parameters to appropriate types for LibPQ
"""
function _validate_and_convert_params(params::Vector{Any})::Vector{Any}
    validated = Any[]
    
    for param in params
        if param === nothing
            push!(validated, nothing)
        elseif param isa String
            # Validate string length to prevent extremely large payloads
            if length(param) > 1_000_000  # 1MB limit
                throw(ArgumentError("String parameter too large (> 1MB)"))
            end
            push!(validated, param)
        elseif param isa Number
            push!(validated, param)
        elseif param isa Bool
            push!(validated, param)
        elseif param isa UUID
            push!(validated, string(param))
        elseif param isa DateTime
            push!(validated, param)
        elseif param isa Vector{String}
            # PostgreSQL array support
            push!(validated, param)
        elseif param isa Dict
            # Convert to JSON string for JSONB columns
            push!(validated, JSON3.write(param))
        else
            # Try to convert unknown types to string as fallback
            @warn "Converting unknown parameter type $(typeof(param)) to string" param
            push!(validated, string(param))
        end
    end
    
    return validated
end

"""
Basic validation to detect potentially unsafe raw SQL queries
"""
function _validate_query_safety(query::String)
    # Convert to lowercase for checking
    query_lower = lowercase(strip(query))
    
    # Allow only safe read operations and known patterns for raw queries
    safe_prefixes = ["select", "with"]
    
    # Check for obviously dangerous patterns
    dangerous_patterns = [
        r";\s*(drop|delete|truncate|alter|create|insert|update)",
        r"--.*;\s*(drop|delete|truncate|alter)",
        r"/\*.*\*/.*;\s*(drop|delete|truncate|alter)"
    ]
    
    if !any(startswith(query_lower, prefix) for prefix in safe_prefixes)
        @warn "Executing raw SQL query that doesn't start with safe prefix" query=query[1:min(100, length(query))]
    end
    
    for pattern in dangerous_patterns
        if occursin(pattern, query_lower)
            throw(ArgumentError("Potentially dangerous SQL pattern detected in raw query"))
        end
    end
end