module MarketplaceAPI

using HTTP
using JSON3
using UUIDs
using Dates

using ..JuliaDB
using ..Agents
using ..AgentAnalytics
using ..SwarmCoordination
using ...Resources: Errors

# Marketplace-specific data types
struct UserProfile
    id::UUID
    username::String
    email::Union{String, Nothing}
    display_name::Union{String, Nothing}
    bio::Union{String, Nothing}
    avatar_url::Union{String, Nothing}
    reputation_score::Float64
    total_agents_created::Int
    total_deployments::Int
    wallet_address::Union{String, Nothing}
    created_at::DateTime
    updated_at::DateTime
end

struct AgentMarketplaceInfo
    agent_id::String
    creator_id::Union{UUID, Nothing}
    is_public::Bool
    is_featured::Bool
    category::Union{String, Nothing}
    tags::Vector{String}
    pricing_model::String  # 'free', 'one_time', 'subscription', 'usage_based'
    price_amount::Union{Float64, Nothing}
    currency::String
    total_deployments::Int
    total_revenue::Float64
    avg_rating::Float64
    rating_count::Int
    featured_image_url::Union{String, Nothing}
    documentation::Union{String, Nothing}
    example_usage::Union{Dict{String, Any}, Nothing}
    performance_metrics::Union{Dict{String, Any}, Nothing}
    created_at::DateTime
    updated_at::DateTime
end

struct AgentDeployment
    id::UUID
    agent_id::String
    deployer_id::Union{UUID, Nothing}
    deployment_config::Union{Dict{String, Any}, Nothing}
    status::String
    execution_count::Int
    last_execution::Union{DateTime, Nothing}
    total_cost::Float64
    created_at::DateTime
    updated_at::DateTime
end

struct AgentReview
    id::UUID
    agent_id::String
    reviewer_id::UUID
    rating::Int
    review_text::Union{String, Nothing}
    deployment_context::Union{Dict{String, Any}, Nothing}
    created_at::DateTime
    updated_at::DateTime
end

struct SwarmConnection
    id::UUID
    source_agent_id::String
    target_agent_id::String
    connection_type::String  # 'delegates_to', 'receives_from', 'coordinates_with'
    data_flow_description::Union{String, Nothing}
    is_active::Bool
    created_at::DateTime
end

# ============================================================================
# MARKETPLACE ENDPOINTS
# ============================================================================

"""
GET /marketplace/agents
List all public agents in the marketplace with filtering and pagination
"""
function list_marketplace_agents(req::HTTP.Request; 
                                category::Union{String, Nothing}=nothing,
                                tags::Union{Vector{String}, Nothing}=nothing,
                                featured_only::Bool=false,
                                sort_by::String="created_at",
                                limit::Int=50,
                                offset::Int=0)::Vector{Dict{String, Any}}
    @info "Triggered endpoint: GET /marketplace/agents"
    
    # Build WHERE conditions
    conditions = ["amp.is_public = true"]
    params = []
    
    if category !== nothing
        push!(conditions, "amp.category = ?")
        push!(params, category)
    end
    
    if featured_only
        push!(conditions, "amp.is_featured = true")
    end
    
    if tags !== nothing && !isempty(tags)
        push!(conditions, "amp.tags && ?")  # PostgreSQL array overlap operator
        push!(params, tags)
    end
    
    where_clause = join(conditions, " AND ")
    
    # Build ORDER BY clause
    order_map = Dict(
        "created_at" => "amp.created_at DESC",
        "rating" => "amp.avg_rating DESC",
        "deployments" => "amp.total_deployments DESC",
        "name" => "a.name ASC"
    )
    order_clause = get(order_map, sort_by, "amp.created_at DESC")
    
    query = """
        SELECT 
            a.id, a.name, a.description, a.strategy,
            amp.category, amp.tags, amp.pricing_model, amp.price_amount, amp.currency,
            amp.total_deployments, amp.avg_rating, amp.rating_count,
            amp.featured_image_url, amp.is_featured,
            up.username as creator_username, up.display_name as creator_display_name,
            amp.created_at, amp.updated_at
        FROM agents a
        LEFT JOIN agent_marketplace amp ON a.id = amp.agent_id
        LEFT JOIN user_profiles up ON amp.creator_id = up.id
        WHERE $where_clause
        ORDER BY $order_clause
        LIMIT $limit OFFSET $offset
    """
    
    try
        result = JuliaDB.execute_query(query, params)
        return [Dict(
            "id" => row.id,
            "name" => row.name,
            "description" => row.description,
            "strategy" => row.strategy,
            "category" => row.category,
            "tags" => row.tags,
            "pricing" => Dict(
                "model" => row.pricing_model,
                "amount" => row.price_amount,
                "currency" => row.currency
            ),
            "stats" => Dict(
                "deployments" => row.total_deployments,
                "avg_rating" => row.avg_rating,
                "rating_count" => row.rating_count
            ),
            "creator" => Dict(
                "username" => row.creator_username,
                "display_name" => row.creator_display_name
            ),
            "featured_image_url" => row.featured_image_url,
            "is_featured" => row.is_featured,
            "created_at" => row.created_at,
            "updated_at" => row.updated_at
        ) for row in result]
    catch e
        @error "Error listing marketplace agents" exception=(e, catch_backtrace())
        return []
    end
