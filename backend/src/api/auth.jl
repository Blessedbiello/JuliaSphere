module Auth

using HTTP
using JSON3
using UUIDs
using Dates
using Base64

# JWT-like token structure (simplified for demonstration)
struct UserContext
    user_id::UUID
    username::String
    email::Union{String, Nothing}
    roles::Vector{String}
    exp::DateTime
end

# In-memory user session storage (replace with Redis/database in production)
const USER_SESSIONS = Dict{String, UserContext}()

"""
Authentication middleware for HTTP requests
"""
function authenticate_request(handler::Function)
    return function(req::HTTP.Request)
        try
            # Extract auth token from Authorization header
            auth_header = get(HTTP.headers(req), "Authorization", "")
            
            if isempty(auth_header)
                # Check for public endpoints that don't require authentication
                if _is_public_endpoint(req)
                    # Add empty user context for public endpoints
                    req.context = Dict{String, Any}("user" => nothing)
                    return handler(req)
                else
                    return _unauthorized_response("Missing authorization header")
                end
            end
            
            # Parse Bearer token
            if !startswith(auth_header, "Bearer ")
                return _unauthorized_response("Invalid authorization format")
            end
            
            token = strip(auth_header[8:end])  # Remove "Bearer " prefix
            
            # Validate and decode token
            user_context = validate_token(token)
            if user_context === nothing
                return _unauthorized_response("Invalid or expired token")
            end
            
            # Check if user has required permissions for this endpoint
            if !_has_required_permissions(req, user_context)
                return _forbidden_response("Insufficient permissions")
            end
            
            # Add user context to request
            req.context = Dict{String, Any}("user" => user_context)
            
            return handler(req)
        catch e
            @error "Authentication middleware error" exception=(e, catch_backtrace())
            return _server_error_response("Authentication error")
        end
    end
end

"""
Check if an endpoint is public (doesn't require authentication)
"""
function _is_public_endpoint(req::HTTP.Request)::Bool
    public_patterns = [
        r"^/ping$",
        r"^/api/v1/marketplace/agents$",  # Public agent listing
        r"^/api/v1/marketplace/agents/[^/]+$",  # Public agent details
        r"^/api/v1/marketplace/categories$",
        r"^/api/v1/marketplace/stats$",
        r"^/api/v1/tools$",
        r"^/api/v1/strategies$"
    ]
    
    path = HTTP.URI(req.target).path
    method = req.method
    
    # GET requests to certain endpoints are public
    if method == "GET"
        return any(occursin(pattern, path) for pattern in public_patterns)
    end
    
    return false
end

"""
Check if user has required permissions for the endpoint
"""
function _has_required_permissions(req::HTTP.Request, user::UserContext)::Bool
    path = HTTP.URI(req.target).path
    method = req.method
    
    # Admin-only endpoints
    admin_patterns = [
        r"^/api/v1/marketplace/agents/.+/publish$",
        r"^/api/v1/marketplace/swarms/analyze$"
    ]
    
    if any(occursin(pattern, path) for pattern in admin_patterns)
        return "admin" in user.roles || "marketplace_admin" in user.roles
    end
    
    # User must own the agent for certain operations
    agent_owner_patterns = [
        r"^/api/v1/agents/[^/]+$",  # GET, PUT, DELETE specific agent
        r"^/api/v1/agents/[^/]+/webhook$"
    ]
    
    if any(occursin(pattern, path) for pattern in agent_owner_patterns)
        # Extract agent ID from path
        path_parts = split(path, '/')
        if length(path_parts) >= 4 && path_parts[4] != ""
            agent_id = path_parts[4]
            return _user_owns_agent(user.user_id, agent_id)
        end
    end
    
    return true  # Default allow for authenticated users
end

"""
Check if user owns a specific agent
"""
function _user_owns_agent(user_id::UUID, agent_id::String)::Bool
    # This would typically query the database
    # For now, we'll implement a simple check
    try
        using ..JuliaDB
        query = "SELECT creator_id FROM agent_marketplace WHERE agent_id = ?"
        result = JuliaDB.execute_query(query, [agent_id])
        
        if !isempty(result)
            creator_id = first(result).creator_id
            return creator_id !== nothing && UUID(creator_id) == user_id
        end
        
        # If not in marketplace, check if user created the agent
        # This would need additional implementation based on your auth system
        return true  # Default allow for now
    catch e
        @warn "Error checking agent ownership" exception=(e, catch_backtrace())
        return false
    end
end

"""
Validate a token and return user context if valid
"""
function validate_token(token::String)::Union{UserContext, Nothing}
    try
        # In a real implementation, this would validate JWT signature
        # For now, we'll use a simple session-based approach
        
        if haskey(USER_SESSIONS, token)
            user_context = USER_SESSIONS[token]
            
            # Check if token is expired
            if user_context.exp < now()
                delete!(USER_SESSIONS, token)
                return nothing
            end
            
            return user_context
        end
        
        # Try to decode as base64 encoded JSON (for development/testing)
        try
            decoded = String(base64decode(token))
            user_data = JSON3.read(decoded, Dict{String, Any})
            
            return UserContext(
                UUID(user_data["user_id"]),
                user_data["username"],
                get(user_data, "email", nothing),
                get(user_data, "roles", String[]),
                DateTime(user_data["exp"])
            )
        catch
            # Invalid token format
            return nothing
        end
        
    catch e
        @warn "Token validation error" exception=(e, catch_backtrace())
        return nothing
    end
end

"""
Create a new user session (for login)
"""
function create_user_session(user_id::UUID, username::String, email::Union{String, Nothing}, roles::Vector{String})::String
    # Generate session token
    session_id = string(uuid4())
    
    # Create user context with 24-hour expiration
    user_context = UserContext(
        user_id,
        username, 
        email,
        roles,
        now() + Hour(24)
    )
    
    USER_SESSIONS[session_id] = user_context
    
    return session_id
end

"""
Revoke a user session (for logout)
"""
function revoke_user_session(token::String)
    delete!(USER_SESSIONS, token)
end

"""
Get current user from request context
"""
function get_current_user(req::HTTP.Request)::Union{UserContext, Nothing}
    if haskey(req.context, "user")
        return req.context["user"]
    end
    return nothing
end

"""
Extract user ID from request, throwing error if not authenticated
"""
function require_user_id(req::HTTP.Request)::UUID
    user = get_current_user(req)
    if user === nothing
        throw(ArgumentError("Authentication required"))
    end
    return user.user_id
end

# Helper functions for standard HTTP error responses
function _unauthorized_response(message::String="Unauthorized")
    return HTTP.Response(401, JSON3.write(Dict(
        "error" => "unauthorized",
        "message" => message
    )))
end

function _forbidden_response(message::String="Forbidden")
    return HTTP.Response(403, JSON3.write(Dict(
        "error" => "forbidden", 
        "message" => message
    )))
end

function _server_error_response(message::String="Internal Server Error")
    return HTTP.Response(500, JSON3.write(Dict(
        "error" => "internal_error",
        "message" => message
    )))
end

"""
Development helper: Create a test user token
"""
function create_test_token(username::String="testuser", roles::Vector{String}=String[])::String
    user_data = Dict(
        "user_id" => string(uuid4()),
        "username" => username,
        "email" => "$username@test.com",
        "roles" => roles,
        "exp" => string(now() + Hour(24))
    )
    
    return base64encode(JSON3.write(user_data))
end

end # module Auth