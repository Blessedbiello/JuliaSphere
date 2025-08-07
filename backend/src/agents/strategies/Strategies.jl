module Strategies

export STRATEGY_REGISTRY

include("strategy_example_adder.jl")
include("strategy_plan_and_execute.jl")
include("strategy_blogger.jl")
include("telegram/strategy_moderator.jl")
include("telegram/strategy_support.jl")
include("strategy_ai_news_scraping.jl")

# JuliaSphere Meta-Agent Strategy
include("strategy_juliasphere_meta.jl")

# Community-contributed investigation strategies
include("community/investigation/strategy_juliaxbt_investigation.jl")

using ..CommonTypes: StrategySpecification

const STRATEGY_REGISTRY = Dict{String, StrategySpecification}()

function register_strategy(strategy_spec::StrategySpecification)
    strategy_name = strategy_spec.metadata.name
    if haskey(STRATEGY_REGISTRY, strategy_name)
        error("Strategy with name '$strategy_name' is already registered.")
    end
    STRATEGY_REGISTRY[strategy_name] = strategy_spec
end

# All strategies to be used by agents must be registered here:

register_strategy(STRATEGY_EXAMPLE_ADDER_SPECIFICATION)
register_strategy(STRATEGY_PLAN_AND_EXECUTE_SPECIFICATION)
register_strategy(STRATEGY_BLOG_WRITER_SPECIFICATION)
register_strategy(STRATEGY_TELEGRAM_MODERATOR_SPECIFICATION)
register_strategy(STRATEGY_TELEGRAM_SUPPORT_SPECIFICATION)
register_strategy(STRATEGY_AI_NEWS_SCRAPING_SPECIFICATION)

# Register JuliaSphere Meta-Agent strategy
register_strategy(STRATEGY_JULIASPHERE_META_SPECIFICATION)

# Register community investigation strategies
register_strategy(STRATEGY_JULIAXBT_INVESTIGATION_SPECIFICATION)

end