end

"""
GET /marketplace/agents/{agent_id}
Get detailed marketplace information for a specific agent
"""
function get_marketplace_agent(req::HTTP.Request, agent_id::String)::Union{HTTP.Response, Dict{String, Any}}
    @info "Triggered endpoint: GET /marketplace/agents/$(agent_id)"
    
    query = """
        SELECT 
            a.id, a.name, a.description, a.strategy, a.strategy_config,
            a.trigger_type, a.trigger_params, a.state,
            amp.creator_id, amp.is_public, amp.is_featured, amp.category, amp.tags,
            amp.pricing_model, amp.price_amount, amp.currency,
            amp.total_deployments, amp.total_revenue, amp.avg_rating, amp.rating_count,
            amp.featured_image_url, amp.documentation, amp.example_usage,
            amp.performance_metrics, amp.created_at, amp.updated_at,
            up.username as creator_username, up.display_name as creator_display_name,
            up.reputation_score as creator_reputation
        FROM agents a
        LEFT JOIN agent_marketplace amp ON a.id = amp.agent_id
        LEFT JOIN user_profiles up ON amp.creator_id = up.id
        WHERE a.id = ?
    """
    
    try
        result = JuliaDB.execute_query(query, [agent_id])
        if isempty(result)
            return HTTP.Response(404, JSON3.write(Dict("error" => "Agent not found")))
        end
        
        row = first(result)
        
        # Get agent tools
        tools_query = "SELECT tool_name, tool_config FROM agent_tools WHERE agent_id = ? ORDER BY tool_index"
        tools_result = JuliaDB.execute_query(tools_query, [agent_id])
        tools = [Dict("name" => t.tool_name, "config" => t.tool_config) for t in tools_result]
        
        # Get recent reviews
        reviews_query = """
            SELECT ar.rating, ar.review_text, ar.created_at,
                   up.username as reviewer_username
            FROM agent_reviews ar
            LEFT JOIN user_profiles up ON ar.reviewer_id = up.id
            WHERE ar.agent_id = ?
            ORDER BY ar.created_at DESC
            LIMIT 10
        """
        reviews_result = JuliaDB.execute_query(reviews_query, [agent_id])
        reviews = [Dict(
            "rating" => r.rating,
            "review_text" => r.review_text,
            "reviewer_username" => r.reviewer_username,
            "created_at" => r.created_at
        ) for r in reviews_result]
        
        return Dict(
            "id" => row.id,
            "name" => row.name,
            "description" => row.description,
            "strategy" => Dict(
                "name" => row.strategy,
                "config" => row.strategy_config
            ),
            "tools" => tools,
            "trigger" => Dict(
                "type" => string(row.trigger_type),
                "params" => row.trigger_params
            ),
            "state" => string(row.state),
            "marketplace" => Dict(
                "is_public" => row.is_public,
                "is_featured" => row.is_featured,
                "category" => row.category,
                "tags" => row.tags,
                "pricing" => Dict(
                    "model" => row.pricing_model,
                    "amount" => row.price_amount,
                    "currency" => row.currency
                ),
                "stats" => Dict(
                    "deployments" => row.total_deployments,
                    "revenue" => row.total_revenue,
                    "avg_rating" => row.avg_rating,
                    "rating_count" => row.rating_count
                ),
                "featured_image_url" => row.featured_image_url,
                "documentation" => row.documentation,
                "example_usage" => row.example_usage,
                "performance_metrics" => row.performance_metrics
            ),
            "creator" => Dict(
                "username" => row.creator_username,
                "display_name" => row.creator_display_name,
                "reputation_score" => row.creator_reputation
            ),
            "reviews" => reviews,
            "created_at" => row.created_at,
            "updated_at" => row.updated_at
        )
    catch e
        @error "Error getting marketplace agent" exception=(e, catch_backtrace())
        return HTTP.Response(500, JSON3.write(Dict("error" => "Internal server error")))
    end
end

