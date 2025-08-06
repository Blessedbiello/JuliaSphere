module AgentAnalytics

using UUIDs
using Dates
using Statistics
using JSON3

using ..JuliaDB
using ..Agents

# Analytics data structures
struct ExecutionMetrics
    execution_id::UUID
    agent_id::String
    deployment_id::Union{UUID, Nothing}
    start_time::DateTime
    end_time::Union{DateTime, Nothing}
    execution_time_ms::Union{Int, Nothing}
    status::String  # 'started', 'completed', 'failed', 'timeout'
    input_data::Union{Dict{String, Any}, Nothing}
    output_data::Union{Dict{String, Any}, Nothing}
    error_message::Union{String, Nothing}
    tools_used::Vector{String}
    cost_incurred::Float64
end

struct PerformanceMetrics
    agent_id::String
    total_executions::Int
    successful_executions::Int
    failed_executions::Int
    avg_execution_time_ms::Float64
    median_execution_time_ms::Float64
    min_execution_time_ms::Float64
    max_execution_time_ms::Float64
    success_rate::Float64
    error_rate::Float64
    total_cost::Float64
    avg_cost_per_execution::Float64
    last_execution::Union{DateTime, Nothing}
    tools_usage_stats::Dict{String, Int}
end

struct AgentHealthScore
    agent_id::String
    overall_score::Float64  # 0-100
    performance_score::Float64
    reliability_score::Float64
    efficiency_score::Float64
    user_satisfaction_score::Float64
    computed_at::DateTime
end

# ============================================================================
# EXECUTION TRACKING
# ============================================================================

"""
Start tracking an agent execution
Returns execution_id for later completion tracking
"""
function start_execution_tracking(agent_id::String; 
                                 deployment_id::Union{UUID, Nothing}=nothing,
                                 input_data::Union{Dict{String, Any}, Nothing}=nothing)::UUID
    execution_id = uuid4()
    
    query = """
        INSERT INTO agent_execution_logs (
            id, agent_id, deployment_id, execution_start, status, input_data
        ) VALUES (?, ?, ?, ?, 'started', ?)
    """
    
    try
        JuliaDB.execute_query(query, [
            execution_id, agent_id, deployment_id, now(), input_data
        ])
        @info "Started execution tracking for agent $agent_id" execution_id
        return execution_id
    catch e
        @error "Failed to start execution tracking" exception=(e, catch_backtrace())
        return execution_id  # Return ID anyway for graceful degradation
    end
end

"""
Complete execution tracking with results
"""
function complete_execution_tracking(execution_id::UUID;
                                   status::String="completed",
                                   output_data::Union{Dict{String, Any}, Nothing}=nothing,
                                   error_message::Union{String, Nothing}=nothing,
                                   tools_used::Vector{String}=String[],
                                   cost_incurred::Float64=0.0)
    end_time = now()
    
    # Calculate execution time
    start_query = "SELECT execution_start FROM agent_execution_logs WHERE id = ?"
    start_result = JuliaDB.execute_query(start_query, [execution_id])
    
    execution_time_ms = nothing
    if !isempty(start_result)
        start_time = first(start_result).execution_start
        execution_time_ms = Int(round((end_time - start_time).value))
    end
    
    update_query = """
        UPDATE agent_execution_logs 
        SET execution_end = ?, status = ?, output_data = ?, error_message = ?,
            tools_used = ?, execution_time_ms = ?, cost_incurred = ?,
            created_at = NOW()
        WHERE id = ?
    """
    
    try
        JuliaDB.execute_query(update_query, [
            end_time, status, output_data, error_message,
            tools_used, execution_time_ms, cost_incurred, execution_id
        ])
        @info "Completed execution tracking" execution_id status execution_time_ms
        
        # Update deployment statistics if applicable
        if execution_time_ms !== nothing
            update_deployment_stats(execution_id)
        end
    catch e
        @error "Failed to complete execution tracking" exception=(e, catch_backtrace())
    end
end

"""
Update deployment execution statistics
"""
function update_deployment_stats(execution_id::UUID)
    query = """
        UPDATE agent_deployments 
        SET execution_count = execution_count + 1,
            last_execution = NOW(),
            total_cost = total_cost + (
                SELECT COALESCE(cost_incurred, 0) 
                FROM agent_execution_logs 
                WHERE id = ?
            ),
            updated_at = NOW()
        WHERE id = (
            SELECT deployment_id 
            FROM agent_execution_logs 
            WHERE id = ? AND deployment_id IS NOT NULL
        )
    """
    
    try
        JuliaDB.execute_query(query, [execution_id, execution_id])
    catch e
        @error "Failed to update deployment stats" exception=(e, catch_backtrace())
    end
end

# ============================================================================
# PERFORMANCE ANALYTICS
# ============================================================================

