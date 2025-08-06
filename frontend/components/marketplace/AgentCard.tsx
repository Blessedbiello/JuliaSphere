'use client'

import { useState } from 'react'
import { motion } from 'framer-motion'
import { 
  Star, 
  Download, 
  Play, 
  Heart,
  ExternalLink,
  User,
  Zap,
  Clock,
  Tag,
  Shield,
  TrendingUp
} from 'lucide-react'
import { MarketplaceAgent } from '@/types'
import { api } from '@/lib/api'
import toast from 'react-hot-toast'

interface AgentCardProps {
  agent: MarketplaceAgent
  viewMode: 'grid' | 'list'
  onDeploy?: (agentId: string) => void
  onFavorite?: (agentId: string, favorited: boolean) => void
}

export function AgentCard({ agent, viewMode, onDeploy, onFavorite }: AgentCardProps) {
  const [isDeploying, setIsDeploying] = useState(false)
  const [isFavorited, setIsFavorited] = useState(false)

  const handleDeploy = async () => {
    if (isDeploying) return
    
    setIsDeploying(true)
    try {
      // TODO: Implement actual deployment
      await new Promise(resolve => setTimeout(resolve, 1000)) // Simulate API call
      toast.success(`${agent.name} deployed successfully!`)
      onDeploy?.(agent.id)
    } catch (error) {
      toast.error('Failed to deploy agent')
    } finally {
      setIsDeploying(false)
    }
  }

  const handleFavorite = () => {
    const newFavorited = !isFavorited
    setIsFavorited(newFavorited)
    onFavorite?.(agent.id, newFavorited)
    toast.success(newFavorited ? 'Added to favorites' : 'Removed from favorites')
  }

  const getStrategyIcon = (strategy: string) => {
    switch (strategy.toLowerCase()) {
      case 'plan_execute':
        return '💎'
      case 'adder':
        return '🔄'
      case 'blogger':
        return '📝'
      case 'telegram_moderator':
        return '📱'
      default:
        return '🤖'
    }
  }

  const getStrategyColor = (strategy: string) => {
    switch (strategy.toLowerCase()) {
      case 'plan_execute':
        return 'bg-purple-100 dark:bg-purple-900/20 text-purple-700 dark:text-purple-300'
      case 'adder':
        return 'bg-green-100 dark:bg-green-900/20 text-green-700 dark:text-green-300'
      case 'blogger':
        return 'bg-orange-100 dark:bg-orange-900/20 text-orange-700 dark:text-orange-300'
      case 'telegram_moderator':
        return 'bg-blue-100 dark:bg-blue-900/20 text-blue-700 dark:text-blue-300'
      default:
        return 'bg-gray-100 dark:bg-gray-700 text-gray-700 dark:text-gray-300'
    }
  }

  const getPricingDisplay = () => {
    if (agent.pricing.model === 'free') {
      return <span className="text-success-600 dark:text-success-400 font-medium">Free</span>
    }
    
    const amount = agent.pricing.amount || 0
    const currency = agent.pricing.currency
    
    switch (agent.pricing.model) {
      case 'one_time':
        return <span className="text-gray-900 dark:text-white font-medium">{currency} {amount}</span>
      case 'subscription':
        return <span className="text-gray-900 dark:text-white font-medium">{currency} {amount}/mo</span>
      case 'usage_based':
        return <span className="text-gray-900 dark:text-white font-medium">{currency} {amount}/use</span>
      default:
        return <span className="text-gray-600 dark:text-gray-400">Contact</span>
    }
  }

  if (viewMode === 'list') {
    return (
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        whileHover={{ y: -2 }}
        className="bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700 p-6 hover:shadow-md transition-all duration-200"
      >
        <div className="flex items-start gap-4">
          {/* Agent Image/Icon */}
          <div className="flex-shrink-0">
            {agent.featured_image_url ? (
              <img
                src={agent.featured_image_url}
                alt={agent.name}
                className="w-16 h-16 rounded-lg object-cover"
              />
            ) : (
              <div className={`w-16 h-16 rounded-lg flex items-center justify-center text-2xl ${getStrategyColor(agent.strategy)}`}>
                {getStrategyIcon(agent.strategy)}
              </div>
            )}
          </div>

          {/* Agent Info */}
          <div className="flex-1 min-w-0">
            <div className="flex items-start justify-between mb-2">
              <div>
                <h3 className="text-lg font-semibold text-gray-900 dark:text-white truncate">
                  {agent.name}
                  {agent.is_featured && (
                    <span className="ml-2 inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-yellow-100 dark:bg-yellow-900/20 text-yellow-700 dark:text-yellow-300">
                      Featured
                    </span>
                  )}
                </h3>
                <p className="text-sm text-gray-600 dark:text-gray-400 line-clamp-2 mt-1">
                  {agent.description}
                </p>
              </div>
              
              <div className="flex items-center gap-2 ml-4">
                <button
                  onClick={handleFavorite}
                  className={`p-2 rounded-lg transition-colors ${
                    isFavorited
                      ? 'text-red-500 bg-red-50 dark:bg-red-900/20'
                      : 'text-gray-400 hover:text-red-500 hover:bg-red-50 dark:hover:bg-red-900/20'
                  }`}
                >
                  <Heart className={`h-5 w-5 ${isFavorited ? 'fill-current' : ''}`} />
                </button>
                
                <button
                  onClick={handleDeploy}
                  disabled={isDeploying}
                  className="flex items-center gap-2 px-4 py-2 bg-primary-600 text-white rounded-lg hover:bg-primary-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
                >
                  {isDeploying ? (
                    <>
                      <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin" />
                      Deploying
                    </>
                  ) : (
                    <>
                      <Play className="h-4 w-4" />
                      Deploy
                    </>
                  )}
                </button>
              </div>
            </div>

            {/* Meta Info */}
            <div className="flex items-center gap-4 text-sm text-gray-600 dark:text-gray-400 mb-3">
              <div className="flex items-center gap-1">
                <User className="h-4 w-4" />
                {agent.creator.display_name || agent.creator.username}
              </div>
              
              <div className="flex items-center gap-1">
                <Star className="h-4 w-4 text-yellow-500" />
                {agent.stats.avg_rating.toFixed(1)} ({agent.stats.rating_count})
              </div>
              
              <div className="flex items-center gap-1">
                <Download className="h-4 w-4" />
                {agent.stats.deployments.toLocaleString()} deployments
              </div>
              
              <div className="flex items-center gap-1">
                <span className={`px-2 py-1 rounded-full text-xs font-medium ${getStrategyColor(agent.strategy)}`}>
                  {agent.strategy}
                </span>
              </div>
              
              <div className="ml-auto">
                {getPricingDisplay()}
              </div>
            </div>

            {/* Tags */}
            {agent.tags.length > 0 && (
              <div className="flex flex-wrap gap-1 mb-3">
                {agent.tags.slice(0, 4).map((tag, index) => (
                  <span
                    key={index}
                    className="inline-flex items-center px-2 py-1 rounded-full text-xs bg-gray-100 dark:bg-gray-700 text-gray-700 dark:text-gray-300"
                  >
                    {tag}
                  </span>
                ))}
                {agent.tags.length > 4 && (
                  <span className="text-xs text-gray-500">+{agent.tags.length - 4} more</span>
                )}
              </div>
            )}
          </div>
        </div>
      </motion.div>
    )
  }

  // Grid view
  return (
    <motion.div
      initial={{ opacity: 0, scale: 0.95 }}
      animate={{ opacity: 1, scale: 1 }}
      whileHover={{ y: -4, scale: 1.02 }}
      className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700 overflow-hidden hover:shadow-lg transition-all duration-200"
    >
      {/* Featured Badge */}
      {agent.is_featured && (
        <div className="relative">
          <div className="absolute top-3 left-3 z-10">
            <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-yellow-100 dark:bg-yellow-900/20 text-yellow-700 dark:text-yellow-300 border border-yellow-200 dark:border-yellow-800">
              <TrendingUp className="h-3 w-3 mr-1" />
              Featured
            </span>
          </div>
        </div>
      )}

      {/* Agent Image */}
      <div className="relative h-48 bg-gradient-to-br from-primary-50 to-secondary-50 dark:from-primary-900/20 dark:to-secondary-900/20">
        {agent.featured_image_url ? (
          <img
            src={agent.featured_image_url}
            alt={agent.name}
            className="w-full h-full object-cover"
          />
        ) : (
          <div className="w-full h-full flex items-center justify-center">
            <div className={`w-20 h-20 rounded-2xl flex items-center justify-center text-4xl ${getStrategyColor(agent.strategy)}`}>
              {getStrategyIcon(agent.strategy)}
            </div>
          </div>
        )}

        {/* Favorite Button */}
        <button
          onClick={handleFavorite}
          className={`absolute top-3 right-3 p-2 rounded-full backdrop-blur-sm transition-colors ${
            isFavorited
              ? 'text-red-500 bg-white/90 dark:bg-gray-800/90'
              : 'text-gray-400 bg-white/70 dark:bg-gray-800/70 hover:text-red-500'
          }`}
        >
          <Heart className={`h-4 w-4 ${isFavorited ? 'fill-current' : ''}`} />
        </button>
      </div>

      <div className="p-6">
        {/* Agent Title & Description */}
        <div className="mb-4">
          <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-2 line-clamp-1">
            {agent.name}
          </h3>
          <p className="text-sm text-gray-600 dark:text-gray-400 line-clamp-2">
            {agent.description}
          </p>
        </div>

        {/* Strategy & Category */}
        <div className="flex items-center gap-2 mb-4">
          <span className={`px-2 py-1 rounded-full text-xs font-medium ${getStrategyColor(agent.strategy)}`}>
            {agent.strategy}
          </span>
          {agent.category && (
            <span className="px-2 py-1 rounded-full text-xs font-medium bg-gray-100 dark:bg-gray-700 text-gray-700 dark:text-gray-300">
              {agent.category}
            </span>
          )}
        </div>

        {/* Stats */}
        <div className="flex items-center justify-between text-sm text-gray-600 dark:text-gray-400 mb-4">
          <div className="flex items-center gap-1">
            <Star className="h-4 w-4 text-yellow-500" />
            <span>{agent.stats.avg_rating.toFixed(1)}</span>
            <span className="text-gray-400">({agent.stats.rating_count})</span>
          </div>
          
          <div className="flex items-center gap-1">
            <Download className="h-4 w-4" />
            <span>{agent.stats.deployments.toLocaleString()}</span>
          </div>
        </div>

        {/* Creator */}
        <div className="flex items-center gap-2 text-sm text-gray-600 dark:text-gray-400 mb-4">
          <User className="h-4 w-4" />
          <span>by {agent.creator.display_name || agent.creator.username}</span>
        </div>

        {/* Tags */}
        {agent.tags.length > 0 && (
          <div className="flex flex-wrap gap-1 mb-4">
            {agent.tags.slice(0, 3).map((tag, index) => (
              <span
                key={index}
                className="inline-flex items-center px-2 py-1 rounded-full text-xs bg-gray-100 dark:bg-gray-700 text-gray-700 dark:text-gray-300"
              >
                <Tag className="h-3 w-3 mr-1" />
                {tag}
              </span>
            ))}
            {agent.tags.length > 3 && (
              <span className="text-xs text-gray-500">+{agent.tags.length - 3}</span>
            )}
          </div>
        )}

        {/* Price & Deploy */}
        <div className="flex items-center justify-between pt-4 border-t border-gray-200 dark:border-gray-700">
          <div className="text-lg font-semibold">
            {getPricingDisplay()}
          </div>
          
          <button
            onClick={handleDeploy}
            disabled={isDeploying}
            className="flex items-center gap-2 px-4 py-2 bg-primary-600 text-white rounded-lg hover:bg-primary-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
          >
            {isDeploying ? (
              <>
                <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin" />
                Deploying
              </>
            ) : (
              <>
                <Play className="h-4 w-4" />
                Deploy
              </>
            )}
          </button>
        </div>
      </div>
    </motion.div>
  )
}