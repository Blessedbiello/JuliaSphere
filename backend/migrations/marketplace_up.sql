-- JuliaSphere Marketplace Database Extensions
-- This extends the existing JuliaOS database with marketplace functionality

-- User profiles for creators and marketplace participants
CREATE TABLE user_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username TEXT UNIQUE NOT NULL,
    email TEXT UNIQUE,
    display_name TEXT,
    bio TEXT,
    avatar_url TEXT,
    reputation_score DECIMAL(5,2) DEFAULT 0.0,
    total_agents_created INTEGER DEFAULT 0,
    total_deployments INTEGER DEFAULT 0,
    wallet_address TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enhanced agent marketplace information
CREATE TABLE agent_marketplace (
    agent_id TEXT PRIMARY KEY REFERENCES agents(id) ON DELETE CASCADE,
    creator_id UUID REFERENCES user_profiles(id),
    is_public BOOLEAN DEFAULT false,
    is_featured BOOLEAN DEFAULT false,
    category TEXT, -- 'trading', 'dao', 'research', 'utility', etc.
    tags TEXT[], -- searchable tags
    pricing_model TEXT CHECK (pricing_model IN ('free', 'one_time', 'subscription', 'usage_based')),
    price_amount DECIMAL(10,2),
    currency TEXT DEFAULT 'USD',
    total_deployments INTEGER DEFAULT 0,
    total_revenue DECIMAL(15,2) DEFAULT 0.0,
    avg_rating DECIMAL(3,2) DEFAULT 0.0,
    rating_count INTEGER DEFAULT 0,
    featured_image_url TEXT,
    documentation TEXT, -- Markdown documentation
    example_usage JSONB, -- Example configurations and use cases
    performance_metrics JSONB, -- Cached performance stats
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Agent deployments tracking
CREATE TABLE agent_deployments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    agent_id TEXT NOT NULL REFERENCES agents(id),
    deployer_id UUID REFERENCES user_profiles(id),
    deployment_config JSONB, -- Custom configuration used for this deployment
    status TEXT CHECK (status IN ('active', 'paused', 'stopped', 'failed')) DEFAULT 'active',
    execution_count INTEGER DEFAULT 0,
    last_execution TIMESTAMP WITH TIME ZONE,
    total_cost DECIMAL(10,2) DEFAULT 0.0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Agent performance metrics tracking
CREATE TABLE agent_performance_metrics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    agent_id TEXT NOT NULL REFERENCES agents(id),
    deployment_id UUID REFERENCES agent_deployments(id),
    metric_type TEXT NOT NULL, -- 'execution_time', 'success_rate', 'error_rate', etc.
    metric_value DECIMAL(15,4) NOT NULL,
    measurement_time TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    context_data JSONB -- Additional context about the measurement
);

-- Agent ratings and reviews
CREATE TABLE agent_reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    agent_id TEXT NOT NULL REFERENCES agents(id),
    reviewer_id UUID NOT NULL REFERENCES user_profiles(id),
    rating INTEGER CHECK (rating >= 1 AND rating <= 5) NOT NULL,
    review_text TEXT,
    deployment_context JSONB, -- Info about how they used the agent
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(agent_id, reviewer_id) -- One review per user per agent
);

-- Swarm topology tracking
CREATE TABLE swarm_connections (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    source_agent_id TEXT NOT NULL REFERENCES agents(id),
    target_agent_id TEXT NOT NULL REFERENCES agents(id),
    connection_type TEXT NOT NULL, -- 'delegates_to', 'receives_from', 'coordinates_with'
    data_flow_description TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(source_agent_id, target_agent_id, connection_type)
);

