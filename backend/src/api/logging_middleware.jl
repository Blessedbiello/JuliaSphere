module LoggingMiddleware

using HTTP
using Dates

# Import structured logger
using ..StructuredLogger

"""
Request logging middleware that captures API call metrics
"""
function request_logging_middleware(handler::Function)
    return function(req::HTTP.Request)
        start_time = now()
        request_id = get(get(req, :context, Dict()), "request_id", "unknown")
        
        # Extract request information
        method = req.method
        path = HTTP.URI(req.target).path
        user_agent = get(HTTP.headers(req), "User-Agent", "")
        content_length = get(HTTP.headers(req), "Content-Length", "0")
        request_size = tryparse(Int, content_length)
        
        # Try to extract user ID from auth context
        user_id = nothing
        if haskey(req, :context) && haskey(req.context, "user")
            user_context = req.context["user"]
            if user_context !== nothing
                user_id = string(user_context.user_id)
            end
        end
        
        # Extract client IP (considering proxy headers)
        ip_address = get_client_ip(req)
        
        try
            # Execute the request
            response = handler(req)
            
            # Calculate response metrics
            end_time = now()
            duration = end_time - start_time
            duration_ms = Int(round(duration.value))
            
            response_size = nothing
            if haskey(response, :body) && response.body !== nothing
                response_size = sizeof(response.body)
            end
            
            # Log successful request
            StructuredLogger.log_api_call(
                method, path, response.status, duration_ms;
                request_id=request_id,
                user_id=user_id,
                request_size=request_size,
                response_size=response_size,
                user_agent=user_agent,
                ip_address=ip_address
            )
            
            return response
        catch e
            # Calculate error response metrics
            end_time = now()
            duration = end_time - start_time
            duration_ms = Int(round(duration.value))
            
            # Determine status code from exception
            status_code = if isa(e, HTTP.ExceptionRequest)
                e.status
            else
                500
            end
            
            # Log failed request
            StructuredLogger.log_api_call(
                method, path, status_code, duration_ms;
                request_id=request_id,
                user_id=user_id,
                request_size=request_size,
                user_agent=user_agent,
                ip_address=ip_address
            )
            
            # Log the exception details
            StructuredLogger.log_error(
                "API request failed: $method $path";
                request_id=request_id,
                user_id=user_id,
                exception=e,
                metadata=Dict(
                    "method" => method,
                    "path" => path,
                    "duration_ms" => duration_ms,
                    "ip_address" => ip_address
                )
            )
            
            rethrow(e)
        end
    end
end

"""
Extract client IP address from request headers, considering proxy scenarios
"""
function get_client_ip(req::HTTP.Request)::String
    headers = Dict(HTTP.headers(req))
    
    # Check common proxy headers in order of preference
    proxy_headers = [
        "X-Forwarded-For",
        "X-Real-IP", 
        "X-Client-IP",
        "CF-Connecting-IP",  # Cloudflare
        "True-Client-IP"     # Akamai
    ]
    
    for header in proxy_headers
        if haskey(headers, header)
            ip = strip(split(headers[header], ',')[1])  # Take first IP if comma-separated
            if !isempty(ip) && ip != "unknown"
                return ip
            end
        end
    end
    
    # Fallback to remote address (may not be available in all HTTP.jl versions)
    return get(headers, "Remote-Addr", "unknown")
end

"""
Performance monitoring middleware for slow request detection
"""
function performance_monitoring_middleware(slow_request_threshold_ms::Int=5000)
    return function(handler::Function)
        return function(req::HTTP.Request)
            start_time = now()
            request_id = get(get(req, :context, Dict()), "request_id", "unknown")
            
            response = handler(req)
            
            duration = now() - start_time
            duration_ms = Int(round(duration.value))
            
            # Log slow requests for performance monitoring
            if duration_ms > slow_request_threshold_ms
                method = req.method
                path = HTTP.URI(req.target).path
                
                StructuredLogger.log_warn(
                    "Slow API request detected: $method $path";
                    request_id=request_id,
                    metadata=Dict(
                        "method" => method,
                        "path" => path,
                        "duration_ms" => duration_ms,
                        "threshold_ms" => slow_request_threshold_ms,
                        "status_code" => response.status
                    )
                )
            end
            
            return response
        end
    end
end

