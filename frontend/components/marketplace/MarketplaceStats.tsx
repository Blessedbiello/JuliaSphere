'use client'

import { useQuery } from 'react-query'
import { motion } from 'framer-motion'
import { 
  Users, 
  Star, 
  Download, 
  TrendingUp,
  Zap,
  Globe
} from 'lucide-react'
import { api } from '@/lib/api'
import { MarketplaceStats as MarketplaceStatsType } from '@/types'

export function MarketplaceStats() {
  const { data: stats, isLoading } = useQuery<MarketplaceStatsType>(
    'marketplaceStats',
    () => api.marketplace.getMarketplaceStats().then(res => res.data),
    {
      refetchInterval: 60000, // Refresh every minute
    }
  )

  if (isLoading) {
    return (
      <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-4">
        {Array.from({ length: 6 }).map((_, i) => (
          <div key={i} className="bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700 p-4">
            <div className="animate-pulse">
              <div className="h-4 bg-gray-200 dark:bg-gray-700 rounded mb-2"></div>
              <div className="h-6 bg-gray-200 dark:bg-gray-700 rounded"></div>
            </div>
          </div>
        ))}
      </div>
    )
  }

  if (!stats) return null

  const statItems = [
    {
      icon: Globe,
      label: 'Total Agents',
      value: stats.total_public_agents.toLocaleString(),
      color: 'text-blue-600 dark:text-blue-400',
      bgColor: 'bg-blue-100 dark:bg-blue-900/20',
    },
    {
      icon: TrendingUp,
      label: 'Featured',
      value: stats.featured_agents.toLocaleString(),
      color: 'text-yellow-600 dark:text-yellow-400',
      bgColor: 'bg-yellow-100 dark:bg-yellow-900/20',
    },
    {
      icon: Star,
      label: 'Avg Rating',
      value: stats.overall_avg_rating.toFixed(1),
      color: 'text-orange-600 dark:text-orange-400',
      bgColor: 'bg-orange-100 dark:bg-orange-900/20',
    },
    {
      icon: Download,
      label: 'Deployments',
      value: stats.total_deployments.toLocaleString(),
      color: 'text-green-600 dark:text-green-400',
      bgColor: 'bg-green-100 dark:bg-green-900/20',
    },
    {
      icon: Users,
      label: 'Creators',
      value: stats.total_creators.toLocaleString(),
      color: 'text-purple-600 dark:text-purple-400',
      bgColor: 'bg-purple-100 dark:bg-purple-900/20',
    },
    {
      icon: Zap,
      label: 'Active Now',
      value: '127', // This would come from real-time data
      color: 'text-emerald-600 dark:text-emerald-400',
      bgColor: 'bg-emerald-100 dark:bg-emerald-900/20',
    },
  ]

  return (
    <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-4">
      {statItems.map((item, index) => {
        const Icon = item.icon
        return (
          <motion.div
            key={item.label}
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5, delay: index * 0.1 }}
            className="bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700 p-4 hover:shadow-md transition-shadow"
          >
            <div className="flex items-center justify-between mb-2">
              <div className={`p-2 rounded-lg ${item.bgColor}`}>
                <Icon className={`h-4 w-4 ${item.color}`} />
              </div>
            </div>
            
            <div className="space-y-1">
              <div className={`text-2xl font-bold ${item.color}`}>
                {item.value}
              </div>
              <div className="text-sm text-gray-600 dark:text-gray-400">
                {item.label}
              </div>
            </div>
          </motion.div>
        )
      })}
    </div>
  )
}