-- Performance Optimization Indexes for JuliaOS Database
-- This migration adds indexes to improve query performance

-- Additional indexes for agent_execution_logs (high-volume table)
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_agent_execution_logs_agent_time 
ON agent_execution_logs(agent_id, execution_start DESC);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_agent_execution_logs_status_time 
ON agent_execution_logs(status, execution_start DESC);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_agent_execution_logs_deployment_time 
ON agent_execution_logs(deployment_id, execution_start DESC) 
WHERE deployment_id IS NOT NULL;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_agent_execution_logs_cost 
ON agent_execution_logs(agent_id, cost_incurred) 
WHERE cost_incurred > 0;

-- Indexes for marketplace queries
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_agent_marketplace_public_category 
ON agent_marketplace(is_public, category) 
WHERE is_public = true AND category IS NOT NULL;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_agent_marketplace_rating_deployments 
ON agent_marketplace(avg_rating DESC, total_deployments DESC) 
WHERE is_public = true;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_agent_marketplace_creator_public 
ON agent_marketplace(creator_id, is_public) 
WHERE creator_id IS NOT NULL;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_agent_marketplace_tags_gin 
ON agent_marketplace USING GIN(tags) 
WHERE is_public = true;

-- Indexes for user profiles
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_user_profiles_reputation 
ON user_profiles(reputation_score DESC);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_user_profiles_username_lower 
ON user_profiles(LOWER(username));

-- Indexes for agent deployments
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_agent_deployments_deployer_status 
ON agent_deployments(deployer_id, status, created_at DESC) 
WHERE deployer_id IS NOT NULL;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_agent_deployments_agent_active 
ON agent_deployments(agent_id, status, last_execution DESC) 
WHERE status = 'active';

-- Indexes for agent performance metrics
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_agent_performance_agent_type_time 
ON agent_performance_metrics(agent_id, metric_type, measurement_time DESC);

-- Composite index for common metric queries
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_agent_performance_metrics_composite 
ON agent_performance_metrics(agent_id, metric_type, measurement_time DESC, metric_value);

-- Indexes for agent reviews
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_agent_reviews_agent_rating_time 
ON agent_reviews(agent_id, rating DESC, created_at DESC);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_agent_reviews_reviewer_time 
ON agent_reviews(reviewer_id, created_at DESC);

-- Indexes for swarm connections
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_swarm_connections_source_type 
ON swarm_connections(source_agent_id, connection_type) 
WHERE is_active = true;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_swarm_connections_target_type 
ON swarm_connections(target_agent_id, connection_type) 
WHERE is_active = true;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_swarm_connections_active_time 
ON swarm_connections(is_active, created_at DESC) 
WHERE is_active = true;

-- Indexes for agent tools (for faster agent loading)
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_agent_tools_agent_index 
ON agent_tools(agent_id, tool_index);

-- Partial indexes for common WHERE conditions
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_agents_state_running 
ON agents(id, state) 
WHERE state = 'RUNNING';

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_agent_execution_logs_recent 
ON agent_execution_logs(agent_id, execution_start DESC, status) 
WHERE execution_start >= NOW() - INTERVAL '30 days';

-- Index for common analytics queries
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_agent_execution_logs_analytics 
ON agent_execution_logs(execution_start, status, execution_time_ms, cost_incurred) 
WHERE execution_start >= NOW() - INTERVAL '90 days';

-- GIN index for JSONB columns (for flexible queries on configuration data)
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_agents_strategy_config_gin 
ON agents USING GIN(strategy_config);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_agent_marketplace_example_usage_gin 
ON agent_marketplace USING GIN(example_usage) 
WHERE example_usage IS NOT NULL;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_agent_execution_logs_input_gin 
ON agent_execution_logs USING GIN(input_data) 
WHERE input_data IS NOT NULL;

-- Text search indexes for marketplace search functionality
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_agents_name_text 
ON agents USING GIN(to_tsvector('english', name));

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_agents_description_text 
ON agents USING GIN(to_tsvector('english', description));

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_agent_marketplace_documentation_text 
ON agent_marketplace USING GIN(to_tsvector('english', documentation)) 
WHERE documentation IS NOT NULL;

-- Update table statistics for better query planning
ANALYZE agents;
ANALYZE agent_marketplace;
ANALYZE agent_execution_logs;
ANALYZE agent_deployments;
ANALYZE agent_performance_metrics;
ANALYZE agent_reviews;
ANALYZE swarm_connections;
ANALYZE user_profiles;