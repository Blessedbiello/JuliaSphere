module ErrorHandling

using HTTP
using JSON3
using UUIDs
using Dates

"""
Standard API error structure
"""
struct ApiError
    code::String
    message::String
    details::Union{Dict{String, Any}, Nothing}
    request_id::Union{String, Nothing}
    timestamp::DateTime
end

"""
Error codes for consistent API responses
"""
module ErrorCodes
    const VALIDATION_ERROR = "validation_error"
    const NOT_FOUND = "not_found"
    const UNAUTHORIZED = "unauthorized"
    const FORBIDDEN = "forbidden"
    const CONFLICT = "conflict"
    const RATE_LIMITED = "rate_limited"
    const INTERNAL_ERROR = "internal_error"
    const BAD_REQUEST = "bad_request"
    const SERVICE_UNAVAILABLE = "service_unavailable"
    const TIMEOUT = "timeout"
end

"""
Standard HTTP status codes for error types
"""
function get_http_status(error_code::String)::Int
    status_map = Dict(
        ErrorCodes.VALIDATION_ERROR => 400,
        ErrorCodes.BAD_REQUEST => 400,
        ErrorCodes.UNAUTHORIZED => 401,
        ErrorCodes.FORBIDDEN => 403,
        ErrorCodes.NOT_FOUND => 404,
        ErrorCodes.CONFLICT => 409,
        ErrorCodes.RATE_LIMITED => 429,
        ErrorCodes.INTERNAL_ERROR => 500,
        ErrorCodes.SERVICE_UNAVAILABLE => 503,
        ErrorCodes.TIMEOUT => 504
    )
    
    return get(status_map, error_code, 500)
end

"""
Create a standardized error response
"""
function create_error_response(error_code::String, message::String; 
                              details::Union{Dict{String, Any}, Nothing}=nothing,
                              request_id::Union{String, Nothing}=nothing)::HTTP.Response
    
    api_error = ApiError(
        error_code,
        message,
        details,
        request_id,
        now()
    )
    
    response_body = Dict{String, Any}(
        "error" => Dict{String, Any}(
            "code" => api_error.code,
            "message" => api_error.message,
            "timestamp" => string(api_error.timestamp)
        )
    )
    
    if api_error.details !== nothing
        response_body["error"]["details"] = api_error.details
    end
    
    if api_error.request_id !== nothing
        response_body["error"]["request_id"] = api_error.request_id
    end
    
    status_code = get_http_status(error_code)
    
    return HTTP.Response(
        status_code,
        ["Content-Type" => "application/json"],
        JSON3.write(response_body)
    )
end

"""
Create validation error with field-specific details
"""
function validation_error(message::String, field_errors::Dict{String, Vector{String}}=Dict{String, Vector{String}}(); request_id::Union{String, Nothing}=nothing)::HTTP.Response
    details = isempty(field_errors) ? nothing : Dict{String, Any}("field_errors" => field_errors)
    return create_error_response(ErrorCodes.VALIDATION_ERROR, message; details=details, request_id=request_id)
end

"""
Create not found error
"""
function not_found_error(resource::String, identifier::String=""; request_id::Union{String, Nothing}=nothing)::HTTP.Response
    message = isempty(identifier) ? "$resource not found" : "$resource '$identifier' not found"
    details = Dict{String, Any}("resource" => resource)
    if !isempty(identifier)
        details["identifier"] = identifier
    end
    return create_error_response(ErrorCodes.NOT_FOUND, message; details=details, request_id=request_id)
end

"""
Create unauthorized error
"""
function unauthorized_error(message::String="Authentication required"; request_id::Union{String, Nothing}=nothing)::HTTP.Response
    return create_error_response(ErrorCodes.UNAUTHORIZED, message; request_id=request_id)
end

"""
Create forbidden error
"""
function forbidden_error(message::String="Access denied"; request_id::Union{String, Nothing}=nothing)::HTTP.Response
    return create_error_response(ErrorCodes.FORBIDDEN, message; request_id=request_id)
end

"""
Create conflict error
"""
function conflict_error(message::String, conflicting_resource::Union{String, Nothing}=nothing; request_id::Union{String, Nothing}=nothing)::HTTP.Response
    details = conflicting_resource !== nothing ? Dict{String, Any}("conflicting_resource" => conflicting_resource) : nothing
    return create_error_response(ErrorCodes.CONFLICT, message; details=details, request_id=request_id)
end

"""
Create internal server error
"""
function internal_error(message::String="Internal server error"; 
                       exception_info::Union{Dict{String, Any}, Nothing}=nothing,
                       request_id::Union{String, Nothing}=nothing)::HTTP.Response
    
    # Log the full exception for internal debugging but don't expose to client
    if exception_info !== nothing
        @error "Internal server error" exception_info request_id
    end
    
    # Only expose generic message to client for security
    return create_error_response(ErrorCodes.INTERNAL_ERROR, message; request_id=request_id)
end

