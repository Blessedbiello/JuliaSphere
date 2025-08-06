using HTTP
using JSON3
using ..CommonTypes: ToolSpecification, ToolMetadata, ToolConfig

Base.@kwdef struct ToolSolanaRPCConfig <: ToolConfig
    rpc_url::String = "https://api.mainnet-beta.solana.com"
    timeout_seconds::Int = 30
end

"""
    tool_solana_rpc(cfg::ToolSolanaRPCConfig, task::Dict) -> Dict{String, Any}

Executes Solana RPC calls to fetch blockchain data including transactions, accounts, and balances.

# Arguments
- `cfg::ToolSolanaRPCConfig`: Configuration containing RPC URL and timeout settings
- `task::Dict`: Task dictionary containing:
  - `method::String`: RPC method name (e.g., "getTransaction", "getAccountInfo", "getSignaturesForAddress")
  - `params::Array`: Parameters for the RPC call
  - `address::String` (optional): Solana address for address-specific queries

# Returns
Dictionary with execution result including transaction data, account info, or error messages.

# Examples
```julia
# Get transaction details
task = Dict(
    "method" => "getTransaction",
    "params" => ["5j7s88kMfF...signature", Dict("encoding" => "json", "maxSupportedTransactionVersion" => 0)]
)

# Get account signatures  
task = Dict(
    "method" => "getSignaturesForAddress",
    "params" => ["DjVE6JNiYqPL2QXyCUUh8rNjHrbz9hXHNYt99MQ59qw1", Dict("limit" => 100)]
)
```
"""
function tool_solana_rpc(cfg::ToolSolanaRPCConfig, task::Dict)::Dict{String,Any}
    # Validate required fields
    if !haskey(task, "method") || !(task["method"] isa AbstractString)
        return Dict("success" => false, "error" => "Missing or invalid 'method' field")
    end
    
    if !haskey(task, "params") || !(task["params"] isa AbstractVector)
        return Dict("success" => false, "error" => "Missing or invalid 'params' field")
    end

    method = task["method"]
    params = task["params"]
    
    # Build RPC request
    rpc_request = Dict(
        "jsonrpc" => "2.0",
        "id" => 1,
        "method" => method,
        "params" => params
    )

    try
        # Execute RPC call
        response = HTTP.post(
            cfg.rpc_url,
            ["Content-Type" => "application/json"],
            JSON3.write(rpc_request);
            connect_timeout=cfg.timeout_seconds,
            readtimeout=cfg.timeout_seconds
        )
        
        if response.status != 200
            return Dict(
                "success" => false, 
                "error" => "RPC request failed with status $(response.status)",
                "response_body" => String(response.body)
            )
        end
        
        # Parse response
        result = JSON3.read(String(response.body))
        
        if haskey(result, "error")
            return Dict(
                "success" => false,
                "error" => "RPC error: $(result.error.message)",
                "error_code" => result.error.code
            )
        end
        
        return Dict(
            "success" => true,
            "method" => method,
            "result" => result.result,
            "raw_response" => result
        )
        
    catch e
        return Dict(
            "success" => false,
            "error" => "Exception during RPC call: $(string(e))"
        )
    end
end

const TOOL_SOLANA_RPC_METADATA = ToolMetadata(
    "solana_rpc",
    "Executes Solana RPC calls to fetch blockchain data including transactions, accounts, and signatures."
)

const TOOL_SOLANA_RPC_SPECIFICATION = ToolSpecification(
    tool_solana_rpc,
    ToolSolanaRPCConfig,
    TOOL_SOLANA_RPC_METADATA
)