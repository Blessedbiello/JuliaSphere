using ...Resources: Gemini
using ..CommonTypes: ToolSpecification, ToolMetadata, ToolConfig

Base.@kwdef struct ToolThreadGeneratorConfig <: ToolConfig
    api_key::String = ENV["GEMINI_API_KEY"]
    model_name::String = "models/gemini-1.5-pro"
    temperature::Float64 = 0.8
    max_output_tokens::Int = 2048
    juliaxbt_style::Bool = true
end

"""
    tool_thread_generator(cfg::ToolThreadGeneratorConfig, task::Dict) -> Dict{String, Any}

Generates Twitter/X investigation threads in juliaXBT style using investigation data.
Creates engaging, well-structured threads with evidence presentation and narrative flow.

# Arguments
- `cfg::ToolThreadGeneratorConfig`: Configuration with LLM settings and style preferences
- `task::Dict`: Task dictionary containing:
  - `investigation_data::Dict`: Core investigation findings (transactions, addresses, patterns)
  - `thread_type::String`: Type of thread ("investigation", "alert", "update", "analysis")
  - `tone::String` (optional): Thread tone ("professional", "urgent", "analytical") - default: "professional"
  - `include_evidence::Bool` (optional): Whether to include evidence links - default: true
  - `max_tweets::Int` (optional): Maximum number of tweets in thread - default: 15
  - `target_audience::String` (optional): Target audience ("general", "technical", "investigators") - default: "general"

# Returns  
Dictionary containing the generated thread with individual tweets and metadata.
"""
function tool_thread_generator(cfg::ToolThreadGeneratorConfig, task::Dict)::Dict{String,Any}
    # Validate required fields
    if !haskey(task, "investigation_data") || !(task["investigation_data"] isa AbstractDict)
        return Dict("success" => false, "error" => "Missing or invalid 'investigation_data' field")
    end
    
    if !haskey(task, "thread_type") || !(task["thread_type"] isa AbstractString)
        return Dict("success" => false, "error" => "Missing or invalid 'thread_type' field")
    end

    investigation_data = task["investigation_data"]
    thread_type = task["thread_type"]
    tone = get(task, "tone", "professional")
    include_evidence = get(task, "include_evidence", true)
    max_tweets = get(task, "max_tweets", 15)
    target_audience = get(task, "target_audience", "general")

    try
        # Generate thread using LLM
        thread_content = generate_investigation_thread(
            cfg, investigation_data, thread_type, tone, 
            include_evidence, max_tweets, target_audience
        )
        
        if !thread_content["success"]
            return thread_content
        end
        
        # Process and structure the thread
        tweets = parse_and_structure_thread(thread_content["content"])
        
        # Add metadata and formatting
        formatted_thread = format_thread_for_posting(tweets, investigation_data)
        
        # Generate thread analytics and optimization suggestions
        thread_analytics = analyze_thread_effectiveness(formatted_thread, target_audience)
        
        return Dict(
            "success" => true,
            "thread_type" => thread_type,
            "tweet_count" => length(formatted_thread),
            "tweets" => formatted_thread,
            "thread_analytics" => thread_analytics,
            "posting_metadata" => Dict(
                "estimated_engagement" => thread_analytics["engagement_prediction"],
                "optimal_posting_time" => "evening_est",  # Placeholder
                "hashtags" => generate_relevant_hashtags(investigation_data, thread_type),
                "content_warnings" => identify_content_warnings(investigation_data)
            )
        )
        
    catch e
        return Dict(
            "success" => false,
            "error" => "Exception during thread generation: $(string(e))"
        )
    end
end

# Generate the investigation thread using LLM
function generate_investigation_thread(cfg, investigation_data, thread_type, tone, include_evidence, max_tweets, target_audience)
    # Build context about the investigation
    investigation_summary = summarize_investigation_data(investigation_data)
    
    # Create ZachXBT-style prompt
    prompt = build_juliaxbt_prompt(
        investigation_summary, thread_type, tone, 
        include_evidence, max_tweets, target_audience
    )
    
    # Configure LLM
    gemini_cfg = Gemini.GeminiConfig(
        api_key = cfg.api_key,
        model_name = cfg.model_name,
        temperature = cfg.temperature,
        max_output_tokens = cfg.max_output_tokens
    )
    
    try
        thread_content = Gemini.gemini_util(gemini_cfg, prompt)
        return Dict("success" => true, "content" => thread_content)
    catch e
        return Dict("success" => false, "error" => string(e))
    end
end

