using HTTP
using JSON3
using ..CommonTypes: ToolSpecification, ToolMetadata, ToolConfig

Base.@kwdef struct ToolTransactionTracerConfig <: ToolConfig
    rpc_url::String = "https://api.mainnet-beta.solana.com"
    max_hops::Int = 10
    timeout_seconds::Int = 30
    min_transfer_amount::Float64 = 0.001  # Minimum SOL amount to consider significant
end

"""
    tool_transaction_tracer(cfg::ToolTransactionTracerConfig, task::Dict) -> Dict{String, Any}

Traces transaction paths by following the flow of funds across multiple hops to reconstruct 
the complete transaction chain from source to destination addresses.

# Arguments
- `cfg::ToolTransactionTracerConfig`: Configuration for tracing parameters
- `task::Dict`: Task dictionary containing:
  - `start_address::String`: Starting address to trace from
  - `target_address::String` (optional): Target address to trace to
  - `max_depth::Int` (optional): Maximum tracing depth (defaults to config max_hops)
  - `follow_direction::String` (optional): "incoming", "outgoing", or "both" (default: "outgoing")
  - `time_range::Dict` (optional): Dict with "start_time" and "end_time" timestamps

# Returns
Dictionary containing the traced transaction path with detailed hop information.
"""
function tool_transaction_tracer(cfg::ToolTransactionTracerConfig, task::Dict)::Dict{String,Any}
    # Validate required fields
    if !haskey(task, "start_address") || !(task["start_address"] isa AbstractString)
        return Dict("success" => false, "error" => "Missing or invalid 'start_address' field")
    end

    start_address = task["start_address"]
    target_address = get(task, "target_address", nothing)
    max_depth = get(task, "max_depth", cfg.max_hops)
    follow_direction = get(task, "follow_direction", "outgoing")
    
    try
        # Initialize tracing data structures
        transaction_path = []
        visited_addresses = Set([start_address])
        current_addresses = [start_address]
        depth = 0
        
        total_volume_traced = 0.0
        suspicious_patterns = []
        
        while depth < max_depth && !isempty(current_addresses)
            depth += 1
            next_addresses = []
            
            for address in current_addresses
                # Get signatures for the current address
                sigs_result = get_address_signatures(cfg, address)
                if !sigs_result["success"]
                    continue
                end
                
                signatures = sigs_result["signatures"]
                
                for sig_info in signatures
                    # Get detailed transaction info
                    tx_result = get_transaction_details(cfg, sig_info["signature"])
                    if !tx_result["success"]
                        continue
                    end
                    
                    tx_data = tx_result["transaction"]
                    
                    # Analyze transaction for fund flows
                    flow_analysis = analyze_transaction_flow(tx_data, address, follow_direction)
                    
                    if !isempty(flow_analysis["transfers"])
                        hop_info = Dict(
                            "depth" => depth,
                            "transaction_signature" => sig_info["signature"],
                            "slot" => sig_info["slot"],
                            "timestamp" => get(sig_info, "blockTime", nothing),
                            "source_address" => address,
                            "transfers" => flow_analysis["transfers"],
                            "total_amount" => flow_analysis["total_amount"],
                            "program_interactions" => flow_analysis["programs"],
                            "suspicious_indicators" => flow_analysis["suspicious_patterns"]
                        )
                        
                        push!(transaction_path, hop_info)
                        total_volume_traced += flow_analysis["total_amount"]
                        
                        # Check for suspicious patterns
                        if !isempty(flow_analysis["suspicious_patterns"])
                            append!(suspicious_patterns, flow_analysis["suspicious_patterns"])
                        end
                        
                        # Add new addresses for next hop tracing
                        for transfer in flow_analysis["transfers"]
                            destination = transfer["destination"]
                            if !(destination in visited_addresses) && 
                               transfer["amount"] >= cfg.min_transfer_amount
                                push!(next_addresses, destination)
                                push!(visited_addresses, destination)
                            end
                        end
                        
                        # Check if we found the target
                        if target_address !== nothing && target_address in [t["destination"] for t in flow_analysis["transfers"]]
                            return Dict(
                                "success" => true,
                                "trace_completed" => true,
                                "target_found" => true,
                                "transaction_path" => transaction_path,
                                "total_hops" => depth,
                                "total_volume" => total_volume_traced,
                                "suspicious_patterns" => unique(suspicious_patterns),
                                "addresses_visited" => collect(visited_addresses)
                            )
                        end
                    end
                end
            end
            
            current_addresses = unique(next_addresses)
            
            # Limit to prevent excessive API calls
            if length(current_addresses) > 20
                current_addresses = current_addresses[1:20]
            end
        end
        
        return Dict(
            "success" => true,
            "trace_completed" => depth >= max_depth,
            "target_found" => false,
            "transaction_path" => transaction_path,
            "total_hops" => length(transaction_path),
            "total_volume" => total_volume_traced,
            "suspicious_patterns" => unique(suspicious_patterns),
            "addresses_visited" => collect(visited_addresses),
            "final_addresses" => current_addresses
        )
        
    catch e
        return Dict(
            "success" => false,
            "error" => "Exception during transaction tracing: $(string(e))"
        )
    end
end

