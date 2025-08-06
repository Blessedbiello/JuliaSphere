module SwarmCoordination

using UUIDs
using Dates
using JSON3

using ..JuliaDB
using ..Agents
using ..AgentAnalytics

# Swarm coordination data structures
struct AgentConnection
    id::UUID
    source_agent_id::String
    target_agent_id::String
    connection_type::String  # 'delegates_to', 'receives_from', 'coordinates_with', 'competes_with'
    data_flow_description::Union{String, Nothing}
    strength::Float64  # 0.0-1.0, based on interaction frequency and importance
    last_interaction::Union{DateTime, Nothing}
    is_active::Bool
    created_at::DateTime
end

struct SwarmTopology
    swarm_id::String
    agents::Vector{String}  # agent IDs
    connections::Vector{AgentConnection}
    coordination_patterns::Dict{String, Any}
    performance_metrics::Union{Dict{String, Any}, Nothing}
    created_at::DateTime
    updated_at::DateTime
end

struct CoordinationPattern
    pattern_name::String
    description::String
    agents_involved::Vector{String}
    interaction_sequence::Vector{Dict{String, Any}}
    success_indicators::Vector{String}
    failure_indicators::Vector{String}
end

# ============================================================================
# AGENT INTERACTION DETECTION
# ============================================================================

"""
Analyze agent execution logs to detect interaction patterns
This function examines tool usage, timing, and data flow to infer agent relationships
"""
function detect_agent_interactions(time_window_hours::Int=24)::Vector{AgentConnection}
    cutoff_time = now() - Hour(time_window_hours)
    
    # Query for recent agent executions with overlapping timeframes
    query = """
        WITH agent_executions AS (
            SELECT 
                agent_id,
                execution_start,
                execution_end,
                tools_used,
                input_data,
                output_data,
                status
            FROM agent_execution_logs
            WHERE execution_start >= ? AND status = 'completed'
            ORDER BY execution_start
        ),
        potential_interactions AS (
            SELECT DISTINCT
                a1.agent_id as source_agent,
                a2.agent_id as target_agent,
                COUNT(*) as interaction_count,
                AVG(EXTRACT(EPOCH FROM (a2.execution_start - a1.execution_end))/60) as avg_delay_minutes,
                STRING_AGG(DISTINCT unnest(a1.tools_used), ',') as source_tools,
                STRING_AGG(DISTINCT unnest(a2.tools_used), ',') as target_tools
            FROM agent_executions a1
            JOIN agent_executions a2 ON a1.agent_id != a2.agent_id
            WHERE a2.execution_start BETWEEN a1.execution_end AND a1.execution_end + INTERVAL '10 minutes'
            GROUP BY a1.agent_id, a2.agent_id
            HAVING COUNT(*) >= 2  -- At least 2 interactions
        )
        SELECT * FROM potential_interactions
        WHERE avg_delay_minutes <= 5  -- Within 5 minutes suggests coordination
        ORDER BY interaction_count DESC
    """
    
    try
        result = JuliaDB.execute_query(query, [cutoff_time])
        connections = AgentConnection[]
        
        for row in result
            # Determine connection type based on patterns
            connection_type = infer_connection_type(
                row.source_agent, row.target_agent, 
                row.source_tools, row.target_tools,
                row.avg_delay_minutes
            )
            
            # Calculate connection strength based on frequency and timing
            strength = calculate_connection_strength(
                row.interaction_count, row.avg_delay_minutes
            )
            
            connection = AgentConnection(
                uuid4(),
                row.source_agent,
                row.target_agent,
                connection_type,
                "Inferred from execution timing patterns",
                strength,
                now(),  # Approximate last interaction
                true,
                now()
            )
            
            push!(connections, connection)
        end
        
        return connections
    catch e
        @error "Failed to detect agent interactions" exception=(e, catch_backtrace())
        return AgentConnection[]
    end
end