"""
POST /marketplace/agents/{agent_id}/publish
Publish an agent to the marketplace
"""
function publish_agent(req::HTTP.Request, agent_id::String; request_body::Dict{String,Any}=Dict{String,Any}())::HTTP.Response
    @info "Triggered endpoint: POST /marketplace/agents/$(agent_id)/publish"
    
    # Get authenticated user
    try
        using ..Auth
        creator_id = Auth.require_user_id(req)
        
        # Validate that agent exists
        agent = get(Agents.AGENTS, agent_id) do
            return nothing
        end
        if agent === nothing
            return HTTP.Response(404, JSON3.write(Dict("error" => "Agent not found")))
        end
        
        # Extract marketplace information from request body
        category = get(request_body, "category", nothing)
        tags = get(request_body, "tags", String[])
        pricing_model = get(request_body, "pricing_model", "free")
        price_amount = get(request_body, "price_amount", nothing)
        currency = get(request_body, "currency", "USD")
        documentation = get(request_body, "documentation", nothing)
        featured_image_url = get(request_body, "featured_image_url", nothing)
        example_usage = get(request_body, "example_usage", nothing)
        
        # Validate pricing model
        valid_pricing_models = ["free", "one_time", "subscription", "usage_based"]
        if !(pricing_model in valid_pricing_models)
            return HTTP.Response(400, JSON3.write(Dict("error" => "Invalid pricing model")))
        end
        
        # Validate price amount for paid models
        if pricing_model != "free" && (price_amount === nothing || price_amount <= 0)
            return HTTP.Response(400, JSON3.write(Dict("error" => "Price amount required for non-free pricing model")))
        end
        
        query = """
            INSERT INTO agent_marketplace (
                agent_id, creator_id, is_public, category, tags,
                pricing_model, price_amount, currency,
                documentation, featured_image_url, example_usage,
                created_at, updated_at
            ) VALUES (?, ?, true, ?, ?, ?, ?, ?, ?, ?, ?, NOW(), NOW())
            ON CONFLICT (agent_id) DO UPDATE SET
                is_public = true,
                category = EXCLUDED.category,
                tags = EXCLUDED.tags,
                pricing_model = EXCLUDED.pricing_model,
                price_amount = EXCLUDED.price_amount,
                currency = EXCLUDED.currency,
                documentation = EXCLUDED.documentation,
                featured_image_url = EXCLUDED.featured_image_url,
                example_usage = EXCLUDED.example_usage,
                updated_at = NOW()
        """
        
        JuliaDB.execute_query(query, [
            agent_id, creator_id, category, tags,
            pricing_model, price_amount, currency,
            documentation, featured_image_url, example_usage
        ])
        
        return HTTP.Response(200, JSON3.write(Dict(
            "message" => "Agent published successfully",
            "agent_id" => agent_id,
            "is_public" => true
        )))
    catch e
        @error "Error publishing agent" exception=(e, catch_backtrace())
        if isa(e, ArgumentError) && occursin("Authentication required", e.msg)
            return HTTP.Response(401, JSON3.write(Dict("error" => "Authentication required")))
        else
            return HTTP.Response(500, JSON3.write(Dict("error" => "Failed to publish agent")))
        end
    end
end

"""
POST /marketplace/agents/{agent_id}/deploy
Deploy an agent from the marketplace
"""
function deploy_marketplace_agent(req::HTTP.Request, agent_id::String; request_body::Dict{String,Any}=Dict{String,Any}())::HTTP.Response
    @info "Triggered endpoint: POST /marketplace/agents/$(agent_id)/deploy"
    
    # This would create a new agent instance for the user
    deployment_config = get(request_body, "config", Dict{String,Any}())
    deployer_id = get(request_body, "deployer_id", nothing)  # Should come from auth
    
    try
        # Create deployment record
        deployment_id = uuid4()
        insert_query = """
            INSERT INTO agent_deployments (
                id, agent_id, deployer_id, deployment_config,
                status, created_at, updated_at
            ) VALUES (?, ?, ?, ?, 'active', NOW(), NOW())
        """
        
        deployer_uuid = deployer_id !== nothing ? UUID(deployer_id) : nothing
        JuliaDB.execute_query(insert_query, [
            deployment_id, agent_id, deployer_uuid, deployment_config
        ])
        
        return HTTP.Response(201, JSON3.write(Dict(
            "deployment_id" => string(deployment_id),
            "agent_id" => agent_id,
            "status" => "active",
            "message" => "Agent deployed successfully"
        )))
    catch e
        @error "Error deploying marketplace agent" exception=(e, catch_backtrace())
        return HTTP.Response(500, JSON3.write(Dict("error" => "Failed to deploy agent")))
    end
end