"""
Create rate limiting error
"""
function rate_limit_error(retry_after::Union{Int, Nothing}=nothing; request_id::Union{String, Nothing}=nothing)::HTTP.Response
    message = "Too many requests. Please slow down."
    details = retry_after !== nothing ? Dict{String, Any}("retry_after_seconds" => retry_after) : nothing
    
    response = create_error_response(ErrorCodes.RATE_LIMITED, message; details=details, request_id=request_id)
    
    # Add Retry-After header if specified
    if retry_after !== nothing
        push!(response.headers, "Retry-After" => string(retry_after))
    end
    
    return response
end

"""
Exception handler middleware that catches and standardizes errors
"""
function error_handler_middleware(handler::Function)
    return function(req::HTTP.Request)
        # Generate request ID for tracking
        request_id = string(uuid4())[1:8]
        
        try
            # Add request ID to request context for downstream handlers
            if !haskey(req, :context)
                req.context = Dict{String, Any}()
            end
            req.context["request_id"] = request_id
            
            return handler(req)
        catch e
            return handle_exception(e, request_id)
        end
    end
end

"""
Handle different types of exceptions and convert to appropriate HTTP responses
"""
function handle_exception(e::Exception, request_id::String)::HTTP.Response
    if isa(e, ArgumentError)
        if occursin("Authentication required", e.msg)
            return unauthorized_error(e.msg; request_id=request_id)
        elseif occursin("not found", lowercase(e.msg))
            return not_found_error("Resource"; request_id=request_id)
        elseif occursin("validation", lowercase(e.msg)) || occursin("invalid", lowercase(e.msg))
            return validation_error(e.msg; request_id=request_id)
        else
            return validation_error("Invalid request: $(e.msg)"; request_id=request_id)
        end
    elseif isa(e, BoundsError)
        return not_found_error("Resource"; request_id=request_id)
    elseif isa(e, KeyError)
        return validation_error("Missing required field: $(e.key)"; request_id=request_id)
    elseif isa(e, JSON3.StructuralError)
        return validation_error("Invalid JSON structure"; request_id=request_id)
    elseif isa(e, MethodError)
        # Usually indicates missing or incorrect parameters
        return validation_error("Invalid request parameters"; request_id=request_id)
    else
        # Log unknown exceptions with full details
        exception_info = Dict{String, Any}(
            "type" => string(typeof(e)),
            "message" => string(e),
            "backtrace" => [string(frame) for frame in stacktrace(catch_backtrace())[1:min(10, end)]]
        )
        
        return internal_error("An unexpected error occurred"; exception_info=exception_info, request_id=request_id)
    end
end

"""
Validate required fields in request body
"""
function validate_required_fields(data::Dict{String, Any}, required_fields::Vector{String})::Union{Nothing, HTTP.Response}
    missing_fields = String[]
    field_errors = Dict{String, Vector{String}}()
    
    for field in required_fields
        if !haskey(data, field) || data[field] === nothing
            push!(missing_fields, field)
            field_errors[field] = ["This field is required"]
        end
    end
    
    if !isempty(missing_fields)
        message = "Missing required fields: $(join(missing_fields, ", "))"
        return validation_error(message, field_errors)
    end
    
    return nothing
end

"""
Validate field types in request data
"""
function validate_field_types(data::Dict{String, Any}, field_types::Dict{String, Type})::Union{Nothing, HTTP.Response}
    field_errors = Dict{String, Vector{String}}()
    
    for (field, expected_type) in field_types
        if haskey(data, field) && data[field] !== nothing
            value = data[field]
            
            # Special handling for common type checks
            if expected_type == String && !isa(value, String)
                field_errors[field] = ["Must be a string"]
            elseif expected_type == Int && !isa(value, Int)
                field_errors[field] = ["Must be an integer"]
            elseif expected_type == Float64 && !isa(value, Number)
                field_errors[field] = ["Must be a number"]
            elseif expected_type == Bool && !isa(value, Bool)
                field_errors[field] = ["Must be a boolean"]
            elseif expected_type == Vector{String} && (!isa(value, Vector) || !all(isa(v, String) for v in value))
                field_errors[field] = ["Must be an array of strings"]
            end
        end
    end
    
    if !isempty(field_errors)
        return validation_error("Invalid field types", field_errors)
    end
    
    return nothing
end

"""
Create a success response with consistent structure
"""
function success_response(data::Any=nothing; message::String="", status_code::Int=200)::HTTP.Response
    response_body = Dict{String, Any}()
    
    if !isempty(message)
        response_body["message"] = message
    end
    
    if data !== nothing
        response_body["data"] = data
    end
    
    response_body["timestamp"] = string(now())
    
    return HTTP.Response(
        status_code,
        ["Content-Type" => "application/json"],
        JSON3.write(response_body)
    )
end

"""
Create a paginated success response
"""
function paginated_response(data::Vector, total::Int, page::Int, limit::Int; message::String="")::HTTP.Response
    has_next = (page * limit) < total
    has_prev = page > 1
    
    response_body = Dict{String, Any}(
        "data" => data,
        "pagination" => Dict{String, Any}(
            "total" => total,
            "page" => page,
            "limit" => limit,
            "has_next" => has_next,
            "has_prev" => has_prev
        ),
        "timestamp" => string(now())
    )
    
    if !isempty(message)
        response_body["message"] = message
    end
    
    return HTTP.Response(
        200,
        ["Content-Type" => "application/json"],
        JSON3.write(response_body)
    )
end

end # module ErrorHandling