-- Agent execution logs (enhanced for marketplace analytics)
CREATE TABLE agent_execution_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    agent_id TEXT NOT NULL REFERENCES agents(id),
    deployment_id UUID REFERENCES agent_deployments(id),
    execution_start TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    execution_end TIMESTAMP WITH TIME ZONE,
    status TEXT CHECK (status IN ('started', 'completed', 'failed', 'timeout')) NOT NULL,
    input_data JSONB,
    output_data JSONB,
    error_message TEXT,
    tools_used TEXT[], -- Array of tool names used in this execution
    execution_time_ms INTEGER, -- Calculated execution time
    cost_incurred DECIMAL(10,4) DEFAULT 0.0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Agent favorites/bookmarks for users
CREATE TABLE agent_favorites (
    user_id UUID NOT NULL REFERENCES user_profiles(id),
    agent_id TEXT NOT NULL REFERENCES agents(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    PRIMARY KEY (user_id, agent_id)
);

-- Agent templates for the no-code builder
CREATE TABLE agent_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    category TEXT,
    template_config JSONB NOT NULL, -- Full agent blueprint template
    creator_id UUID REFERENCES user_profiles(id),
    is_public BOOLEAN DEFAULT true,
    usage_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_agent_marketplace_creator ON agent_marketplace(creator_id);
CREATE INDEX idx_agent_marketplace_category ON agent_marketplace(category);
CREATE INDEX idx_agent_marketplace_public ON agent_marketplace(is_public) WHERE is_public = true;
CREATE INDEX idx_agent_marketplace_featured ON agent_marketplace(is_featured) WHERE is_featured = true;
CREATE INDEX idx_agent_marketplace_rating ON agent_marketplace(avg_rating DESC);
CREATE INDEX idx_agent_deployments_agent ON agent_deployments(agent_id);
CREATE INDEX idx_agent_deployments_deployer ON agent_deployments(deployer_id);
CREATE INDEX idx_agent_performance_agent ON agent_performance_metrics(agent_id);
CREATE INDEX idx_agent_performance_type ON agent_performance_metrics(metric_type);
CREATE INDEX idx_agent_performance_time ON agent_performance_metrics(measurement_time);
CREATE INDEX idx_agent_reviews_agent ON agent_reviews(agent_id);
CREATE INDEX idx_agent_reviews_rating ON agent_reviews(rating);
CREATE INDEX idx_swarm_connections_source ON swarm_connections(source_agent_id);
CREATE INDEX idx_swarm_connections_target ON swarm_connections(target_agent_id);
CREATE INDEX idx_execution_logs_agent ON agent_execution_logs(agent_id);
CREATE INDEX idx_execution_logs_deployment ON agent_execution_logs(deployment_id);
CREATE INDEX idx_execution_logs_time ON agent_execution_logs(execution_start);

-- Update triggers for maintaining statistics
CREATE OR REPLACE FUNCTION update_agent_marketplace_stats()
RETURNS TRIGGER AS $$
BEGIN
    -- Update total deployments
    UPDATE agent_marketplace 
    SET total_deployments = (
        SELECT COUNT(*) FROM agent_deployments 
        WHERE agent_id = NEW.agent_id
    ),
    updated_at = NOW()
    WHERE agent_id = NEW.agent_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_deployment_stats
    AFTER INSERT ON agent_deployments
    FOR EACH ROW
    EXECUTE FUNCTION update_agent_marketplace_stats();

-- Update rating statistics when reviews are added/updated
CREATE OR REPLACE FUNCTION update_agent_rating_stats()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE agent_marketplace 
    SET 
        avg_rating = (
            SELECT AVG(rating)::DECIMAL(3,2) 
            FROM agent_reviews 
            WHERE agent_id = COALESCE(NEW.agent_id, OLD.agent_id)
        ),
        rating_count = (
            SELECT COUNT(*) 
            FROM agent_reviews 
            WHERE agent_id = COALESCE(NEW.agent_id, OLD.agent_id)
        ),
        updated_at = NOW()
    WHERE agent_id = COALESCE(NEW.agent_id, OLD.agent_id);
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_rating_stats
    AFTER INSERT OR UPDATE OR DELETE ON agent_reviews
    FOR EACH ROW
    EXECUTE FUNCTION update_agent_rating_stats();