"""
GET /marketplace/categories
Get list of available agent categories
"""
function list_categories(req::HTTP.Request)::Vector{Dict{String, Any}}
    @info "Triggered endpoint: GET /marketplace/categories"
    
    query = """
        SELECT category, COUNT(*) as agent_count
        FROM agent_marketplace
        WHERE is_public = true AND category IS NOT NULL
        GROUP BY category
        ORDER BY agent_count DESC, category ASC
    """
    
    try
        result = JuliaDB.execute_query(query, [])
        return [Dict(
            "name" => row.category,
            "agent_count" => row.agent_count
        ) for row in result]
    catch e
        @error "Error listing categories" exception=(e, catch_backtrace())
        return []
    end
end

"""
GET /marketplace/stats
Get marketplace statistics
"""
function get_marketplace_stats(req::HTTP.Request)::Dict{String, Any}
    @info "Triggered endpoint: GET /marketplace/stats"
    
    stats_query = """
        SELECT 
            COUNT(*) as total_public_agents,
            COUNT(CASE WHEN is_featured THEN 1 END) as featured_agents,
            AVG(avg_rating) as overall_avg_rating,
            SUM(total_deployments) as total_deployments,
            COUNT(DISTINCT creator_id) as total_creators
        FROM agent_marketplace
        WHERE is_public = true
    """
    
    try
        result = JuliaDB.execute_query(stats_query, [])
        if !isempty(result)
            row = first(result)
            return Dict(
                "total_public_agents" => row.total_public_agents,
                "featured_agents" => row.featured_agents,
                "overall_avg_rating" => round(row.overall_avg_rating, digits=2),
                "total_deployments" => row.total_deployments,
                "total_creators" => row.total_creators
            )
        else
            return Dict()
        end
    catch e
        @error "Error getting marketplace stats" exception=(e, catch_backtrace())
        return Dict("error" => "Failed to retrieve stats")
    end
end

# ============================================================================
# ANALYTICS ENDPOINTS
# ============================================================================

"""
GET /marketplace/analytics/overview
Get overall marketplace analytics
"""
function get_analytics_overview(req::HTTP.Request)::Dict{String, Any}
    @info "Triggered endpoint: GET /marketplace/analytics/overview"
    return AgentAnalytics.get_marketplace_analytics()
end

"""
GET /marketplace/analytics/leaderboard
Get agent performance leaderboard
"""
function get_leaderboard(req::HTTP.Request; 
                        limit::Int=20,
                        metric::String="overall_score")::Vector{Dict{String, Any}}
    @info "Triggered endpoint: GET /marketplace/analytics/leaderboard"
    
    # Parse query parameters from URL
    url_parts = split(req.target, '?')
    if length(url_parts) > 1
        query_params = HTTP.URIs.queryparams(url_parts[2])
        limit = parse(Int, get(query_params, "limit", "20"))
        metric = get(query_params, "metric", "overall_score")
    end
    
    return AgentAnalytics.get_agents_leaderboard(limit, metric)
end

"""
GET /marketplace/analytics/agents/{agent_id}/performance
Get detailed performance metrics for a specific agent
"""
function get_agent_performance(req::HTTP.Request, agent_id::String)::Union{HTTP.Response, Dict{String, Any}}
    @info "Triggered endpoint: GET /marketplace/analytics/agents/$(agent_id)/performance"
    
    try
        performance_metrics = AgentAnalytics.calculate_agent_performance(agent_id)
        health_score = AgentAnalytics.calculate_agent_health_score(agent_id)
        
        if performance_metrics === nothing
            return HTTP.Response(404, JSON3.write(Dict("error" => "No performance data found for agent")))
        end
        
        return Dict(
            "agent_id" => agent_id,
            "performance_metrics" => Dict(
                "total_executions" => performance_metrics.total_executions,
                "successful_executions" => performance_metrics.successful_executions,
                "failed_executions" => performance_metrics.failed_executions,
                "success_rate" => performance_metrics.success_rate,
                "error_rate" => performance_metrics.error_rate,
                "avg_execution_time_ms" => performance_metrics.avg_execution_time_ms,
                "median_execution_time_ms" => performance_metrics.median_execution_time_ms,
                "min_execution_time_ms" => performance_metrics.min_execution_time_ms,
                "max_execution_time_ms" => performance_metrics.max_execution_time_ms,
                "total_cost" => performance_metrics.total_cost,
                "avg_cost_per_execution" => performance_metrics.avg_cost_per_execution,
                "last_execution" => performance_metrics.last_execution,
                "tools_usage_stats" => performance_metrics.tools_usage_stats
            ),
            "health_score" => health_score !== nothing ? Dict(
                "overall_score" => health_score.overall_score,
                "performance_score" => health_score.performance_score,
                "reliability_score" => health_score.reliability_score,
                "efficiency_score" => health_score.efficiency_score,
                "user_satisfaction_score" => health_score.user_satisfaction_score,
                "computed_at" => health_score.computed_at
            ) : nothing
        )
    catch e
        @error "Error getting agent performance" exception=(e, catch_backtrace())
        return HTTP.Response(500, JSON3.write(Dict("error" => "Failed to retrieve performance data")))
    end
