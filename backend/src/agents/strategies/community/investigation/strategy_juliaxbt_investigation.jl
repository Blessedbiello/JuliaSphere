using ..CommonTypes: StrategyConfig, AgentContext, StrategySpecification, StrategyMetadata, StrategyInput
using JSON3
using Dates

Base.@kwdef struct StrategyjuliaXBTInvestigationConfig <: StrategyConfig
    max_investigation_depth::Int = 7
    auto_publish_threads::Bool = false
    investigation_priority_threshold::String = "MEDIUM"  # MINIMAL, LOW, MEDIUM, HIGH, CRITICAL
    enable_social_media_research::Bool = true
    evidence_confidence_threshold::Float64 = 0.7
end

Base.@kwdef struct juliaXBTInvestigationInput <: StrategyInput
    target_address::String
    investigation_type::String = "full"  # "full", "quick", "social_only", "blockchain_only"
    suspected_activity::String = "unknown"  # "mixer", "scam", "hack", "laundering" 
    tip_source::String = "community"  # "community", "automated", "law_enforcement"
    urgency_level::String = "normal"  # "low", "normal", "high", "critical"
end

"""
juliaXBT-style blockchain investigation strategy that orchestrates multiple specialized agents
to conduct comprehensive investigations including blockchain analysis, social media intelligence,
and evidence documentation with automated thread generation.
"""
function strategy_juliaxbt_investigation(
    cfg::StrategyjuliaXBTInvestigationConfig,
    ctx::AgentContext,
    input::juliaXBTInvestigationInput
)
    push!(ctx.logs, "🔍 Starting juliaXBT-style investigation for address: $(input.target_address)")
    push!(ctx.logs, "Investigation type: $(input.investigation_type) | Suspected activity: $(input.suspected_activity)")
    
    # Initialize investigation results
    investigation_results = Dict(
        "target_address" => input.target_address,
        "investigation_id" => generate_investigation_id(),
        "start_time" => now(),
        "investigation_type" => input.investigation_type,
        "blockchain_analysis" => Dict(),
        "social_media_intelligence" => Dict(),
        "compliance_assessment" => Dict(),
        "evidence_package" => Dict(),
        "key_findings" => [],
        "risk_assessment" => Dict()
    )
    
    try
        # Phase 1: Blockchain Analysis
        if input.investigation_type in ["full", "blockchain_only"]
            push!(ctx.logs, "📊 Phase 1: Conducting blockchain analysis...")
            blockchain_results = conduct_blockchain_investigation(ctx, input, cfg)
            investigation_results["blockchain_analysis"] = blockchain_results
            
            # Early termination if high-risk activity detected
            if blockchain_results["risk_level"] == "CRITICAL" && input.urgency_level == "critical"
                push!(ctx.logs, "🚨 CRITICAL risk detected - proceeding to immediate alert generation")
                return handle_critical_alert(ctx, investigation_results, cfg)
            end
        end
        
        # Phase 2: Social Media Intelligence  
        if input.investigation_type in ["full", "social_only"] && cfg.enable_social_media_research
            push!(ctx.logs, "🌐 Phase 2: Gathering social media intelligence...")
            social_results = conduct_social_media_investigation(ctx, input, investigation_results)
            investigation_results["social_media_intelligence"] = social_results
        end
        
        # Phase 3: Cross-Reference and Pattern Analysis
        if input.investigation_type == "full"
            push!(ctx.logs, "🔗 Phase 3: Cross-referencing findings and analyzing patterns...")
            pattern_analysis = analyze_cross_platform_patterns(investigation_results)
            investigation_results["pattern_analysis"] = pattern_analysis
        end
        
        # Phase 4: Compliance and Risk Assessment
        push!(ctx.logs, "⚖️ Phase 4: Conducting compliance assessment...")
        compliance_results = assess_compliance_violations(ctx, investigation_results)
        investigation_results["compliance_assessment"] = compliance_results
        
        # Phase 5: Evidence Compilation and Visualization
        push!(ctx.logs, "📋 Phase 5: Compiling evidence package...")
        evidence_package = compile_evidence_package(ctx, investigation_results)
        investigation_results["evidence_package"] = evidence_package
        
        # Phase 6: Generate Investigation Output
        push!(ctx.logs, "📝 Phase 6: Generating investigation output...")
        final_assessment = generate_final_assessment(investigation_results)
        investigation_results["final_assessment"] = final_assessment
        
        # Phase 7: Content Generation (if warranted)
        if should_generate_public_content(investigation_results, cfg)
            push!(ctx.logs, "📱 Phase 7: Generating public content...")
            content_results = generate_investigation_content(ctx, investigation_results, cfg)
            investigation_results["generated_content"] = content_results
            
            # Auto-publish if configured
            if cfg.auto_publish_threads && content_results["thread_generated"]
                publish_investigation_thread(ctx, content_results["thread"])
            end
        end
        
        # Log investigation completion
        investigation_results["end_time"] = now()
        investigation_results["status"] = "completed"
        
        push!(ctx.logs, "✅ Investigation completed successfully")
        push!(ctx.logs, "Final risk level: $(final_assessment["risk_level"])")
        push!(ctx.logs, "Key findings: $(length(investigation_results["key_findings"])) items")
        
        # Store results in context for potential follow-up
        push!(ctx.memories, "investigation_$(investigation_results["investigation_id"])" => investigation_results)
        
        return ctx
        
    catch e
        push!(ctx.logs, "❌ Investigation failed with error: $(string(e))")
        investigation_results["status"] = "failed"
        investigation_results["error"] = string(e)
        return ctx
    end
