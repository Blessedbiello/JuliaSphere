'use client'

import { useQuery } from 'react-query'
import { motion } from 'framer-motion'
import { Activity, Bot, Users, Zap, ExternalLink } from 'lucide-react'
import Link from 'next/link'
import { formatDistanceToNow } from 'date-fns'
import { apiClient } from '@/lib/api'

interface ActivityItem {
  id: string
  type: 'agent_deployed' | 'agent_created' | 'swarm_detected' | 'high_performance'
  title: string
  description: string
  timestamp: string
  metadata?: {
    agent_id?: string
    agent_name?: string
    swarm_id?: string
    performance_score?: number
  }
}

// Mock data for now - in real app, this would come from an activity feed API
const mockActivities: ActivityItem[] = [
  {
    id: '1',
    type: 'agent_deployed',
    title: 'New Agent Deployment',
    description: 'Plan & Execute Agent was deployed by @developer',
    timestamp: new Date(Date.now() - 5 * 60 * 1000).toISOString(),
    metadata: {
      agent_id: 'plan-execute-agent',
      agent_name: 'Plan & Execute Agent'
    }
  },
  {
    id: '2',
    type: 'swarm_detected',
    title: 'Swarm Formation Detected',
    description: 'New coordination pattern identified between 3 agents',
    timestamp: new Date(Date.now() - 15 * 60 * 1000).toISOString(),
    metadata: {
      swarm_id: 'swarm-abc123'
    }
  },
  {
    id: '3',
    type: 'high_performance',
    title: 'High Performance Alert',
    description: 'AI News Agent achieved 98% success rate this hour',
    timestamp: new Date(Date.now() - 30 * 60 * 1000).toISOString(),
    metadata: {
      agent_id: 'ai-news-agent',
      agent_name: 'AI News Agent',
      performance_score: 98
    }
  },
  {
    id: '4',
    type: 'agent_created',
    title: 'New Agent Published',
    description: 'Crypto Trading Bot was published to the marketplace',
    timestamp: new Date(Date.now() - 45 * 60 * 1000).toISOString(),
    metadata: {
      agent_id: 'crypto-trading-bot',
      agent_name: 'Crypto Trading Bot'
    }
  },
]

function getActivityIcon(type: ActivityItem['type']) {
  switch (type) {
    case 'agent_deployed':
      return Bot
    case 'agent_created':
      return Zap
    case 'swarm_detected':
      return Users
    case 'high_performance':
      return Activity
    default:
      return Activity
  }
}

function getActivityColor(type: ActivityItem['type']) {
  switch (type) {
    case 'agent_deployed':
      return 'primary'
    case 'agent_created':
      return 'secondary'
    case 'swarm_detected':
      return 'warning'
    case 'high_performance':
      return 'success'
    default:
      return 'primary'
  }
}

export function RecentActivity() {
  // For now, using mock data. In real app, uncomment below:
  // const { data: activities, isLoading, error } = useQuery<ActivityItem[]>(
  //   'recentActivity',
  //   () => apiClient.get('/marketplace/activity').then(res => res.data),
  //   {
  //     refetchInterval: 30000, // Refresh every 30 seconds
  //   }
  // )

  const activities = mockActivities
  const isLoading = false
  const error = null

  if (isLoading) {
    return (
      <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700 p-6">
        <div className="flex items-center justify-between mb-6">
          <h2 className="text-lg font-semibold text-gray-900 dark:text-white">
            Recent Activity
          </h2>
        </div>
        <div className="space-y-4">
          {[...Array(4)].map((_, i) => (
            <div key={i} className="animate-pulse">
              <div className="flex items-start space-x-4">
                <div className="h-10 w-10 bg-gray-200 dark:bg-gray-700 rounded-lg"></div>
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

  if (error || !activities) {
    return (
      <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700 p-6">
        <h2 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">
          Recent Activity
        </h2>
        <div className="bg-error-50 dark:bg-error-900/20 border border-error-200 dark:border-error-800 rounded-lg p-4">
          <p className="text-error-600 dark:text-error-400 text-sm">
            Failed to load recent activity
          </p>
        </div>
      </div>
    )
  }

  return (
    <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700 p-6">
      <div className="flex items-center justify-between mb-6">
        <h2 className="text-lg font-semibold text-gray-900 dark:text-white">
          Recent Activity
        </h2>
        <Link
          href="/activity"
          className="text-primary-600 dark:text-primary-400 hover:text-primary-700 dark:hover:text-primary-300 text-sm font-medium flex items-center gap-1"
        >
          View all
          <ExternalLink className="h-3 w-3" />
        </Link>
      </div>

      <div className="space-y-4">
        {activities.map((activity, index) => {
          const Icon = getActivityIcon(activity.type)
          const color = getActivityColor(activity.type)
          
          return (
            <motion.div
              key={activity.id}
              initial={{ opacity: 0, x: 20 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ duration: 0.4, delay: index * 0.1 }}
              className="flex items-start space-x-4 p-3 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-700/50 transition-colors group"
            >
              {/* Activity Icon */}
              <div className="flex-shrink-0">
                <div className={`p-2 rounded-lg bg-${color}-100 dark:bg-${color}-900/20 group-hover:bg-${color}-200 dark:group-hover:bg-${color}-900/30 transition-colors`}>
                  <Icon className={`h-5 w-5 text-${color}-600 dark:text-${color}-400`} />
                </div>
              </div>

              {/* Activity Content */}
              <div className="flex-1 min-w-0">
                <div className="flex items-center justify-between mb-1">
                  <h3 className="text-sm font-semibold text-gray-900 dark:text-white">
                    {activity.title}
                  </h3>
                  <span className="text-xs text-gray-500 dark:text-gray-400 flex-shrink-0 ml-2">
                    {formatDistanceToNow(new Date(activity.timestamp), { addSuffix: true })}
                  </span>
                </div>
                
                <p className="text-sm text-gray-600 dark:text-gray-300 mb-2">
                  {activity.description}
                </p>
                
                {/* Metadata */}
                {activity.metadata && (
                  <div className="flex items-center gap-2 text-xs text-gray-500 dark:text-gray-400">
                    {activity.metadata.agent_name && (
                      <Link
                        href={`/marketplace/agents/${activity.metadata.agent_id}`}
                        className="hover:text-primary-600 dark:hover:text-primary-400 transition-colors"
                      >
                        {activity.metadata.agent_name}
                      </Link>
                    )}
                    {activity.metadata.performance_score && (
                      <span className="bg-success-100 dark:bg-success-900/20 text-success-700 dark:text-success-300 px-2 py-0.5 rounded-full">
                        {activity.metadata.performance_score}% success
                      </span>
                    )}
                    {activity.metadata.swarm_id && (
                      <Link
                        href={`/swarms#${activity.metadata.swarm_id}`}
                        className="hover:text-primary-600 dark:hover:text-primary-400 transition-colors"
                      >
                        View swarm
                      </Link>
                    )}
                  </div>
                )}
              </div>
            </motion.div>
          )
        })}
      </div>

      {activities.length === 0 && (
        <div className="text-center py-8">
          <Activity className="h-12 w-12 text-gray-400 dark:text-gray-600 mx-auto mb-4" />
          <p className="text-gray-500 dark:text-gray-400 text-sm">
            No recent activity to display
          </p>
        </div>
      )}
    </div>
  )
}