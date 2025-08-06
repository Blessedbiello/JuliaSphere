'use client'

import { useState } from 'react'
import { useQuery } from 'react-query'
import { motion, AnimatePresence } from 'framer-motion'
import { 
  Plus, 
  Trash2, 
  Settings,
  Search,
  Globe,
  FileText,
  MessageSquare,
  Calculator,
  Database,
  Image,
  Code,
  ChevronDown,
  ChevronUp,
  Info,
  CheckCircle
} from 'lucide-react'
import { api } from '@/lib/api'
import { Tool, ToolSummary } from '@/types'

interface ToolConfiguratorProps {
  selectedTools: Tool[]
  onToolsChange: (tools: Tool[]) => void
}

const TOOL_ICONS: Record<string, any> = {
  web_search: Globe,
  file_reader: FileText,
  telegram_bot: MessageSquare,
  calculator: Calculator,
  database_query: Database,
  image_generator: Image,
  code_executor: Code,
  default: Settings,
}

const TOOL_CATEGORIES = {
  'Communication': ['telegram_bot', 'email_sender', 'slack_bot'],
  'Data & Analysis': ['database_query', 'csv_reader', 'json_parser', 'calculator'],
  'Web & APIs': ['web_search', 'api_client', 'web_scraper'],
  'Content': ['file_reader', 'text_generator', 'image_generator', 'pdf_creator'],
  'Development': ['code_executor', 'git_client', 'docker_runner'],
}

