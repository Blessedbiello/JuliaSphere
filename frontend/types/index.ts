// Core JuliaOS types
export interface Agent {
  id: string
  name: string
  description: string
  strategy: {
    name: string
    config: Record<string, any>
  }
  tools: Tool[]
  trigger: {
    type: string
    params: Record<string, any>
  }
  state: 'CREATED' | 'RUNNING' | 'PAUSED' | 'STOPPED'
  created_at: string
  updated_at: string
}

export interface Tool {
  name: string
  config: Record<string, any>
}

export interface Strategy {
  name: string
  description?: string
}

export interface ToolSummary {
  name: string
  metadata: {
    description: string
  }
}

// Marketplace types
export interface MarketplaceAgent {
  id: string
  name: string
  description: string
  strategy: string
  category: string | null
  tags: string[]
  pricing: {
    model: 'free' | 'one_time' | 'subscription' | 'usage_based'
    amount: number | null
    currency: string
  }
  stats: {
    deployments: number
    avg_rating: number
    rating_count: number
  }
  creator: {
    username: string
    display_name: string | null
  }
  featured_image_url: string | null
  is_featured: boolean
  created_at: string
  updated_at: string
}

export interface MarketplaceAgentDetail extends MarketplaceAgent {
  tools: Tool[]
  trigger: {
    type: string
    params: Record<string, any>
  }
  state: string
  marketplace: {
    is_public: boolean
    is_featured: boolean
    category: string | null
    tags: string[]
    pricing: {
      model: string
      amount: number | null
      currency: string
    }
    stats: {
      deployments: number
      revenue: number
      avg_rating: number
      rating_count: number
    }
    featured_image_url: string | null
    documentation: string | null
    example_usage: Record<string, any> | null
    performance_metrics: Record<string, any> | null
  }
  reviews: AgentReview[]
}

export interface AgentReview {
  rating: number
  review_text: string | null
  reviewer_username: string
  created_at: string
}

export interface UserProfile {
  id: string
  username: string
  email: string | null
  display_name: string | null
  bio: string | null
  avatar_url: string | null
  reputation_score: number
  total_agents_created: number
  total_deployments: number
  wallet_address: string | null
  created_at: string
  updated_at: string
}

export interface AgentDeployment {
  id: string
  agent_id: string
  deployer_id: string | null
  deployment_config: Record<string, any> | null
  status: 'active' | 'paused' | 'stopped' | 'failed'
  execution_count: number
  last_execution: string | null
  total_cost: number
  created_at: string
  updated_at: string
}

// Analytics types
export interface PerformanceMetrics {
  total_executions: number
  successful_executions: number
  failed_executions: number
  success_rate: number
  error_rate: number
  avg_execution_time_ms: number
  median_execution_time_ms: number
  min_execution_time_ms: number
  max_execution_time_ms: number
  total_cost: number
  avg_cost_per_execution: number
  last_execution: string | null
  tools_usage_stats: Record<string, number>
}

export interface AgentHealthScore {
  overall_score: number
  performance_score: number
  reliability_score: number
  efficiency_score: number
  user_satisfaction_score: number
  computed_at: string
}

export interface AgentPerformanceData {
  agent_id: string
  performance_metrics: PerformanceMetrics
  health_score: AgentHealthScore | null
}

export interface TimeSeriesDataPoint {
  date: string
  total_executions: number
  successful_executions: number
  success_rate: number
  avg_execution_time_ms: number
  total_cost: number
}

export interface LeaderboardEntry {
  id: string
  name: string
  category: string | null
  health_score: AgentHealthScore
  performance_metrics: PerformanceMetrics
}

export interface MarketplaceStats {
  total_public_agents: number
  featured_agents: number
  overall_avg_rating: number
  total_deployments: number
  total_creators: number
}

export interface AnalyticsOverview {
  active_agents: number
  total_executions_30d: number
  success_rate_30d: number
  avg_execution_time_ms: number
  total_revenue_30d: number
  active_deployments: number
}

// Swarm coordination types
export interface AgentConnection {
  id: string
  source_agent_id: string
  target_agent_id: string
  connection_type: 'delegates_to' | 'receives_from' | 'coordinates_with' | 'feeds_data_to'
  data_flow_description: string | null
  strength: number
  last_interaction: string | null
  is_active: boolean
  created_at: string
}

export interface SwarmTopology {
  swarm_id: string
  agents: string[]
  connections: AgentConnection[]
  coordination_patterns: {
    hierarchical: number
    collaborative: number
    pipeline: number
    dominant_pattern: string
    dominant_score: number
  }
  created_at: string
  updated_at: string
}

export interface SwarmPerformance {
  swarm_id: string
  agent_count: number
  connection_count: number
  total_executions: number
  swarm_success_rate: number
  avg_agent_success_rate: number
  avg_execution_time_ms: number
  coordination_effectiveness: number
  coordination_pattern: Record<string, any>
}

// Graph visualization types (for Cytoscape.js)
export interface GraphNode {
  data: {
    id: string
    label: string
    strategy: string
    category: string | null
    state: string
    status: 'healthy' | 'warning' | 'error' | 'idle'
    is_featured: boolean
    success_rate: number
  }
}

export interface GraphEdge {
  data: {
    id: string
    source: string
    target: string
    label: string
    strength: number
    description: string | null
    is_active: boolean
  }
}

export interface SwarmGraphData {
  elements: {
    nodes: GraphNode[]
    edges: GraphEdge[]
  }
  swarms: {
    swarm_id: string
    agents: string[]
    coordination_pattern: string
    pattern_score: number
  }[]
  stats: {
    total_agents: number
    total_connections: number
    swarm_count: number
  }
}

// UI state types
export interface FilterState {
  category: string | null
  tags: string[]
  priceModel: string | null
  rating: number | null
  sortBy: string
  searchQuery: string
}

export interface PaginationState {
  page: number
  limit: number
  total: number
  hasNext: boolean
  hasPrev: boolean
}

// Form types
export interface CreateAgentForm {
  name: string
  description: string
  strategy: string
  strategyConfig: Record<string, any>
  tools: Tool[]
  triggerType: string
  triggerParams: Record<string, any>
}

export interface PublishAgentForm {
  category: string
  tags: string[]
  pricingModel: 'free' | 'one_time' | 'subscription' | 'usage_based'
  priceAmount: number | null
  currency: string
  documentation: string
  featuredImageUrl: string
  exampleUsage: Record<string, any>
}

// WebSocket types (for real-time updates)
export interface WebSocketMessage {
  type: 'agent_status' | 'execution_update' | 'swarm_change' | 'performance_update'
  payload: any
  timestamp: string
}

export interface AgentStatusUpdate {
  agent_id: string
  status: 'healthy' | 'warning' | 'error' | 'idle'
  last_execution: string | null
  success_rate: number
}

export interface ExecutionUpdate {
  execution_id: string
  agent_id: string
  status: 'started' | 'completed' | 'failed' | 'timeout'
  execution_time_ms: number | null
  error_message: string | null
}

// Utility types
export type LoadingState = 'idle' | 'loading' | 'success' | 'error'

export interface AsyncState<T = any> {
  data: T | null
  loading: boolean
  error: string | null
}

export interface Category {
  name: string
  agent_count: number
}