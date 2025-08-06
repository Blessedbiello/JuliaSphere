using HTTP
using JSON3
using ..CommonTypes: ToolSpecification, ToolMetadata, ToolConfig

Base.@kwdef struct ToolTwitterResearchConfig <: ToolConfig
    bearer_token::String  # Twitter API v2 Bearer Token
    api_base_url::String = "https://api.twitter.com/2"
    max_results_per_request::Int = 100
    timeout_seconds::Int = 30
    include_metrics::Bool = true
end

"""
    tool_twitter_research(cfg::ToolTwitterResearchConfig, task::Dict) -> Dict{String, Any}

Researches Twitter/X accounts, tweets, and social connections related to blockchain investigations.
Designed for juliaXBT-style social media intelligence gathering.

# Arguments
- `cfg::ToolTwitterResearchConfig`: Configuration with Twitter API credentials
- `task::Dict`: Task dictionary containing:
  - `query_type::String`: Type of research ("user_profile", "tweet_search", "user_timeline", "followers_analysis")
  - `username::String` (optional): Twitter username to research
  - `user_id::String` (optional): Twitter user ID
  - `search_query::String` (optional): Search query for tweet research
  - `wallet_address::String` (optional): Blockchain address to search for in tweets
  - `hashtags::Vector{String}` (optional): Hashtags to monitor
  - `time_range::Dict` (optional): Time range with "start_time" and "end_time"

# Returns
Dictionary containing detailed social media intelligence and connections to blockchain activity.
"""
function tool_twitter_research(cfg::ToolTwitterResearchConfig, task::Dict)::Dict{String,Any}
    # Validate required fields
    if !haskey(task, "query_type") || !(task["query_type"] isa AbstractString)
        return Dict("success" => false, "error" => "Missing or invalid 'query_type' field")
    end

    query_type = task["query_type"]
    
    try
        result = if query_type == "user_profile"
            research_user_profile(cfg, task)
        elseif query_type == "tweet_search"
            search_tweets(cfg, task)
        elseif query_type == "user_timeline" 
            analyze_user_timeline(cfg, task)
        elseif query_type == "followers_analysis"
            analyze_followers(cfg, task)
        elseif query_type == "blockchain_mentions"
            search_blockchain_mentions(cfg, task)
        else
            Dict("success" => false, "error" => "Invalid query_type: $(query_type)")
        end
        
        return result
        
    catch e
        return Dict(
            "success" => false,
            "error" => "Exception during Twitter research: $(string(e))"
        )
    end
end

# Research detailed user profile including bio, links, and activity patterns
function research_user_profile(cfg::ToolTwitterResearchConfig, task::Dict)
    username = get(task, "username", nothing)
    user_id = get(task, "user_id", nothing)
    
    if username === nothing && user_id === nothing
        return Dict("success" => false, "error" => "Must provide either 'username' or 'user_id'")
    end
    
    # Get user by username or ID
    user_endpoint = if username !== nothing
        "$(cfg.api_base_url)/users/by/username/$(username)"
    else
        "$(cfg.api_base_url)/users/$(user_id)"
    end
    
    user_fields = "id,name,username,description,url,profile_image_url,verified,public_metrics,created_at,location"
    
    headers = ["Authorization" => "Bearer $(cfg.bearer_token)"]
    params = Dict("user.fields" => user_fields)
    
    # Make API request
    response = HTTP.get(user_endpoint, headers; query=params, timeout=cfg.timeout_seconds)
    
    if response.status != 200
        return Dict("success" => false, "error" => "Twitter API error: $(response.status)")
    end
    
    user_data = JSON3.read(String(response.body))
    
    if !haskey(user_data, "data")
        return Dict("success" => false, "error" => "User not found")
    end
    
    user = user_data["data"]
    
    # Analyze user profile for suspicious indicators
    suspicious_indicators = analyze_profile_for_fraud_indicators(user)
    
    # Extract potential blockchain addresses from bio and tweets
    blockchain_mentions = extract_blockchain_addresses(user)
    
    # Analyze account creation date and verification status
    account_analysis = analyze_account_credibility(user)
    
    return Dict(
        "success" => true,
        "user_profile" => Dict(
            "id" => user["id"],
            "username" => user["username"],
            "display_name" => user["name"],
            "description" => get(user, "description", ""),
            "url" => get(user, "url", ""),
            "location" => get(user, "location", ""),
            "verified" => get(user, "verified", false),
            "created_at" => user["created_at"],
            "followers_count" => get(user["public_metrics"], "followers_count", 0),
            "following_count" => get(user["public_metrics"], "following_count", 0),
            "tweet_count" => get(user["public_metrics"], "tweet_count", 0)
        ),
        "suspicious_indicators" => suspicious_indicators,
        "blockchain_mentions" => blockchain_mentions,
        "account_analysis" => account_analysis,
        "investigation_priority" => calculate_investigation_priority(suspicious_indicators, account_analysis)
    )
end

