using HTTP
using JSON3
using ..CommonTypes: ToolSpecification, ToolMetadata, ToolConfig

Base.@kwdef struct ToolMixerDetectorConfig <: ToolConfig
    rpc_url::String = "https://api.mainnet-beta.solana.com"
    tornado_cash_addresses::Vector{String} = String[]  # Known Tornado Cash addresses
    samourai_addresses::Vector{String} = String[]     # Known Samourai addresses
    mixer_confidence_threshold::Float64 = 0.7         # Confidence threshold for mixer detection
    analysis_depth::Int = 5                           # How many transaction levels to analyze
    timeout_seconds::Int = 30
end

"""
    tool_mixer_detector(cfg::ToolMixerDetectorConfig, task::Dict) -> Dict{String, Any}

Detects interaction with mixing services like Tornado Cash, Samourai Wallet mixers, and other
obfuscation services by analyzing transaction patterns and known mixer addresses.

# Arguments  
- `cfg::ToolMixerDetectorConfig`: Configuration with known mixer addresses and detection parameters
- `task::Dict`: Task dictionary containing:
  - `address::String`: Address to analyze for mixer interactions
  - `transaction_signature::String` (optional): Specific transaction to analyze
  - `check_incoming::Bool` (optional): Check for incoming funds from mixers (default: true)
  - `check_outgoing::Bool` (optional): Check for outgoing funds to mixers (default: true)

# Returns
Dictionary containing detailed analysis of mixer interactions and risk assessment.
"""
function tool_mixer_detector(cfg::ToolMixerDetectorConfig, task::Dict)::Dict{String,Any}
    # Validate required fields
    if !haskey(task, "address") || !(task["address"] isa AbstractString)
        return Dict("success" => false, "error" => "Missing or invalid 'address' field")
    end

    target_address = task["address"]
    specific_tx = get(task, "transaction_signature", nothing)
    check_incoming = get(task, "check_incoming", true)
    check_outgoing = get(task, "check_outgoing", true)
    
    try
        mixer_detections = []
        risk_score = 0.0
        total_mixed_volume = 0.0
        
        # Get transactions for the address
        if specific_tx !== nothing
            # Analyze specific transaction
            tx_analysis = analyze_transaction_for_mixers(cfg, specific_tx, target_address)
            if tx_analysis["has_mixer_interaction"]
                push!(mixer_detections, tx_analysis)
                risk_score += tx_analysis["risk_contribution"]
                total_mixed_volume += tx_analysis["mixed_volume"]
            end
        else
            # Analyze recent transactions
            sigs_result = get_address_signatures(cfg, target_address, 100)
            if !sigs_result["success"]
                return Dict("success" => false, "error" => "Failed to fetch address signatures")
            end
            
            signatures = sigs_result["signatures"]
            
            for (i, sig_info) in enumerate(signatures)
                if i > cfg.analysis_depth * 10  # Limit analysis scope
                    break
                end
                
                tx_analysis = analyze_transaction_for_mixers(cfg, sig_info["signature"], target_address)
                
                if tx_analysis["has_mixer_interaction"]
                    push!(mixer_detections, tx_analysis)
                    risk_score += tx_analysis["risk_contribution"]
                    total_mixed_volume += tx_analysis["mixed_volume"]
                end
            end
        end
        
        # Calculate final risk assessment
        final_risk_score = min(risk_score, 1.0)  # Cap at 1.0
        risk_level = classify_risk_level(final_risk_score)
        
        # Detect mixing patterns
        mixing_patterns = detect_mixing_patterns(mixer_detections)
        
        return Dict(
            "success" => true,
            "address" => target_address,
            "has_mixer_interactions" => !isempty(mixer_detections),
            "mixer_detections" => mixer_detections,
            "risk_score" => final_risk_score,
            "risk_level" => risk_level,
            "total_mixed_volume" => total_mixed_volume,
            "mixing_patterns" => mixing_patterns,
            "analysis_summary" => generate_analysis_summary(mixer_detections, risk_level)
        )
        
    catch e
        return Dict(
            "success" => false,
            "error" => "Exception during mixer detection: $(string(e))"
        )
    end
