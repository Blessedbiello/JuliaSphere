'use client'

import { useState } from 'react'
import { RefreshCw, Play, Pause, Square, Download, Settings, Zap } from 'lucide-react'
import { motion } from 'framer-motion'
import toast from 'react-hot-toast'

interface SwarmControlsProps {
  onRefresh: () => void
  autoRefresh: boolean
  onAutoRefreshChange: (enabled: boolean) => void
  isRefreshing?: boolean
  selectedAgentId?: string | null
  selectedSwarmId?: string | null
}

export function SwarmControls({
  onRefresh,
  autoRefresh,
  onAutoRefreshChange,
  isRefreshing = false,
  selectedAgentId,
  selectedSwarmId,
}: SwarmControlsProps) {
  const [showAdvanced, setShowAdvanced] = useState(false)

  const handleExportGraph = () => {
    // TODO: Implement graph data export
    toast.success('Graph data exported successfully')
  }

  const handleTriggerAnalysis = () => {
    // TODO: Implement swarm analysis trigger
    toast.success('Swarm analysis triggered')
  }

  const handleStartAgent = () => {
    if (!selectedAgentId) {
      toast.error('Please select an agent first')
      return
    }
    // TODO: Implement agent start
    toast.success('Starting agent...')
  }

  const handlePauseAgent = () => {
    if (!selectedAgentId) {
      toast.error('Please select an agent first')
      return
    }
    // TODO: Implement agent pause
    toast.success('Pausing agent...')
  }

  const handleStopAgent = () => {
    if (!selectedAgentId) {
      toast.error('Please select an agent first')
      return
    }
    // TODO: Implement agent stop
    toast.success('Stopping agent...')
  }

  return (
    <div className="flex items-center gap-2">
      {/* Refresh Control */}
      <button
        onClick={onRefresh}
        disabled={isRefreshing}
        className="flex items-center gap-1.5 px-3 py-1.5 text-sm bg-gray-100 dark:bg-gray-700 hover:bg-gray-200 dark:hover:bg-gray-600 text-gray-700 dark:text-gray-200 rounded-lg transition-colors disabled:opacity-50"
      >
        <RefreshCw className={`h-4 w-4 ${isRefreshing ? 'animate-spin' : ''}`} />
        Refresh
      </button>

      {/* Auto Refresh Toggle */}
      <button
        onClick={() => onAutoRefreshChange(!autoRefresh)}
        className={`flex items-center gap-1.5 px-3 py-1.5 text-sm rounded-lg font-medium transition-colors ${
          autoRefresh
            ? 'bg-success-100 dark:bg-success-900/20 text-success-700 dark:text-success-300'
            : 'bg-gray-100 dark:bg-gray-700 text-gray-700 dark:text-gray-200 hover:bg-gray-200 dark:hover:bg-gray-600'
        }`}
      >
        <div className={`w-2 h-2 rounded-full ${autoRefresh ? 'bg-success-500' : 'bg-gray-400'}`} />
        Auto
      </button>

      {/* Agent Controls - Only show when agent is selected */}
      {selectedAgentId && (
        <motion.div
          initial={{ opacity: 0, x: -10 }}
          animate={{ opacity: 1, x: 0 }}
          className="flex items-center gap-1 border-l border-gray-300 dark:border-gray-600 pl-2 ml-1"
        >
          <button
            onClick={handleStartAgent}
            className="p-1.5 text-success-600 dark:text-success-400 hover:bg-success-50 dark:hover:bg-success-900/20 rounded transition-colors"
            title="Start Agent"
          >
            <Play className="h-4 w-4" />
          </button>
          
          <button
            onClick={handlePauseAgent}
            className="p-1.5 text-warning-600 dark:text-warning-400 hover:bg-warning-50 dark:hover:bg-warning-900/20 rounded transition-colors"
            title="Pause Agent"
          >
            <Pause className="h-4 w-4" />
          </button>
          
          <button
            onClick={handleStopAgent}
            className="p-1.5 text-error-600 dark:text-error-400 hover:bg-error-50 dark:hover:bg-error-900/20 rounded transition-colors"
            title="Stop Agent"
          >
            <Square className="h-4 w-4" />
          </button>
        </motion.div>
      )}

      {/* Advanced Controls */}
      <div className="relative">
        <button
          onClick={() => setShowAdvanced(!showAdvanced)}
          className="p-1.5 text-gray-600 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-700 rounded transition-colors"
          title="More Options"
        >
          <Settings className="h-4 w-4" />
        </button>

        {showAdvanced && (
          <motion.div
            initial={{ opacity: 0, y: -10 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -10 }}
            className="absolute right-0 top-full mt-2 w-48 bg-white dark:bg-gray-800 rounded-lg shadow-lg border border-gray-200 dark:border-gray-700 py-2 z-20"
          >
            <button
              onClick={handleExportGraph}
              className="flex items-center gap-2 w-full px-3 py-2 text-sm text-gray-700 dark:text-gray-200 hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors"
            >
              <Download className="h-4 w-4" />
              Export Graph Data
            </button>
            
            <button
              onClick={handleTriggerAnalysis}
              className="flex items-center gap-2 w-full px-3 py-2 text-sm text-gray-700 dark:text-gray-200 hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors"
            >
              <Zap className="h-4 w-4" />
              Trigger Analysis
            </button>
            
            <div className="border-t border-gray-200 dark:border-gray-700 my-1" />
            
            <div className="px-3 py-2">
              <div className="text-xs font-medium text-gray-500 dark:text-gray-400 mb-1">
                Layout Options
              </div>
              <select className="w-full text-xs bg-gray-50 dark:bg-gray-700 border border-gray-200 dark:border-gray-600 rounded px-2 py-1">
                <option>Force-directed</option>
                <option>Hierarchical</option>
                <option>Circular</option>
                <option>Grid</option>
              </select>
            </div>
          </motion.div>
        )}
      </div>

      {/* Click outside to close advanced menu */}
      {showAdvanced && (
        <div 
          className="fixed inset-0 z-10" 
          onClick={() => setShowAdvanced(false)}
        />
      )}
    </div>
  )
}