end

"""
GET /marketplace/analytics/agents/{agent_id}/timeseries
Get time-series performance data for an agent
"""
function get_agent_timeseries(req::HTTP.Request, agent_id::String)::Vector{Dict{String, Any}}
    @info "Triggered endpoint: GET /marketplace/analytics/agents/$(agent_id)/timeseries"
    
    # Parse days_back parameter
    days_back = 30
    url_parts = split(req.target, '?')
    if length(url_parts) > 1
        query_params = HTTP.URIs.queryparams(url_parts[2])
        days_back = parse(Int, get(query_params, "days", "30"))
    end
    
    return AgentAnalytics.get_agent_performance_timeseries(agent_id, days_back)
end

"""
POST /marketplace/analytics/agents/{agent_id}/execution/start
Start tracking an agent execution
"""
function start_execution_tracking_endpoint(req::HTTP.Request, agent_id::String; 
                                         request_body::Dict{String,Any}=Dict{String,Any}())::HTTP.Response
    @info "Triggered endpoint: POST /marketplace/analytics/agents/$(agent_id)/execution/start"
    
    deployment_id = get(request_body, "deployment_id", nothing)
    if deployment_id !== nothing
        deployment_id = UUID(deployment_id)
    end
    
    input_data = get(request_body, "input_data", nothing)
    
    try
        execution_id = AgentAnalytics.start_execution_tracking(
            agent_id; 
            deployment_id=deployment_id, 
            input_data=input_data
        )
        
        return HTTP.Response(201, JSON3.write(Dict(
            "execution_id" => string(execution_id),
            "agent_id" => agent_id,
            "status" => "tracking_started"
        )))
    catch e
        @error "Failed to start execution tracking" exception=(e, catch_backtrace())
        return HTTP.Response(500, JSON3.write(Dict("error" => "Failed to start execution tracking")))
    end
end

"""
POST /marketplace/analytics/executions/{execution_id}/complete
Complete execution tracking
"""
function complete_execution_tracking_endpoint(req::HTTP.Request, execution_id_str::String; 
                                            request_body::Dict{String,Any}=Dict{String,Any}())::HTTP.Response
    @info "Triggered endpoint: POST /marketplace/analytics/executions/$(execution_id_str)/complete"
    
    try
        execution_id = UUID(execution_id_str)
        
        status = get(request_body, "status", "completed")
        output_data = get(request_body, "output_data", nothing)
        error_message = get(request_body, "error_message", nothing)
        tools_used = get(request_body, "tools_used", String[])
        cost_incurred = get(request_body, "cost_incurred", 0.0)
        
        AgentAnalytics.complete_execution_tracking(
            execution_id;
            status=status,
            output_data=output_data,
            error_message=error_message,
            tools_used=tools_used,
            cost_incurred=cost_incurred
        )
        
        return HTTP.Response(200, JSON3.write(Dict(
            "execution_id" => execution_id_str,
            "status" => "tracking_completed"
        )))
    catch e
        @error "Failed to complete execution tracking" exception=(e, catch_backtrace())
        return HTTP.Response(500, JSON3.write(Dict("error" => "Failed to complete execution tracking")))
    end
end

# ============================================================================
# SWARM COORDINATION ENDPOINTS
# ============================================================================

"""
GET /marketplace/swarms
Get current swarm topologies
"""
function get_swarm_topologies(req::HTTP.Request)::Vector{Dict{String, Any}}
    @info "Triggered endpoint: GET /marketplace/swarms"
    
    try
        swarms = SwarmCoordination.get_current_swarm_topology()
        
        return [Dict(
            "swarm_id" => swarm.swarm_id,
            "agents" => swarm.agents,
            "connections" => [Dict(
                "id" => string(conn.id),
                "source" => conn.source_agent_id,
                "target" => conn.target_agent_id,
                "type" => conn.connection_type,
                "description" => conn.data_flow_description,
                "strength" => conn.strength,
                "last_interaction" => conn.last_interaction,
                "is_active" => conn.is_active
            ) for conn in swarm.connections],
            "coordination_patterns" => swarm.coordination_patterns,
            "created_at" => swarm.created_at,
            "updated_at" => swarm.updated_at
        ) for swarm in swarms]
    catch e
        @error "Error getting swarm topologies" exception=(e, catch_backtrace())
        return []
    end
end

