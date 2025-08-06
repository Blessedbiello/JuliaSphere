module StructuredLogger

using Logging
using JSON3
using Dates
using UUIDs

# Log levels with numeric values for filtering
const LOG_LEVELS = Dict(
    "TRACE" => 0,
    "DEBUG" => 1,
    "INFO" => 2,
    "WARN" => 3,
    "ERROR" => 4,
    "FATAL" => 5
)

# Structured log entry
struct LogEntry
    timestamp::DateTime
    level::String
    message::String
    module::String
    function_name::String
    file::String
    line::Int
    request_id::Union{String, Nothing}
    user_id::Union{String, Nothing}
    agent_id::Union{String, Nothing}
    execution_id::Union{String, Nothing}
    metadata::Dict{String, Any}
    stack_trace::Union{Vector{String}, Nothing}
end

# Global logger configuration
mutable struct LoggerConfig
    min_level::String
    output_format::String  # "json" or "text"
    include_stack_trace::Bool
    max_message_length::Int
    sanitize_sensitive_data::Bool
    
    LoggerConfig() = new("INFO", "json", true, 10000, true)
end

const LOGGER_CONFIG = LoggerConfig()

"""
Configure the structured logger
"""
function configure_logger(;
    min_level::String="INFO",
    output_format::String="json",
    include_stack_trace::Bool=true,
    max_message_length::Int=10000,
    sanitize_sensitive_data::Bool=true
)
    LOGGER_CONFIG.min_level = min_level
    LOGGER_CONFIG.output_format = output_format
    LOGGER_CONFIG.include_stack_trace = include_stack_trace
    LOGGER_CONFIG.max_message_length = max_message_length
    LOGGER_CONFIG.sanitize_sensitive_data = sanitize_sensitive_data
    
    @info "Structured logger configured" config=LOGGER_CONFIG
end

"""
Check if a log level should be output
"""
function should_log(level::String)::Bool
    min_level_value = get(LOG_LEVELS, LOGGER_CONFIG.min_level, 2)
    level_value = get(LOG_LEVELS, level, 2)
    return level_value >= min_level_value
end

"""
Sanitize sensitive data from log messages and metadata
"""
function sanitize_data(data::Any)::Any
    if !LOGGER_CONFIG.sanitize_sensitive_data
        return data
    end
    
    if isa(data, String)
        # Remove potential passwords, tokens, and keys
        sanitized = replace(data, r"password[\"']?\s*[:=]\s*[\"'][^\"']*[\"']"i => "password: \"[REDACTED]\"")
        sanitized = replace(sanitized, r"token[\"']?\s*[:=]\s*[\"'][^\"']*[\"']"i => "token: \"[REDACTED]\"")
        sanitized = replace(sanitized, r"key[\"']?\s*[:=]\s*[\"'][^\"']*[\"']"i => "key: \"[REDACTED]\"")
        sanitized = replace(sanitized, r"secret[\"']?\s*[:=]\s*[\"'][^\"']*[\"']"i => "secret: \"[REDACTED]\"")
        return sanitized
    elseif isa(data, Dict)
        sanitized = Dict{String, Any}()
        for (key, value) in data
            key_lower = lowercase(string(key))
            if key_lower in ["password", "token", "key", "secret", "auth", "authorization"]
                sanitized[key] = "[REDACTED]"
            else
                sanitized[key] = sanitize_data(value)
            end
        end
        return sanitized
    elseif isa(data, Vector)
        return [sanitize_data(item) for item in data]
    else
        return data
    end
end

"""
Extract context information from current execution
"""
function extract_context()::Dict{String, Any}
    context = Dict{String, Any}()
    
    # Try to get current stack trace info
    try
        stack = stacktrace()
        if length(stack) >= 3  # Skip extract_context and log_structured calls
            frame = stack[3]
            context["file"] = string(frame.file)
            context["line"] = frame.line
            context["function_name"] = string(frame.func)
        end
    catch
        context["file"] = "unknown"
        context["line"] = 0
        context["function_name"] = "unknown"
    end
    
    return context
end