"""
Security event logging middleware
"""
function security_logging_middleware(handler::Function)
    return function(req::HTTP.Request)
        method = req.method
        path = HTTP.URI(req.target).path
        request_id = get(get(req, :context, Dict()), "request_id", "unknown")
        ip_address = get_client_ip(req)
        
        # Detect potentially suspicious requests
        suspicious_patterns = [
            r"\.\./"i,           # Path traversal
            r"<script"i,         # XSS attempts
            r"union\s+select"i,  # SQL injection
            r"eval\s*\("i,       # Code injection
            r"base64_decode"i    # Encoded payload
        ]
        
        # Check URL and query parameters for suspicious content
        target = req.target
        is_suspicious = any(occursin(pattern, target) for pattern in suspicious_patterns)
        
        # Check request body for suspicious content (if present and not too large)
        if !isempty(req.body) && sizeof(req.body) < 10000  # Only check small bodies
            body_str = String(req.body)
            is_suspicious = is_suspicious || any(occursin(pattern, body_str) for pattern in suspicious_patterns)
        end
        
        if is_suspicious
            StructuredLogger.log_warn(
                "Suspicious request detected: $method $path";
                request_id=request_id,
                metadata=Dict(
                    "method" => method,
                    "path" => path,
                    "ip_address" => ip_address,
                    "user_agent" => get(Dict(HTTP.headers(req)), "User-Agent", ""),
                    "target" => target,
                    "reason" => "suspicious_patterns"
                )
            )
        end
        
        response = handler(req)
        
        # Log authentication failures
        if response.status == 401
            StructuredLogger.log_warn(
                "Authentication failure: $method $path";
                request_id=request_id,
                metadata=Dict(
                    "method" => method,
                    "path" => path,
                    "ip_address" => ip_address,
                    "status_code" => response.status
                )
            )
        end
        
        # Log authorization failures
        if response.status == 403
            user_id = nothing
            if haskey(req, :context) && haskey(req.context, "user")
                user_context = req.context["user"]
                if user_context !== nothing
                    user_id = string(user_context.user_id)
                end
            end
            
            StructuredLogger.log_warn(
                "Authorization failure: $method $path";
                request_id=request_id,
                user_id=user_id,
                metadata=Dict(
                    "method" => method,
                    "path" => path,
                    "ip_address" => ip_address,
                    "status_code" => response.status
                )
            )
        end
        
        return response
    end
end

"""
Rate limiting logging middleware (logs when rate limits are exceeded)
"""
function rate_limit_logging_middleware(handler::Function)
    return function(req::HTTP.Request)
        response = handler(req)
        
        # Log rate limiting events
        if response.status == 429
            method = req.method
            path = HTTP.URI(req.target).path
            request_id = get(get(req, :context, Dict()), "request_id", "unknown")
            ip_address = get_client_ip(req)
            
            retry_after = nothing
            for (key, value) in response.headers
                if lowercase(key) == "retry-after"
                    retry_after = value
                    break
                end
            end
            
            StructuredLogger.log_warn(
                "Rate limit exceeded: $method $path";
                request_id=request_id,
                metadata=Dict(
                    "method" => method,
                    "path" => path,
                    "ip_address" => ip_address,
                    "retry_after" => retry_after,
                    "status_code" => response.status
                )
            )
        end
        
        return response
    end
end

"""
Composite middleware that combines all logging functionality
"""
function comprehensive_logging_middleware(;
    slow_request_threshold_ms::Int=5000,
    enable_security_logging::Bool=true,
    enable_performance_monitoring::Bool=true,
    enable_rate_limit_logging::Bool=true
)
    return function(handler::Function)
        wrapped_handler = handler
        
        # Apply middlewares in reverse order (they wrap around each other)
        if enable_rate_limit_logging
            wrapped_handler = rate_limit_logging_middleware(wrapped_handler)
        end
        
        if enable_security_logging
            wrapped_handler = security_logging_middleware(wrapped_handler)
        end
        
        if enable_performance_monitoring
            wrapped_handler = performance_monitoring_middleware(slow_request_threshold_ms)(wrapped_handler)
        end
        
        # Request logging is always applied last (outermost)
        wrapped_handler = request_logging_middleware(wrapped_handler)
        
        return wrapped_handler
    end
end

end # module LoggingMiddleware