"""
GET /marketplace/swarms/{swarm_id}/performance
Get performance analysis for a specific swarm
"""
function get_swarm_performance(req::HTTP.Request, swarm_id::String)::Union{HTTP.Response, Dict{String, Any}}
    @info "Triggered endpoint: GET /marketplace/swarms/$(swarm_id)/performance"
    
    try
        swarms = SwarmCoordination.get_current_swarm_topology()
        target_swarm = findfirst(s -> s.swarm_id == swarm_id, swarms)
        
        if target_swarm === nothing
            return HTTP.Response(404, JSON3.write(Dict("error" => "Swarm not found")))
        end
        
        performance = SwarmCoordination.analyze_swarm_performance(swarms[target_swarm])
        return performance
    catch e
        @error "Error getting swarm performance" exception=(e, catch_backtrace())
        return HTTP.Response(500, JSON3.write(Dict("error" => "Failed to analyze swarm performance")))
    end
end

"""
POST /marketplace/swarms/analyze
Trigger swarm coordination analysis
"""
function trigger_swarm_analysis(req::HTTP.Request; request_body::Dict{String,Any}=Dict{String,Any}())::HTTP.Response
    @info "Triggered endpoint: POST /marketplace/swarms/analyze"
    
    time_window_hours = get(request_body, "time_window_hours", 24)
    
    try
        swarms = SwarmCoordination.update_swarm_coordination(time_window_hours)
        
        return HTTP.Response(200, JSON3.write(Dict(
            "message" => "Swarm analysis completed",
            "swarms_detected" => length(swarms),
            "time_window_hours" => time_window_hours,
            "swarms" => [Dict(
                "swarm_id" => swarm.swarm_id,
                "agent_count" => length(swarm.agents),
                "connection_count" => length(swarm.connections),
                "dominant_pattern" => get(swarm.coordination_patterns, "dominant_pattern", "unknown")
            ) for swarm in swarms]
        )))
    catch e
        @error "Failed to trigger swarm analysis" exception=(e, catch_backtrace())
        return HTTP.Response(500, JSON3.write(Dict("error" => "Failed to analyze swarm coordination")))
    end
end

"""
GET /marketplace/agents/{agent_id}/connections
Get all connections for a specific agent
"""
function get_agent_connections(req::HTTP.Request, agent_id::String)::Vector{Dict{String, Any}}
    @info "Triggered endpoint: GET /marketplace/agents/$(agent_id)/connections"
    
    query = """
        SELECT 
            id, source_agent_id, target_agent_id, connection_type,
            data_flow_description, is_active, created_at
        FROM swarm_connections
        WHERE (source_agent_id = ? OR target_agent_id = ?) AND is_active = true
        ORDER BY created_at DESC
    """
    
    try
        result = JuliaDB.execute_query(query, [agent_id, agent_id])
        
        return [Dict(
            "id" => string(row.id),
            "source_agent_id" => row.source_agent_id,
            "target_agent_id" => row.target_agent_id,
            "connection_type" => row.connection_type,
            "data_flow_description" => row.data_flow_description,
            "is_active" => row.is_active,
            "created_at" => row.created_at,
            "direction" => row.source_agent_id == agent_id ? "outgoing" : "incoming"
        ) for row in result]
    catch e
        @error "Error getting agent connections" exception=(e, catch_backtrace())
        return []
    end
end