"""
Create a structured log entry
"""
function create_log_entry(
    level::String,
    message::String;
    request_id::Union{String, Nothing}=nothing,
    user_id::Union{String, Nothing}=nothing,
    agent_id::Union{String, Nothing}=nothing,
    execution_id::Union{String, Nothing}=nothing,
    metadata::Dict{String, Any}=Dict{String, Any}(),
    exception::Union{Exception, Nothing}=nothing
)::LogEntry
    
    # Extract context information
    context = extract_context()
    
    # Sanitize message and metadata
    sanitized_message = sanitize_data(message)
    sanitized_metadata = sanitize_data(metadata)
    
    # Truncate message if too long
    if length(sanitized_message) > LOGGER_CONFIG.max_message_length
        sanitized_message = sanitized_message[1:LOGGER_CONFIG.max_message_length] * "... [TRUNCATED]"
    end
    
    # Add exception information if provided
    stack_trace = nothing
    if exception !== nothing
        sanitized_metadata["exception_type"] = string(typeof(exception))
        sanitized_metadata["exception_message"] = sanitize_data(string(exception))
        
        if LOGGER_CONFIG.include_stack_trace
            try
                stack_trace = [string(frame) for frame in stacktrace(catch_backtrace())[1:min(20, end)]]
            catch
                stack_trace = ["Failed to capture stack trace"]
            end
        end
    end
    
    return LogEntry(
        now(),
        level,
        sanitized_message,
        get(context, "module", "Unknown"),
        get(context, "function_name", "unknown"),
        get(context, "file", "unknown"),
        get(context, "line", 0),
        request_id,
        user_id,
        agent_id,
        execution_id,
        sanitized_metadata,
        stack_trace
    )
end

"""
Format log entry for output
"""
function format_log_entry(entry::LogEntry)::String
    if LOGGER_CONFIG.output_format == "json"
        return format_json_log(entry)
    else
        return format_text_log(entry)
    end
end

"""
Format log entry as JSON
"""
function format_json_log(entry::LogEntry)::String
    log_obj = Dict{String, Any}(
        "timestamp" => string(entry.timestamp),
        "level" => entry.level,
        "message" => entry.message,
        "module" => entry.module,
        "function" => entry.function_name,
        "file" => entry.file,
        "line" => entry.line
    )
    
    # Add optional fields if present
    if entry.request_id !== nothing
        log_obj["request_id"] = entry.request_id
    end
    if entry.user_id !== nothing
        log_obj["user_id"] = entry.user_id
    end
    if entry.agent_id !== nothing
        log_obj["agent_id"] = entry.agent_id
    end
    if entry.execution_id !== nothing
        log_obj["execution_id"] = entry.execution_id
    end
    
    # Add metadata
    if !isempty(entry.metadata)
        log_obj["metadata"] = entry.metadata
    end
    
    # Add stack trace if present
    if entry.stack_trace !== nothing
        log_obj["stack_trace"] = entry.stack_trace
    end
    
    return JSON3.write(log_obj)
end

"""
Format log entry as human-readable text
"""
function format_text_log(entry::LogEntry)::String
    parts = [
        "[$(entry.timestamp)]",
        "[$(entry.level)]",
        "[$(entry.function_name):$(entry.line)]"
    ]
    
    if entry.request_id !== nothing
        push!(parts, "[req:$(entry.request_id)]")
    end
    if entry.agent_id !== nothing
        push!(parts, "[agent:$(entry.agent_id)]")
    end
    
    header = join(parts, " ")
    
    text = "$header $(entry.message)"
    
    if !isempty(entry.metadata)
        text *= "\n  Metadata: $(JSON3.write(entry.metadata))"
    end
    
    if entry.stack_trace !== nothing
        text *= "\n  Stack Trace:\n    " * join(entry.stack_trace, "\n    ")
    end
    
    return text
end

"""
Write log entry to output
"""
function write_log(entry::LogEntry)
    if should_log(entry.level)
        formatted = format_log_entry(entry)
        
        # Write to appropriate output based on level
        if entry.level in ["ERROR", "FATAL"]
            println(stderr, formatted)
            flush(stderr)
        else
            println(stdout, formatted)
            flush(stdout)
        end
        
        # Also write to file if configured (would need file handling)
        # write_to_log_file(formatted)
    end
end

"""
Main structured logging function
"""
function log_structured(
    level::String,
    message::String;
    request_id::Union{String, Nothing}=nothing,
    user_id::Union{String, Nothing}=nothing,
    agent_id::Union{String, Nothing}=nothing,
    execution_id::Union{String, Nothing}=nothing,
    metadata::Dict{String, Any}=Dict{String, Any}(),
    exception::Union{Exception, Nothing}=nothing
)
    entry = create_log_entry(
        level, message;
        request_id=request_id,
        user_id=user_id,
        agent_id=agent_id,
        execution_id=execution_id,
        metadata=metadata,
        exception=exception
    )
    
    write_log(entry)
end

# Convenience functions for different log levels
function log_trace(message::String; kwargs...)
    log_structured("TRACE", message; kwargs...)
