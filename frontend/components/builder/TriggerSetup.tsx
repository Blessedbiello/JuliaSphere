'use client'

import { useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { 
  Clock, 
  Zap, 
  Globe, 
  PlayCircle,
  Calendar,
  Webhook,
  Database,
  MessageSquare,
  Info,
  ChevronRight,
  CheckCircle
} from 'lucide-react'

interface TriggerSetupProps {
  triggerType: string
  triggerParams: Record<string, any>
  onTriggerChange: (triggerType: string, triggerParams: Record<string, any>) => void
}

const TRIGGER_TYPES = [
  {
    id: 'manual',
    name: 'Manual',
    description: 'Start the agent manually when needed',
    icon: PlayCircle,
    color: 'text-blue-600 dark:text-blue-400 bg-blue-100 dark:bg-blue-900/20',
    useCase: 'Perfect for testing and on-demand execution',
  },
  {
    id: 'schedule',
    name: 'Schedule',
    description: 'Run on a recurring schedule (cron-like)',
    icon: Clock,
    color: 'text-green-600 dark:text-green-400 bg-green-100 dark:bg-green-900/20',
    useCase: 'Great for regular maintenance or monitoring tasks',
  },
  {
    id: 'webhook',
    name: 'Webhook',
    description: 'Trigger via HTTP webhook calls',
    icon: Webhook,
    color: 'text-purple-600 dark:text-purple-400 bg-purple-100 dark:bg-purple-900/20',
    useCase: 'Ideal for integrating with external systems',
  },
  {
    id: 'telegram',
    name: 'Telegram',
    description: 'Respond to Telegram messages',
    icon: MessageSquare,
    color: 'text-cyan-600 dark:text-cyan-400 bg-cyan-100 dark:bg-cyan-900/20',
    useCase: 'Perfect for chat bots and interactive agents',
  },
  {
    id: 'database',
    name: 'Database Change',
    description: 'React to database changes',
    icon: Database,
    color: 'text-orange-600 dark:text-orange-400 bg-orange-100 dark:bg-orange-900/20',
    useCase: 'Useful for data processing workflows',
  },
]

const SCHEDULE_PRESETS = [
  { label: 'Every minute', value: '* * * * *' },
  { label: 'Every 5 minutes', value: '*/5 * * * *' },
  { label: 'Every hour', value: '0 * * * *' },
  { label: 'Every day at 9 AM', value: '0 9 * * *' },
  { label: 'Every Monday at 10 AM', value: '0 10 * * 1' },
  { label: 'Every 1st of month', value: '0 0 1 * *' },
]

export function TriggerSetup({ triggerType, triggerParams, onTriggerChange }: TriggerSetupProps) {
  const [showAdvanced, setShowAdvanced] = useState(false)

  const handleTriggerSelect = (type: string) => {
    const defaultParams = getDefaultParams(type)
    onTriggerChange(type, defaultParams)
  }

  const handleParamChange = (key: string, value: any) => {
    onTriggerChange(triggerType, { ...triggerParams, [key]: value })
  }

  const getDefaultParams = (type: string): Record<string, any> => {
    switch (type) {
      case 'manual':
        return {}
      case 'schedule':
        return {
          cron_expression: '0 9 * * *',
          timezone: 'UTC',
          enabled: true,
        }
      case 'webhook':
        return {
          endpoint_path: '/webhook',
          authentication: 'none',
          allowed_ips: [],
          timeout: 30,
        }
      case 'telegram':
        return {
          bot_token: '',
          allowed_users: [],
          command_prefix: '/',
          respond_to_all: false,
        }
      case 'database':
        return {
          connection_string: '',
          table_name: '',
          operation: 'INSERT',
          polling_interval: 30,
        }
      default:
        return {}
    }
  }

  const renderTriggerConfig = () => {
    if (!triggerType) return null

    switch (triggerType) {
      case 'manual':
        return (
          <div className="text-center py-8">
            <PlayCircle className="h-16 w-16 text-blue-500 mx-auto mb-4" />
            <h4 className="text-lg font-medium text-gray-900 dark:text-white mb-2">
              Manual Trigger
            </h4>
            <p className="text-gray-600 dark:text-gray-400">
              Your agent will run when you start it manually. Perfect for testing and on-demand execution.
            </p>
          </div>
        )

      case 'schedule':
        return (
          <div className="space-y-6">
            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Schedule Preset
              </label>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-2 mb-4">
                {SCHEDULE_PRESETS.map((preset) => (
                  <button
                    key={preset.value}
                    onClick={() => handleParamChange('cron_expression', preset.value)}
                    className={`text-left px-3 py-2 text-sm rounded-lg border transition-colors ${
                      triggerParams.cron_expression === preset.value
                        ? 'border-primary-500 bg-primary-50 dark:bg-primary-900/20 text-primary-700 dark:text-primary-300'
                        : 'border-gray-300 dark:border-gray-600 hover:border-gray-400 dark:hover:border-gray-500'
                    }`}
                  >
                    {preset.label}
                  </button>
                ))}
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Custom Cron Expression
              </label>
              <input
                type="text"
                placeholder="0 9 * * *"
                value={triggerParams.cron_expression || ''}
                onChange={(e) => handleParamChange('cron_expression', e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-primary-500 bg-white dark:bg-gray-800"
              />
              <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">
                Format: minute hour day month day-of-week
              </p>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Timezone
              </label>
              <select
                value={triggerParams.timezone || 'UTC'}
                onChange={(e) => handleParamChange('timezone', e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-primary-500 bg-white dark:bg-gray-800"
              >
                <option value="UTC">UTC</option>
                <option value="America/New_York">Eastern Time</option>
                <option value="America/Los_Angeles">Pacific Time</option>
                <option value="Europe/London">London</option>
                <option value="Europe/Paris">Paris</option>
                <option value="Asia/Tokyo">Tokyo</option>
              </select>
            </div>

            <div className="flex items-center">
              <input
                type="checkbox"
                id="schedule_enabled"
                checked={triggerParams.enabled || false}
                onChange={(e) => handleParamChange('enabled', e.target.checked)}
                className="w-4 h-4 text-primary-600 border-gray-300 dark:border-gray-600 rounded focus:ring-primary-500"
              />
              <label htmlFor="schedule_enabled" className="ml-2 text-sm text-gray-700 dark:text-gray-300">
                Enable scheduled execution
              </label>
            </div>
          </div>
        )

      case 'webhook':
        return (
          <div className="space-y-6">
            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Webhook Endpoint Path
              </label>
              <div className="flex">
                <span className="inline-flex items-center px-3 py-2 border border-r-0 border-gray-300 dark:border-gray-600 bg-gray-50 dark:bg-gray-700 text-gray-500 dark:text-gray-400 text-sm rounded-l-lg">
                  https://api.juliasphere.com
                </span>
                <input
                  type="text"
                  placeholder="/webhook/my-agent"
                  value={triggerParams.endpoint_path || ''}
                  onChange={(e) => handleParamChange('endpoint_path', e.target.value)}
                  className="flex-1 px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-r-lg focus:ring-2 focus:ring-primary-500 bg-white dark:bg-gray-800"
                />
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Authentication
              </label>
              <select
                value={triggerParams.authentication || 'none'}
                onChange={(e) => handleParamChange('authentication', e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-primary-500 bg-white dark:bg-gray-800"
              >
                <option value="none">No Authentication</option>
                <option value="api_key">API Key</option>
                <option value="bearer_token">Bearer Token</option>
                <option value="hmac">HMAC Signature</option>
              </select>
            </div>

            {triggerParams.authentication !== 'none' && (
              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                  {triggerParams.authentication === 'api_key' ? 'API Key' : 
                   triggerParams.authentication === 'bearer_token' ? 'Bearer Token' : 'HMAC Secret'}
                </label>
                <input
                  type="password"
                  placeholder="Enter your authentication credential"
                  value={triggerParams.auth_credential || ''}
                  onChange={(e) => handleParamChange('auth_credential', e.target.value)}
                  className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-primary-500 bg-white dark:bg-gray-800"
                />
              </div>
            )}

            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Timeout (seconds)
              </label>
              <input
                type="number"
                min="1"
                max="300"
                value={triggerParams.timeout || 30}
                onChange={(e) => handleParamChange('timeout', parseInt(e.target.value))}
                className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-primary-500 bg-white dark:bg-gray-800"
              />
            </div>
          </div>
        )

      case 'telegram':
        return (
          <div className="space-y-6">
            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Bot Token *
              </label>
              <input
                type="password"
                placeholder="Enter your Telegram bot token"
                value={triggerParams.bot_token || ''}
                onChange={(e) => handleParamChange('bot_token', e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-primary-500 bg-white dark:bg-gray-800"
              />
              <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">
                Get this from @BotFather on Telegram
              </p>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Allowed Users (User IDs)
              </label>
              <input
                type="text"
                placeholder="123456789, 987654321"
                value={triggerParams.allowed_users?.join(', ') || ''}
                onChange={(e) => handleParamChange('allowed_users', 
                  e.target.value.split(',').map(id => id.trim()).filter(Boolean)
                )}
                className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-primary-500 bg-white dark:bg-gray-800"
              />
              <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">
                Leave empty to allow all users
              </p>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Command Prefix
              </label>
              <input
                type="text"
                placeholder="/"
                value={triggerParams.command_prefix || '/'}
                onChange={(e) => handleParamChange('command_prefix', e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-primary-500 bg-white dark:bg-gray-800"
              />
            </div>

            <div className="flex items-center">
              <input
                type="checkbox"
                id="respond_to_all"
                checked={triggerParams.respond_to_all || false}
                onChange={(e) => handleParamChange('respond_to_all', e.target.checked)}
                className="w-4 h-4 text-primary-600 border-gray-300 dark:border-gray-600 rounded focus:ring-primary-500"
              />
              <label htmlFor="respond_to_all" className="ml-2 text-sm text-gray-700 dark:text-gray-300">
                Respond to all messages (not just commands)
              </label>
            </div>
          </div>
        )

      case 'database':
        return (
          <div className="space-y-6">
            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Database Connection String *
              </label>
              <input
                type="password"
                placeholder="postgresql://user:pass@host:port/db"
                value={triggerParams.connection_string || ''}
                onChange={(e) => handleParamChange('connection_string', e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-primary-500 bg-white dark:bg-gray-800"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Table Name *
              </label>
              <input
                type="text"
                placeholder="my_table"
                value={triggerParams.table_name || ''}
                onChange={(e) => handleParamChange('table_name', e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-primary-500 bg-white dark:bg-gray-800"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Operation to Monitor
              </label>
              <select
                value={triggerParams.operation || 'INSERT'}
                onChange={(e) => handleParamChange('operation', e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-primary-500 bg-white dark:bg-gray-800"
              >
                <option value="INSERT">INSERT</option>
                <option value="UPDATE">UPDATE</option>
                <option value="DELETE">DELETE</option>
                <option value="ANY">Any Change</option>
              </select>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Polling Interval (seconds)
              </label>
              <input
                type="number"
                min="5"
                max="3600"
                value={triggerParams.polling_interval || 30}
                onChange={(e) => handleParamChange('polling_interval', parseInt(e.target.value))}
                className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-primary-500 bg-white dark:bg-gray-800"
              />
            </div>
          </div>
        )

      default:
        return null
    }
  }

  return (
    <div className="space-y-8">
      {/* Trigger Type Selection */}
      <div>
        <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-2">
          Choose Trigger Type *
        </h3>
        <p className="text-gray-600 dark:text-gray-400 mb-6">
          Select when and how your agent should be activated
        </p>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {TRIGGER_TYPES.map((trigger) => {
            const Icon = trigger.icon
            const isSelected = triggerType === trigger.id
            
            return (
              <motion.button
                key={trigger.id}
                onClick={() => handleTriggerSelect(trigger.id)}
                whileHover={{ scale: 1.02 }}
                whileTap={{ scale: 0.98 }}
                className={`text-left p-6 rounded-xl border-2 transition-all duration-200 ${
                  isSelected
                    ? 'border-primary-500 bg-primary-50 dark:bg-primary-900/20'
                    : 'border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800 hover:border-gray-300 dark:hover:border-gray-600'
                }`}
              >
                <div className="flex items-start justify-between mb-4">
                  <div className={`p-3 rounded-lg ${trigger.color}`}>
                    <Icon className="h-6 w-6" />
                  </div>
                  
                  {isSelected && (
                    <CheckCircle className="h-6 w-6 text-primary-600 dark:text-primary-400" />
                  )}
                </div>
                
                <h4 className="font-semibold text-gray-900 dark:text-white mb-2">
                  {trigger.name}
                </h4>
                
                <p className="text-sm text-gray-600 dark:text-gray-400 mb-3">
                  {trigger.description}
                </p>
                
                <p className="text-xs text-gray-500 dark:text-gray-400 mb-4">
                  {trigger.useCase}
                </p>
                
                <div className="flex items-center text-primary-600 dark:text-primary-400 text-sm font-medium">
                  Configure
                  <ChevronRight className="h-4 w-4 ml-1" />
                </div>
              </motion.button>
            )
          })}
        </div>
      </div>

      {/* Trigger Configuration */}
      <AnimatePresence>
        {triggerType && (
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -20 }}
            className="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 p-6"
          >
            <div className="flex items-center gap-3 mb-6">
              <div className={TRIGGER_TYPES.find(t => t.id === triggerType)?.color}>
                {(() => {
                  const trigger = TRIGGER_TYPES.find(t => t.id === triggerType)
                  if (!trigger) return null
                  const Icon = trigger.icon
                  return <Icon className="h-6 w-6" />
                })()}
              </div>
              <div>
                <h4 className="font-semibold text-gray-900 dark:text-white">
                  {TRIGGER_TYPES.find(t => t.id === triggerType)?.name} Configuration
                </h4>
                <p className="text-sm text-gray-600 dark:text-gray-400">
                  Set up the parameters for your trigger
                </p>
              </div>
            </div>
            
            {renderTriggerConfig()}
          </motion.div>
        )}
      </AnimatePresence>

      {/* Help Section */}
      <div className="bg-indigo-50 dark:bg-indigo-900/20 border border-indigo-200 dark:border-indigo-800 rounded-xl p-6">
        <div className="flex items-start gap-3">
          <Info className="h-5 w-5 text-indigo-600 dark:text-indigo-400 mt-0.5 flex-shrink-0" />
          <div>
            <h4 className="font-medium text-indigo-900 dark:text-indigo-100 mb-2">
              Trigger Selection Guide
            </h4>
            <div className="text-sm text-indigo-800 dark:text-indigo-200 space-y-1">
              <p>• <strong>Manual:</strong> Best for testing and development</p>
              <p>• <strong>Schedule:</strong> Great for automated maintenance and reports</p>
              <p>• <strong>Webhook:</strong> Perfect for integrations with external services</p>
              <p>• <strong>Telegram:</strong> Ideal for interactive chat bots</p>
              <p>• <strong>Database:</strong> Useful for real-time data processing</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}