end

# Phase 1: Blockchain Investigation
function conduct_blockchain_investigation(ctx::AgentContext, input::juliaXBTInvestigationInput, cfg::StrategyjuliaXBTInvestigationConfig)
    results = Dict(
        "transaction_traces" => [],
        "mixer_interactions" => Dict(),
        "bridge_activities" => [],
        "wallet_clustering" => Dict(),
        "risk_level" => "MINIMAL"
    )
    
    # 1. Transaction Tracing
    tracer_tool = find_tool(ctx, "transaction_tracer")
    if tracer_tool !== nothing
        push!(ctx.logs, "🔍 Tracing transaction paths...")
        try
            trace_result = tracer_tool.execute(tracer_tool.config, Dict(
                "start_address" => input.target_address,
                "max_depth" => cfg.max_investigation_depth,
                "follow_direction" => "both"
            ))
            
            if haskey(trace_result, "success") && trace_result["success"]
                results["transaction_traces"] = get(trace_result, "transaction_path", [])
                results["total_volume"] = get(trace_result, "total_volume", 0.0)
                results["addresses_visited"] = get(trace_result, "addresses_visited", [])
                
                push!(ctx.logs, "Found $(length(results["transaction_traces"])) transaction hops")
                push!(ctx.logs, "Total volume traced: $(results["total_volume"]) SOL")
            else
                error_msg = get(trace_result, "error", "Unknown error during transaction tracing")
                push!(ctx.logs, "⚠️ Transaction tracing failed: $(error_msg)")
                results["risk_level"] = "LOW"  # Partial failure still allows other analysis
            end
        catch e
            push!(ctx.logs, "❌ Transaction tracing error: $(string(e))")
            results["risk_level"] = "LOW"
        end
    else
        push!(ctx.logs, "⚠️ Transaction tracer tool not found - skipping transaction tracing")
    end
    
    # 2. Mixer Detection
    mixer_tool = find_tool(ctx, "mixer_detector")
    if mixer_tool !== nothing
        push!(ctx.logs, "🌪️ Analyzing for mixer interactions...")
        try
            mixer_result = mixer_tool.execute(mixer_tool.config, Dict(
                "address" => input.target_address,
                "check_incoming" => true,
                "check_outgoing" => true
            ))
            
            if haskey(mixer_result, "success") && mixer_result["success"]
                results["mixer_interactions"] = mixer_result
                if get(mixer_result, "has_mixer_interactions", false)
                    risk_level = get(mixer_result, "risk_level", "MEDIUM")
                    results["risk_level"] = risk_level
                    push!(ctx.logs, "⚠️ Mixer interactions detected - Risk level: $(risk_level)")
                else
                    push!(ctx.logs, "✅ No mixer interactions detected")
                end
            else
                error_msg = get(mixer_result, "error", "Unknown error during mixer detection")
                push!(ctx.logs, "⚠️ Mixer detection failed: $(error_msg)")
            end
        catch e
            push!(ctx.logs, "❌ Mixer detection error: $(string(e))")
        end
    else
        push!(ctx.logs, "⚠️ Mixer detector tool not found - skipping mixer analysis")
    end
    
    # 3. Additional blockchain analysis tools would be called here
    # (bridge monitor, wallet analyzer, etc.)
    
    return results