"""
Infer the type of connection between two agents based on their tool usage and timing
"""
function infer_connection_type(source_agent::String, target_agent::String,
                              source_tools::String, target_tools::String,
                              avg_delay_minutes::Float64)::String
    source_tool_list = split(source_tools, ',')
    target_tool_list = split(target_tools, ',')
    
    # Check for delegation patterns
    if "llm_chat" in source_tool_list && any(t -> t != "llm_chat", target_tool_list)
        return "delegates_to"
    end
    
    # Check for data flow patterns
    if "web_scraper" in source_tool_list || "scrape_article_text" in source_tool_list
        if "post_to_x" in target_tool_list || "send_message" in target_tool_list
            return "feeds_data_to"
        end
    end
    
    # Check for coordination patterns (very short delays)
    if avg_delay_minutes < 1.0
        return "coordinates_with"
    end
    
    # Default to general delegation
    return "delegates_to"
end

"""
Calculate connection strength based on interaction patterns
"""
function calculate_connection_strength(interaction_count::Int, avg_delay_minutes::Float64)::Float64
    # Base strength from frequency (0.0-0.7)
    frequency_strength = min(0.7, interaction_count / 10.0)
    
    # Timing strength - shorter delays indicate stronger coordination (0.0-0.3)
    timing_strength = if avg_delay_minutes <= 0.5
        0.3
    elseif avg_delay_minutes <= 2.0
        0.2
    elseif avg_delay_minutes <= 5.0
        0.1
    else
        0.0
    end
    
    return min(1.0, frequency_strength + timing_strength)
end

# ============================================================================
# SWARM TOPOLOGY MANAGEMENT
# ============================================================================

"""
Build swarm topology by grouping related agents
"""
function build_swarm_topology(connections::Vector{AgentConnection})::Vector{SwarmTopology}
    # Group agents into swarms based on connection patterns
    agent_groups = Dict{String, Set{String}}()
    
    # Use union-find algorithm to group connected agents
    for connection in connections
        if connection.strength >= 0.3  # Only consider strong connections
            source_group = get_agent_group(agent_groups, connection.source_agent_id)
            target_group = get_agent_group(agent_groups, connection.target_agent_id)
            
            # Merge groups if they're different
            if source_group != target_group
                merged_group = union(source_group, target_group)
                group_id = first(merged_group)
                agent_groups[group_id] = merged_group
                
                # Update all agents in merged group to point to new group
                for agent in merged_group
                    if agent != group_id
                        delete!(agent_groups, agent)
                    end
                end
            end
        end
    end
    
    # Create SwarmTopology objects
    swarms = SwarmTopology[]
    for (group_id, agents_set) in agent_groups
        if length(agents_set) >= 2  # Only create swarms with multiple agents
            agents_list = collect(agents_set)
            swarm_connections = filter(c -> 
                c.source_agent_id in agents_set && c.target_agent_id in agents_set,
                connections
            )
            
            # Analyze coordination patterns for this swarm
            patterns = analyze_coordination_patterns(agents_list, swarm_connections)
            
            swarm = SwarmTopology(
                "swarm-$(group_id[1:8])",  # Use first 8 chars of agent ID as swarm ID
                agents_list,
                swarm_connections,
                patterns,
                nothing,  # Performance metrics calculated separately
                now(),
                now()
            )
            
            push!(swarms, swarm)
        end
    end
    
    return swarms
end

"""
Get the group that an agent belongs to, creating a new one if necessary
"""
function get_agent_group(agent_groups::Dict{String, Set{String}}, agent_id::String)::Set{String}
    for (group_id, group) in agent_groups
        if agent_id in group
            return group
        end
    end
    
    # Create new group for this agent
    new_group = Set([agent_id])
    agent_groups[agent_id] = new_group
    return new_group
end

"""
Analyze coordination patterns within a swarm
"""
function analyze_coordination_patterns(agents::Vector{String}, 
                                     connections::Vector{AgentConnection})::Dict{String, Any}
    patterns = Dict{String, Any}()
    
    # Detect hierarchical patterns
    hierarchical_score = detect_hierarchical_pattern(agents, connections)
    patterns["hierarchical"] = hierarchical_score
    
    # Detect collaborative patterns
    collaborative_score = detect_collaborative_pattern(agents, connections)
    patterns["collaborative"] = collaborative_score
    
    # Detect pipeline patterns
    pipeline_score = detect_pipeline_pattern(agents, connections)
    patterns["pipeline"] = pipeline_score
    
    # Determine dominant pattern
    scores = [
        ("hierarchical", hierarchical_score),
        ("collaborative", collaborative_score),
        ("pipeline", pipeline_score)
    ]
    dominant_pattern = first(sort(scores, by=x->x[2], rev=true))
    patterns["dominant_pattern"] = dominant_pattern[1]
    patterns["dominant_score"] = dominant_pattern[2]
    
    return patterns
