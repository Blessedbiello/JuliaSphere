module Tools

export TOOL_REGISTRY

include("tool_example_adder.jl")
include("tool_ping.jl")
include("tool_llm_chat.jl")
include("tool_write_blog.jl")
include("tool_post_to_x.jl")
include("telegram/tool_ban_user.jl")
include("telegram/tool_detect_swearing.jl")
include("telegram/tool_send_message.jl")
include("tool_scrape_article_text.jl")
include("tool_summarize_for_post.jl")

# Community-contributed blockchain investigation tools
include("community/blockchain/tool_solana_rpc.jl")
include("community/blockchain/tool_transaction_tracer.jl")
include("community/blockchain/tool_mixer_detector.jl")

# Community-contributed social media tools
include("community/social_media/tool_twitter_research.jl")
include("community/social_media/tool_thread_generator.jl")

# JuliaSphere marketplace management tools
include("marketplace/tool_marketplace_curator.jl")
include("marketplace/tool_agent_recommender.jl")
include("marketplace/tool_marketplace_optimizer.jl")

# JuliaSphere community management tools
include("community/tool_community_moderator.jl")
include("community/tool_market_analyst.jl")
include("community/tool_user_onboarding.jl")

using ..CommonTypes: ToolSpecification

const TOOL_REGISTRY = Dict{String, ToolSpecification}()

function register_tool(tool_spec::ToolSpecification)
    tool_name = tool_spec.metadata.name
    if haskey(TOOL_REGISTRY, tool_name)
        error("Tool with name '$tool_name' is already registered.")
    end
    TOOL_REGISTRY[tool_name] = tool_spec
end

# All tools to be used by agents must be registered here:

register_tool(TOOL_BLOG_WRITER_SPECIFICATION)
register_tool(TOOL_POST_TO_X_SPECIFICATION)
register_tool(TOOL_EXAMPLE_ADDER_SPECIFICATION)
register_tool(TOOL_LLM_CHAT_SPECIFICATION)
register_tool(TOOL_PING_SPECIFICATION)
register_tool(TOOL_BAN_USER_SPECIFICATION)
register_tool(TOOL_DETECT_SWEAR_SPECIFICATION)
register_tool(TOOL_SEND_MESSAGE_SPECIFICATION)
register_tool(TOOL_SCRAPE_ARTICLE_TEXT_SPECIFICATION)
register_tool(TOOL_SUMMARIZE_FOR_POST_SPECIFICATION)

# Register community blockchain investigation tools
register_tool(TOOL_SOLANA_RPC_SPECIFICATION)
register_tool(TOOL_TRANSACTION_TRACER_SPECIFICATION)  
register_tool(TOOL_MIXER_DETECTOR_SPECIFICATION)

# Register community social media tools
register_tool(TOOL_TWITTER_RESEARCH_SPECIFICATION)
register_tool(TOOL_THREAD_GENERATOR_SPECIFICATION)

# Register JuliaSphere marketplace management tools
register_tool(TOOL_MARKETPLACE_CURATOR_SPECIFICATION)
register_tool(TOOL_AGENT_RECOMMENDER_SPECIFICATION)
register_tool(TOOL_MARKETPLACE_OPTIMIZER_SPECIFICATION)

# Register JuliaSphere community management tools
register_tool(TOOL_COMMUNITY_MODERATOR_SPECIFICATION)
register_tool(TOOL_MARKET_ANALYST_SPECIFICATION)
register_tool(TOOL_USER_ONBOARDING_SPECIFICATION)

end