end

# Helper function to analyze a single transaction for mixer interactions
function analyze_transaction_for_mixers(cfg::ToolMixerDetectorConfig, signature::String, focus_address::String)
    # Get transaction details
    tx_result = get_transaction_details(cfg, signature)
    if !tx_result["success"]
        return Dict("has_mixer_interaction" => false, "risk_contribution" => 0.0, "mixed_volume" => 0.0)
    end
    
    tx_data = tx_result["transaction"]
    mixer_indicators = []
    risk_contribution = 0.0
    mixed_volume = 0.0
    
    if haskey(tx_data, "transaction") && haskey(tx_data["transaction"], "message")
        message = tx_data["transaction"]["message"]
        account_keys = message["accountKeys"]
        
        # Check for direct interactions with known mixer addresses
        for account in account_keys
            if account in cfg.tornado_cash_addresses
                push!(mixer_indicators, Dict(
                    "type" => "tornado_cash_interaction",
                    "address" => account,
                    "confidence" => 0.95
                ))
                risk_contribution += 0.4
            elseif account in cfg.samourai_addresses  
                push!(mixer_indicators, Dict(
                    "type" => "samourai_interaction", 
                    "address" => account,
                    "confidence" => 0.9
                ))
                risk_contribution += 0.35
            end
        end
        
        # Analyze transaction patterns typical of mixers
        pattern_analysis = analyze_mixing_patterns(tx_data, focus_address)
        append!(mixer_indicators, pattern_analysis["indicators"])
        risk_contribution += pattern_analysis["risk_contribution"]
        mixed_volume += pattern_analysis["volume"]
        
        # Check for program-based mixing (DEX aggregators used for obfuscation)
        program_analysis = analyze_program_mixing(message)
        append!(mixer_indicators, program_analysis["indicators"]) 
        risk_contribution += program_analysis["risk_contribution"]
    end
    
    return Dict(
        "transaction_signature" => signature,
        "has_mixer_interaction" => !isempty(mixer_indicators),
        "mixer_indicators" => mixer_indicators,
        "risk_contribution" => risk_contribution,
        "mixed_volume" => mixed_volume,
        "timestamp" => get(tx_data, "blockTime", nothing)
    )
end

# Helper function to analyze transaction patterns for mixing behaviors
function analyze_mixing_patterns(tx_data, focus_address::String)
    indicators = []
    risk_contribution = 0.0
    volume = 0.0
    
    # Pattern 1: Multiple equal-value outputs (typical mixer behavior)
    if haskey(tx_data["meta"], "preBalances") && haskey(tx_data["meta"], "postBalances")
        balance_changes = []
        for (i, (pre, post)) in enumerate(zip(tx_data["meta"]["preBalances"], tx_data["meta"]["postBalances"]))
            change = (post - pre) / 1e9
            if abs(change) > 0.001
                push!(balance_changes, abs(change))
            end
        end
        
        # Check for multiple equal amounts (mixer signature)
        if length(balance_changes) >= 3
            unique_amounts = unique(round.(balance_changes, digits=6))
            if length(unique_amounts) < length(balance_changes) / 2
                push!(indicators, Dict(
                    "type" => "equal_value_outputs",
                    "confidence" => 0.8,
                    "details" => "Multiple equal-value transfers detected"
                ))
                risk_contribution += 0.25
                volume += sum(balance_changes)
            end
        end
    end
    
    # Pattern 2: High-frequency small transactions (layering)
    if haskey(tx_data["meta"], "fee") && tx_data["meta"]["fee"] > 0
        fee_ratio = tx_data["meta"]["fee"] / 1e9
        if fee_ratio > 0.01  # High fee relative to amount suggests small transaction
            push!(indicators, Dict(
                "type" => "high_fee_ratio",
                "confidence" => 0.6,
                "details" => "High fee ratio suggests small-value mixing transaction"
            ))
            risk_contribution += 0.1
        end
    end
    
    return Dict(
        "indicators" => indicators,
        "risk_contribution" => risk_contribution,
        "volume" => volume
    )
end