end

"""
Detect hierarchical coordination patterns (one agent delegating to many)
"""
function detect_hierarchical_pattern(agents::Vector{String}, 
                                   connections::Vector{AgentConnection})::Float64
    if length(agents) < 2
        return 0.0
    end
    
    # Count outgoing connections per agent
    outgoing_counts = Dict{String, Int}()
    for agent in agents
        outgoing_counts[agent] = count(c -> c.source_agent_id == agent, connections)
    end
    
    # Hierarchical pattern: one agent has many outgoing connections, others have few/none
    max_outgoing = maximum(values(outgoing_counts))
    total_connections = length(connections)
    
    if max_outgoing >= length(agents) / 2 && total_connections > 0
        return min(1.0, max_outgoing / length(agents))
    else
        return 0.0
    end
end

"""
Detect collaborative coordination patterns (bidirectional connections)
"""
function detect_collaborative_pattern(agents::Vector{String}, 
                                    connections::Vector{AgentConnection})::Float64
    if length(connections) < 2
        return 0.0
    end
    
    # Count bidirectional connections
    bidirectional_count = 0
    for conn1 in connections
        for conn2 in connections
            if conn1.source_agent_id == conn2.target_agent_id && 
               conn1.target_agent_id == conn2.source_agent_id
                bidirectional_count += 1
                break
            end
        end
    end
    
    # Score based on proportion of bidirectional connections
    return min(1.0, (bidirectional_count / 2) / length(connections))
end

"""
Detect pipeline coordination patterns (sequential processing)
"""
function detect_pipeline_pattern(agents::Vector{String}, 
                                connections::Vector{AgentConnection})::Float64
    if length(agents) < 3
        return 0.0
    end
    
    # Look for linear chains of connections
    # Each agent (except first and last) should have exactly one incoming and one outgoing
    chain_agents = 0
    for agent in agents
        incoming = count(c -> c.target_agent_id == agent, connections)
        outgoing = count(c -> c.source_agent_id == agent, connections)
        
        # Chain agent: 1 incoming, 1 outgoing
        # Start agent: 0 incoming, 1+ outgoing  
        # End agent: 1+ incoming, 0 outgoing
        if (incoming == 1 && outgoing == 1) ||
           (incoming == 0 && outgoing >= 1) ||
           (incoming >= 1 && outgoing == 0)
            chain_agents += 1
        end
    end
    
    return chain_agents / length(agents)
end

# ============================================================================
# SWARM PERSISTENCE AND RETRIEVAL
# ============================================================================

"""
Save detected swarm topology to database
"""
function save_swarm_topology(swarm::SwarmTopology)
    # Save connections first
    for connection in swarm.connections
        save_agent_connection(connection)
    end
    
    # Save swarm metadata (could extend database schema for this)
    @info "Swarm topology saved" swarm_id=swarm.swarm_id agents=length(swarm.agents) connections=length(swarm.connections)
end

"""
Save individual agent connection to database
"""
function save_agent_connection(connection::AgentConnection)
    query = """
        INSERT INTO swarm_connections (
            id, source_agent_id, target_agent_id, connection_type,
            data_flow_description, is_active, created_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT (source_agent_id, target_agent_id, connection_type) DO UPDATE SET
            data_flow_description = EXCLUDED.data_flow_description,
            is_active = EXCLUDED.is_active,
            created_at = EXCLUDED.created_at
    """
    
    try
        JuliaDB.execute_query(query, [
            connection.id, connection.source_agent_id, connection.target_agent_id,
            connection.connection_type, connection.data_flow_description,
            connection.is_active, connection.created_at
        ])
    catch e
        @error "Failed to save agent connection" exception=(e, catch_backtrace())
    end
end

"""
Get current swarm topology from database
"""
function get_current_swarm_topology()::Vector{SwarmTopology}
    query = """
        SELECT 
            id, source_agent_id, target_agent_id, connection_type,
            data_flow_description, is_active, created_at
        FROM swarm_connections
        WHERE is_active = true
        ORDER BY created_at DESC
    """
    
    try
        result = JuliaDB.execute_query(query, [])
        connections = [AgentConnection(
            row.id,
            row.source_agent_id,
            row.target_agent_id,
            row.connection_type,
            row.data_flow_description,
            1.0,  # Default strength
            nothing,  # Last interaction not stored in this query
            row.is_active,
            row.created_at
        ) for row in result]
        
        return build_swarm_topology(connections)
    catch e
        @error "Failed to get swarm topology" exception=(e, catch_backtrace())
        return SwarmTopology[]
    end