# Build juliaXBT-style investigation prompt
function build_juliaxbt_prompt(investigation_summary, thread_type, tone, include_evidence, max_tweets, target_audience)
    base_prompt = """
    You are creating a Twitter/X investigation thread in the style of juliaXBT, a renowned blockchain investigator known for:
    - Clear, evidence-based narratives
    - Professional but engaging tone
    - Methodical presentation of evidence
    - Strong investigative conclusions
    - Community-focused transparency
    
    Investigation Summary:
    $(investigation_summary)
    
    Thread Type: $(thread_type)
    Tone: $(tone)  
    Target Audience: $(target_audience)
    Max Tweets: $(max_tweets)
    Include Evidence: $(include_evidence)
    
    """
    
    style_guidelines = if thread_type == "investigation"
        """
        Create an investigation thread that:
        1. Opens with a compelling hook about the discovery
        2. Presents timeline of events chronologically  
        3. Shows evidence methodically (transaction traces, addresses, connections)
        4. Explains the implications clearly
        5. Provides actionable next steps or warnings
        6. Maintains professional credibility throughout
        
        Structure each tweet as: "TWEET X: [content]"
        Keep tweets under 280 characters each.
        Use emojis sparingly and professionally (🧵 for thread, 🚨 for alerts, 💰 for money flows).
        """
    elseif thread_type == "alert"
        """
        Create an urgent alert thread that:
        1. Immediately states the threat/risk
        2. Provides essential details quickly
        3. Shows evidence of immediate concern
        4. Gives clear warnings or actions to take
        5. Provides resources for further information
        
        Use urgent but professional language.
        Structure as: "TWEET X: [content]"
        Prioritize critical information in early tweets.
        """
    elseif thread_type == "update"
        """
        Create an investigation update thread that:
        1. References previous investigation
        2. Presents new developments
        3. Shows how new evidence connects to previous findings  
        4. Updates community on current status
        5. Indicates next investigation steps
        
        Maintain continuity with previous narrative.
        Structure as: "TWEET X: [content]"
        """
    else  # analysis
        """
        Create an analytical thread that:
        1. Explains complex blockchain concepts simply
        2. Shows patterns and trends in the data
        3. Provides educational context
        4. Draws broader implications
        5. Encourages informed discussion
        
        Focus on education and insight.
        Structure as: "TWEET X: [content]"
        """
    end
    
    evidence_instructions = if include_evidence
        "\nInclude specific transaction hashes, addresses, and amounts where relevant. Format addresses as shortened versions (e.g., 'ABC...XYZ') to save character space."
    else
        "\nFocus on narrative and implications rather than specific technical evidence."
    end
    
    return base_prompt * style_guidelines * evidence_instructions * "\n\nGenerate the complete thread now:"
end

# Summarize investigation data for LLM context  
function summarize_investigation_data(data)
    summary_parts = []
    
    # Transaction tracing results
    if haskey(data, "transaction_traces")
        traces = data["transaction_traces"]
        push!(summary_parts, "Transaction tracing found $(length(traces)) hops with total volume of $(get(data, "total_volume", 0)) SOL")
    end
    
    # Mixer detection results
    if haskey(data, "mixer_detections") && !isempty(data["mixer_detections"])
        mixer_count = length(data["mixer_detections"])
        push!(summary_parts, "Detected $(mixer_count) mixer interactions with risk level: $(get(data, "risk_level", "UNKNOWN"))")
    end
    
    # Social media findings
    if haskey(data, "social_media_intelligence")
        social = data["social_media_intelligence"]
        if haskey(social, "suspicious_accounts")
            push!(summary_parts, "Identified $(length(social["suspicious_accounts"])) suspicious social media accounts")
        end
    end
    
    # Key addresses involved
    if haskey(data, "key_addresses")
        addresses = data["key_addresses"]
        push!(summary_parts, "Investigation involves $(length(addresses)) key addresses including: $(join(addresses[1:min(3, length(addresses))], ", "))")
    end
    
    # Compliance issues
    if haskey(data, "compliance_issues") && !isempty(data["compliance_issues"])
        push!(summary_parts, "Compliance violations detected: $(join(data["compliance_issues"], ", "))")
    end
    
    if isempty(summary_parts)
        return "General blockchain investigation with limited specific findings available."
    end
    
    return join(summary_parts, ". ")
end

# Parse LLM output into structured tweets
function parse_and_structure_thread(content::String)
    tweets = []
    
    # Split by TWEET markers
    tweet_sections = split(content, r"TWEET \d+:")
    
    for section in tweet_sections[2:end]  # Skip first empty section
        tweet_text = strip(section)
        
        # Clean up the text
        tweet_text = replace(tweet_text, r"\n\n+" => " ")  # Multiple newlines to single space
        tweet_text = replace(tweet_text, r"\s+" => " ")    # Multiple spaces to single space
        tweet_text = strip(tweet_text)
        
        # Ensure tweet is under 280 characters
        if length(tweet_text) > 280
            tweet_text = tweet_text[1:277] * "..."
        end
        
        if !isempty(tweet_text)
            push!(tweets, tweet_text)
        end
    end
    
    return tweets
