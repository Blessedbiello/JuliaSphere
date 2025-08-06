'use client'

import { useState } from 'react'
import { motion } from 'framer-motion'
import { Activity, BarChart3, Settings, RefreshCw, Maximize2 } from 'lucide-react'
import { SwarmVisualizer } from '@/components/swarms/SwarmVisualizer'
import { SwarmControls } from '@/components/swarms/SwarmControls'
import { SwarmStats } from '@/components/swarms/SwarmStats'
import { SwarmDetails } from '@/components/swarms/SwarmDetails'

export default function SwarmsPage() {
  const [selectedSwarmId, setSelectedSwarmId] = useState<string | null>(null)
  const [selectedAgentId, setSelectedAgentId] = useState<string | null>(null)
  const [isFullscreen, setIsFullscreen] = useState(false)
  const [autoRefresh, setAutoRefresh] = useState(true)

  return (
    <div className="space-y-6">
      {/* Header */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5 }}
        className="flex items-center justify-between"
      >
        <div>
          <h1 className="text-3xl font-bold text-gray-900 dark:text-white">
            Swarm Visualizer
          </h1>
          <p className="text-gray-600 dark:text-gray-400 mt-2">
            Real-time visualization of agent coordination patterns and swarm intelligence
          </p>
        </div>
        
        <div className="flex items-center gap-3">
          <button
            onClick={() => setAutoRefresh(!autoRefresh)}
            className={`flex items-center gap-2 px-4 py-2 rounded-lg font-medium transition-colors ${
              autoRefresh
                ? 'bg-success-100 dark:bg-success-900/20 text-success-700 dark:text-success-300'
                : 'bg-gray-100 dark:bg-gray-700 text-gray-700 dark:text-gray-300'
            }`}
          >
            <RefreshCw className={`h-4 w-4 ${autoRefresh ? 'animate-spin' : ''}`} />
            Auto Refresh
          </button>
          
          <button
            onClick={() => setIsFullscreen(!isFullscreen)}
            className="flex items-center gap-2 px-4 py-2 bg-primary-100 dark:bg-primary-900/20 text-primary-700 dark:text-primary-300 rounded-lg font-medium hover:bg-primary-200 dark:hover:bg-primary-900/30 transition-colors"
          >
            <Maximize2 className="h-4 w-4" />
            {isFullscreen ? 'Exit Fullscreen' : 'Fullscreen'}
          </button>
        </div>
      </motion.div>

      {/* Main Content */}
      <div className={`${
        isFullscreen 
          ? 'fixed inset-0 z-50 bg-white dark:bg-gray-900 p-6' 
          : 'grid grid-cols-1 lg:grid-cols-4 gap-6'
      }`}>
        {/* Swarm Visualization */}
        <motion.div
          initial={{ opacity: 0, scale: 0.95 }}
          animate={{ opacity: 1, scale: 1 }}
          transition={{ duration: 0.5, delay: 0.1 }}
          className={`${
            isFullscreen 
              ? 'col-span-1 h-full' 
              : 'lg:col-span-3 h-[600px]'
          } bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700 overflow-hidden`}
        >
          <div className="p-4 border-b border-gray-200 dark:border-gray-700">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <Activity className="h-5 w-5 text-primary-600 dark:text-primary-400" />
                <h2 className="text-lg font-semibold text-gray-900 dark:text-white">
                  Agent Coordination Graph
                </h2>
              </div>
              
              <SwarmControls 
                onRefresh={() => window.location.reload()}
                autoRefresh={autoRefresh}
                onAutoRefreshChange={setAutoRefresh}
              />
            </div>
          </div>
          
          <div className={`${isFullscreen ? 'h-[calc(100%-80px)]' : 'h-[calc(600px-80px)]'}`}>
            <SwarmVisualizer
              onSwarmSelect={setSelectedSwarmId}
              onAgentSelect={setSelectedAgentId}
              selectedSwarmId={selectedSwarmId}
              selectedAgentId={selectedAgentId}
              autoRefresh={autoRefresh}
            />
          </div>
        </motion.div>

        {/* Side Panel */}
        {!isFullscreen && (
          <div className="space-y-6">
            {/* Swarm Statistics */}
            <motion.div
              initial={{ opacity: 0, x: 20 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ duration: 0.5, delay: 0.2 }}
            >
              <SwarmStats 
                selectedSwarmId={selectedSwarmId} 
                selectedAgentId={selectedAgentId}
              />
            </motion.div>

            {/* Swarm/Agent Details */}
            <motion.div
              initial={{ opacity: 0, x: 20 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ duration: 0.5, delay: 0.3 }}
            >
              <SwarmDetails
                selectedSwarmId={selectedSwarmId}
                selectedAgentId={selectedAgentId}
                onAgentSelect={setSelectedAgentId}
                onSwarmSelect={setSelectedSwarmId}
              />
            </motion.div>
          </div>
        )}
      </div>

      {/* Bottom Section - Analysis Tools */}
      {!isFullscreen && (
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5, delay: 0.4 }}
          className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6"
        >
          {/* Coordination Patterns */}
          <div className="bg-white dark:bg-gray-800 p-6 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700">
            <div className="flex items-center gap-2 mb-4">
              <BarChart3 className="h-5 w-5 text-secondary-600 dark:text-secondary-400" />
              <h3 className="text-lg font-semibold text-gray-900 dark:text-white">
                Coordination Patterns
              </h3>
            </div>
            <div className="space-y-3">
              <div className="flex justify-between items-center">
                <span className="text-sm text-gray-600 dark:text-gray-400">Hierarchical</span>
                <div className="flex items-center gap-2">
                  <div className="w-16 h-2 bg-gray-200 dark:bg-gray-700 rounded-full overflow-hidden">
                    <div className="h-full bg-primary-500 rounded-full" style={{ width: '75%' }}></div>
                  </div>
                  <span className="text-sm font-medium text-gray-900 dark:text-white">75%</span>
                </div>
              </div>
              <div className="flex justify-between items-center">
                <span className="text-sm text-gray-600 dark:text-gray-400">Collaborative</span>
                <div className="flex items-center gap-2">
                  <div className="w-16 h-2 bg-gray-200 dark:bg-gray-700 rounded-full overflow-hidden">
                    <div className="h-full bg-secondary-500 rounded-full" style={{ width: '45%' }}></div>
                  </div>
                  <span className="text-sm font-medium text-gray-900 dark:text-white">45%</span>
                </div>
              </div>
              <div className="flex justify-between items-center">
                <span className="text-sm text-gray-600 dark:text-gray-400">Pipeline</span>
                <div className="flex items-center gap-2">
                  <div className="w-16 h-2 bg-gray-200 dark:bg-gray-700 rounded-full overflow-hidden">
                    <div className="h-full bg-success-500 rounded-full" style={{ width: '60%' }}></div>
                  </div>
                  <span className="text-sm font-medium text-gray-900 dark:text-white">60%</span>
                </div>
              </div>
            </div>
          </div>

          {/* Performance Overview */}
          <div className="bg-white dark:bg-gray-800 p-6 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700">
            <div className="flex items-center gap-2 mb-4">
              <Activity className="h-5 w-5 text-success-600 dark:text-success-400" />
              <h3 className="text-lg font-semibold text-gray-900 dark:text-white">
                Performance Overview
              </h3>
            </div>
            <div className="space-y-3">
              <div className="flex justify-between">
                <span className="text-sm text-gray-600 dark:text-gray-400">Avg Success Rate</span>
                <span className="text-sm font-medium text-success-600 dark:text-success-400">87.3%</span>
              </div>
              <div className="flex justify-between">
                <span className="text-sm text-gray-600 dark:text-gray-400">Coordination Score</span>
                <span className="text-sm font-medium text-primary-600 dark:text-primary-400">92.1</span>
              </div>
              <div className="flex justify-between">
                <span className="text-sm text-gray-600 dark:text-gray-400">Active Swarms</span>
                <span className="text-sm font-medium text-gray-900 dark:text-white">7</span>
              </div>
              <div className="flex justify-between">
                <span className="text-sm text-gray-600 dark:text-gray-400">Total Agents</span>
                <span className="text-sm font-medium text-gray-900 dark:text-white">23</span>
              </div>
            </div>
          </div>

          {/* Quick Actions */}
          <div className="bg-white dark:bg-gray-800 p-6 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700">
            <div className="flex items-center gap-2 mb-4">
              <Settings className="h-5 w-5 text-warning-600 dark:text-warning-400" />
              <h3 className="text-lg font-semibold text-gray-900 dark:text-white">
                Quick Actions
              </h3>
            </div>
            <div className="space-y-3">
              <button className="w-full text-left px-3 py-2 text-sm text-gray-700 dark:text-gray-200 hover:bg-gray-100 dark:hover:bg-gray-700 rounded-lg transition-colors">
                Trigger Swarm Analysis
              </button>
              <button className="w-full text-left px-3 py-2 text-sm text-gray-700 dark:text-gray-200 hover:bg-gray-100 dark:hover:bg-gray-700 rounded-lg transition-colors">
                Export Graph Data
              </button>
              <button className="w-full text-left px-3 py-2 text-sm text-gray-700 dark:text-gray-200 hover:bg-gray-100 dark:hover:bg-gray-700 rounded-lg transition-colors">
                Performance Report
              </button>
              <button className="w-full text-left px-3 py-2 text-sm text-gray-700 dark:text-gray-200 hover:bg-gray-100 dark:hover:bg-gray-700 rounded-lg transition-colors">
                Configure Alerts
              </button>
            </div>
          </div>
        </motion.div>
      )}
    </div>
  )
}