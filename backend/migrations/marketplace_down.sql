-- JuliaSphere Marketplace Database Rollback
-- This removes all marketplace-related tables and functions

-- Drop triggers first
DROP TRIGGER IF EXISTS trigger_update_rating_stats ON agent_reviews;
DROP TRIGGER IF EXISTS trigger_update_deployment_stats ON agent_deployments;

-- Drop functions
DROP FUNCTION IF EXISTS update_agent_rating_stats();
DROP FUNCTION IF EXISTS update_agent_marketplace_stats();

-- Drop tables in reverse dependency order
DROP TABLE IF EXISTS agent_templates;
DROP TABLE IF EXISTS agent_favorites;
DROP TABLE IF EXISTS agent_execution_logs;
DROP TABLE IF EXISTS swarm_connections;
DROP TABLE IF EXISTS agent_reviews;
DROP TABLE IF EXISTS agent_performance_metrics;
DROP TABLE IF EXISTS agent_deployments;
DROP TABLE IF EXISTS agent_marketplace;
DROP TABLE IF EXISTS user_profiles;