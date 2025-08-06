'use client'

import { motion } from 'framer-motion'
import { ArrowRight, Activity, Users, BarChart3, Zap } from 'lucide-react'
import Link from 'next/link'
import { MarketplaceStats } from '@/components/dashboard/MarketplaceStats'
import { FeaturedAgents } from '@/components/dashboard/FeaturedAgents'
import { RecentActivity } from '@/components/dashboard/RecentActivity'

export default function HomePage() {
  return (
    <div className="space-y-8">
      {/* Hero Section */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.6 }}
        className="relative overflow-hidden rounded-2xl bg-gradient-to-br from-primary-600 via-secondary-600 to-juliaos-purple p-8 text-white"
      >
        <div className="relative z-10">
          <h1 className="text-4xl font-bold mb-4">
            Welcome to JuliaSphere
          </h1>
          <p className="text-xl text-primary-100 mb-6 max-w-2xl">
            The ultimate marketplace for AI agents and swarms. Discover, deploy, clone, and visualize 
            intelligent agents powered by the JuliaOS framework.
          </p>
          <div className="flex flex-wrap gap-4">
            <Link
              href="/marketplace"
              className="inline-flex items-center gap-2 bg-white text-primary-600 px-6 py-3 rounded-lg font-semibold hover:bg-primary-50 transition-colors"
            >
              Explore Marketplace
              <ArrowRight className="h-4 w-4" />
            </Link>
            <Link
              href="/swarms"
              className="inline-flex items-center gap-2 bg-primary-500/20 text-white px-6 py-3 rounded-lg font-semibold hover:bg-primary-500/30 transition-colors backdrop-blur-sm"
            >
              Visualize Swarms
              <Activity className="h-4 w-4" />
            </Link>
          </div>
        </div>
        
        {/* Background Pattern */}
        <div className="absolute inset-0 opacity-10">
          <div className="absolute top-0 right-0 w-96 h-96 bg-white rounded-full mix-blend-overlay filter blur-xl"></div>
          <div className="absolute bottom-0 left-0 w-96 h-96 bg-secondary-300 rounded-full mix-blend-overlay filter blur-xl"></div>
        </div>
      </motion.div>

      {/* Quick Stats */}
      <MarketplaceStats />

      {/* Main Content Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        {/* Featured Agents */}
        <motion.div
          initial={{ opacity: 0, x: -20 }}
          animate={{ opacity: 1, x: 0 }}
          transition={{ duration: 0.6, delay: 0.2 }}
        >
          <FeaturedAgents />
        </motion.div>

        {/* Recent Activity */}
        <motion.div
          initial={{ opacity: 0, x: 20 }}
          animate={{ opacity: 1, x: 0 }}
          transition={{ duration: 0.6, delay: 0.3 }}
        >
          <RecentActivity />
        </motion.div>
      </div>

      {/* Feature Highlights */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.6, delay: 0.4 }}
        className="grid grid-cols-1 md:grid-cols-3 gap-6"
      >
        <div className="bg-white dark:bg-gray-800 p-6 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700">
          <div className="flex items-center gap-3 mb-4">
            <div className="p-2 bg-primary-100 dark:bg-primary-900/20 rounded-lg">
              <Users className="h-6 w-6 text-primary-600 dark:text-primary-400" />
            </div>
            <h3 className="text-lg font-semibold text-gray-900 dark:text-gray-100">
              Agent Ecosystem
            </h3>
          </div>
          <p className="text-gray-600 dark:text-gray-400 mb-4">
            Discover thousands of pre-built agents for trading, research, content creation, and more.
          </p>
          <Link
            href="/marketplace"
            className="text-primary-600 dark:text-primary-400 font-medium hover:text-primary-700 dark:hover:text-primary-300 transition-colors"
          >
            Browse agents →
          </Link>
        </div>

        <div className="bg-white dark:bg-gray-800 p-6 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700">
          <div className="flex items-center gap-3 mb-4">
            <div className="p-2 bg-secondary-100 dark:bg-secondary-900/20 rounded-lg">
              <Activity className="h-6 w-6 text-secondary-600 dark:text-secondary-400" />
            </div>
            <h3 className="text-lg font-semibold text-gray-900 dark:text-gray-100">
              Swarm Intelligence
            </h3>
          </div>
          <p className="text-gray-600 dark:text-gray-400 mb-4">
            Visualize and analyze how agents coordinate in real-time swarms with interactive graphs.
          </p>
          <Link
            href="/swarms"
            className="text-secondary-600 dark:text-secondary-400 font-medium hover:text-secondary-700 dark:hover:text-secondary-300 transition-colors"
          >
            View swarms →
          </Link>
        </div>

        <div className="bg-white dark:bg-gray-800 p-6 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700">
          <div className="flex items-center gap-3 mb-4">
            <div className="p-2 bg-success-100 dark:bg-success-900/20 rounded-lg">
              <BarChart3 className="h-6 w-6 text-success-600 dark:text-success-400" />
            </div>
            <h3 className="text-lg font-semibold text-gray-900 dark:text-gray-100">
              Performance Analytics
            </h3>
          </div>
          <p className="text-gray-600 dark:text-gray-400 mb-4">
            Track agent performance, success rates, and optimization opportunities with detailed metrics.
          </p>
          <Link
            href="/analytics"
            className="text-success-600 dark:text-success-400 font-medium hover:text-success-700 dark:hover:text-success-300 transition-colors"
          >
            View analytics →
          </Link>
        </div>
      </motion.div>
    </div>
  )
}