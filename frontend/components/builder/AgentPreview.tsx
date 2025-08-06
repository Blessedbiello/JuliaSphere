'use client'

import { useState } from 'react'
import { motion } from 'framer-motion'
import { 
  Eye, 
  Play, 
  Settings, 
  Zap, 
  Clock, 
  User,
  CheckCircle,
  AlertCircle,
  Info,
  Code,
  FileText,
  Calendar,
  Webhook,
  MessageSquare,
  Database,
  PlayCircle
} from 'lucide-react'
import { CreateAgentForm } from '@/types'

interface AgentPreviewProps {
  agent: CreateAgentForm
  onTest: () => void
  isTesting: boolean
}

const STRATEGY_ICONS = {
  plan_execute: '💎',
  adder: '🔄',
  blogger: '📝',
  telegram_moderator: '📱',
  default: '🤖',
}

const TRIGGER_ICONS = {
  manual: PlayCircle,
  schedule: Clock,
  webhook: Webhook,
  telegram: MessageSquare,
  database: Database,
}

export function AgentPreview({ agent, onTest, isTesting }: AgentPreviewProps) {
  const [showJson, setShowJson] = useState(false)

  const getStrategyIcon = (strategy: string) => {
    return STRATEGY_ICONS[strategy as keyof typeof STRATEGY_ICONS] || STRATEGY_ICONS.default
  }

  const getTriggerIcon = (triggerType: string) => {
    return TRIGGER_ICONS[triggerType as keyof typeof TRIGGER_ICONS] || PlayCircle
  }

  const isAgentValid = () => {
    return (
      agent.name &&
      agent.description &&
      agent.strategy &&
      agent.tools.length > 0 &&
      agent.triggerType
    )
  }

  const getValidationIssues = () => {
    const issues = []
    
    if (!agent.name) issues.push('Agent name is required')
    if (!agent.description) issues.push('Agent description is required')
    if (!agent.strategy) issues.push('Strategy selection is required')
    if (agent.tools.length === 0) issues.push('At least one tool must be selected')
    if (!agent.triggerType) issues.push('Trigger type must be configured')
    
    // Check trigger-specific validation
    if (agent.triggerType === 'telegram' && !agent.triggerParams.bot_token) {
      issues.push('Telegram bot token is required')
    }
    if (agent.triggerType === 'database' && (!agent.triggerParams.connection_string || !agent.triggerParams.table_name)) {
      issues.push('Database connection and table name are required')
    }
    if (agent.triggerType === 'webhook' && !agent.triggerParams.endpoint_path) {
      issues.push('Webhook endpoint path is required')
    }
    
    return issues
  }

  const formatTriggerDescription = () => {
    switch (agent.triggerType) {
      case 'manual':
        return 'Runs when manually started'
      case 'schedule':
        return `Runs on schedule: ${agent.triggerParams.cron_expression || 'Not configured'}`
      case 'webhook':
        return `Webhook endpoint: ${agent.triggerParams.endpoint_path || 'Not configured'}`
      case 'telegram':
        return `Telegram bot: ${agent.triggerParams.bot_token ? 'Configured' : 'Not configured'}`
      case 'database':
        return `Database: ${agent.triggerParams.table_name || 'Not configured'}`
      default:
        return 'Not configured'
    }
  }

  const generateAgentJson = () => {
    return JSON.stringify({
      name: agent.name,
      description: agent.description,
      strategy: {
        name: agent.strategy,
        config: agent.strategyConfig,
      },
      tools: agent.tools,
      trigger: {
        type: agent.triggerType,
        params: agent.triggerParams,
      },
    }, null, 2)
  }

  const validationIssues = getValidationIssues()
  const isValid = isAgentValid()

  return (
    <div className="space-y-8">
      {/* Agent Summary Card */}
      <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 overflow-hidden">
        <div className="bg-gradient-to-r from-primary-50 to-secondary-50 dark:from-primary-900/20 dark:to-secondary-900/20 p-6 border-b border-gray-200 dark:border-gray-700">
          <div className="flex items-start gap-4">
            <div className="w-16 h-16 bg-white dark:bg-gray-800 rounded-xl flex items-center justify-center text-3xl shadow-sm">
              {getStrategyIcon(agent.strategy)}
            </div>
            
            <div className="flex-1">
              <h3 className="text-2xl font-bold text-gray-900 dark:text-white mb-2">
                {agent.name || 'Untitled Agent'}
              </h3>
              <p className="text-gray-600 dark:text-gray-400 mb-4">
                {agent.description || 'No description provided'}
              </p>
              
              <div className="flex items-center gap-4 text-sm">
                <div className="flex items-center gap-2">
                  <Settings className="h-4 w-4 text-gray-500" />
                  <span className="text-gray-700 dark:text-gray-300">
                    {agent.strategy ? agent.strategy.replace('_', ' ').replace(/\b\w/g, l => l.toUpperCase()) : 'No strategy'}
                  </span>
                </div>
                
                <div className="flex items-center gap-2">
                  <Zap className="h-4 w-4 text-gray-500" />
                  <span className="text-gray-700 dark:text-gray-300">
                    {agent.tools.length} tools
                  </span>
                </div>
                
                <div className="flex items-center gap-2">
                  {(() => {
                    const Icon = getTriggerIcon(agent.triggerType)
                    return <Icon className="h-4 w-4 text-gray-500" />
                  })()}
                  <span className="text-gray-700 dark:text-gray-300">
                    {agent.triggerType ? agent.triggerType.replace('_', ' ') : 'No trigger'}
                  </span>
                </div>
              </div>
            </div>

            {/* Validation Status */}
            <div className="flex flex-col items-center gap-2">
              {isValid ? (
                <div className="flex items-center gap-2 px-3 py-1 bg-success-100 dark:bg-success-900/20 text-success-700 dark:text-success-300 rounded-full text-sm">
                  <CheckCircle className="h-4 w-4" />
                  Ready
                </div>
              ) : (
                <div className="flex items-center gap-2 px-3 py-1 bg-warning-100 dark:bg-warning-900/20 text-warning-700 dark:text-warning-300 rounded-full text-sm">
                  <AlertCircle className="h-4 w-4" />
                  Issues
                </div>
              )}
            </div>
          </div>
        </div>

        <div className="p-6">
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            {/* Strategy Details */}
            <div className="space-y-3">
              <h4 className="font-medium text-gray-900 dark:text-white flex items-center gap-2">
                <Settings className="h-4 w-4" />
                Strategy
              </h4>
              
              {agent.strategy ? (
                <div>
                  <div className="text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                    {agent.strategy.replace('_', ' ').replace(/\b\w/g, l => l.toUpperCase())}
                  </div>
                  {Object.keys(agent.strategyConfig).length > 0 && (
                    <div className="text-xs text-gray-500 dark:text-gray-400 space-y-1">
                      {Object.entries(agent.strategyConfig).map(([key, value]) => (
                        <div key={key}>
                          <span className="font-medium">{key}:</span> {String(value)}
                        </div>
                      ))}
                    </div>
                  )}
                </div>
              ) : (
                <div className="text-sm text-gray-500 dark:text-gray-400">
                  No strategy selected
                </div>
              )}
            </div>

            {/* Tools */}
            <div className="space-y-3">
              <h4 className="font-medium text-gray-900 dark:text-white flex items-center gap-2">
                <Zap className="h-4 w-4" />
                Tools ({agent.tools.length})
              </h4>
              
              {agent.tools.length > 0 ? (
                <div className="space-y-2">
                  {agent.tools.map((tool, index) => (
                    <div key={index} className="text-sm">
                      <div className="font-medium text-gray-700 dark:text-gray-300">
                        {tool.name.replace('_', ' ').replace(/\b\w/g, l => l.toUpperCase())}
                      </div>
                      {Object.keys(tool.config).length > 0 && (
                        <div className="text-xs text-gray-500 dark:text-gray-400 ml-2">
                          {Object.keys(tool.config).length} config options
                        </div>
                      )}
                    </div>
                  ))}
                </div>
              ) : (
                <div className="text-sm text-gray-500 dark:text-gray-400">
                  No tools selected
                </div>
              )}
            </div>

            {/* Trigger */}
            <div className="space-y-3">
              <h4 className="font-medium text-gray-900 dark:text-white flex items-center gap-2">
                {(() => {
                  const Icon = getTriggerIcon(agent.triggerType)
                  return <Icon className="h-4 w-4" />
                })()}
                Trigger
              </h4>
              
              {agent.triggerType ? (
                <div>
                  <div className="text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                    {agent.triggerType.replace('_', ' ').replace(/\b\w/g, l => l.toUpperCase())}
                  </div>
                  <div className="text-xs text-gray-500 dark:text-gray-400">
                    {formatTriggerDescription()}
                  </div>
                </div>
              ) : (
                <div className="text-sm text-gray-500 dark:text-gray-400">
                  No trigger configured
                </div>
              )}
            </div>
          </div>
        </div>
      </div>

      {/* Validation Issues */}
      {validationIssues.length > 0 && (
        <motion.div
          initial={{ opacity: 0, y: 10 }}
          animate={{ opacity: 1, y: 0 }}
          className="bg-warning-50 dark:bg-warning-900/20 border border-warning-200 dark:border-warning-800 rounded-xl p-6"
        >
          <div className="flex items-start gap-3">
            <AlertCircle className="h-5 w-5 text-warning-600 dark:text-warning-400 mt-0.5 flex-shrink-0" />
            <div>
              <h4 className="font-medium text-warning-900 dark:text-warning-100 mb-2">
                Configuration Issues
              </h4>
              <ul className="text-sm text-warning-800 dark:text-warning-200 space-y-1">
                {validationIssues.map((issue, index) => (
                  <li key={index}>• {issue}</li>
                ))}
              </ul>
            </div>
          </div>
        </motion.div>
      )}

      {/* Test Results */}
      <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-6">
        <div className="flex items-center justify-between mb-6">
          <h4 className="text-lg font-semibold text-gray-900 dark:text-white">
            Test Your Agent
          </h4>
          
          <button
            onClick={onTest}
            disabled={!isValid || isTesting}
            className="flex items-center gap-2 px-4 py-2 bg-secondary-600 text-white rounded-lg hover:bg-secondary-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
          >
            {isTesting ? (
              <>
                <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin" />
                Testing...
              </>
            ) : (
              <>
                <Play className="h-4 w-4" />
                Run Test
              </>
            )}
          </button>
        </div>

        {isTesting ? (
          <div className="border border-gray-200 dark:border-gray-700 rounded-lg p-4 bg-gray-50 dark:bg-gray-900">
            <div className="flex items-center gap-3 mb-4">
              <div className="w-6 h-6 border-2 border-primary-600 border-t-transparent rounded-full animate-spin" />
              <span className="text-gray-700 dark:text-gray-300">Testing agent configuration...</span>
            </div>
            
            <div className="space-y-2 text-sm text-gray-600 dark:text-gray-400">
              <div className="flex items-center gap-2">
                <CheckCircle className="h-4 w-4 text-success-500" />
                Validating strategy configuration
              </div>
              <div className="flex items-center gap-2">
                <CheckCircle className="h-4 w-4 text-success-500" />
                Testing tool connections
              </div>
              <div className="flex items-center gap-2">
                <div className="w-4 h-4 border-2 border-primary-500 border-t-transparent rounded-full animate-spin" />
                Verifying trigger setup
              </div>
            </div>
          </div>
        ) : (
          <div className="text-center py-8 text-gray-500 dark:text-gray-400">
            <Play className="h-12 w-12 mx-auto mb-4 opacity-50" />
            <p>Click "Run Test" to validate your agent configuration</p>
          </div>
        )}
      </div>

      {/* Configuration Export */}
      <div className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-6">
        <div className="flex items-center justify-between mb-4">
          <h4 className="text-lg font-semibold text-gray-900 dark:text-white">
            Configuration Export
          </h4>
          
          <button
            onClick={() => setShowJson(!showJson)}
            className="flex items-center gap-2 px-3 py-1.5 text-sm bg-gray-100 dark:bg-gray-700 text-gray-700 dark:text-gray-200 rounded-lg hover:bg-gray-200 dark:hover:bg-gray-600 transition-colors"
          >
            <Code className="h-4 w-4" />
            {showJson ? 'Hide' : 'Show'} JSON
          </button>
        </div>

        {showJson && (
          <motion.div
            initial={{ opacity: 0, height: 0 }}
            animate={{ opacity: 1, height: 'auto' }}
            exit={{ opacity: 0, height: 0 }}
          >
            <pre className="bg-gray-50 dark:bg-gray-900 border border-gray-200 dark:border-gray-700 rounded-lg p-4 text-sm overflow-x-auto">
              <code className="text-gray-800 dark:text-gray-200">
                {generateAgentJson()}
              </code>
            </pre>
          </motion.div>
        )}
      </div>

      {/* Success State */}
      {isValid && (
        <motion.div
          initial={{ opacity: 0, y: 10 }}
          animate={{ opacity: 1, y: 0 }}
          className="bg-success-50 dark:bg-success-900/20 border border-success-200 dark:border-success-800 rounded-xl p-6"
        >
          <div className="flex items-start gap-3">
            <CheckCircle className="h-5 w-5 text-success-600 dark:text-success-400 mt-0.5 flex-shrink-0" />
            <div>
              <h4 className="font-medium text-success-900 dark:text-success-100 mb-2">
                Agent Ready for Deployment!
              </h4>
              <p className="text-sm text-success-800 dark:text-success-200">
                Your agent configuration is complete and valid. You can now save it to create your agent.
              </p>
            </div>
          </div>
        </motion.div>
      )}
    </div>
  )
}