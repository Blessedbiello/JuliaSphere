'use client'

import { useQuery } from 'react-query'
import { motion, AnimatePresence } from 'framer-motion'
import { 
  User, 
  Calendar, 
  Activity, 
  GitBranch, 
  Zap, 
  Clock,
  Star,
  Shield,
  Tag,
  ExternalLink,
  Play,
  Pause,
  Square
} from 'lucide-react'
import { api } from '@/lib/api'
import { MarketplaceAgentDetail, SwarmTopology } from '@/types'
import toast from 'react-hot-toast'

interface SwarmDetailsProps {
  selectedSwarmId?: string | null
  selectedAgentId?: string | null
  onAgentSelect: (agentId: string | null) => void
  onSwarmSelect: (swarmId: string | null) => void
}

export function SwarmDetails({
  selectedSwarmId,
  selectedAgentId,
  onAgentSelect,
  onSwarmSelect,
}: SwarmDetailsProps) {
  // Fetch agent details
  const { data: agentDetail, isLoading: isLoadingAgent } = useQuery<MarketplaceAgentDetail>(
    ['agentDetail', selectedAgentId],
    () => selectedAgentId 
      ? api.marketplace.getAgent(selectedAgentId).then(res => res.data)
      : Promise.resolve(null),
    {
      enabled: !!selectedAgentId,
    }
  )

  // Fetch swarm topology
  const { data: swarmTopology, isLoading: isLoadingSwarm } = useQuery<SwarmTopology>(
    ['swarmTopology', selectedSwarmId],
    () => selectedSwarmId 
      ? api.marketplace.getSwarmTopology(selectedSwarmId).then(res => res.data)
      : Promise.resolve(null),
    {
      enabled: !!selectedSwarmId,
    }
  )

  const handleAgentAction = (action: 'start' | 'pause' | 'stop') => {
    if (!selectedAgentId) return
    
    const actions = {
      start: 'Starting',
      pause: 'Pausing', 
      stop: 'Stopping'
    }
    
    toast.success(`${actions[action]} agent...`)
    // TODO: Implement actual agent control
  }

  const renderAgentDetails = () => {
    if (!agentDetail) return null

    return (
      <div className="space-y-6">
        {/* Agent Header */}
        <div className="flex items-start justify-between">
          <div>
            <h3 className="text-lg font-semibold text-gray-900 dark:text-white">
              {agentDetail.name}
            </h3>
            <p className="text-sm text-gray-600 dark:text-gray-400 mt-1">
              {agentDetail.description}
            </p>
          </div>
          
          <div className="flex items-center gap-1">
            <button
              onClick={() => handleAgentAction('start')}
              className="p-2 text-success-600 dark:text-success-400 hover:bg-success-50 dark:hover:bg-success-900/20 rounded transition-colors"
              title="Start Agent"
            >
              <Play className="h-4 w-4" />
            </button>
            <button
              onClick={() => handleAgentAction('pause')}
              className="p-2 text-warning-600 dark:text-warning-400 hover:bg-warning-50 dark:hover:bg-warning-900/20 rounded transition-colors"
              title="Pause Agent"
            >
              <Pause className="h-4 w-4" />
            </button>
            <button
              onClick={() => handleAgentAction('stop')}
              className="p-2 text-error-600 dark:text-error-400 hover:bg-error-50 dark:hover:bg-error-900/20 rounded transition-colors"
              title="Stop Agent"
            >
              <Square className="h-4 w-4" />
            </button>
          </div>
        </div>

        {/* Agent Metadata */}
        <div className="grid grid-cols-2 gap-4">
          <div className="flex items-center gap-2 text-sm">
            <User className="h-4 w-4 text-gray-500" />
            <span className="text-gray-600 dark:text-gray-400">Creator:</span>
            <span className="font-medium text-gray-900 dark:text-white">
              {agentDetail.creator.display_name || agentDetail.creator.username}
            </span>
          </div>
          
          <div className="flex items-center gap-2 text-sm">
            <Calendar className="h-4 w-4 text-gray-500" />
            <span className="text-gray-600 dark:text-gray-400">Created:</span>
            <span className="font-medium text-gray-900 dark:text-white">
              {new Date(agentDetail.created_at).toLocaleDateString()}
            </span>
          </div>
          
          <div className="flex items-center gap-2 text-sm">
            <Activity className="h-4 w-4 text-gray-500" />
            <span className="text-gray-600 dark:text-gray-400">Strategy:</span>
            <span className="font-medium text-gray-900 dark:text-white">
              {agentDetail.strategy}
            </span>
          </div>
          
          <div className="flex items-center gap-2 text-sm">
            <Shield className="h-4 w-4 text-gray-500" />
            <span className="text-gray-600 dark:text-gray-400">State:</span>
            <span className={`font-medium px-2 py-1 rounded-full text-xs ${
              agentDetail.state === 'RUNNING' 
                ? 'bg-success-100 dark:bg-success-900/20 text-success-700 dark:text-success-300'
                : agentDetail.state === 'PAUSED'
                ? 'bg-warning-100 dark:bg-warning-900/20 text-warning-700 dark:text-warning-300'
                : 'bg-gray-100 dark:bg-gray-700 text-gray-700 dark:text-gray-300'
            }`}>
              {agentDetail.state}
            </span>
          </div>
        </div>

        {/* Marketplace Info */}
        {agentDetail.marketplace && (
          <div className="border-t border-gray-200 dark:border-gray-700 pt-4">
            <h4 className="font-medium text-gray-900 dark:text-white mb-3">Marketplace Info</h4>
            
            <div className="space-y-3">
              {/* Rating */}
              <div className="flex items-center gap-2">
                <Star className="h-4 w-4 text-yellow-500" />
                <span className="text-sm text-gray-600 dark:text-gray-400">
                  {agentDetail.stats.avg_rating.toFixed(1)} stars
                </span>
                <span className="text-xs text-gray-500">
                  ({agentDetail.stats.rating_count} reviews)
                </span>
              </div>
              
              {/* Deployments */}
              <div className="flex items-center gap-2">
                <Zap className="h-4 w-4 text-blue-500" />
                <span className="text-sm text-gray-600 dark:text-gray-400">
                  {agentDetail.stats.deployments} deployments
                </span>
              </div>
              
              {/* Tags */}
              {agentDetail.tags.length > 0 && (
                <div className="flex items-start gap-2">
                  <Tag className="h-4 w-4 text-gray-500 mt-0.5" />
                  <div className="flex flex-wrap gap-1">
                    {agentDetail.tags.map((tag, index) => (
                      <span
                        key={index}
                        className="px-2 py-1 bg-gray-100 dark:bg-gray-700 text-gray-700 dark:text-gray-300 text-xs rounded-full"
                      >
                        {tag}
                      </span>
                    ))}
                  </div>
                </div>
              )}
              
              {/* Pricing */}
              <div className="flex items-center gap-2">
                <Clock className="h-4 w-4 text-green-500" />
                <span className="text-sm text-gray-600 dark:text-gray-400">
                  {agentDetail.pricing.model === 'free' 
                    ? 'Free' 
                    : `${agentDetail.pricing.currency} ${agentDetail.pricing.amount} (${agentDetail.pricing.model})`
                  }
                </span>
              </div>
            </div>
          </div>
        )}

        {/* Tools */}
        <div className="border-t border-gray-200 dark:border-gray-700 pt-4">
          <h4 className="font-medium text-gray-900 dark:text-white mb-3">Tools</h4>
          <div className="space-y-2">
            {agentDetail.tools.map((tool, index) => (
              <div key={index} className="flex items-center gap-2 text-sm bg-gray-50 dark:bg-gray-700 p-2 rounded">
                <span className="font-medium text-gray-900 dark:text-white">{tool.name}</span>
              </div>
            ))}
          </div>
        </div>

        {/* Actions */}
        <div className="border-t border-gray-200 dark:border-gray-700 pt-4">
          <div className="flex gap-2">
            <button className="flex-1 flex items-center justify-center gap-2 px-4 py-2 bg-primary-600 text-white rounded-lg hover:bg-primary-700 transition-colors text-sm">
              <ExternalLink className="h-4 w-4" />
              View in Marketplace
            </button>
            <button 
              onClick={() => onAgentSelect(null)}
              className="px-4 py-2 bg-gray-100 dark:bg-gray-700 text-gray-700 dark:text-gray-200 rounded-lg hover:bg-gray-200 dark:hover:bg-gray-600 transition-colors text-sm"
            >
              Close
            </button>
          </div>
        </div>
      </div>
    )
  }

  const renderSwarmDetails = () => {
    if (!swarmTopology) return null

    return (
      <div className="space-y-6">
        <div className="flex items-start justify-between">
          <div>
            <h3 className="text-lg font-semibold text-gray-900 dark:text-white">
              Swarm Details
            </h3>
            <p className="text-sm text-gray-600 dark:text-gray-400 mt-1">
              Coordination pattern: {swarmTopology.coordination_patterns.dominant_pattern}
            </p>
          </div>
        </div>

        {/* Swarm Stats */}
        <div className="grid grid-cols-2 gap-4">
          <div className="bg-blue-50 dark:bg-blue-900/20 p-3 rounded-lg">
            <div className="text-lg font-bold text-blue-600 dark:text-blue-400">
              {swarmTopology.agents.length}
            </div>
            <div className="text-xs text-gray-600 dark:text-gray-400">Agents</div>
          </div>
          
          <div className="bg-purple-50 dark:bg-purple-900/20 p-3 rounded-lg">
            <div className="text-lg font-bold text-purple-600 dark:text-purple-400">
              {swarmTopology.connections.length}
            </div>
            <div className="text-xs text-gray-600 dark:text-gray-400">Connections</div>
          </div>
        </div>

        {/* Coordination Patterns */}
        <div className="border-t border-gray-200 dark:border-gray-700 pt-4">
          <h4 className="font-medium text-gray-900 dark:text-white mb-3">Coordination Patterns</h4>
          <div className="space-y-2">
            <div className="flex justify-between items-center">
              <span className="text-sm text-gray-600 dark:text-gray-400">Hierarchical</span>
              <div className="flex items-center gap-2">
                <div className="w-20 h-2 bg-gray-200 dark:bg-gray-700 rounded-full overflow-hidden">
                  <div 
                    className="h-full bg-primary-500 rounded-full transition-all duration-300" 
                    style={{ width: `${(swarmTopology.coordination_patterns.hierarchical * 100)}%` }}
                  />
                </div>
                <span className="text-sm font-medium text-gray-900 dark:text-white w-8">
                  {(swarmTopology.coordination_patterns.hierarchical * 100).toFixed(0)}%
                </span>
              </div>
            </div>
            
            <div className="flex justify-between items-center">
              <span className="text-sm text-gray-600 dark:text-gray-400">Collaborative</span>
              <div className="flex items-center gap-2">
                <div className="w-20 h-2 bg-gray-200 dark:bg-gray-700 rounded-full overflow-hidden">
                  <div 
                    className="h-full bg-secondary-500 rounded-full transition-all duration-300" 
                    style={{ width: `${(swarmTopology.coordination_patterns.collaborative * 100)}%` }}
                  />
                </div>
                <span className="text-sm font-medium text-gray-900 dark:text-white w-8">
                  {(swarmTopology.coordination_patterns.collaborative * 100).toFixed(0)}%
                </span>
              </div>
            </div>
            
            <div className="flex justify-between items-center">
              <span className="text-sm text-gray-600 dark:text-gray-400">Pipeline</span>
              <div className="flex items-center gap-2">
                <div className="w-20 h-2 bg-gray-200 dark:bg-gray-700 rounded-full overflow-hidden">
                  <div 
                    className="h-full bg-success-500 rounded-full transition-all duration-300" 
                    style={{ width: `${(swarmTopology.coordination_patterns.pipeline * 100)}%` }}
                  />
                </div>
                <span className="text-sm font-medium text-gray-900 dark:text-white w-8">
                  {(swarmTopology.coordination_patterns.pipeline * 100).toFixed(0)}%
                </span>
              </div>
            </div>
          </div>
        </div>

        {/* Agent List */}
        <div className="border-t border-gray-200 dark:border-gray-700 pt-4">
          <h4 className="font-medium text-gray-900 dark:text-white mb-3">Swarm Agents</h4>
          <div className="space-y-2 max-h-32 overflow-y-auto">
            {swarmTopology.agents.map((agentId, index) => (
              <button
                key={index}
                onClick={() => onAgentSelect(agentId)}
                className="w-full text-left px-3 py-2 text-sm bg-gray-50 dark:bg-gray-700 hover:bg-gray-100 dark:hover:bg-gray-600 rounded transition-colors"
              >
                Agent {agentId.slice(0, 8)}...
              </button>
            ))}
          </div>
        </div>

        {/* Actions */}
        <div className="border-t border-gray-200 dark:border-gray-700 pt-4">
          <div className="flex gap-2">
            <button className="flex-1 flex items-center justify-center gap-2 px-4 py-2 bg-secondary-600 text-white rounded-lg hover:bg-secondary-700 transition-colors text-sm">
              <GitBranch className="h-4 w-4" />
              Analyze Swarm
            </button>
            <button 
              onClick={() => onSwarmSelect(null)}
              className="px-4 py-2 bg-gray-100 dark:bg-gray-700 text-gray-700 dark:text-gray-200 rounded-lg hover:bg-gray-200 dark:hover:bg-gray-600 transition-colors text-sm"
            >
              Close
            </button>
          </div>
        </div>
      </div>
    )
  }

  const renderEmptyState = () => (
    <div className="text-center py-8">
      <div className="w-16 h-16 bg-gray-200 dark:bg-gray-700 rounded-full flex items-center justify-center mx-auto mb-4">
        <GitBranch className="h-8 w-8 text-gray-400" />
      </div>
      <h3 className="text-lg font-medium text-gray-900 dark:text-white mb-2">
        No Selection
      </h3>
      <p className="text-gray-600 dark:text-gray-400 text-sm">
        Click on an agent or swarm in the visualization to see detailed information here.
      </p>
    </div>
  )

  const isLoading = isLoadingAgent || isLoadingSwarm

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700 p-6"
    >
      <AnimatePresence mode="wait">
        {isLoading ? (
          <motion.div
            key="loading"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="flex items-center justify-center h-32"
          >
            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600"></div>
          </motion.div>
        ) : selectedAgentId ? (
          <motion.div
            key="agent"
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: -20 }}
          >
            {renderAgentDetails()}
          </motion.div>
        ) : selectedSwarmId ? (
          <motion.div
            key="swarm"
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: -20 }}
          >
            {renderSwarmDetails()}
          </motion.div>
        ) : (
          <motion.div
            key="empty"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
          >
            {renderEmptyState()}
          </motion.div>
        )}
      </AnimatePresence>
    </motion.div>
  )
}