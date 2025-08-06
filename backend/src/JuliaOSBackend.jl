module JuliaOSBackend

include("resources/Resources.jl")
include("agents/Agents.jl")
include("db/JuliaDB.jl")
include("api/JuliaOSV1Server.jl")
include("marketplace/MarketplaceAPI.jl")
include("marketplace/AgentAnalytics.jl")
include("marketplace/SwarmCoordination.jl")
include("logging/structured_logger.jl")

using .Resources
using .Agents
using .JuliaDB
using .JuliaOSV1Server
using .MarketplaceAPI
using .AgentAnalytics
using .SwarmCoordination
using .StructuredLogger

# Configure structured logging on module load
function __init__()
    # Configure logger based on environment
    log_level = get(ENV, "JULIA_LOG_LEVEL", "INFO")
    log_format = get(ENV, "JULIA_LOG_FORMAT", "json")
    
    StructuredLogger.configure_logger(
        min_level=log_level,
        output_format=log_format,
        include_stack_trace=true,
        sanitize_sensitive_data=true
    )
    
    StructuredLogger.log_info("JuliaOS Backend initialized"; 
        metadata=Dict("version" => "1.0.0", "log_level" => log_level))
end

end