# Search tweets for blockchain-related content
function search_tweets(cfg::ToolTwitterResearchConfig, task::Dict) 
    search_query = get(task, "search_query", "")
    wallet_address = get(task, "wallet_address", nothing)
    hashtags = get(task, "hashtags", String[])
    
    if isempty(search_query) && wallet_address === nothing && isempty(hashtags)
        return Dict("success" => false, "error" => "Must provide search_query, wallet_address, or hashtags")
    end
    
    # Build search query
    query_parts = []
    
    if !isempty(search_query)
        push!(query_parts, search_query)
    end
    
    if wallet_address !== nothing
        push!(query_parts, wallet_address)
    end
    
    for hashtag in hashtags
        push!(query_parts, "#$(hashtag)")
    end
    
    final_query = join(query_parts, " OR ")
    
    # Search tweets
    search_endpoint = "$(cfg.api_base_url)/tweets/search/recent"
    tweet_fields = "id,text,author_id,created_at,public_metrics,context_annotations,entities"
    user_fields = "id,name,username,verified"
    
    headers = ["Authorization" => "Bearer $(cfg.bearer_token)"]
    params = Dict(
        "query" => final_query,
        "tweet.fields" => tweet_fields,
        "user.fields" => user_fields,
        "expansions" => "author_id",
        "max_results" => string(cfg.max_results_per_request)
    )
    
    response = HTTP.get(search_endpoint, headers; query=params, timeout=cfg.timeout_seconds)
    
    if response.status != 200
        return Dict("success" => false, "error" => "Twitter API error: $(response.status)")
    end
    
    search_data = JSON3.read(String(response.body))
    
    # Process and analyze tweets
    tweets = get(search_data, "data", [])
    users = Dict(user["id"] => user for user in get(search_data["includes"], "users", []))
    
    analyzed_tweets = []
    for tweet in tweets
        author = get(users, tweet["author_id"], Dict())
        
        tweet_analysis = Dict(
            "tweet_id" => tweet["id"],
            "text" => tweet["text"],
            "author" => Dict(
                "id" => get(author, "id", ""),
                "username" => get(author, "username", "unknown"),
                "name" => get(author, "name", ""),
                "verified" => get(author, "verified", false)
            ),
            "created_at" => tweet["created_at"],
            "metrics" => get(tweet, "public_metrics", Dict()),
            "blockchain_addresses" => extract_addresses_from_text(tweet["text"]),
            "suspicious_indicators" => analyze_tweet_for_fraud(tweet),
            "entities" => get(tweet, "entities", Dict())
        )
        
        push!(analyzed_tweets, tweet_analysis)
    end
    
    return Dict(
        "success" => true,
        "search_query" => final_query,
        "tweet_count" => length(analyzed_tweets),
        "tweets" => analyzed_tweets,
        "investigation_leads" => identify_investigation_leads(analyzed_tweets)
    )
end

# Analyze a user's recent timeline for patterns
function analyze_user_timeline(cfg::ToolTwitterResearchConfig, task::Dict)
    username = get(task, "username", nothing)
    user_id = get(task, "user_id", nothing)
    
    if username === nothing && user_id === nothing
        return Dict("success" => false, "error" => "Must provide either 'username' or 'user_id'")
    end
    
    # Get user ID if username provided
    if user_id === nothing
        user_lookup = research_user_profile(cfg, Dict("username" => username))
        if !user_lookup["success"]
            return user_lookup
        end
        user_id = user_lookup["user_profile"]["id"]
    end
    
    # Get user's tweets
    timeline_endpoint = "$(cfg.api_base_url)/users/$(user_id)/tweets"
    tweet_fields = "id,text,created_at,public_metrics,entities,context_annotations"
    
    headers = ["Authorization" => "Bearer $(cfg.bearer_token)"]
    params = Dict(
        "tweet.fields" => tweet_fields,
        "max_results" => string(min(cfg.max_results_per_request, 100))
    )
    
    response = HTTP.get(timeline_endpoint, headers; query=params, timeout=cfg.timeout_seconds)
    
    if response.status != 200
        return Dict("success" => false, "error" => "Twitter API error: $(response.status)")
    end
    
    timeline_data = JSON3.read(String(response.body))
    tweets = get(timeline_data, "data", [])
    
    # Analyze timeline patterns
    timeline_analysis = Dict(
        "tweet_frequency" => analyze_tweet_frequency(tweets),
        "blockchain_activity" => analyze_blockchain_mentions_timeline(tweets), 
        "sentiment_patterns" => analyze_sentiment_patterns(tweets),
        "coordination_indicators" => detect_coordination_patterns(tweets),
        "suspicious_timing" => detect_suspicious_timing_patterns(tweets)
    )
    
    return Dict(
        "success" => true,
        "user_id" => user_id,
        "timeline_tweet_count" => length(tweets),
        "tweets" => tweets,
        "timeline_analysis" => timeline_analysis,
        "risk_assessment" => assess_timeline_risk(timeline_analysis)
    )
end

# Helper functions for analysis