end

# Phase 2: Social Media Investigation
function conduct_social_media_investigation(ctx::AgentContext, input::juliaXBTInvestigationInput, investigation_results::Dict)
    results = Dict(
        "twitter_profiles" => [],
        "suspicious_accounts" => [],
        "related_discussions" => [],
        "social_risk_indicators" => []
    )
    
    # Search for mentions of the target address on Twitter
    twitter_tool = find_tool(ctx, "twitter_research")
    if twitter_tool !== nothing
        push!(ctx.logs, "🐦 Searching Twitter for address mentions...")
        
        # Search for direct address mentions
        search_result = twitter_tool.execute(twitter_tool.config, Dict(
            "query_type" => "blockchain_mentions",
            "wallet_address" => input.target_address,
            "search_query" => "$(input.target_address) OR scam OR hack OR stolen"
        ))
        
        if search_result["success"] && haskey(search_result, "tweets")
            results["related_discussions"] = search_result["tweets"]
            push!(ctx.logs, "Found $(length(search_result["tweets"])) related tweets")
            
            # Extract suspicious accounts for deeper analysis
            for tweet in search_result["tweets"]
                if !isempty(tweet["suspicious_indicators"])
                    push!(results["suspicious_accounts"], tweet["author"])
                end
            end
        end
        
        # Research profiles of suspicious accounts
        for account in results["suspicious_accounts"][1:min(5, length(results["suspicious_accounts"]))]
            profile_result = twitter_tool.execute(twitter_tool.config, Dict(
                "query_type" => "user_profile", 
                "username" => account["username"]
            ))
            
            if profile_result["success"]
                push!(results["twitter_profiles"], profile_result["user_profile"])
            end
        end
    end
    
    return results
end

# Pattern Analysis across platforms
function analyze_cross_platform_patterns(investigation_results::Dict)
    patterns = Dict(
        "timing_correlations" => [],
        "address_social_connections" => [],
        "coordinated_activity" => [],
        "narrative_consistency" => Dict()
    )
    
    # Analyze timing between blockchain activity and social media posts
    if haskey(investigation_results, "blockchain_analysis") && 
       haskey(investigation_results, "social_media_intelligence")
        
        blockchain_timestamps = extract_blockchain_timestamps(investigation_results["blockchain_analysis"])
        social_timestamps = extract_social_timestamps(investigation_results["social_media_intelligence"])
        
        # Look for correlations (simplified analysis)
        for bt in blockchain_timestamps
            for st in social_timestamps
                time_diff = abs(bt - st)
                if time_diff < 3600  # Within 1 hour
                    push!(patterns["timing_correlations"], Dict(
                        "blockchain_time" => bt,
                        "social_time" => st,
                        "time_difference_seconds" => time_diff
                    ))
                end
            end
        end
    end
    
    return patterns
end

