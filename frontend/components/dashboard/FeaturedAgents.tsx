'use client'

import { useQuery } from 'react-query'
import { motion } from 'framer-motion'
import { Star, TrendingUp, Users, ExternalLink } from 'lucide-react'
import Link from 'next/link'
import { apiClient } from '@/lib/api'

interface FeaturedAgent {
  id: string
  name: string
  description: string
  strategy: string
  category: string
  tags: string[]
  pricing: {
    model: string
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
    display_name: string
  }
  featured_image_url: string | null
  is_featured: boolean
}

export function FeaturedAgents() {
  const { data: agents, isLoading, error } = useQuery<FeaturedAgent[]>(
    'featuredAgents',
    () => apiClient.get('/marketplace/agents?featured_only=true&limit=6').then(res => res.data),
    {
      refetchInterval: 60000, // Refresh every minute
    }
  )

  if (isLoading) {
    return (
      <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700 p-6">
        <div className="flex items-center justify-between mb-6">
          <h2 className="text-lg font-semibold text-gray-900 dark:text-white">
            Featured Agents
          </h2>
        </div>
        <div className="space-y-4">
          {[...Array(3)].map((_, i) => (
            <div key={i} className="animate-pulse">
              <div className="flex items-center space-x-4">
                <div className="h-12 w-12 bg-gray-200 dark:bg-gray-700 rounded-lg"></div>
                <div className="flex-1">
                  <div className="h-4 bg-gray-200 dark:bg-gray-700 rounded w-3/4 mb-2"></div>
                  <div className="h-3 bg-gray-200 dark:bg-gray-700 rounded w-1/2"></div>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    )
  }

  if (error || !agents) {
    return (
      <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700 p-6">
        <h2 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">
          Featured Agents
        </h2>
        <div className="bg-error-50 dark:bg-error-900/20 border border-error-200 dark:border-error-800 rounded-lg p-4">
          <p className="text-error-600 dark:text-error-400 text-sm">
            Failed to load featured agents
          </p>
        </div>
      </div>
    )
  }

  return (
    <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700 p-6">
      <div className="flex items-center justify-between mb-6">
        <h2 className="text-lg font-semibold text-gray-900 dark:text-white">
          Featured Agents
        </h2>
        <Link
          href="/marketplace?featured=true"
          className="text-primary-600 dark:text-primary-400 hover:text-primary-700 dark:hover:text-primary-300 text-sm font-medium flex items-center gap-1"
        >
          View all
          <ExternalLink className="h-3 w-3" />
        </Link>
      </div>

      <div className="space-y-4">
        {agents.slice(0, 4).map((agent, index) => (
          <motion.div
            key={agent.id}
            initial={{ opacity: 0, x: -20 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ duration: 0.4, delay: index * 0.1 }}
          >
            <Link
              href={`/marketplace/agents/${agent.id}`}
              className="block group"
            >
              <div className="flex items-center space-x-4 p-3 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-700/50 transition-colors">
                {/* Agent Icon */}
                <div className="flex-shrink-0">
                  {agent.featured_image_url ? (
                    <img
                      src={agent.featured_image_url}
                      alt={agent.name}
                      className="h-12 w-12 rounded-lg object-cover"
                    />
                  ) : (
                    <div className="h-12 w-12 bg-gradient-to-br from-primary-500 to-secondary-500 rounded-lg flex items-center justify-center">
                      <span className="text-white font-semibold text-sm">
                        {agent.name.substring(0, 2).toUpperCase()}
                      </span>
                    </div>
                  )}
                </div>

                {/* Agent Info */}
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2 mb-1">
                    <h3 className="text-sm font-semibold text-gray-900 dark:text-white group-hover:text-primary-600 dark:group-hover:text-primary-400 transition-colors truncate">
                      {agent.name}
                    </h3>
                    {agent.is_featured && (
                      <Star className="h-3 w-3 text-warning-500 fill-current flex-shrink-0" />
                    )}
                  </div>
                  
                  <p className="text-xs text-gray-500 dark:text-gray-400 truncate mb-1">
                    {agent.description}
                  </p>
                  
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-3 text-xs text-gray-500 dark:text-gray-400">
                      <span className="flex items-center gap-1">
                        <Users className="h-3 w-3" />
                        {agent.stats.deployments}
                      </span>
                      {agent.stats.rating_count > 0 && (
                        <span className="flex items-center gap-1">
                          <Star className="h-3 w-3" />
                          {agent.stats.avg_rating.toFixed(1)}
                        </span>
                      )}
                    </div>
                    
                    {agent.pricing.model !== 'free' && (
                      <span className="text-xs font-medium text-primary-600 dark:text-primary-400">
                        {agent.pricing.amount 
                          ? `${agent.pricing.currency} ${agent.pricing.amount}` 
                          : agent.pricing.model
                        }
                      </span>
                    )}
                  </div>
                </div>
              </div>
            </Link>
          </motion.div>
        ))}
      </div>

      {agents.length === 0 && (
        <div className="text-center py-8">
          <TrendingUp className="h-12 w-12 text-gray-400 dark:text-gray-600 mx-auto mb-4" />
          <p className="text-gray-500 dark:text-gray-400 text-sm">
            No featured agents available yet
          </p>
        </div>
      )}
    </div>
  )
}