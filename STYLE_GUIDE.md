# JuliaOS Code Style Guide

This document outlines the coding standards and conventions used in the JuliaOS project to ensure consistency, readability, and maintainability.

## Table of Contents

1. [General Principles](#general-principles)
2. [Naming Conventions](#naming-conventions)
3. [Code Organization](#code-organization)
4. [Documentation Standards](#documentation-standards)
5. [Type System Guidelines](#type-system-guidelines)
6. [Module Structure](#module-structure)
7. [Error Handling](#error-handling)
8. [Testing Standards](#testing-standards)

## General Principles

### Follow Julia Style Guidelines
- Adhere to the [Julia Style Guide](https://docs.julialang.org/en/v1/manual/style-guide/)
- Use 4 spaces for indentation (no tabs)
- Maximum line length of 92 characters
- Use meaningful variable and function names

### Code Readability
- Write code that tells a story
- Prefer explicit over implicit
- Use whitespace effectively for visual grouping
- Add comments for complex logic, not obvious code

## Naming Conventions

### Variables and Functions
```julia
# Use snake_case for variables and functions
user_id = "123"
agent_config = Dict()
process_agent_request(request)

# Use descriptive names
# Good
agent_execution_count = 0
calculate_performance_metrics()

# Bad
c = 0  
calc_pm()
```

### Constants
```julia
# Use SCREAMING_SNAKE_CASE for constants
const MAX_RETRY_ATTEMPTS = 3
const DEFAULT_TIMEOUT_MS = 5000
const TOOL_REGISTRY = Dict{String, ToolSpecification}()
```

### Types and Structs
```julia
# Use PascalCase for types
struct AgentConfiguration
    id::String
    name::String
    tools::Vector{ToolSpecification}
end

abstract type ToolConfig end

# Enums should be descriptive
@enum AgentState CREATED_STATE RUNNING_STATE PAUSED_STATE STOPPED_STATE
```

### Modules
```julia
# Use PascalCase for module names
module AgentManagement
module DatabaseOperations  
module MarketplaceAPI
```

### Files and Directories
```julia
# Use snake_case for filenames
agent_management.jl
database_operations.jl
marketplace_api.jl

# Group related functionality in directories
agents/
    tools/
    strategies/
    triggers/
api/
    endpoints/
    middleware/
    validation/
```

## Code Organization

### Module Structure
Every module should follow this pattern:

```julia
module ModuleName

# Imports at the top
using SomePackage
import AnotherPackage: specific_function

# Include statements
include("submodule1.jl")
include("submodule2.jl")

# Using statements for included modules
using .SubModule1, .SubModule2

# Constants
const MODULE_CONSTANT = "value"

# Types and structs
struct SomeType
    field::String
end

# Main functionality
function main_function()
    # implementation
end

# Helper functions
function _helper_function()
    # implementation
end

# Exports at the bottom
export main_function, SomeType

end # module ModuleName
```

### Function Organization
```julia
"""
Brief description of what the function does.

# Arguments
- `arg1::Type`: Description of first argument
- `arg2::Type`: Description of second argument  
- `optional_arg::Type=default`: Description of optional argument

# Returns
- `ReturnType`: Description of return value

# Throws
- `ArgumentError`: When input validation fails
- `NetworkError`: When network request fails

# Examples
```julia
result = my_function("example", 42)
```
"""
function my_function(arg1::String, arg2::Int; optional_arg::Bool=false)
    # Input validation
    isempty(arg1) && throw(ArgumentError("arg1 cannot be empty"))
    arg2 < 0 && throw(ArgumentError("arg2 must be non-negative"))
    
    # Main logic
    result = process_arguments(arg1, arg2)
    
    # Return
    return optional_arg ? transform_result(result) : result
end
```

## Documentation Standards

### Module Documentation
```julia
"""
    ModuleName

Brief description of the module's purpose.

This module provides functionality for [specific domain]. It includes:
- Feature 1: Description
- Feature 2: Description
- Feature 3: Description

# Examples
```julia
using .ModuleName
result = main_function("input")
```

See also: [`RelatedModule`](@ref), [`other_function`](@ref)
"""
module ModuleName
```

### Function Documentation
Use Julia's docstring format with the following sections:
- Brief description (one line)
- Detailed description (if needed)
- Arguments section
- Returns section  
- Throws section (if applicable)
- Examples section
- See also section (if applicable)

### Type Documentation
```julia
"""
    AgentConfiguration

Configuration structure for JuliaOS agents.

This struct encapsulates all configuration parameters needed to create
and run an agent within the JuliaOS framework.

# Fields
- `id::String`: Unique identifier for the agent
- `name::String`: Human-readable name for the agent  
- `description::String`: Detailed description of agent purpose
- `tools::Vector{ToolSpecification}`: List of available tools
- `strategy::StrategySpecification`: Execution strategy configuration
- `trigger::TriggerConfiguration`: Event trigger configuration

# Examples
```julia
config = AgentConfiguration(
    "agent-1",
    "News Scraper", 
    "Scrapes and summarizes AI news",
    [web_scraper_tool, summarizer_tool],
    plan_execute_strategy,
    schedule_trigger
)
```
"""
struct AgentConfiguration
    id::String
    name::String
    description::String
    tools::Vector{ToolSpecification}
    strategy::StrategySpecification  
    trigger::TriggerConfiguration
end
```

## Type System Guidelines

### Use Concrete Types for Performance
```julia
# Good - concrete types
struct AgentMetrics
    execution_count::Int64
    success_rate::Float64
    average_duration_ms::Int32
end

# Avoid - abstract/Any types for performance-critical code
struct SlowMetrics
    data::Any  # Avoid this
end
```

### Use Union Types for Optional Values
```julia
# Good - explicit union with Nothing
struct UserProfile  
    id::String
    email::Union{String, Nothing}
    avatar_url::Union{String, Nothing}
end

# Initialize with nothing
profile = UserProfile("123", nothing, nothing)
```

### Parameterized Types for Flexibility
```julia
# Generic response type
struct ApiResponse{T}
    data::T
    status::Int
    message::String
end

# Usage
user_response = ApiResponse{User}(user_data, 200, "Success")
error_response = ApiResponse{Nothing}(nothing, 404, "Not found")
```

## Error Handling

### Use Specific Exception Types
```julia
# Define custom exceptions for your domain
struct AgentNotFoundError <: Exception
    agent_id::String
end

struct InvalidConfigurationError <: Exception
    field::String
    reason::String
end

# Use them consistently
function get_agent(id::String)
    haskey(AGENTS, id) || throw(AgentNotFoundError(id))
    return AGENTS[id]
end
```

### Error Messages Should Be Actionable
```julia
# Good - specific and actionable
throw(ArgumentError("Agent name must be 1-100 characters, got $(length(name))"))

# Bad - vague
throw(ArgumentError("Invalid name"))
```

### Use Result Types for Expected Errors
```julia
# For operations that commonly fail
struct Result{T, E}
    value::Union{T, Nothing}
    error::Union{E, Nothing}
    success::Bool
end

function safe_parse_json(input::String)::Result{Dict, String}
    try
        data = JSON3.read(input, Dict)
        return Result{Dict, String}(data, nothing, true)
    catch e
        return Result{Dict, String}(nothing, string(e), false)
    end
end
```

## Module Structure

### Agent System Modules
```
agents/
├── Agents.jl              # Main module coordinator
├── CommonTypes.jl         # Shared type definitions
├── agent_management.jl    # Agent lifecycle management
├── utils.jl              # Utility functions
├── tools/
│   ├── Tools.jl          # Tool registry and management
│   ├── tool_*.jl         # Individual tool implementations
│   └── telegram/         # Tool category grouping
├── strategies/
│   ├── Strategies.jl     # Strategy registry
│   ├── strategy_*.jl     # Individual strategies
│   └── telegram/         # Strategy category grouping
└── triggers/
    ├── Triggers.jl       # Trigger system
    └── trigger_*.jl      # Individual trigger types
```

### API System Modules
```
api/
├── JuliaOSV1Server.jl    # Main server module
├── auth.jl               # Authentication & authorization
├── validation.jl         # Request validation
├── error_handling.jl     # Standardized error responses
├── logging_middleware.jl # Request/response logging
├── server/               # Auto-generated OpenAPI code
└── endpoints/            # Manual endpoint implementations
```

### Database System Modules
```
db/
├── JuliaDB.jl           # Main database module
├── connection_management.jl # Connection pooling
├── updating.jl          # Write operations
├── loading.jl           # Read operations
├── migrations/          # Database schema changes
└── utils.jl            # Database utilities
```

## Testing Standards

### Test File Organization
```julia
# tests/test_agent_management.jl
using Test
using JuliaOSBackend.Agents

@testset "Agent Management Tests" begin
    @testset "Agent Creation" begin
        # Test successful creation
        @test create_agent("test-1", "Test Agent", test_config) isa Agent
        
        # Test validation errors
        @test_throws ArgumentError create_agent("", "Test Agent", test_config)
    end
    
    @testset "Agent Lifecycle" begin
        agent = create_agent("test-2", "Test Agent", test_config) 
        
        @test agent.state == CREATED_STATE
        start_agent(agent)
        @test agent.state == RUNNING_STATE
    end
end
```

### Mock External Dependencies
```julia
# Use dependency injection for testability
function process_agent_request(request, database=get_database())
    # implementation using database
end

# In tests
@testset "Request Processing" begin
    mock_db = MockDatabase()
    result = process_agent_request(test_request, mock_db)
    @test result.status == "success"
end
```

## Performance Guidelines

### Prefer Type-Stable Code
```julia
# Good - type stable
function calculate_metrics(data::Vector{Float64})::Float64
    return sum(data) / length(data)
end

# Bad - type unstable
function calculate_metrics(data)
    if isa(data, Vector)
        return sum(data) / length(data)  # Type unclear
    else
        return 0.0
    end
end
```

### Use @inbounds and @simd When Safe
```julia
function fast_sum(arr::Vector{Float64})
    total = 0.0
    @inbounds @simd for i in 1:length(arr)
        total += arr[i]
    end
    return total
end
```

### Pre-allocate Collections When Possible
```julia
# Good - pre-allocate
function process_items(items::Vector{Item})
    results = Vector{ProcessedItem}(undef, length(items))
    for (i, item) in enumerate(items)
        results[i] = process_item(item)
    end
    return results
end
```

This style guide should be followed for all new code and applied when refactoring existing code. It ensures consistency across the JuliaOS codebase and makes it easier for new contributors to understand and maintain the code.