# Compliance Assessment
function assess_compliance_violations(ctx::AgentContext, investigation_results::Dict)
    violations = []
    risk_score = 0.0
    
    # Check blockchain compliance issues
    if haskey(investigation_results["blockchain_analysis"], "mixer_interactions")
        mixer_data = investigation_results["blockchain_analysis"]["mixer_interactions"]
        if mixer_data["has_mixer_interactions"]
            push!(violations, "AML_VIOLATION_MIXER_USAGE")
            risk_score += 0.4
            
            if mixer_data["risk_level"] == "CRITICAL"
                push!(violations, "CRITICAL_AML_RISK")
                risk_score += 0.3
            end
        end
    end
    
    # Check social media compliance
    if haskey(investigation_results, "social_media_intelligence")
        social_data = investigation_results["social_media_intelligence"]
        if length(social_data["suspicious_accounts"]) > 0
            push!(violations, "COORDINATED_INAUTHENTIC_BEHAVIOR")
            risk_score += 0.2
        end
    end
    
    return Dict(
        "violations" => violations,
        "risk_score" => min(risk_score, 1.0),
        "compliance_level" => risk_score > 0.7 ? "NON_COMPLIANT" : risk_score > 0.4 ? "HIGH_RISK" : "ACCEPTABLE"
    )
end

# Evidence Compilation
function compile_evidence_package(ctx::AgentContext, investigation_results::Dict)
    evidence = Dict(
        "blockchain_evidence" => [],
        "social_evidence" => [],
        "timeline" => [],
        "key_addresses" => [],
        "supporting_documents" => []
    )
    
    # Compile blockchain evidence
    if haskey(investigation_results["blockchain_analysis"], "transaction_traces")
        for trace in investigation_results["blockchain_analysis"]["transaction_traces"]
            push!(evidence["blockchain_evidence"], Dict(
                "type" => "transaction_trace",
                "transaction_signature" => trace["transaction_signature"],
                "amount" => trace["total_amount"],
                "timestamp" => trace["timestamp"],
                "suspicious_indicators" => trace["suspicious_indicators"]
            ))
        end
    end
    
    # Compile social evidence  
    if haskey(investigation_results, "social_media_intelligence")
        social_data = investigation_results["social_media_intelligence"] 
        for account in social_data["suspicious_accounts"]
            push!(evidence["social_evidence"], Dict(
                "type" => "suspicious_account",
                "username" => account["username"],
                "indicators" => account.get("suspicious_indicators", [])
            ))
        end
    end
    
    # Create investigation timeline
    evidence["timeline"] = create_investigation_timeline(investigation_results)
    
    return evidence
end

# Final Assessment
function generate_final_assessment(investigation_results::Dict)
    key_findings = []
    overall_risk = "MINIMAL"
    
    # Aggregate findings from all phases
    if haskey(investigation_results["blockchain_analysis"], "mixer_interactions")
        mixer_risk = investigation_results["blockchain_analysis"]["mixer_interactions"]["risk_level"]
        if mixer_risk != "MINIMAL"
            push!(key_findings, "Mixer usage detected with $(mixer_risk) risk level")
            if mixer_risk == "CRITICAL"
                overall_risk = "CRITICAL"
            elseif mixer_risk in ["HIGH", "MEDIUM"] && overall_risk == "MINIMAL"
                overall_risk = mixer_risk
            end
        end
    end
    
    if haskey(investigation_results, "compliance_assessment")
        compliance = investigation_results["compliance_assessment"]
        if !isempty(compliance["violations"])
            push!(key_findings, "Compliance violations: $(join(compliance["violations"], ", "))")
            if compliance["compliance_level"] == "NON_COMPLIANT" && overall_risk != "CRITICAL"
                overall_risk = "HIGH"
            end
        end
    end
    
    investigation_results["key_findings"] = key_findings
    
    return Dict(
        "risk_level" => overall_risk,
        "key_findings" => key_findings,
        "investigation_score" => calculate_investigation_score(investigation_results),
        "recommended_actions" => generate_recommended_actions(overall_risk, key_findings)
    )
end