"""
Calculate comprehensive performance metrics for an agent
"""
function calculate_agent_performance(agent_id::String)::Union{PerformanceMetrics, Nothing}
    # Get execution statistics
    stats_query = """
        SELECT 
            COUNT(*) as total_executions,
            COUNT(CASE WHEN status = 'completed' THEN 1 END) as successful_executions,
            COUNT(CASE WHEN status = 'failed' THEN 1 END) as failed_executions,
            AVG(execution_time_ms) as avg_execution_time,
            PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY execution_time_ms) as median_execution_time,
            MIN(execution_time_ms) as min_execution_time,
            MAX(execution_time_ms) as max_execution_time,
            SUM(cost_incurred) as total_cost,
            MAX(execution_start) as last_execution
        FROM agent_execution_logs
        WHERE agent_id = ? AND execution_time_ms IS NOT NULL
    """
    
    try
        result = JuliaDB.execute_query(stats_query, [agent_id])
        if isempty(result)
            return nothing
        end
        
        row = first(result)
        
        # Calculate derived metrics
        success_rate = row.total_executions > 0 ? 
                      (row.successful_executions / row.total_executions) * 100 : 0.0
        error_rate = 100.0 - success_rate
        avg_cost = row.total_executions > 0 ? 
                  row.total_cost / row.total_executions : 0.0
        
        # Get tools usage statistics
        tools_stats = get_tools_usage_stats(agent_id)
        
        return PerformanceMetrics(
            agent_id,
            row.total_executions,
            row.successful_executions,
            row.failed_executions,
            row.avg_execution_time || 0.0,
            row.median_execution_time || 0.0,
            row.min_execution_time || 0.0,
            row.max_execution_time || 0.0,
            success_rate,
            error_rate,
            row.total_cost,
            avg_cost,
            row.last_execution,
            tools_stats
        )
    catch e
        @error "Failed to calculate agent performance" exception=(e, catch_backtrace())
        return nothing
    end
end

"""
Get tools usage statistics for an agent
"""
function get_tools_usage_stats(agent_id::String)::Dict{String, Int}
    query = """
        SELECT unnest(tools_used) as tool_name, COUNT(*) as usage_count
        FROM agent_execution_logs
        WHERE agent_id = ? AND tools_used IS NOT NULL
        GROUP BY unnest(tools_used)
        ORDER BY usage_count DESC
    """
    
    try
        result = JuliaDB.execute_query(query, [agent_id])
        return Dict(row.tool_name => row.usage_count for row in result)
    catch e
        @error "Failed to get tools usage stats" exception=(e, catch_backtrace())
        return Dict{String, Int}()
    end
end

"""
Calculate agent health score based on multiple factors
"""
function calculate_agent_health_score(agent_id::String)::Union{AgentHealthScore, Nothing}
    perf_metrics = calculate_agent_performance(agent_id)
    if perf_metrics === nothing
        return nothing
    end
    
    # Performance score (0-25 points): Based on success rate and speed
    performance_score = min(25.0, 
        (perf_metrics.success_rate / 100.0) * 20.0 +  # Up to 20 points for success rate
        (perf_metrics.avg_execution_time_ms < 5000 ? 5.0 : 
         perf_metrics.avg_execution_time_ms < 15000 ? 3.0 : 1.0)  # Up to 5 points for speed
    )
    
    # Reliability score (0-25 points): Based on consistency and uptime
    reliability_score = min(25.0,
        (perf_metrics.success_rate / 100.0) * 15.0 +  # Up to 15 points for success rate
        (perf_metrics.total_executions >= 100 ? 10.0 :
         perf_metrics.total_executions >= 50 ? 7.0 :
         perf_metrics.total_executions >= 10 ? 5.0 : 2.0)  # Up to 10 points for volume
    )
    
    # Efficiency score (0-25 points): Based on cost and resource usage
    efficiency_score = if perf_metrics.avg_cost_per_execution > 0
        min(25.0,
            (1.0 / log10(max(1.1, perf_metrics.avg_cost_per_execution))) * 15.0 +  # Lower cost = higher score
            (perf_metrics.avg_execution_time_ms < 3000 ? 10.0 :
             perf_metrics.avg_execution_time_ms < 10000 ? 7.0 : 3.0)  # Faster execution
        )
    else
        20.0  # Default good score for free agents
    end
    
    # User satisfaction score (0-25 points): Based on ratings and reviews
    satisfaction_score = get_user_satisfaction_score(agent_id)
    
    overall_score = performance_score + reliability_score + efficiency_score + satisfaction_score
    
    return AgentHealthScore(
        agent_id,
        overall_score,
        performance_score,
        reliability_score,
        efficiency_score,
        satisfaction_score,
        now()
    )
end

"""
Get user satisfaction score from reviews and ratings
"""
function get_user_satisfaction_score(agent_id::String)::Float64
    query = """
        SELECT AVG(rating) as avg_rating, COUNT(*) as review_count
        FROM agent_reviews
        WHERE agent_id = ?
    """
    
    try
        result = JuliaDB.execute_query(query, [agent_id])
        if isempty(result)
            return 15.0  # Default neutral score
        end
        
        row = first(result)
        if row.avg_rating === nothing
            return 15.0
        end
        
        # Convert 1-5 star rating to 0-20 point scale, with bonus for volume
        base_score = (row.avg_rating / 5.0) * 20.0
        volume_bonus = min(5.0, log10(max(1, row.review_count)))  # Up to 5 bonus points
        
        return min(25.0, base_score + volume_bonus)
    catch e
        @error "Failed to get user satisfaction score" exception=(e, catch_backtrace())
        return 15.0  # Default neutral score
    end
