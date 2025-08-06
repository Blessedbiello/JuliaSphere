'use client'

import { useQuery } from 'react-query'
import { motion } from 'framer-motion'
import { 
  Activity, 
  Users, 
  GitBranch, 
  Zap, 
  TrendingUp, 
  Clock,
  Target,
  AlertTriangle
} from 'lucide-react'
import { api } from '@/lib/api'
import { SwarmPerformance, AgentPerformanceData } from '@/types'

interface SwarmStatsProps {
  selectedSwarmId?: string | null
  selectedAgentId?: string | null
}

export function SwarmStats({ selectedSwarmId, selectedAgentId }: SwarmStatsProps) {
  // Fetch swarm performance data
  const { data: swarmPerformance, isLoading: isLoadingSwarm } = useQuery<SwarmPerformance>(
    ['swarmPerformance', selectedSwarmId],
    () => selectedSwarmId 
      ? api.marketplace.getSwarmPerformance(selectedSwarmId).then(res => res.data)
      : Promise.resolve(null),
    {
      enabled: !!selectedSwarmId,
    }
  )

  // Fetch agent performance data
  const { data: agentPerformance, isLoading: isLoadingAgent } = useQuery<AgentPerformanceData>(
    ['agentPerformance', selectedAgentId],
    () => selectedAgentId 
      ? api.marketplace.getAgentPerformance(selectedAgentId).then(res => res.data)
      : Promise.resolve(null),
    {
      enabled: !!selectedAgentId,
    }
  )

  // Fetch overall analytics
  const { data: analytics, isLoading: isLoadingAnalytics } = useQuery(
    'analyticsOverview',
    () => api.marketplace.getAnalyticsOverview().then(res => res.data),
    {
      refetchInterval: 30000, // Refresh every 30 seconds
    }
  )

  const renderOverallStats = () => (
    <div className="space-y-4">
      <h3 className="text-lg font-semibold text-gray-900 dark:text-white flex items-center gap-2">
        <Activity className="h-5 w-5 text-primary-600 dark:text-primary-400" />
        System Overview
      </h3>
      
      <div className="grid grid-cols-2 gap-3">
        <div className="bg-primary-50 dark:bg-primary-900/20 p-3 rounded-lg">
          <div className="text-2xl font-bold text-primary-600 dark:text-primary-400">
            {analytics?.active_agents || 0}
          </div>
          <div className="text-xs text-gray-600 dark:text-gray-400">Active Agents</div>
        </div>
        
        <div className="bg-secondary-50 dark:bg-secondary-900/20 p-3 rounded-lg">
          <div className="text-2xl font-bold text-secondary-600 dark:text-secondary-400">
            {analytics?.active_deployments || 0}
          </div>
          <div className="text-xs text-gray-600 dark:text-gray-400">Deployments</div>
        </div>
        
        <div className="bg-success-50 dark:bg-success-900/20 p-3 rounded-lg">
          <div className="text-2xl font-bold text-success-600 dark:text-success-400">
            {analytics?.success_rate_30d ? `${(analytics.success_rate_30d * 100).toFixed(1)}%` : 'N/A'}
          </div>
          <div className="text-xs text-gray-600 dark:text-gray-400">Success Rate</div>
        </div>
        
        <div className="bg-warning-50 dark:bg-warning-900/20 p-3 rounded-lg">
          <div className="text-2xl font-bold text-warning-600 dark:text-warning-400">
            {analytics?.avg_execution_time_ms ? `${analytics.avg_execution_time_ms}ms` : 'N/A'}
          </div>
          <div className="text-xs text-gray-600 dark:text-gray-400">Avg Time</div>
        </div>
      </div>

      <div className="pt-2 border-t border-gray-200 dark:border-gray-700">
        <div className="flex justify-between items-center text-sm">
          <span className="text-gray-600 dark:text-gray-400">30-day Executions</span>
          <span className="font-medium text-gray-900 dark:text-white">
            {analytics?.total_executions_30d?.toLocaleString() || '0'}
          </span>
        </div>
        <div className="flex justify-between items-center text-sm mt-1">
          <span className="text-gray-600 dark:text-gray-400">Revenue (30d)</span>
          <span className="font-medium text-success-600 dark:text-success-400">
            ${analytics?.total_revenue_30d?.toFixed(2) || '0.00'}
          </span>
        </div>
      </div>
    </div>
  )

  const renderSwarmStats = () => {
    if (!swarmPerformance) return null

    return (
      <div className="space-y-4">
        <h3 className="text-lg font-semibold text-gray-900 dark:text-white flex items-center gap-2">
          <GitBranch className="h-5 w-5 text-secondary-600 dark:text-secondary-400" />
          Swarm Performance
        </h3>
        
        <div className="grid grid-cols-2 gap-3">
          <div className="bg-blue-50 dark:bg-blue-900/20 p-3 rounded-lg">
            <div className="text-2xl font-bold text-blue-600 dark:text-blue-400">
              {swarmPerformance.agent_count}
            </div>
            <div className="text-xs text-gray-600 dark:text-gray-400">Agents</div>
          </div>
          
          <div className="bg-purple-50 dark:bg-purple-900/20 p-3 rounded-lg">
            <div className="text-2xl font-bold text-purple-600 dark:text-purple-400">
              {swarmPerformance.connection_count}
            </div>
            <div className="text-xs text-gray-600 dark:text-gray-400">Connections</div>
          </div>
          
          <div className="bg-green-50 dark:bg-green-900/20 p-3 rounded-lg">
            <div className="text-2xl font-bold text-green-600 dark:text-green-400">
              {(swarmPerformance.swarm_success_rate * 100).toFixed(1)}%
            </div>
            <div className="text-xs text-gray-600 dark:text-gray-400">Success Rate</div>
          </div>
          
          <div className="bg-orange-50 dark:bg-orange-900/20 p-3 rounded-lg">
            <div className="text-2xl font-bold text-orange-600 dark:text-orange-400">
              {swarmPerformance.coordination_effectiveness.toFixed(1)}
            </div>
            <div className="text-xs text-gray-600 dark:text-gray-400">Coordination</div>
          </div>
        </div>

        <div className="pt-2 border-t border-gray-200 dark:border-gray-700">
          <div className="flex justify-between items-center text-sm">
            <span className="text-gray-600 dark:text-gray-400">Total Executions</span>
            <span className="font-medium text-gray-900 dark:text-white">
              {swarmPerformance.total_executions.toLocaleString()}
            </span>
          </div>
          <div className="flex justify-between items-center text-sm mt-1">
            <span className="text-gray-600 dark:text-gray-400">Avg Execution Time</span>
            <span className="font-medium text-gray-900 dark:text-white">
              {swarmPerformance.avg_execution_time_ms}ms
            </span>
          </div>
        </div>
      </div>
    )
  }

  const renderAgentStats = () => {
    if (!agentPerformance) return null

    const { performance_metrics: metrics, health_score } = agentPerformance

    return (
      <div className="space-y-4">
        <h3 className="text-lg font-semibold text-gray-900 dark:text-white flex items-center gap-2">
          <Users className="h-5 w-5 text-success-600 dark:text-success-400" />
          Agent Performance
        </h3>
        
        {/* Health Score */}
        {health_score && (
          <div className="bg-gradient-to-r from-primary-50 to-secondary-50 dark:from-primary-900/20 dark:to-secondary-900/20 p-4 rounded-lg">
            <div className="flex items-center justify-between mb-2">
              <span className="text-sm font-medium text-gray-700 dark:text-gray-300">Health Score</span>
              <span className={`text-2xl font-bold ${
                health_score.overall_score >= 80 
                  ? 'text-success-600 dark:text-success-400'
                  : health_score.overall_score >= 60
                  ? 'text-warning-600 dark:text-warning-400'
                  : 'text-error-600 dark:text-error-400'
              }`}>
                {health_score.overall_score.toFixed(0)}
              </span>
            </div>
            
            <div className="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-2">
              <div 
                className={`h-2 rounded-full transition-all duration-300 ${
                  health_score.overall_score >= 80 
                    ? 'bg-success-500'
                    : health_score.overall_score >= 60
                    ? 'bg-warning-500'
                    : 'bg-error-500'
                }`}
                style={{ width: `${health_score.overall_score}%` }}
              />
            </div>
          </div>
        )}
        
        <div className="grid grid-cols-2 gap-3">
          <div className="bg-green-50 dark:bg-green-900/20 p-3 rounded-lg">
            <div className="flex items-center gap-1 mb-1">
              <TrendingUp className="h-4 w-4 text-green-600 dark:text-green-400" />
              <div className="text-lg font-bold text-green-600 dark:text-green-400">
                {(metrics.success_rate * 100).toFixed(1)}%
              </div>
            </div>
            <div className="text-xs text-gray-600 dark:text-gray-400">Success Rate</div>
          </div>
          
          <div className="bg-blue-50 dark:bg-blue-900/20 p-3 rounded-lg">
            <div className="flex items-center gap-1 mb-1">
              <Target className="h-4 w-4 text-blue-600 dark:text-blue-400" />
              <div className="text-lg font-bold text-blue-600 dark:text-blue-400">
                {metrics.total_executions}
              </div>
            </div>
            <div className="text-xs text-gray-600 dark:text-gray-400">Executions</div>
          </div>
          
          <div className="bg-purple-50 dark:bg-purple-900/20 p-3 rounded-lg">
            <div className="flex items-center gap-1 mb-1">
              <Clock className="h-4 w-4 text-purple-600 dark:text-purple-400" />
              <div className="text-lg font-bold text-purple-600 dark:text-purple-400">
                {metrics.avg_execution_time_ms}ms
              </div>
            </div>
            <div className="text-xs text-gray-600 dark:text-gray-400">Avg Time</div>
          </div>
          
          <div className="bg-red-50 dark:bg-red-900/20 p-3 rounded-lg">
            <div className="flex items-center gap-1 mb-1">
              <AlertTriangle className="h-4 w-4 text-red-600 dark:text-red-400" />
              <div className="text-lg font-bold text-red-600 dark:text-red-400">
                {(metrics.error_rate * 100).toFixed(1)}%
              </div>
            </div>
            <div className="text-xs text-gray-600 dark:text-gray-400">Error Rate</div>
          </div>
        </div>

        <div className="pt-2 border-t border-gray-200 dark:border-gray-700">
          <div className="flex justify-between items-center text-sm">
            <span className="text-gray-600 dark:text-gray-400">Total Cost</span>
            <span className="font-medium text-gray-900 dark:text-white">
              ${metrics.total_cost.toFixed(2)}
            </span>
          </div>
          <div className="flex justify-between items-center text-sm mt-1">
            <span className="text-gray-600 dark:text-gray-400">Cost per Execution</span>
            <span className="font-medium text-gray-900 dark:text-white">
              ${metrics.avg_cost_per_execution.toFixed(3)}
            </span>
          </div>
        </div>
      </div>
    )
  }

  const isLoading = isLoadingSwarm || isLoadingAgent || isLoadingAnalytics

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700 p-6"
    >
      {isLoading ? (
        <div className="flex items-center justify-center h-32">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600"></div>
        </div>
      ) : selectedSwarmId ? (
        renderSwarmStats()
      ) : selectedAgentId ? (
        renderAgentStats()
      ) : (
        renderOverallStats()
      )}
    </motion.div>
  )
}