# Helper function to analyze program-based mixing
function analyze_program_mixing(message)
    indicators = []
    risk_contribution = 0.0
    
    if haskey(message, "instructions")
        # Known DEX aggregators often used for obfuscation
        suspicious_programs = [
            "JUP4Fb2cqiRUcaTHdrPC8h2gNsA2ETXiPDD33WcGuJB",  # Jupiter
            "whirLbMiicVdio4qvUfM5KAg6Ct8VwpYzGff3uctyCc",   # Whirlpool  
            "9W959DqEETiGZocYWCQPaJ6sBmUzgfxXfqGeTEdp3aQP",  # Orca
        ]
        
        program_interactions = []
        for instruction in message["instructions"] 
            if haskey(instruction, "programIdIndex") && instruction["programIdIndex"] <= length(message["accountKeys"])
                program_id = message["accountKeys"][instruction["programIdIndex"]]
                push!(program_interactions, program_id)
            end
        end
        
        # Multiple DEX interactions in single transaction (possible sandwich mixing)
        unique_programs = unique(program_interactions)
        dex_interactions = intersect(unique_programs, suspicious_programs)
        
        if length(dex_interactions) >= 2
            push!(indicators, Dict(
                "type" => "multi_dex_mixing",
                "confidence" => 0.7,
                "programs" => dex_interactions,
                "details" => "Multiple DEX interactions suggest potential mixing"
            ))
            risk_contribution += 0.2
        end
    end
    
    return Dict(
        "indicators" => indicators,
        "risk_contribution" => risk_contribution
    )
end

# Helper function to detect overall mixing patterns
function detect_mixing_patterns(detections)
    patterns = []
    
    if length(detections) >= 3
        push!(patterns, "frequent_mixing")
    end
    
    # Check for time-based patterns
    if length(detections) >= 2
        timestamps = [d["timestamp"] for d in detections if d["timestamp"] !== nothing]
        if length(timestamps) >= 2
            time_gaps = [timestamps[i] - timestamps[i-1] for i in 2:length(timestamps)]
            avg_gap = sum(time_gaps) / length(time_gaps)
            
            if avg_gap < 3600  # Less than 1 hour between mixing transactions
                push!(patterns, "rapid_mixing")
            end
        end
    end
    
    return patterns
end

# Helper function to classify risk level
function classify_risk_level(risk_score::Float64)
    if risk_score >= 0.8
        return "CRITICAL"
    elseif risk_score >= 0.6
        return "HIGH"  
    elseif risk_score >= 0.4
        return "MEDIUM"
    elseif risk_score >= 0.2
        return "LOW"
    else
        return "MINIMAL"
    end
end

# Helper function to generate analysis summary
function generate_analysis_summary(detections, risk_level::String)
    if isempty(detections)
        return "No mixer interactions detected. Address shows clean transaction patterns."
    end
    
    mixer_types = unique([indicator["type"] for detection in detections for indicator in detection["mixer_indicators"]])
    detection_count = length(detections)
    
    summary = "Detected $(detection_count) mixer interaction(s). "
    summary *= "Risk level: $(risk_level). "
    summary *= "Interaction types: $(join(mixer_types, ", ")). "
    
    if "tornado_cash_interaction" in mixer_types
        summary *= "CRITICAL: Direct Tornado Cash interaction detected. "
    end
    
    if "frequent_mixing" in [d["mixing_patterns"] for d in detections if haskey(d, "mixing_patterns")]
        summary *= "Pattern indicates systematic mixing behavior."
    end
    
    return summary
end

# Reuse helper functions from transaction tracer
function get_address_signatures(cfg::ToolMixerDetectorConfig, address::String, limit::Int=50)
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

function get_transaction_details(cfg::ToolMixerDetectorConfig, signature::String)
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

const TOOL_MIXER_DETECTOR_METADATA = ToolMetadata(
    "mixer_detector",
    "Detects interactions with mixing services and obfuscation techniques by analyzing transaction patterns and known mixer addresses."
)

const TOOL_MIXER_DETECTOR_SPECIFICATION = ToolSpecification(
    tool_mixer_detector,
    ToolMixerDetectorConfig,
    TOOL_MIXER_DETECTOR_METADATA
)