'use client'

import { useState, useEffect } from 'react'
import { useQuery } from 'react-query'
import { motion, AnimatePresence } from 'framer-motion'
import { 
  Brain, 
  Zap, 
  Users, 
  FileText,
  MessageSquare,
  Bot,
  ChevronRight,
  Info,
  Settings,
  CheckCircle
} from 'lucide-react'
import { api } from '@/lib/api'
import { Strategy } from '@/types'

interface StrategySelectorProps {
  selectedStrategy: string
  strategyConfig: Record<string, any>
  agentName: string
  agentDescription: string
  onStrategyChange: (strategy: string, config: Record<string, any>) => void
  onBasicInfoChange: (name: string, description: string) => void
}

const STRATEGY_ICONS = {
  plan_execute: Brain,
  adder: Zap,
  blogger: FileText,
  telegram_moderator: MessageSquare,
  default: Bot,
}

const STRATEGY_COLORS = {
  plan_execute: 'text-purple-600 dark:text-purple-400 bg-purple-100 dark:bg-purple-900/20',
  adder: 'text-green-600 dark:text-green-400 bg-green-100 dark:bg-green-900/20',
  blogger: 'text-orange-600 dark:text-orange-400 bg-orange-100 dark:bg-orange-900/20',
  telegram_moderator: 'text-blue-600 dark:text-blue-400 bg-blue-100 dark:bg-blue-900/20',
  default: 'text-gray-600 dark:text-gray-400 bg-gray-100 dark:bg-gray-700',
}

const STRATEGY_DESCRIPTIONS = {
  plan_execute: 'Advanced reasoning strategy that breaks down complex tasks into manageable steps, plans execution, and adapts based on results.',
  adder: 'Simple computational strategy focused on mathematical operations and data processing tasks.',
  blogger: 'Content creation strategy specialized in generating high-quality written content, articles, and documentation.',
  telegram_moderator: 'Communication strategy designed for managing and moderating chat interactions in messaging platforms.',
}