end

"""
Get agents that are part of any swarm
"""
function get_swarm_agents()::Vector{String}
    query = """
        SELECT DISTINCT source_agent_id as agent_id FROM swarm_connections WHERE is_active = true
        UNION
        SELECT DISTINCT target_agent_id as agent_id FROM swarm_connections WHERE is_active = true
    """
    
    try
        result = JuliaDB.execute_query(query, [])
        return [row.agent_id for row in result]
    catch e
        @error "Failed to get swarm agents" exception=(e, catch_backtrace())
        return String[]
    end
end

# ============================================================================
# SWARM COORDINATION ANALYSIS
# ============================================================================

"""
Analyze real-time swarm coordination effectiveness
"""
function analyze_swarm_performance(swarm::SwarmTopology)::Dict{String, Any}
    performance = Dict{String, Any}()
    
    # Get performance metrics for all agents in swarm
    agent_performances = []
    for agent_id in swarm.agents
        agent_perf = AgentAnalytics.calculate_agent_performance(agent_id)
        if agent_perf !== nothing
            push!(agent_performances, agent_perf)
        end
    end
    
    if isempty(agent_performances)
        return Dict("error" => "No performance data available")
    end
    
    # Calculate swarm-level metrics
    performance["swarm_id"] = swarm.swarm_id
    performance["agent_count"] = length(swarm.agents)
    performance["connection_count"] = length(swarm.connections)
    
    # Aggregate performance metrics
    total_executions = sum(p.total_executions for p in agent_performances)
    successful_executions = sum(p.successful_executions for p in agent_performances)
    
    performance["total_executions"] = total_executions
    performance["swarm_success_rate"] = total_executions > 0 ? 
                                      (successful_executions / total_executions) * 100 : 0.0
    
    performance["avg_agent_success_rate"] = mean(p.success_rate for p in agent_performances)
    performance["avg_execution_time_ms"] = mean(p.avg_execution_time_ms for p in agent_performances)
    
    # Coordination effectiveness score
    coordination_score = calculate_coordination_effectiveness(swarm, agent_performances)
    performance["coordination_effectiveness"] = coordination_score
    
    # Dominant coordination pattern
    performance["coordination_pattern"] = swarm.coordination_patterns
    
    return performance
end

"""
Calculate how well agents are coordinating within a swarm
"""
function calculate_coordination_effectiveness(swarm::SwarmTopology, 
                                           agent_performances::Vector)::Float64
    if length(agent_performances) < 2
        return 0.0
    end
    
    # Factor 1: Consistency of success rates (lower variance = better coordination)
    success_rates = [p.success_rate for p in agent_performances]
    consistency_score = 1.0 - (std(success_rates) / 100.0)  # Normalize by max possible std
    
    # Factor 2: Connection strength average
    avg_connection_strength = length(swarm.connections) > 0 ? 
                             mean(c.strength for c in swarm.connections) : 0.0
    
    # Factor 3: Pattern dominance (how clear the coordination pattern is)
    pattern_clarity = get(swarm.coordination_patterns, "dominant_score", 0.0)
    
    # Weighted combination
    effectiveness = (consistency_score * 0.4 + 
                    avg_connection_strength * 0.4 + 
                    pattern_clarity * 0.2)
    
    return min(1.0, max(0.0, effectiveness))
end

"""
Detect and update swarm topologies - main coordination analysis function
"""
function update_swarm_coordination(time_window_hours::Int=24)::Vector{SwarmTopology}
    @info "Starting swarm coordination analysis" time_window_hours
    
    # Detect agent interactions
    connections = detect_agent_interactions(time_window_hours)
    @info "Detected agent interactions" count=length(connections)
    
    # Build swarm topologies
    swarms = build_swarm_topology(connections)
    @info "Built swarm topologies" count=length(swarms)
    
    # Save to database
    for swarm in swarms
        save_swarm_topology(swarm)
    end
    
    return swarms
end

end # module SwarmCoordination