function analyze_profile_for_fraud_indicators(user)
    indicators = []
    
    # Check for generic profile
    if get(user, "description", "") == ""
        push!(indicators, "empty_bio")
    end
    
    # Check follower/following ratio
    followers = get(user["public_metrics"], "followers_count", 0)
    following = get(user["public_metrics"], "following_count", 0)
    
    if following > 0 && followers / following < 0.1 && followers < 100
        push!(indicators, "low_follower_ratio")
    end
    
    # Check for recently created account
    if haskey(user, "created_at")
        # This would need proper date parsing in a real implementation
        push!(indicators, "recent_account")
    end
    
    return indicators
end

function extract_blockchain_addresses(user)
    addresses = []
    text_to_search = "$(get(user, "description", "")) $(get(user, "url", ""))"
    
    # Simple regex patterns for common address formats
    # Solana addresses (base58, ~44 chars)
    solana_matches = eachmatch(r"[1-9A-HJ-NP-Za-km-z]{32,44}", text_to_search)
    for m in solana_matches
        push!(addresses, Dict("type" => "solana", "address" => m.match))
    end
    
    # Ethereum addresses (0x + 40 hex chars)
    eth_matches = eachmatch(r"0x[a-fA-F0-9]{40}", text_to_search)
    for m in eth_matches
        push!(addresses, Dict("type" => "ethereum", "address" => m.match))
    end
    
    return addresses
end

function extract_addresses_from_text(text::String)
    addresses = []
    
    # Solana addresses
    solana_matches = eachmatch(r"[1-9A-HJ-NP-Za-km-z]{32,44}", text)
    for m in solana_matches
        push!(addresses, Dict("type" => "solana", "address" => m.match))
    end
    
    # Ethereum addresses
    eth_matches = eachmatch(r"0x[a-fA-F0-9]{40}", text)
    for m in eth_matches
        push!(addresses, Dict("type" => "ethereum", "address" => m.match))
    end
    
    return addresses
end

function analyze_account_credibility(user)
    credibility_score = 0.5  # Start neutral
    factors = []
    
    # Verification status
    if get(user, "verified", false)
        credibility_score += 0.3
        push!(factors, "verified_account")
    end
    
    # Account age (would need proper implementation)
    push!(factors, "account_age_analysis_needed")
    
    # Follower count
    followers = get(user["public_metrics"], "followers_count", 0)
    if followers > 10000
        credibility_score += 0.2
        push!(factors, "high_follower_count")
    elseif followers < 50
        credibility_score -= 0.2  
        push!(factors, "low_follower_count")
    end
    
    return Dict(
        "credibility_score" => credibility_score,
        "factors" => factors
    )
end

function analyze_tweet_for_fraud(tweet)
    indicators = []
    text = get(tweet, "text", "")
    
    # Check for common fraud keywords
    fraud_keywords = ["airdrop", "free", "giveaway", "urgent", "limited time", "double your"]
    for keyword in fraud_keywords
        if occursin(lowercase(keyword), lowercase(text))
            push!(indicators, "fraud_keyword_$(keyword)")
        end
    end
    
    # Check for excessive URLs
    url_count = length(eachmatch(r"https?://", text))
    if url_count > 2
        push!(indicators, "excessive_urls")
    end
    
    return indicators
end

function calculate_investigation_priority(suspicious_indicators, account_analysis)
    score = length(suspicious_indicators) * 0.1
    score += (1.0 - account_analysis["credibility_score"]) * 0.3
    
    if score > 0.7
        return "HIGH"
    elseif score > 0.4
        return "MEDIUM"  
    else
        return "LOW"
    end
end

function identify_investigation_leads(tweets)
    leads = []
    
    for tweet in tweets
        if !isempty(tweet["blockchain_addresses"]) && !isempty(tweet["suspicious_indicators"])
            push!(leads, Dict(
                "tweet_id" => tweet["tweet_id"],
                "author" => tweet["author"]["username"],
                "addresses" => tweet["blockchain_addresses"],
                "red_flags" => tweet["suspicious_indicators"]
            ))
        end
    end
    
    return leads
end

# Placeholder implementations for timeline analysis
function analyze_tweet_frequency(tweets)
    return Dict("average_per_day" => length(tweets) / 30)  # Simplified
end

function analyze_blockchain_mentions_timeline(tweets)
    mentions = 0
    for tweet in tweets
        if !isempty(extract_addresses_from_text(tweet["text"]))
            mentions += 1
        end
    end
    return Dict("blockchain_mention_count" => mentions)
end

function analyze_sentiment_patterns(tweets)
    return Dict("analysis" => "sentiment_analysis_placeholder")
end

function detect_coordination_patterns(tweets)
    return Dict("coordination_detected" => false)  # Placeholder
end

function detect_suspicious_timing_patterns(tweets)
    return Dict("suspicious_timing" => false)  # Placeholder  
end

function assess_timeline_risk(timeline_analysis)
    return "MEDIUM"  # Placeholder
end

const TOOL_TWITTER_RESEARCH_METADATA = ToolMetadata(
    "twitter_research",
    "Researches Twitter/X accounts and tweets for blockchain investigation intelligence gathering in juliaXBT style."
)

const TOOL_TWITTER_RESEARCH_SPECIFICATION = ToolSpecification(
    tool_twitter_research,
    ToolTwitterResearchConfig,
    TOOL_TWITTER_RESEARCH_METADATA
)