export function StrategySelector({
  selectedStrategy,
  strategyConfig,
  agentName,
  agentDescription,
  onStrategyChange,
  onBasicInfoChange,
}: StrategySelectorProps) {
  const [showConfig, setShowConfig] = useState(false)
  const [tempConfig, setTempConfig] = useState(strategyConfig)

  // Fetch available strategies
  const { data: strategies, isLoading } = useQuery<Strategy[]>(
    'strategies',
    () => api.general.getStrategies().then(res => res.data),
    {
      onSuccess: (data) => {
        console.log('Available strategies:', data)
      }
    }
  )

  useEffect(() => {
    setTempConfig(strategyConfig)
  }, [strategyConfig])

  const handleStrategySelect = (strategy: string) => {
    // Set default configuration based on strategy
    const defaultConfig = getDefaultConfig(strategy)
    onStrategyChange(strategy, defaultConfig)
    setTempConfig(defaultConfig)
    setShowConfig(true)
  }

  const getDefaultConfig = (strategy: string): Record<string, any> => {
    switch (strategy) {
      case 'plan_execute':
        return {
          max_iterations: 5,
          planning_depth: 3,
          adaptation_threshold: 0.7,
        }
      case 'adder':
        return {
          precision: 2,
          operation_timeout: 1000,
        }
      case 'blogger':
        return {
          content_length: 'medium',
          writing_style: 'professional',
          include_sources: true,
        }
      case 'telegram_moderator':
        return {
          moderation_level: 'moderate',
          auto_respond: true,
          spam_threshold: 0.8,
        }
      default:
        return {}
    }
  }

  const handleConfigChange = (key: string, value: any) => {
    const newConfig = { ...tempConfig, [key]: value }
    setTempConfig(newConfig)
    onStrategyChange(selectedStrategy, newConfig)
  }

  const getStrategyIcon = (strategyName: string) => {
    return STRATEGY_ICONS[strategyName as keyof typeof STRATEGY_ICONS] || STRATEGY_ICONS.default
  }

  const getStrategyColor = (strategyName: string) => {
    return STRATEGY_COLORS[strategyName as keyof typeof STRATEGY_COLORS] || STRATEGY_COLORS.default
  }

  const renderStrategyConfig = () => {
    if (!selectedStrategy || !showConfig) return null

    switch (selectedStrategy) {
      case 'plan_execute':
        return (
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Max Iterations
              </label>
              <input
                type="number"
                min="1"
                max="10"
                value={tempConfig.max_iterations || 5}
                onChange={(e) => handleConfigChange('max_iterations', parseInt(e.target.value))}
                className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-transparent bg-white dark:bg-gray-800"
              />
              <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">
                Maximum number of planning iterations
              </p>
            </div>
            
            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Planning Depth
              </label>
              <select
                value={tempConfig.planning_depth || 3}
                onChange={(e) => handleConfigChange('planning_depth', parseInt(e.target.value))}
                className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-transparent bg-white dark:bg-gray-800"
              >
                <option value={1}>Shallow (1 level)</option>
                <option value={2}>Medium (2 levels)</option>
                <option value={3}>Deep (3 levels)</option>
                <option value={4}>Very Deep (4 levels)</option>
              </select>
            </div>
          </div>
        )
        
      case 'blogger':
        return (
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Content Length
              </label>
              <select
                value={tempConfig.content_length || 'medium'}
                onChange={(e) => handleConfigChange('content_length', e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-transparent bg-white dark:bg-gray-800"
              >
                <option value="short">Short (200-500 words)</option>
                <option value="medium">Medium (500-1000 words)</option>
                <option value="long">Long (1000-2000 words)</option>
                <option value="very_long">Very Long (2000+ words)</option>
              </select>
            </div>
            
            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Writing Style
              </label>
              <select
                value={tempConfig.writing_style || 'professional'}
                onChange={(e) => handleConfigChange('writing_style', e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-transparent bg-white dark:bg-gray-800"
              >
                <option value="casual">Casual</option>
                <option value="professional">Professional</option>
                <option value="academic">Academic</option>
                <option value="creative">Creative</option>
              </select>
            </div>
            
            <div className="flex items-center">
              <input
                type="checkbox"
                id="include_sources"
                checked={tempConfig.include_sources || false}
                onChange={(e) => handleConfigChange('include_sources', e.target.checked)}
                className="w-4 h-4 text-primary-600 border-gray-300 dark:border-gray-600 rounded focus:ring-primary-500"
              />
              <label htmlFor="include_sources" className="ml-2 text-sm text-gray-700 dark:text-gray-300">
                Include source citations
              </label>
            </div>
          </div>
        )
        
      case 'telegram_moderator':
        return (
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Moderation Level
              </label>
              <select
                value={tempConfig.moderation_level || 'moderate'}
                onChange={(e) => handleConfigChange('moderation_level', e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-transparent bg-white dark:bg-gray-800"
              >
                <option value="lenient">Lenient</option>
                <option value="moderate">Moderate</option>
                <option value="strict">Strict</option>
              </select>
            </div>
            
            <div className="flex items-center">
              <input
                type="checkbox"
                id="auto_respond"
                checked={tempConfig.auto_respond || false}
                onChange={(e) => handleConfigChange('auto_respond', e.target.checked)}
                className="w-4 h-4 text-primary-600 border-gray-300 dark:border-gray-600 rounded focus:ring-primary-500"
              />
              <label htmlFor="auto_respond" className="ml-2 text-sm text-gray-700 dark:text-gray-300">
                Auto-respond to violations
              </label>
            </div>
          </div>
        )
        
      default:
        return (
          <div className="text-center py-8 text-gray-500 dark:text-gray-400">
            <Settings className="h-12 w-12 mx-auto mb-2 opacity-50" />
            <p>No additional configuration required for this strategy.</p>
          </div>
        )
    }
  }

  return (
    <div className="space-y-8">
      {/* Basic Agent Information */}
      <div className="space-y-6">
        <div>
          <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">
            Basic Information
          </h3>
          
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Agent Name *
              </label>
              <input
                type="text"
                placeholder="My Awesome Agent"
                value={agentName}
                onChange={(e) => onBasicInfoChange(e.target.value, agentDescription)}
                className="w-full px-4 py-3 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-transparent bg-white dark:bg-gray-800"
              />
            </div>
            
            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Description *
              </label>
              <textarea
                placeholder="Brief description of what your agent does..."
                value={agentDescription}
                onChange={(e) => onBasicInfoChange(agentName, e.target.value)}
                rows={3}
                className="w-full px-4 py-3 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-transparent bg-white dark:bg-gray-800"
              />
            </div>
          </div>
        </div>
      </div>

      {/* Strategy Selection */}
      <div className="space-y-6">
        <div>
          <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-2">
            Choose Strategy *
          </h3>
          <p className="text-gray-600 dark:text-gray-400 mb-6">
            Select the reasoning approach that best matches your agent's purpose
          </p>
        </div>

        {isLoading ? (
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {Array.from({ length: 4 }).map((_, i) => (
              <div key={i} className="bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-xl p-6 animate-pulse">
                <div className="h-6 bg-gray-200 dark:bg-gray-700 rounded mb-4"></div>
                <div className="h-4 bg-gray-200 dark:bg-gray-700 rounded mb-2"></div>
                <div className="h-4 bg-gray-200 dark:bg-gray-700 rounded w-3/4"></div>
              </div>
            ))}
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {strategies?.map((strategy) => {
              const Icon = getStrategyIcon(strategy.name)
              const colorClass = getStrategyColor(strategy.name)
              const isSelected = selectedStrategy === strategy.name
              
              return (
                <motion.button
                  key={strategy.name}
                  onClick={() => handleStrategySelect(strategy.name)}
                  whileHover={{ scale: 1.02 }}
                  whileTap={{ scale: 0.98 }}
                  className={`text-left p-6 rounded-xl border-2 transition-all duration-200 ${
                    isSelected
                      ? 'border-primary-500 bg-primary-50 dark:bg-primary-900/20'
                      : 'border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800 hover:border-gray-300 dark:hover:border-gray-600'
                  }`}
                >
                  <div className="flex items-start justify-between mb-4">
                    <div className={`p-3 rounded-lg ${colorClass}`}>
                      <Icon className="h-6 w-6" />
                    </div>
                    
                    {isSelected && (
                      <CheckCircle className="h-6 w-6 text-primary-600 dark:text-primary-400" />
                    )}
                  </div>
                  
                  <h4 className="font-semibold text-gray-900 dark:text-white mb-2 capitalize">
                    {strategy.name.replace('_', ' ')}
                  </h4>
                  
                  <p className="text-sm text-gray-600 dark:text-gray-400 mb-4">
                    {STRATEGY_DESCRIPTIONS[strategy.name as keyof typeof STRATEGY_DESCRIPTIONS] || 
                     strategy.description || 
                     'A flexible strategy for various agent tasks.'}
                  </p>
                  
                  <div className="flex items-center text-primary-600 dark:text-primary-400 text-sm font-medium">
                    Learn more
                    <ChevronRight className="h-4 w-4 ml-1" />
                  </div>
                </motion.button>
              )
            })}
          </div>
        )}
      </div>

      {/* Strategy Configuration */}
      <AnimatePresence>
        {selectedStrategy && showConfig && (
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -20 }}
            className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-6"
          >
            <div className="flex items-center gap-3 mb-6">
              <div className={`p-2 rounded-lg ${getStrategyColor(selectedStrategy)}`}>
                {(() => {
                  const Icon = getStrategyIcon(selectedStrategy)
                  return <Icon className="h-5 w-5" />
                })()}
              </div>
              <div>
                <h4 className="font-semibold text-gray-900 dark:text-white">
                  Configure {selectedStrategy.replace('_', ' ')} Strategy
                </h4>
                <p className="text-sm text-gray-600 dark:text-gray-400">
                  Fine-tune the behavior of your selected strategy
                </p>
              </div>
            </div>
            
            {renderStrategyConfig()}
          </motion.div>
        )}
      </AnimatePresence>

      {/* Help Section */}
      <div className="bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded-xl p-6">
        <div className="flex items-start gap-3">
          <Info className="h-5 w-5 text-blue-600 dark:text-blue-400 mt-0.5 flex-shrink-0" />
          <div>
            <h4 className="font-medium text-blue-900 dark:text-blue-100 mb-2">
              Need help choosing a strategy?
            </h4>
            <div className="text-sm text-blue-800 dark:text-blue-200 space-y-1">
              <p>• <strong>Plan & Execute:</strong> Best for complex, multi-step tasks that require planning</p>
              <p>• <strong>Blogger:</strong> Ideal for content creation and writing tasks</p>
              <p>• <strong>Telegram Moderator:</strong> Perfect for chat moderation and communication</p>
              <p>• <strong>Adder:</strong> Great for simple computational and data processing tasks</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}