# Helper function to get signatures for an address
function get_address_signatures(cfg::ToolTransactionTracerConfig, address::String; limit::Int=50)
    rpc_request = Dict(
        "jsonrpc" => "2.0",
        "id" => 1,
        "method" => "getSignaturesForAddress",
        "params" => [address, Dict("limit" => limit)]
    )
    
    try
        response = HTTP.post(
            cfg.rpc_url,
            ["Content-Type" => "application/json"],
            JSON3.write(rpc_request);
            connect_timeout=cfg.timeout_seconds
        )
        
        if response.status == 200
            result = JSON3.read(String(response.body))
            if haskey(result, "result")
                return Dict("success" => true, "signatures" => result.result)
            end
        end
        
        return Dict("success" => false, "error" => "Failed to fetch signatures")
    catch e
        return Dict("success" => false, "error" => string(e))
    end
end

# Helper function to get transaction details
function get_transaction_details(cfg::ToolTransactionTracerConfig, signature::String)
    rpc_request = Dict(
        "jsonrpc" => "2.0",
        "id" => 1,
        "method" => "getTransaction",
        "params" => [signature, Dict("encoding" => "json", "maxSupportedTransactionVersion" => 0)]
    )
    
    try
        response = HTTP.post(
            cfg.rpc_url,
            ["Content-Type" => "application/json"],
            JSON3.write(rpc_request);
            connect_timeout=cfg.timeout_seconds
        )
        
        if response.status == 200
            result = JSON3.read(String(response.body))
            if haskey(result, "result") && result.result !== nothing
                return Dict("success" => true, "transaction" => result.result)
            end
        end
        
        return Dict("success" => false, "error" => "Failed to fetch transaction")
    catch e
        return Dict("success" => false, "error" => string(e))
    end
end

# Helper function to analyze transaction for fund flows
function analyze_transaction_flow(tx_data, focus_address::String, direction::String)
    transfers = []
    total_amount = 0.0
    programs = []
    suspicious_patterns = []
    
    if haskey(tx_data, "transaction") && haskey(tx_data["transaction"], "message")
        message = tx_data["transaction"]["message"]
        
        # Get account keys
        account_keys = message["accountKeys"]
        
        # Analyze pre and post balances
        if haskey(tx_data["meta"], "preBalances") && haskey(tx_data["meta"], "postBalances")
            pre_balances = tx_data["meta"]["preBalances"]
            post_balances = tx_data["meta"]["postBalances"]
            
            for (i, account) in enumerate(account_keys)
                if i <= length(pre_balances) && i <= length(post_balances)
                    balance_change = (post_balances[i] - pre_balances[i]) / 1e9  # Convert lamports to SOL
                    
                    if abs(balance_change) >= 0.001  # Minimum significant change
                        if balance_change > 0 && direction in ["incoming", "both"]
                            # Incoming transfer to this account
                            if account != focus_address
                                push!(transfers, Dict(
                                    "source" => focus_address,
                                    "destination" => account,
                                    "amount" => balance_change,
                                    "type" => "SOL_transfer"
                                ))
                                total_amount += balance_change
                            end
                        elseif balance_change < 0 && direction in ["outgoing", "both"]
                            # Outgoing transfer from this account
                            if account == focus_address
                                # Find where the funds went (need to check other accounts)
                                for (j, other_account) in enumerate(account_keys)
                                    if j != i && j <= length(post_balances)
                                        other_change = (post_balances[j] - pre_balances[j]) / 1e9
                                        if other_change > 0 && abs(other_change) >= abs(balance_change) * 0.9
                                            push!(transfers, Dict(
                                                "source" => focus_address,
                                                "destination" => other_account,
                                                "amount" => abs(balance_change),
                                                "type" => "SOL_transfer"
                                            ))
                                            total_amount += abs(balance_change)
                                            break
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        
        # Analyze program interactions for suspicious patterns
        if haskey(message, "instructions")
            for instruction in message["instructions"]
                program_id_index = instruction["programIdIndex"]
                if program_id_index <= length(account_keys)
                    program_id = account_keys[program_id_index]
                    push!(programs, program_id)
                    
                    # Check for known mixer/tumbler programs
                    if is_mixer_program(program_id)
                        push!(suspicious_patterns, "mixer_interaction")
                    end
                end
            end
        end
        
        # Check for other suspicious patterns
        if length(transfers) > 10
            push!(suspicious_patterns, "high_fan_out")
        end
        
        if total_amount > 100.0  # Large amount transfers
            push!(suspicious_patterns, "large_transfer")
        end
    end
    
    return Dict(
        "transfers" => transfers,
        "total_amount" => total_amount,
        "programs" => unique(programs),
        "suspicious_patterns" => suspicious_patterns
    )
end

# Helper function to check if a program is a known mixer
function is_mixer_program(program_id::String)
    known_mixers = [
        # Add known mixer program IDs here
        "TornadoCash...",  # Placeholder - would need actual program IDs
        "Samourai...",
    ]
    return program_id in known_mixers
end

const TOOL_TRANSACTION_TRACER_METADATA = ToolMetadata(
    "transaction_tracer",
    "Traces transaction paths by following fund flows across multiple hops to reconstruct complete transaction chains."
)

const TOOL_TRANSACTION_TRACER_SPECIFICATION = ToolSpecification(
    tool_transaction_tracer,
    ToolTransactionTracerConfig,
    TOOL_TRANSACTION_TRACER_METADATA
)