# Content Generation
function generate_investigation_content(ctx::AgentContext, investigation_results::Dict, cfg::StrategyjuliaXBTInvestigationConfig)
    content_results = Dict("thread_generated" => false, "blog_generated" => false)
    
    # Generate Twitter thread if findings are significant
    if investigation_results["final_assessment"]["risk_level"] in ["HIGH", "CRITICAL"]
        thread_tool = find_tool(ctx, "thread_generator")
        if thread_tool !== nothing
            push!(ctx.logs, "📱 Generating investigation thread...")
            
            thread_type = investigation_results["final_assessment"]["risk_level"] == "CRITICAL" ? "alert" : "investigation"
            
            thread_result = thread_tool.execute(thread_tool.config, Dict(
                "investigation_data" => investigation_results,
                "thread_type" => thread_type,
                "tone" => "professional",
                "include_evidence" => true,
                "max_tweets" => 12,
                "target_audience" => "general"
            ))
            
            if thread_result["success"]
                content_results["thread"] = thread_result
                content_results["thread_generated"] = true
                push!(ctx.logs, "✅ Investigation thread generated ($(thread_result["tweet_count"]) tweets)")
            end
        end
    end
    
    return content_results
end

# Helper Functions

function find_tool(ctx::AgentContext, tool_name::String)
    index = findfirst(tool -> tool.metadata.name == tool_name, ctx.tools)
    return index !== nothing ? ctx.tools[index] : nothing
end

function generate_investigation_id()
    return "INV_$(rand(100000:999999))"
end

function should_generate_public_content(investigation_results::Dict, cfg::StrategyjuliaXBTInvestigationConfig)
    risk_level = investigation_results["final_assessment"]["risk_level"]
    priority_levels = ["MINIMAL", "LOW", "MEDIUM", "HIGH", "CRITICAL"]
    
    risk_index = findfirst(x -> x == risk_level, priority_levels)
    threshold_index = findfirst(x -> x == cfg.investigation_priority_threshold, priority_levels)
    
    return risk_index !== nothing && threshold_index !== nothing && risk_index >= threshold_index
end

function handle_critical_alert(ctx::AgentContext, investigation_results::Dict, cfg::StrategyjuliaXBTInvestigationConfig)
    push!(ctx.logs, "🚨 CRITICAL: Generating immediate alert content")
    
    # Generate urgent alert thread
    thread_tool = find_tool(ctx, "thread_generator")
    if thread_tool !== nothing
        alert_result = thread_tool.execute(thread_tool.config, Dict(
            "investigation_data" => investigation_results,
            "thread_type" => "alert", 
            "tone" => "urgent",
            "include_evidence" => true,
            "max_tweets" => 8,
            "target_audience" => "general"
        ))
        
        if alert_result["success"] && cfg.auto_publish_threads
            publish_investigation_thread(ctx, alert_result)
        end
    end
    
    investigation_results["status"] = "critical_alert_issued"
    return ctx
end

function publish_investigation_thread(ctx::AgentContext, thread_data::Dict)
    # This would integrate with the existing post_to_x tool
    post_tool = find_tool(ctx, "post_to_x")
    if post_tool !== nothing
        # Post first tweet (others would need threaded posting logic)
        if !isempty(thread_data["tweets"])
            first_tweet = thread_data["tweets"][1]["content"]
            post_tool.execute(post_tool.config, Dict("blog_text" => first_tweet))
            push!(ctx.logs, "📤 Published investigation thread to Twitter/X")
        end
    end
end

# Additional helper functions (simplified implementations)
function extract_blockchain_timestamps(blockchain_data::Dict)
    timestamps = []
    if haskey(blockchain_data, "transaction_traces")
        for trace in blockchain_data["transaction_traces"]
            if haskey(trace, "timestamp") && trace["timestamp"] !== nothing
                push!(timestamps, trace["timestamp"])
            end
        end
    end
    return timestamps
end