"""
GET /marketplace/swarms/graph-data
Get graph visualization data for all swarms
"""
function get_swarm_graph_data(req::HTTP.Request)::Dict{String, Any}
    @info "Triggered endpoint: GET /marketplace/swarms/graph-data"
    
    try
        swarms = SwarmCoordination.get_current_swarm_topology()
        
        # Collect all unique agents and connections
        all_agents = Set{String}()
        all_connections = []
        
        for swarm in swarms
            union!(all_agents, swarm.agents)
            append!(all_connections, swarm.connections)
        end
        
        # Get agent details for nodes (batch query to avoid N+1 problem)
        agent_ids_list = collect(all_agents)
        if !isempty(agent_ids_list)
            # Create placeholder string for IN clause
            placeholders = join(["?" for _ in 1:length(agent_ids_list)], ", ")
            
            agent_batch_query = """
                SELECT a.id, a.name, a.strategy, a.state,
                       amp.category, amp.is_featured
                FROM agents a
                LEFT JOIN agent_marketplace amp ON a.id = amp.agent_id
                WHERE a.id IN ($placeholders)
            """
            
            agent_results = JuliaDB.execute_query(agent_batch_query, agent_ids_list)
            
            # Batch calculate performance metrics to avoid N+1
            performance_batch = _batch_calculate_performance_metrics(agent_ids_list)
            
            nodes = []
            for agent_row in agent_results
                agent_id = agent_row.id
                perf_metrics = get(performance_batch, agent_id, nothing)
                
                status = if perf_metrics !== nothing && perf_metrics.total_executions > 0
                    perf_metrics.success_rate > 80 ? "healthy" : 
                    perf_metrics.success_rate > 50 ? "warning" : "error"
                else
                    "idle"
                end
                
                push!(nodes, Dict(
                    "data" => Dict(
                        "id" => agent_id,
                        "label" => agent_row.name,
                        "strategy" => agent_row.strategy,
                        "category" => agent_row.category,
                        "state" => string(agent_row.state),
                        "status" => status,
                        "is_featured" => agent_row.is_featured || false,
                        "success_rate" => perf_metrics !== nothing ? perf_metrics.success_rate : 0.0
                    )
                ))
            end
        else
            nodes = []
        end
        
        # Create edges from connections
        edges = [Dict(
            "data" => Dict(
                "id" => string(conn.id),
                "source" => conn.source_agent_id,
                "target" => conn.target_agent_id,
                "label" => conn.connection_type,
                "strength" => conn.strength,
                "description" => conn.data_flow_description,
                "is_active" => conn.is_active
            )
        ) for conn in all_connections]
        
        return Dict(
            "elements" => Dict(
                "nodes" => nodes,
                "edges" => edges
            ),
            "swarms" => [Dict(
                "swarm_id" => swarm.swarm_id,
                "agents" => swarm.agents,
                "coordination_pattern" => get(swarm.coordination_patterns, "dominant_pattern", "unknown"),
                "pattern_score" => get(swarm.coordination_patterns, "dominant_score", 0.0)
            ) for swarm in swarms],
            "stats" => Dict(
                "total_agents" => length(all_agents),
                "total_connections" => length(all_connections),
                "swarm_count" => length(swarms)
            )
        )
    catch e
        @error "Error getting swarm graph data" exception=(e, catch_backtrace())
        return Dict("error" => "Failed to retrieve swarm graph data")
    end
end

"""
Batch calculate performance metrics for multiple agents to avoid N+1 queries
"""
function _batch_calculate_performance_metrics(agent_ids::Vector{String})::Dict{String, Any}
    if isempty(agent_ids)
        return Dict{String, Any}()
    end
    
    # Create placeholder string for IN clause
    placeholders = join(["?" for _ in 1:length(agent_ids)], ", ")
    
    batch_query = """
        SELECT 
            agent_id,
            COUNT(*) as total_executions,
            COUNT(CASE WHEN status = 'completed' THEN 1 END) as successful_executions,
            COUNT(CASE WHEN status = 'failed' THEN 1 END) as failed_executions,
            AVG(execution_time_ms) as avg_execution_time,
            SUM(cost_incurred) as total_cost
        FROM agent_execution_logs
        WHERE agent_id IN ($placeholders) AND execution_time_ms IS NOT NULL
        GROUP BY agent_id
    """
    
    try
        result = JuliaDB.execute_query(batch_query, agent_ids)
        performance_map = Dict{String, Any}()
        
        for row in result
            agent_id = row.agent_id
            
            # Calculate derived metrics
            success_rate = row.total_executions > 0 ? 
                          (row.successful_executions / row.total_executions) * 100 : 0.0
            error_rate = 100.0 - success_rate
            avg_cost = row.total_executions > 0 ? 
                      row.total_cost / row.total_executions : 0.0
            
            performance_map[agent_id] = (
                total_executions = row.total_executions,
                successful_executions = row.successful_executions,
                failed_executions = row.failed_executions,
                avg_execution_time_ms = row.avg_execution_time || 0.0,
                success_rate = success_rate,
                error_rate = error_rate,
                total_cost = row.total_cost,
                avg_cost_per_execution = avg_cost
            )
        end
        
        return performance_map
    catch e
        @error "Failed to batch calculate performance metrics" exception=(e, catch_backtrace())
        return Dict{String, Any}()
    end
end