end

# ============================================================================
# ANALYTICS ENDPOINTS
# ============================================================================

"""
Get performance metrics for multiple agents (leaderboard data)
"""
function get_agents_leaderboard(limit::Int=20, 
                               metric::String="overall_score")::Vector{Dict{String, Any}}
    # First, calculate health scores for all active agents
    agents_query = """
        SELECT DISTINCT a.id, a.name, amp.category, amp.is_public
        FROM agents a
        LEFT JOIN agent_marketplace amp ON a.id = amp.agent_id
        WHERE amp.is_public = true
        ORDER BY a.name
    """
    
    try
        agents_result = JuliaDB.execute_query(agents_query, [])
        leaderboard = []
        
        for agent_row in agents_result
            health_score = calculate_agent_health_score(agent_row.id)
            perf_metrics = calculate_agent_performance(agent_row.id)
            
            if health_score !== nothing && perf_metrics !== nothing
                push!(leaderboard, Dict(
                    "id" => agent_row.id,
                    "name" => agent_row.name,
                    "category" => agent_row.category,
                    "health_score" => health_score,
                    "performance_metrics" => perf_metrics
                ))
            end
        end
        
        # Sort by specified metric
        sort_key = if metric == "success_rate"
            agent -> agent["performance_metrics"].success_rate
        elseif metric == "executions"
            agent -> agent["performance_metrics"].total_executions
        elseif metric == "speed"
            agent -> -agent["performance_metrics"].avg_execution_time_ms  # Negative for ascending order
        else  # default to overall_score
            agent -> agent["health_score"].overall_score
        end
        
        sort!(leaderboard, by=sort_key, rev=true)
        
        return leaderboard[1:min(limit, length(leaderboard))]
    catch e
        @error "Failed to get agents leaderboard" exception=(e, catch_backtrace())
        return []
    end
end

"""
Get time-series performance data for an agent
"""
function get_agent_performance_timeseries(agent_id::String, 
                                        days_back::Int=30)::Vector{Dict{String, Any}}
    start_date = now() - Day(days_back)
    
    query = """
        SELECT 
            DATE(execution_start) as execution_date,
            COUNT(*) as total_executions,
            COUNT(CASE WHEN status = 'completed' THEN 1 END) as successful_executions,
            AVG(execution_time_ms) as avg_execution_time,
            SUM(cost_incurred) as total_cost
        FROM agent_execution_logs
        WHERE agent_id = ? AND execution_start >= ?
        GROUP BY DATE(execution_start)
        ORDER BY execution_date ASC
    """
    
    try
        result = JuliaDB.execute_query(query, [agent_id, start_date])
        
        return [Dict(
            "date" => row.execution_date,
            "total_executions" => row.total_executions,
            "successful_executions" => row.successful_executions,
            "success_rate" => row.total_executions > 0 ? 
                             (row.successful_executions / row.total_executions) * 100 : 0.0,
            "avg_execution_time_ms" => row.avg_execution_time || 0.0,
            "total_cost" => row.total_cost
        ) for row in result]
    catch e
        @error "Failed to get agent performance timeseries" exception=(e, catch_backtrace())
        return []
    end
end

"""
Get marketplace analytics overview
"""
function get_marketplace_analytics()::Dict{String, Any}
    overview_query = """
        SELECT 
            COUNT(DISTINCT ael.agent_id) as active_agents,
            COUNT(*) as total_executions,
            COUNT(CASE WHEN ael.status = 'completed' THEN 1 END) as successful_executions,
            AVG(ael.execution_time_ms) as avg_execution_time,
            SUM(ael.cost_incurred) as total_revenue,
            COUNT(DISTINCT ael.deployment_id) as active_deployments
        FROM agent_execution_logs ael
        JOIN agent_marketplace amp ON ael.agent_id = amp.agent_id
        WHERE amp.is_public = true
        AND ael.execution_start >= NOW() - INTERVAL '30 days'
    """
    
    try
        result = JuliaDB.execute_query(overview_query, [])
        if isempty(result)
            return Dict()
        end
        
        row = first(result)
        success_rate = row.total_executions > 0 ? 
                      (row.successful_executions / row.total_executions) * 100 : 0.0
        
        return Dict(
            "active_agents" => row.active_agents,
            "total_executions_30d" => row.total_executions,
            "success_rate_30d" => round(success_rate, digits=2),
            "avg_execution_time_ms" => round(row.avg_execution_time || 0.0, digits=2),
            "total_revenue_30d" => row.total_revenue,
            "active_deployments" => row.active_deployments
        )
    catch e
        @error "Failed to get marketplace analytics" exception=(e, catch_backtrace())
        return Dict("error" => "Failed to retrieve analytics")
    end
end

end # module AgentAnalytics