export function ToolConfigurator({ selectedTools, onToolsChange }: ToolConfiguratorProps) {
  const [searchQuery, setSearchQuery] = useState('')
  const [selectedCategory, setSelectedCategory] = useState<string | null>(null)
  const [expandedTool, setExpandedTool] = useState<string | null>(null)

  // Fetch available tools
  const { data: availableTools, isLoading } = useQuery<ToolSummary[]>(
    'tools',
    () => api.general.getTools().then(res => res.data),
    {
      onSuccess: (data) => {
        console.log('Available tools:', data)
      }
    }
  )

  const handleAddTool = (toolName: string) => {
    if (selectedTools.some(tool => tool.name === toolName)) {
      return // Tool already added
    }

    const newTool: Tool = {
      name: toolName,
      config: getDefaultToolConfig(toolName),
    }

    onToolsChange([...selectedTools, newTool])
    setExpandedTool(toolName)
  }

  const handleRemoveTool = (toolName: string) => {
    onToolsChange(selectedTools.filter(tool => tool.name !== toolName))
    if (expandedTool === toolName) {
      setExpandedTool(null)
    }
  }

  const handleToolConfigChange = (toolName: string, config: Record<string, any>) => {
    onToolsChange(
      selectedTools.map(tool => 
        tool.name === toolName ? { ...tool, config } : tool
      )
    )
  }

  const getDefaultToolConfig = (toolName: string): Record<string, any> => {
    switch (toolName) {
      case 'web_search':
        return {
          search_engine: 'google',
          max_results: 10,
          safe_search: true,
        }
      case 'telegram_bot':
        return {
          bot_token: '',
          chat_id: '',
          parse_mode: 'HTML',
        }
      case 'database_query':
        return {
          connection_string: '',
          query_timeout: 30,
          max_rows: 1000,
        }
      case 'file_reader':
        return {
          supported_formats: ['txt', 'md', 'json', 'csv'],
          max_file_size: '10MB',
          encoding: 'utf-8',
        }
      case 'calculator':
        return {
          precision: 10,
          angle_unit: 'radians',
          allow_variables: true,
        }
      default:
        return {}
    }
  }

  const getToolIcon = (toolName: string) => {
    return TOOL_ICONS[toolName] || TOOL_ICONS.default
  }

  const getToolDescription = (toolName: string, toolData?: ToolSummary) => {
    if (toolData?.metadata?.description) {
      return toolData.metadata.description
    }
    
    const descriptions: Record<string, string> = {
      web_search: 'Search the web for information and retrieve relevant results',
      telegram_bot: 'Send messages and interact with Telegram chats',
      database_query: 'Execute queries against SQL databases',
      file_reader: 'Read and process various file formats',
      calculator: 'Perform mathematical calculations and operations',
      image_generator: 'Generate images using AI models',
      code_executor: 'Execute code in various programming languages',
    }
    
    return descriptions[toolName] || 'A useful tool for your agent'
  }

  const renderToolConfig = (tool: Tool) => {
    const Icon = getToolIcon(tool.name)
    
    return (
      <motion.div
        key={tool.name}
        initial={{ opacity: 0, y: 10 }}
        animate={{ opacity: 1, y: 0 }}
        className="bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg overflow-hidden"
      >
        <div className="flex items-center justify-between p-4 border-b border-gray-200 dark:border-gray-700">
          <div className="flex items-center gap-3">
            <div className="p-2 bg-primary-100 dark:bg-primary-900/20 text-primary-600 dark:text-primary-400 rounded-lg">
              <Icon className="h-5 w-5" />
            </div>
            <div>
              <h4 className="font-medium text-gray-900 dark:text-white">
                {tool.name.replace('_', ' ').replace(/\b\w/g, l => l.toUpperCase())}
              </h4>
              <p className="text-sm text-gray-600 dark:text-gray-400">
                {getToolDescription(tool.name)}
              </p>
            </div>
          </div>
          
          <div className="flex items-center gap-2">
            <button
              onClick={() => setExpandedTool(expandedTool === tool.name ? null : tool.name)}
              className="p-2 text-gray-400 hover:text-gray-600 dark:hover:text-gray-200 transition-colors"
            >
              {expandedTool === tool.name ? (
                <ChevronUp className="h-4 w-4" />
              ) : (
                <ChevronDown className="h-4 w-4" />
              )}
            </button>
            <button
              onClick={() => handleRemoveTool(tool.name)}
              className="p-2 text-red-400 hover:text-red-600 dark:hover:text-red-300 transition-colors"
            >
              <Trash2 className="h-4 w-4" />
            </button>
          </div>
        </div>

        <AnimatePresence>
          {expandedTool === tool.name && (
            <motion.div
              initial={{ height: 0, opacity: 0 }}
              animate={{ height: 'auto', opacity: 1 }}
              exit={{ height: 0, opacity: 0 }}
              className="overflow-hidden"
            >
              <div className="p-4 space-y-4">
                {renderToolSpecificConfig(tool)}
              </div>
            </motion.div>
          )}
        </AnimatePresence>
      </motion.div>
    )
  }

  const renderToolSpecificConfig = (tool: Tool) => {
    const handleConfigChange = (key: string, value: any) => {
      handleToolConfigChange(tool.name, { ...tool.config, [key]: value })
    }

    switch (tool.name) {
      case 'web_search':
        return (
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Search Engine
              </label>
              <select
                value={tool.config.search_engine || 'google'}
                onChange={(e) => handleConfigChange('search_engine', e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-primary-500 bg-white dark:bg-gray-800"
              >
                <option value="google">Google</option>
                <option value="bing">Bing</option>
                <option value="duckduckgo">DuckDuckGo</option>
              </select>
            </div>
            
            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Max Results
              </label>
              <input
                type="number"
                min="1"
                max="50"
                value={tool.config.max_results || 10}
                onChange={(e) => handleConfigChange('max_results', parseInt(e.target.value))}
                className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-primary-500 bg-white dark:bg-gray-800"
              />
            </div>
            
            <div className="md:col-span-2">
              <label className="flex items-center">
                <input
                  type="checkbox"
                  checked={tool.config.safe_search || false}
                  onChange={(e) => handleConfigChange('safe_search', e.target.checked)}
                  className="w-4 h-4 text-primary-600 border-gray-300 dark:border-gray-600 rounded focus:ring-primary-500"
                />
                <span className="ml-2 text-sm text-gray-700 dark:text-gray-300">
                  Enable safe search
                </span>
              </label>
            </div>
          </div>
        )

      case 'telegram_bot':
        return (
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Bot Token *
              </label>
              <input
                type="password"
                placeholder="Enter your Telegram bot token"
                value={tool.config.bot_token || ''}
                onChange={(e) => handleConfigChange('bot_token', e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-primary-500 bg-white dark:bg-gray-800"
              />
            </div>
            
            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Default Chat ID
              </label>
              <input
                type="text"
                placeholder="Chat ID or @username"
                value={tool.config.chat_id || ''}
                onChange={(e) => handleConfigChange('chat_id', e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-primary-500 bg-white dark:bg-gray-800"
              />
            </div>
          </div>
        )

      case 'database_query':
        return (
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                Connection String *
              </label>
              <input
                type="password"
                placeholder="postgresql://user:pass@host:port/db"
                value={tool.config.connection_string || ''}
                onChange={(e) => handleConfigChange('connection_string', e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-primary-500 bg-white dark:bg-gray-800"
              />
            </div>
            
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                  Query Timeout (seconds)
                </label>
                <input
                  type="number"
                  min="1"
                  max="300"
                  value={tool.config.query_timeout || 30}
                  onChange={(e) => handleConfigChange('query_timeout', parseInt(e.target.value))}
                  className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-primary-500 bg-white dark:bg-gray-800"
                />
              </div>
              
              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                  Max Rows
                </label>
                <input
                  type="number"
                  min="1"
                  max="10000"
                  value={tool.config.max_rows || 1000}
                  onChange={(e) => handleConfigChange('max_rows', parseInt(e.target.value))}
                  className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-primary-500 bg-white dark:bg-gray-800"
                />
              </div>
            </div>
          </div>
        )

      default:
        return (
          <div className="text-center py-8 text-gray-500 dark:text-gray-400">
            <Settings className="h-12 w-12 mx-auto mb-2 opacity-50" />
            <p>No additional configuration required for this tool.</p>
          </div>
        )
    }
  }

  const filteredTools = availableTools?.filter(tool => {
    const matchesSearch = tool.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
                         getToolDescription(tool.name, tool).toLowerCase().includes(searchQuery.toLowerCase())
    
    const matchesCategory = !selectedCategory || 
                           TOOL_CATEGORIES[selectedCategory]?.includes(tool.name)
    
    return matchesSearch && matchesCategory
  }) || []

  return (
    <div className="space-y-8">
      {/* Selected Tools */}
      <div>
        <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">
          Selected Tools ({selectedTools.length})
        </h3>
        
        {selectedTools.length > 0 ? (
          <div className="space-y-4">
            {selectedTools.map(tool => renderToolConfig(tool))}
          </div>
        ) : (
          <div className="bg-gray-50 dark:bg-gray-800 border-2 border-dashed border-gray-300 dark:border-gray-600 rounded-lg p-8 text-center">
            <Settings className="h-12 w-12 text-gray-400 mx-auto mb-4" />
            <h4 className="text-lg font-medium text-gray-900 dark:text-white mb-2">
              No tools selected
            </h4>
            <p className="text-gray-600 dark:text-gray-400">
              Add tools from the available options below to give your agent capabilities.
            </p>
          </div>
        )}
      </div>

      {/* Available Tools */}
      <div>
        <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">
          Available Tools
        </h3>
        
        {/* Search and Filter */}
        <div className="flex flex-col sm:flex-row gap-4 mb-6">
          <div className="flex-1">
            <div className="relative">
              <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-gray-400" />
              <input
                type="text"
                placeholder="Search tools..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="w-full pl-10 pr-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-primary-500 bg-white dark:bg-gray-800"
              />
            </div>
          </div>
          
          <div className="flex gap-2 overflow-x-auto">
            <button
              onClick={() => setSelectedCategory(null)}
              className={`px-3 py-2 text-sm rounded-lg whitespace-nowrap transition-colors ${
                selectedCategory === null
                  ? 'bg-primary-100 dark:bg-primary-900/20 text-primary-700 dark:text-primary-300'
                  : 'bg-gray-100 dark:bg-gray-700 text-gray-700 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-600'
              }`}
            >
              All
            </button>
            {Object.keys(TOOL_CATEGORIES).map(category => (
              <button
                key={category}
                onClick={() => setSelectedCategory(category)}
                className={`px-3 py-2 text-sm rounded-lg whitespace-nowrap transition-colors ${
                  selectedCategory === category
                    ? 'bg-primary-100 dark:bg-primary-900/20 text-primary-700 dark:text-primary-300'
                    : 'bg-gray-100 dark:bg-gray-700 text-gray-700 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-gray-600'
                }`}
              >
                {category}
              </button>
            ))}
          </div>
        </div>

        {/* Tools Grid */}
        {isLoading ? (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {Array.from({ length: 6 }).map((_, i) => (
              <div key={i} className="bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg p-4 animate-pulse">
                <div className="h-6 bg-gray-200 dark:bg-gray-700 rounded mb-2"></div>
                <div className="h-4 bg-gray-200 dark:bg-gray-700 rounded mb-4"></div>
                <div className="h-8 bg-gray-200 dark:bg-gray-700 rounded"></div>
              </div>
            ))}
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            <AnimatePresence>
              {filteredTools.map((tool) => {
                const Icon = getToolIcon(tool.name)
                const isSelected = selectedTools.some(t => t.name === tool.name)
                
                return (
                  <motion.div
                    key={tool.name}
                    initial={{ opacity: 0, scale: 0.95 }}
                    animate={{ opacity: 1, scale: 1 }}
                    exit={{ opacity: 0, scale: 0.95 }}
                    className={`bg-white dark:bg-gray-800 border rounded-lg p-4 transition-all duration-200 ${
                      isSelected 
                        ? 'border-primary-500 bg-primary-50 dark:bg-primary-900/20'
                        : 'border-gray-200 dark:border-gray-700 hover:border-gray-300 dark:hover:border-gray-600'
                    }`}
                  >
                    <div className="flex items-start justify-between mb-3">
                      <div className="p-2 bg-gray-100 dark:bg-gray-700 rounded-lg">
                        <Icon className="h-5 w-5 text-gray-600 dark:text-gray-400" />
                      </div>
                      
                      {isSelected && (
                        <CheckCircle className="h-5 w-5 text-primary-600 dark:text-primary-400" />
                      )}
                    </div>
                    
                    <h4 className="font-medium text-gray-900 dark:text-white mb-2">
                      {tool.name.replace('_', ' ').replace(/\b\w/g, l => l.toUpperCase())}
                    </h4>
                    
                    <p className="text-sm text-gray-600 dark:text-gray-400 mb-4 line-clamp-2">
                      {getToolDescription(tool.name, tool)}
                    </p>
                    
                    <button
                      onClick={() => isSelected ? handleRemoveTool(tool.name) : handleAddTool(tool.name)}
                      disabled={isSelected}
                      className={`w-full flex items-center justify-center gap-2 px-3 py-2 text-sm rounded-lg transition-colors ${
                        isSelected
                          ? 'bg-gray-100 dark:bg-gray-700 text-gray-500 dark:text-gray-400 cursor-not-allowed'
                          : 'bg-primary-600 text-white hover:bg-primary-700'
                      }`}
                    >
                      {isSelected ? (
                        <>
                          <CheckCircle className="h-4 w-4" />
                          Added
                        </>
                      ) : (
                        <>
                          <Plus className="h-4 w-4" />
                          Add Tool
                        </>
                      )}
                    </button>
                  </motion.div>
                )
              })}
            </AnimatePresence>
          </div>
        )}
      </div>

      {/* Help Section */}
      <div className="bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800 rounded-xl p-6">
        <div className="flex items-start gap-3">
          <Info className="h-5 w-5 text-amber-600 dark:text-amber-400 mt-0.5 flex-shrink-0" />
          <div>
            <h4 className="font-medium text-amber-900 dark:text-amber-100 mb-2">
              Tool Selection Tips
            </h4>
            <div className="text-sm text-amber-800 dark:text-amber-200 space-y-1">
              <p>• Start with 1-3 tools to keep your agent focused and efficient</p>
              <p>• Choose tools that match your agent's primary purpose</p>
              <p>• Configure tools carefully - incorrect settings can cause failures</p>
              <p>• You can always add or remove tools later after testing</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}