"""
Register marketplace routes with the HTTP router
"""
function register_routes!(router::HTTP.Router; path_prefix::String="/api/v1")
    # Marketplace agent discovery
    HTTP.register!(router, "GET", "$path_prefix/marketplace/agents", 
                   (req) -> HTTP.Response(200, JSON3.write(list_marketplace_agents(req))))
    
    HTTP.register!(router, "GET", "$path_prefix/marketplace/agents/{agent_id}", 
                   (req) -> begin
                       agent_id = HTTP.URIs.splitpath(req.target)[end]
                       result = get_marketplace_agent(req, agent_id)
                       if isa(result, HTTP.Response)
                           return result
                       else
                           return HTTP.Response(200, JSON3.write(result))
                       end
                   end)
    
    # Publishing and deployment
    HTTP.register!(router, "POST", "$path_prefix/marketplace/agents/{agent_id}/publish",
                   (req) -> begin
                       agent_id = HTTP.URIs.splitpath(req.target)[end-1]  # Remove /publish from end
                       body = JSON3.read(String(req.body), Dict{String,Any})
                       return publish_agent(req, agent_id; request_body=body)
                   end)
    
    HTTP.register!(router, "POST", "$path_prefix/marketplace/agents/{agent_id}/deploy",
                   (req) -> begin
                       agent_id = HTTP.URIs.splitpath(req.target)[end-1]  # Remove /deploy from end
                       body = JSON3.read(String(req.body), Dict{String,Any})
                       return deploy_marketplace_agent(req, agent_id; request_body=body)
                   end)
    
    # Marketplace metadata
    HTTP.register!(router, "GET", "$path_prefix/marketplace/categories",
                   (req) -> HTTP.Response(200, JSON3.write(list_categories(req))))
    
    HTTP.register!(router, "GET", "$path_prefix/marketplace/stats",
                   (req) -> HTTP.Response(200, JSON3.write(get_marketplace_stats(req))))
    
    # Analytics endpoints
    HTTP.register!(router, "GET", "$path_prefix/marketplace/analytics/overview",
                   (req) -> HTTP.Response(200, JSON3.write(get_analytics_overview(req))))
    
    HTTP.register!(router, "GET", "$path_prefix/marketplace/analytics/leaderboard",
                   (req) -> HTTP.Response(200, JSON3.write(get_leaderboard(req))))
    
    HTTP.register!(router, "GET", "$path_prefix/marketplace/analytics/agents/{agent_id}/performance",
                   (req) -> begin
                       agent_id = HTTP.URIs.splitpath(req.target)[end-1]  # Remove /performance from end
                       result = get_agent_performance(req, agent_id)
                       if isa(result, HTTP.Response)
                           return result
                       else
                           return HTTP.Response(200, JSON3.write(result))
                       end
                   end)
    
    HTTP.register!(router, "GET", "$path_prefix/marketplace/analytics/agents/{agent_id}/timeseries",
                   (req) -> begin
                       agent_id = HTTP.URIs.splitpath(req.target)[end-1]  # Remove /timeseries from end
                       return HTTP.Response(200, JSON3.write(get_agent_timeseries(req, agent_id)))
                   end)
    
    # Execution tracking endpoints
    HTTP.register!(router, "POST", "$path_prefix/marketplace/analytics/agents/{agent_id}/execution/start",
                   (req) -> begin
                       agent_id = HTTP.URIs.splitpath(req.target)[end-2]  # Remove /execution/start from end
                       body = JSON3.read(String(req.body), Dict{String,Any})
                       return start_execution_tracking_endpoint(req, agent_id; request_body=body)
                   end)
    
    HTTP.register!(router, "POST", "$path_prefix/marketplace/analytics/executions/{execution_id}/complete",
                   (req) -> begin
                       execution_id = HTTP.URIs.splitpath(req.target)[end-1]  # Remove /complete from end
                       body = JSON3.read(String(req.body), Dict{String,Any})
                       return complete_execution_tracking_endpoint(req, execution_id; request_body=body)
                   end)
    
    # Swarm coordination endpoints
    HTTP.register!(router, "GET", "$path_prefix/marketplace/swarms",
                   (req) -> HTTP.Response(200, JSON3.write(get_swarm_topologies(req))))
    
    HTTP.register!(router, "GET", "$path_prefix/marketplace/swarms/{swarm_id}/performance",
                   (req) -> begin
                       swarm_id = HTTP.URIs.splitpath(req.target)[end-1]  # Remove /performance from end
                       result = get_swarm_performance(req, swarm_id)
                       if isa(result, HTTP.Response)
                           return result
                       else
                           return HTTP.Response(200, JSON3.write(result))
                       end
                   end)
    
    HTTP.register!(router, "POST", "$path_prefix/marketplace/swarms/analyze",
                   (req) -> begin
                       body = JSON3.read(String(req.body), Dict{String,Any})
                       return trigger_swarm_analysis(req; request_body=body)
                   end)
    
    HTTP.register!(router, "GET", "$path_prefix/marketplace/agents/{agent_id}/connections",
                   (req) -> begin
                       agent_id = HTTP.URIs.splitpath(req.target)[end-1]  # Remove /connections from end
                       return HTTP.Response(200, JSON3.write(get_agent_connections(req, agent_id)))
                   end)
    
    HTTP.register!(router, "GET", "$path_prefix/marketplace/swarms/graph-data",
                   (req) -> HTTP.Response(200, JSON3.write(get_swarm_graph_data(req))))
end

end # module MarketplaceAPI