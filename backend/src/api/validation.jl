macro validate_model(model)
    return quote
        local _validation_result = validate_model($(esc(model)))
        if _validation_result !== nothing
            @info "Validation failed for $(typeof($(esc(model))))"
            return _validation_result
        end
    end
end

function validate_model(model)::Union{HTTP.Response, Nothing}
    processed_ids = Set{UInt}()
    stack = Vector{Any}()
    push!(stack, model)

    while !isempty(stack)
        obj = pop!(stack)
        obj_id = objectid(obj)

        if obj_id in processed_ids
            continue
        end
        push!(processed_ids, obj_id)

        if obj isa OpenAPI.APIModel
            validation_result = validate_single_model!(stack, obj)
            if validation_result !== nothing
                return validation_result
            end
        elseif obj isa AbstractVector
            for item in obj
                push!(stack, item)
            end
        end
    end

    return nothing
end

function validate_single_model!(children_stack::Vector{Any}, obj)::Union{HTTP.Response, Nothing}
    T = typeof(obj)

    if !JuliaOSServer.check_required(obj)
        return HTTP.Response(400, "Missing required fields in $(T)")
    end

    for field in fieldnames(T)
        val = getfield(obj, field)
        try
            OpenAPI.validate_property(T, field, val)
        catch e
            return HTTP.Response(400, "Invalid value for field $(field) in $(T): $(e.message)")
        end
        if val isa OpenAPI.APIModel || val isa AbstractVector
            push!(children_stack, val)
        end
    end
    return nothing
end

# Enhanced validation system for better type safety and security
module RequestValidation

using JSON3
using UUIDs
using Dates
using HTTP

"""
Validation rule structure
"""
struct ValidationRule
    field::String
    required::Bool
    type_check::Union{Function, Nothing}
    validator::Union{Function, Nothing}
    error_message::String
end

"""
Create a validation rule for a required field
"""
function required_field(field::String, type_check::Function=x->true, validator::Function=x->true; error_message::String="")
    message = isempty(error_message) ? "Field '$field' is required" : error_message
    return ValidationRule(field, true, type_check, validator, message)
end

"""
Create a validation rule for an optional field
"""
function optional_field(field::String, type_check::Function=x->true, validator::Function=x->true; error_message::String="")
    message = isempty(error_message) ? "Field '$field' is invalid" : error_message
    return ValidationRule(field, false, type_check, validator, message)
end

"""
Common type validators
"""
module TypeValidators
    is_string(x) = isa(x, String)
    is_integer(x) = isa(x, Int) || (isa(x, Number) && isinteger(x))
    is_positive_integer(x) = is_integer(x) && x > 0
    is_non_negative_integer(x) = is_integer(x) && x >= 0
    is_float(x) = isa(x, Number)
    is_positive_float(x) = is_float(x) && x > 0
    is_boolean(x) = isa(x, Bool)
    is_array(x) = isa(x, Vector)
    is_string_array(x) = isa(x, Vector) && all(isa(item, String) for item in x)
    is_object(x) = isa(x, Dict)
    is_uuid(x) = try; UUID(string(x)); true; catch; false; end
    is_datetime(x) = try; DateTime(string(x)); true; catch; false; end
    is_email(x) = is_string(x) && occursin(r"^[^@]+@[^@]+\.[^@]+$", x)
    is_url(x) = is_string(x) && (startswith(x, "http://") || startswith(x, "https://"))
    is_non_empty_string(x) = is_string(x) && !isempty(strip(x))
end

"""
Common business logic validators
"""
module BusinessValidators
    function is_valid_pricing_model(x)
        valid_models = ["free", "one_time", "subscription", "usage_based"]
        return isa(x, String) && x in valid_models
    end
    
    function is_valid_agent_state(x)
        valid_states = ["CREATED", "RUNNING", "PAUSED", "STOPPED"]
        return isa(x, String) && x in valid_states
    end
    
    function is_valid_rating(x)
        return isa(x, Int) && x >= 1 && x <= 5
    end
    
    function is_valid_currency(x)
        valid_currencies = ["USD", "EUR", "GBP", "BTC", "ETH"]
        return isa(x, String) && x in valid_currencies
    end
    
    function is_reasonable_string_length(x, max_length::Int=1000)
        return isa(x, String) && length(x) <= max_length
    end
    
    function is_valid_category(x)
        valid_categories = ["trading", "dao", "research", "utility", "social", "gaming", "defi", "nft"]
        return isa(x, String) && x in valid_categories
    end
end

"""
Sanitize string input to prevent basic XSS and injection
"""
function sanitize_string(input::String)::String
    # Remove potential script tags and dangerous characters
    sanitized = replace(input, r"<script[^>]*>.*?</script>"i => "")
    sanitized = replace(sanitized, r"javascript:" => "")
    sanitized = replace(sanitized, r"on\w+\s*=" => "")  # Remove event handlers
    
    # Trim and normalize whitespace
    return strip(sanitized)
end

"""
Validate request data against validation rules
"""
function validate_request_data(data::Dict{String, Any}, rules::Vector{ValidationRule})
    field_errors = Dict{String, Vector{String}}()
    
    for rule in rules
        field_value = get(data, rule.field, nothing)
        
        # Check if required field is missing
        if rule.required && (field_value === nothing || (isa(field_value, String) && isempty(strip(field_value))))
            field_errors[rule.field] = [rule.error_message]
            continue
        end
        
        # Skip validation for optional fields that are not provided
        if !rule.required && field_value === nothing
            continue
        end
        
        # Type check
        if rule.type_check !== nothing && !rule.type_check(field_value)
            if !haskey(field_errors, rule.field)
                field_errors[rule.field] = String[]
            end
            push!(field_errors[rule.field], "Invalid type for field '$(rule.field)'")
            continue
        end
        
        # Business logic validation
        if rule.validator !== nothing && !rule.validator(field_value)
            if !haskey(field_errors, rule.field)
                field_errors[rule.field] = String[]
            end
            push!(field_errors[rule.field], rule.error_message)
        end
    end
    
    return field_errors
end

end # module RequestValidation

