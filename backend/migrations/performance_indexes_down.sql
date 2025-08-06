-- Rollback Performance Optimization Indexes
-- This removes all performance indexes added in the up migration

-- Drop agent_execution_logs indexes
DROP INDEX CONCURRENTLY IF EXISTS idx_agent_execution_logs_agent_time;
DROP INDEX CONCURRENTLY IF EXISTS idx_agent_execution_logs_status_time;
DROP INDEX CONCURRENTLY IF EXISTS idx_agent_execution_logs_deployment_time;
DROP INDEX CONCURRENTLY IF EXISTS idx_agent_execution_logs_cost;
DROP INDEX CONCURRENTLY IF EXISTS idx_agent_execution_logs_recent;
DROP INDEX CONCURRENTLY IF EXISTS idx_agent_execution_logs_analytics;
DROP INDEX CONCURRENTLY IF EXISTS idx_agent_execution_logs_input_gin;

-- Drop marketplace indexes
DROP INDEX CONCURRENTLY IF EXISTS idx_agent_marketplace_public_category;
DROP INDEX CONCURRENTLY IF EXISTS idx_agent_marketplace_rating_deployments;
DROP INDEX CONCURRENTLY IF EXISTS idx_agent_marketplace_creator_public;
DROP INDEX CONCURRENTLY IF EXISTS idx_agent_marketplace_tags_gin;
DROP INDEX CONCURRENTLY IF EXISTS idx_agent_marketplace_example_usage_gin;
DROP INDEX CONCURRENTLY IF EXISTS idx_agent_marketplace_documentation_text;

-- Drop user profile indexes
DROP INDEX CONCURRENTLY IF EXISTS idx_user_profiles_reputation;
DROP INDEX CONCURRENTLY IF EXISTS idx_user_profiles_username_lower;

-- Drop agent deployment indexes
DROP INDEX CONCURRENTLY IF EXISTS idx_agent_deployments_deployer_status;
DROP INDEX CONCURRENTLY IF EXISTS idx_agent_deployments_agent_active;

-- Drop performance metric indexes
DROP INDEX CONCURRENTLY IF EXISTS idx_agent_performance_agent_type_time;
DROP INDEX CONCURRENTLY IF EXISTS idx_agent_performance_metrics_composite;

-- Drop review indexes
DROP INDEX CONCURRENTLY IF EXISTS idx_agent_reviews_agent_rating_time;
DROP INDEX CONCURRENTLY IF EXISTS idx_agent_reviews_reviewer_time;

-- Drop swarm connection indexes
DROP INDEX CONCURRENTLY IF EXISTS idx_swarm_connections_source_type;
DROP INDEX CONCURRENTLY IF EXISTS idx_swarm_connections_target_type;
DROP INDEX CONCURRENTLY IF EXISTS idx_swarm_connections_active_time;

-- Drop agent tool indexes
DROP INDEX CONCURRENTLY IF EXISTS idx_agent_tools_agent_index;

-- Drop agent state indexes
DROP INDEX CONCURRENTLY IF EXISTS idx_agents_state_running;
DROP INDEX CONCURRENTLY IF EXISTS idx_agents_strategy_config_gin;

-- Drop text search indexes
DROP INDEX CONCURRENTLY IF EXISTS idx_agents_name_text;
DROP INDEX CONCURRENTLY IF EXISTS idx_agents_description_text;