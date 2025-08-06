"""
    CommonTypes

Core type definitions for the JuliaOS agent framework.

This module defines all the fundamental types and structures used throughout
the JuliaOS system, including:
- Tool system types and configurations
- Agent state management and contexts  
- Trigger and strategy specifications
- Blueprint types for agent construction

These types form the foundation of the JuliaOS type system and ensure
type safety across all modules.
"""
module CommonTypes

using StructTypes

# =============================================================================
# TOOL SYSTEM TYPES
# =============================================================================

"""
    ToolConfig

Abstract base type for all tool configuration objects.

Tool configurations contain the parameters and settings needed to
execute a specific tool. Each tool implementation should define
a concrete subtype of `ToolConfig` with its specific parameters.

# Examples
```julia
struct WebScraperConfig <: ToolConfig
    url::String
    timeout_seconds::Int
end
```
"""
abstract type ToolConfig end

"""
    ToolMetadata

Metadata information for a tool specification.

Contains descriptive information about a tool that is used for
registration, documentation, and user interfaces.

# Fields
- `name::String`: Unique identifier for the tool
- `description::String`: Human-readable description of tool functionality

# Examples
```julia
metadata = ToolMetadata(
    "web_scraper",
    "Scrapes content from web pages and extracts text"
)
```
"""
struct ToolMetadata
    name::String
    description::String
end

"""
    ToolSpecification

Complete specification for a tool that can be used by agents.

This struct contains everything needed to register and instantiate a tool,
including the execution function, configuration type, and metadata.

# Fields
- `execute::Function`: Function that implements the tool's functionality
- `config_type::DataType`: Type of configuration object this tool expects
- `metadata::ToolMetadata`: Descriptive metadata about the tool

# Examples
```julia
spec = ToolSpecification(
    web_scraper_execute,
    WebScraperConfig,
    ToolMetadata("web_scraper", "Scrapes web content")
)
```
"""
struct ToolSpecification
    execute::Function
    config_type::DataType
    metadata::ToolMetadata
end

"""
    InstantiatedTool

A tool that has been configured and is ready for execution.

This represents a tool that has been paired with a specific configuration
and is ready to be used by an agent during execution.

# Fields
- `execute::Function`: The tool's execution function
- `config::ToolConfig`: Configured parameters for this tool instance
- `metadata::ToolMetadata`: Tool metadata for identification

# Examples
```julia
config = WebScraperConfig("https://example.com", 30)
tool = InstantiatedTool(web_scraper_execute, config, metadata)
```
"""
struct InstantiatedTool
    execute::Function
    config::ToolConfig
    metadata::ToolMetadata
end

# =============================================================================
# AGENT STATE MANAGEMENT
# =============================================================================

"""
    AgentState

Enumeration of possible agent execution states.

Agents transition through these states during their lifecycle:
- `CREATED_STATE`: Agent has been created but not started
- `RUNNING_STATE`: Agent is actively executing
- `PAUSED_STATE`: Agent execution is temporarily suspended
- `STOPPED_STATE`: Agent has been permanently stopped

# State Transitions
```
CREATED → RUNNING → PAUSED ⇄ RUNNING → STOPPED
    ↓                                      ↑
    └──────────────────────────────────────┘
```
"""
@enum AgentState CREATED_STATE RUNNING_STATE PAUSED_STATE STOPPED_STATE

struct AgentContext
    tools::Vector{InstantiatedTool}
    logs::Vector{String}
end

# Triggers:

@enum TriggerType PERIODIC_TRIGGER WEBHOOK_TRIGGER

abstract type TriggerParams end

struct TriggerConfig
    type::TriggerType
    params::TriggerParams
end

struct PeriodicTriggerParams <: TriggerParams
    interval::Int  # Interval in seconds
end

struct WebhookTriggerParams <: TriggerParams
end

# Strategies:

abstract type StrategyConfig end

struct StrategyMetadata
    name::String
end

abstract type StrategyInput end
StructTypes.StructType(::Type{T}) where {T<:StrategyInput} = StructTypes.Struct()

struct StrategySpecification
    run::Function
    initialize::Union{Nothing, Function}
    config_type::DataType
    metadata::StrategyMetadata
    input_type::Union{DataType,Nothing}
end

struct InstantiatedStrategy
    run::Function
    initialize::Union{Nothing, Function}
    config::StrategyConfig
    metadata::StrategyMetadata
    input_type::Union{DataType,Nothing}
end

# Blueprints:

struct ToolBlueprint
    name::String
    config_data::Dict{String, Any}
end

struct StrategyBlueprint
    name::String
    config_data::Dict{String, Any}
end

struct AgentBlueprint
    tools::Vector{ToolBlueprint}
    strategy::StrategyBlueprint
    trigger::TriggerConfig
end

# Agent proper:

mutable struct Agent
    id::String
    name::String
    description::String
    context::AgentContext
    strategy::InstantiatedStrategy
    trigger::TriggerConfig
    state::AgentState
end

end