function extract_social_timestamps(social_data::Dict)
    timestamps = []
    if haskey(social_data, "related_discussions")
        for tweet in social_data["related_discussions"]
            if haskey(tweet, "created_at") && tweet["created_at"] !== nothing
                # Parse Twitter timestamp format (ISO 8601)
                try
                    timestamp = parse(DateTime, tweet["created_at"])
                    push!(timestamps, timestamp)
                catch e
                    # If parsing fails, skip this timestamp
                    @warn "Failed to parse timestamp: $(tweet["created_at"])"
                end
            end
        end
    end
    return timestamps
end

function create_investigation_timeline(investigation_results::Dict)
    timeline_events = []
    
    # Add blockchain events
    if haskey(investigation_results, "blockchain_analysis") && 
       haskey(investigation_results["blockchain_analysis"], "transaction_traces")
        for trace in investigation_results["blockchain_analysis"]["transaction_traces"]
            if haskey(trace, "timestamp") && trace["timestamp"] !== nothing
                push!(timeline_events, Dict(
                    "timestamp" => trace["timestamp"],
                    "type" => "blockchain_transaction",
                    "description" => "Transaction: $(trace["transaction_signature"][1:8])...",
                    "amount" => get(trace, "total_amount", 0),
                    "suspicious" => !isempty(get(trace, "suspicious_indicators", []))
                ))
            end
        end
    end
    
    # Add social media events
    if haskey(investigation_results, "social_media_intelligence") &&
       haskey(investigation_results["social_media_intelligence"], "related_discussions")
        for tweet in investigation_results["social_media_intelligence"]["related_discussions"]
            if haskey(tweet, "created_at") && tweet["created_at"] !== nothing
                try
                    timestamp = parse(DateTime, tweet["created_at"])
                    push!(timeline_events, Dict(
                        "timestamp" => timestamp,
                        "type" => "social_media_post",
                        "description" => "Tweet by @$(tweet["author"]["username"]): $(tweet["text"][1:min(50, length(tweet["text"]))])...",
                        "suspicious" => !isempty(get(tweet, "suspicious_indicators", []))
                    ))
                catch e
                    # Skip if timestamp parsing fails
                end
            end
        end
    end
    
    # Sort timeline by timestamp
    sort!(timeline_events, by = x -> get(x, "timestamp", DateTime(0)))
    
    return timeline_events
end

function calculate_investigation_score(investigation_results::Dict)
    score = 0.0
    
    # Score based on evidence strength
    if haskey(investigation_results["blockchain_analysis"], "mixer_interactions")
        mixer_data = investigation_results["blockchain_analysis"]["mixer_interactions"]
        if mixer_data["has_mixer_interactions"]
            score += mixer_data["risk_score"] * 0.4
        end
    end
    
    # Score based on social media findings
    if haskey(investigation_results, "social_media_intelligence")
        social_data = investigation_results["social_media_intelligence"]
        if length(social_data["suspicious_accounts"]) > 0
            score += min(length(social_data["suspicious_accounts"]) * 0.1, 0.3)
        end
    end
    
    return min(score, 1.0)
end

function generate_recommended_actions(risk_level::String, key_findings::Vector)
    actions = []
    
    if risk_level == "CRITICAL"
        push!(actions, "IMMEDIATE: Report to law enforcement")
        push!(actions, "IMMEDIATE: Issue public warning")
        push!(actions, "Monitor associated addresses for continued activity")
    elseif risk_level == "HIGH"
        push!(actions, "Report to relevant compliance authorities")
        push!(actions, "Add addresses to watchlist")
        push!(actions, "Share findings with security community")
    else
        push!(actions, "Continue monitoring for escalation")
        push!(actions, "Document findings for future reference")
    end
    
    return actions
end

const STRATEGY_JULIAXBT_INVESTIGATION_METADATA = StrategyMetadata(
    "juliaxbt_investigation"
)

const STRATEGY_JULIAXBT_INVESTIGATION_SPECIFICATION = StrategySpecification(
    strategy_juliaxbt_investigation,
    nothing,
    StrategyjuliaXBTInvestigationConfig,
    STRATEGY_JULIAXBT_INVESTIGATION_METADATA,
    juliaXBTInvestigationInput
)