end

# Format thread with metadata and numbering
function format_thread_for_posting(tweets, investigation_data)
    formatted_tweets = []
    
    for (i, tweet) in enumerate(tweets)
        formatted_tweet = Dict(
            "tweet_number" => i,
            "content" => tweet,
            "character_count" => length(tweet),
            "hashtags" => extract_hashtags_from_tweet(tweet),
            "mentions" => extract_mentions_from_tweet(tweet),
            "urls" => extract_urls_from_tweet(tweet),
            "thread_position" => i == 1 ? "opener" : i == length(tweets) ? "closer" : "body"
        )
        
        # Add thread numbering to first tweet
        if i == 1 && length(tweets) > 1
            thread_indicator = " 🧵 ($(length(tweets)) tweets)"
            if length(tweet) + length(thread_indicator) <= 280
                formatted_tweet["content"] = tweet * thread_indicator
                formatted_tweet["character_count"] = length(formatted_tweet["content"])
            end
        end
        
        push!(formatted_tweets, formatted_tweet)
    end
    
    return formatted_tweets
end

# Analyze thread for effectiveness
function analyze_thread_effectiveness(formatted_thread, target_audience)
    total_chars = sum(tweet["character_count"] for tweet in formatted_thread)
    avg_chars = total_chars / length(formatted_thread)
    
    # Engagement prediction based on content analysis
    engagement_factors = []
    
    # Check for engaging elements
    first_tweet = formatted_thread[1]["content"]
    if occursin(r"🚨|BREAKING|ALERT", first_tweet)
        push!(engagement_factors, "urgent_opener")
    end
    
    if occursin(r"\$|\d+\s*(SOL|ETH|USD)", first_tweet)
        push!(engagement_factors, "monetary_hook") 
    end
    
    # Thread length optimization
    length_score = if length(formatted_thread) <= 10
        "optimal"
    elseif length(formatted_thread) <= 15
        "good"
    else
        "long"
    end
    
    # Engagement prediction
    engagement_prediction = if length(engagement_factors) >= 2 && length_score == "optimal"
        "high"
    elseif length(engagement_factors) >= 1 || length_score == "good"
        "medium"
    else
        "low"
    end
    
    return Dict(
        "thread_length" => length(formatted_thread),
        "average_tweet_length" => round(avg_chars, digits=1),
        "length_assessment" => length_score,
        "engagement_factors" => engagement_factors,
        "engagement_prediction" => engagement_prediction,
        "target_audience_fit" => assess_audience_fit(formatted_thread, target_audience)
    )
end

# Helper functions
function generate_relevant_hashtags(investigation_data, thread_type)
    base_hashtags = ["#BlockchainInvestigation", "#Crypto", "#Investigation"]
    
    if thread_type == "alert"
        push!(base_hashtags, "#CryptoAlert", "#Scam")
    elseif haskey(investigation_data, "mixer_detections") && !isempty(investigation_data["mixer_detections"])
        push!(base_hashtags, "#CryptoMixer", "#AML")
    end
    
    return base_hashtags[1:min(5, length(base_hashtags))]  # Limit to 5 hashtags
end

function identify_content_warnings(investigation_data)
    warnings = []
    
    if haskey(investigation_data, "risk_level") && investigation_data["risk_level"] in ["HIGH", "CRITICAL"] 
        push!(warnings, "high_risk_content")
    end
    
    if haskey(investigation_data, "mixer_detections") && !isempty(investigation_data["mixer_detections"])
        push!(warnings, "money_laundering_discussion")
    end
    
    return warnings
end

function extract_hashtags_from_tweet(tweet::String)
    hashtag_matches = eachmatch(r"#\w+", tweet)
    return [m.match for m in hashtag_matches]
end

function extract_mentions_from_tweet(tweet::String)
    mention_matches = eachmatch(r"@\w+", tweet)
    return [m.match for m in mention_matches]
end

function extract_urls_from_tweet(tweet::String)
    url_matches = eachmatch(r"https?://\S+", tweet)
    return [m.match for m in url_matches]
end

function assess_audience_fit(formatted_thread, target_audience)
    if target_audience == "technical"
        return "technical_appropriate"  # Would need more sophisticated analysis
    else
        return "general_appropriate"
    end
end

const TOOL_THREAD_GENERATOR_METADATA = ToolMetadata(
    "thread_generator", 
    "Generates Twitter/X investigation threads in juliaXBT style using investigation data and evidence."
)

const TOOL_THREAD_GENERATOR_SPECIFICATION = ToolSpecification(
    tool_thread_generator,
    ToolThreadGeneratorConfig,
    TOOL_THREAD_GENERATOR_METADATA
)