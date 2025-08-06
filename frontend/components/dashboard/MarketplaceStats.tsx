'use client'

import { useQuery } from 'react-query'
import { motion } from 'framer-motion'
import { TrendingUp, Users, Activity, Zap } from 'lucide-react'
import { apiClient } from '@/lib/api'

interface MarketplaceStatsData {
  total_public_agents: number
  featured_agents: number
  overall_avg_rating: number
  total_deployments: number
  total_creators: number
}

export function MarketplaceStats() {
  const { data: stats, isLoading, error } = useQuery<MarketplaceStatsData>(
    'marketplaceStats',
    () => apiClient.get('/marketplace/stats').then(res => res.data),
    {
      refetchInterval: 30000, // Refresh every 30 seconds
    }
  )

  if (isLoading) {
    return (
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {[...Array(4)].map((_, i) => (
          <div key={i} className="bg-white dark:bg-gray-800 p-6 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700">
            <div className="animate-pulse">
              <div className="h-4 bg-gray-200 dark:bg-gray-700 rounded w-3/4 mb-2"></div>
              <div className="h-8 bg-gray-200 dark:bg-gray-700 rounded w-1/2"></div>
            </div>
          </div>
        ))}
      </div>
    )
  }

  if (error || !stats) {
    return (
      <div className="bg-error-50 dark:bg-error-900/20 border border-error-200 dark:border-error-800 rounded-lg p-4">
        <p className="text-error-600 dark:text-error-400 text-sm">
          Failed to load marketplace statistics
        </p>
      </div>
    )
  }

  const statCards = [
    {
      name: 'Total Agents',
      value: stats.total_public_agents.toLocaleString(),
      icon: Zap,
      color: 'primary',
      change: '+12%',
      changeType: 'positive' as const,
    },
    {
      name: 'Active Creators',
      value: stats.total_creators.toLocaleString(),
      icon: Users,
      color: 'secondary',
      change: '+5%',
      changeType: 'positive' as const,
    },
    {
      name: 'Total Deployments',
      value: stats.total_deployments.toLocaleString(),
      icon: Activity,
      color: 'success',
      change: '+23%',
      changeType: 'positive' as const,
    },
    {
      name: 'Avg Rating',
      value: stats.overall_avg_rating.toFixed(1),
      icon: TrendingUp,
      color: 'warning',
      change: '+0.2',
      changeType: 'positive' as const,
    },
  ]

  return (
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
      {statCards.map((stat, index) => (
        <motion.div
          key={stat.name}
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.4, delay: index * 0.1 }}
          className="bg-white dark:bg-gray-800 p-6 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700 hover:shadow-md transition-shadow"
        >
          <div className="flex items-center">
            <div className="flex-shrink-0">
              <div className={`p-3 rounded-lg bg-${stat.color}-100 dark:bg-${stat.color}-900/20`}>
                <stat.icon className={`h-6 w-6 text-${stat.color}-600 dark:text-${stat.color}-400`} />
              </div>
            </div>
            <div className="ml-4 flex-1">
              <p className="text-sm font-medium text-gray-500 dark:text-gray-400">
                {stat.name}
              </p>
              <div className="flex items-baseline">
                <p className="text-2xl font-semibold text-gray-900 dark:text-white">
                  {stat.value}
                </p>
                <p className={`ml-2 text-sm font-medium ${
                  stat.changeType === 'positive' 
                    ? 'text-success-600 dark:text-success-400' 
                    : 'text-error-600 dark:text-error-400'
                }`}>
                  {stat.change}
                </p>
              </div>
            </div>
          </div>
        </motion.div>
      ))}
    </div>
  )
}