end

function log_debug(message::String; kwargs...)
    log_structured("DEBUG", message; kwargs...)
end

function log_info(message::String; kwargs...)
    log_structured("INFO", message; kwargs...)
end

function log_warn(message::String; kwargs...)
    log_structured("WARN", message; kwargs...)
end

function log_error(message::String; kwargs...)
    log_structured("ERROR", message; kwargs...)
end

function log_fatal(message::String; kwargs...)
    log_structured("FATAL", message; kwargs...)
end

"""
Log API request/response
"""
function log_api_call(
    method::String,
    path::String,
    status_code::Int,
    duration_ms::Int;
    request_id::Union{String, Nothing}=nothing,
    user_id::Union{String, Nothing}=nothing,
    request_size::Union{Int, Nothing}=nothing,
    response_size::Union{Int, Nothing}=nothing,
    user_agent::Union{String, Nothing}=nothing,
    ip_address::Union{String, Nothing}=nothing
)
    metadata = Dict{String, Any}(
        "method" => method,
        "path" => path,
        "status_code" => status_code,
        "duration_ms" => duration_ms
    )
    
    if request_size !== nothing
        metadata["request_size_bytes"] = request_size
    end
    if response_size !== nothing
        metadata["response_size_bytes"] = response_size
    end
    if user_agent !== nothing
        metadata["user_agent"] = user_agent
    end
    if ip_address !== nothing
        metadata["ip_address"] = ip_address
    end
    
    level = if status_code >= 500
        "ERROR"
    elseif status_code >= 400
        "WARN"
    else
        "INFO"
    end
    
    log_structured(
        level,
        "API call: $method $path -> $status_code ($duration_ms ms)";
        request_id=request_id,
        user_id=user_id,
        metadata=metadata
    )
end

"""
Log agent execution events
"""
function log_agent_execution(
    event::String,
    agent_id::String;
    execution_id::Union{String, Nothing}=nothing,
    user_id::Union{String, Nothing}=nothing,
    duration_ms::Union{Int, Nothing}=nothing,
    tools_used::Union{Vector{String}, Nothing}=nothing,
    status::Union{String, Nothing}=nothing,
    error_message::Union{String, Nothing}=nothing,
    metadata::Dict{String, Any}=Dict{String, Any}()
)
    log_metadata = copy(metadata)
    log_metadata["event"] = event
    
    if duration_ms !== nothing
        log_metadata["duration_ms"] = duration_ms
    end
    if tools_used !== nothing
        log_metadata["tools_used"] = tools_used
    end
    if status !== nothing
        log_metadata["status"] = status
    end
    if error_message !== nothing
        log_metadata["error_message"] = error_message
    end
    
    level = if status == "failed" || error_message !== nothing
        "ERROR"
    elseif status == "completed"
        "INFO"
    else
        "DEBUG"
    end
    
    message = "Agent execution $event: $agent_id"
    if status !== nothing
        message *= " ($status)"
    end
    
    log_structured(
        level,
        message;
        agent_id=agent_id,
        execution_id=execution_id,
        user_id=user_id,
        metadata=log_metadata
    )
end

"""
Create a performance timer for logging execution time
"""
mutable struct PerformanceTimer
    start_time::DateTime
    operation::String
    metadata::Dict{String, Any}
    
    function PerformanceTimer(operation::String, metadata::Dict{String, Any}=Dict{String, Any}())
        timer = new(now(), operation, metadata)
        log_debug("Started: $operation"; metadata=metadata)
        return timer
    end
end

"""
Finish timing and log the result
"""
function finish_timer(timer::PerformanceTimer; 
                     status::String="completed",
                     additional_metadata::Dict{String, Any}=Dict{String, Any}())
    duration = now() - timer.start_time
    duration_ms = Int(round(duration.value))
    
    combined_metadata = merge(timer.metadata, additional_metadata)
    combined_metadata["duration_ms"] = duration_ms
    combined_metadata["status"] = status
    
    level = status == "failed" ? "WARN" : "INFO"
    
    log_structured(
        level,
        "Completed: $(timer.operation) ($(duration_ms)ms)";
        metadata=combined_metadata
    )
end

"""
Macro for timing code blocks
"""
macro timed(operation, expr)
    quote
        timer = PerformanceTimer($(esc(operation)))
        try
            result = $(esc(expr))
            finish_timer(timer; status="completed")
            result
        catch e
            finish_timer(timer; 
                status="failed", 
                additional_metadata=Dict("error" => string(e))
            )
            rethrow(e)
        end
    end
end

end # module StructuredLogger