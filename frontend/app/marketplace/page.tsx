'use client'

import { useState } from 'react'
import { motion } from 'framer-motion'
import { Search, Filter, SlidersHorizontal, Grid3X3, List, TrendingUp } from 'lucide-react'
import { AgentGrid } from '@/components/marketplace/AgentGrid'
import { MarketplaceFilters } from '@/components/marketplace/MarketplaceFilters'
import { MarketplaceStats } from '@/components/marketplace/MarketplaceStats'
import { FilterState } from '@/types'

export default function MarketplacePage() {
  const [searchQuery, setSearchQuery] = useState('')
  const [showFilters, setShowFilters] = useState(false)
  const [viewMode, setViewMode] = useState<'grid' | 'list'>('grid')
  const [filters, setFilters] = useState<FilterState>({
    category: null,
    tags: [],
    priceModel: null,
    rating: null,
    sortBy: 'featured',
    searchQuery: '',
  })

  const handleFilterChange = (newFilters: Partial<FilterState>) => {
    setFilters(prev => ({ ...prev, ...newFilters }))
  }

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault()
    handleFilterChange({ searchQuery })
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5 }}
        className="flex flex-col lg:flex-row lg:items-center justify-between gap-4"
      >
        <div>
          <h1 className="text-3xl font-bold text-gray-900 dark:text-white">
            Agent Marketplace
          </h1>
          <p className="text-gray-600 dark:text-gray-400 mt-2">
            Discover, deploy, and share AI agents built with JuliaOS
          </p>
        </div>
        
        <div className="flex items-center gap-3">
          {/* View Mode Toggle */}
          <div className="flex items-center bg-gray-100 dark:bg-gray-700 rounded-lg p-1">
            <button
              onClick={() => setViewMode('grid')}
              className={`p-2 rounded transition-colors ${
                viewMode === 'grid'
                  ? 'bg-white dark:bg-gray-600 text-gray-900 dark:text-white shadow-sm'
                  : 'text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white'
              }`}
            >
              <Grid3X3 className="h-4 w-4" />
            </button>
            <button
              onClick={() => setViewMode('list')}
              className={`p-2 rounded transition-colors ${
                viewMode === 'list'
                  ? 'bg-white dark:bg-gray-600 text-gray-900 dark:text-white shadow-sm'
                  : 'text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white'
              }`}
            >
              <List className="h-4 w-4" />
            </button>
          </div>

          {/* Sort Dropdown */}
          <select
            value={filters.sortBy}
            onChange={(e) => handleFilterChange({ sortBy: e.target.value })}
            className="px-3 py-2 bg-white dark:bg-gray-800 border border-gray-300 dark:border-gray-600 rounded-lg text-sm focus:ring-2 focus:ring-primary-500 focus:border-transparent"
          >
            <option value="featured">Featured</option>
            <option value="newest">Newest</option>
            <option value="popular">Most Popular</option>
            <option value="rating">Highest Rated</option>
            <option value="deployments">Most Deployed</option>
            <option value="price_low">Price: Low to High</option>
            <option value="price_high">Price: High to Low</option>
          </select>
        </div>
      </motion.div>

      {/* Search and Filter Bar */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5, delay: 0.1 }}
        className="flex flex-col sm:flex-row gap-4 items-center"
      >
        {/* Search */}
        <form onSubmit={handleSearch} className="flex-1 w-full sm:w-auto">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-5 w-5 text-gray-400" />
            <input
              type="text"
              placeholder="Search agents by name, description, or tags..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full pl-10 pr-4 py-3 bg-white dark:bg-gray-800 border border-gray-300 dark:border-gray-600 rounded-lg text-sm focus:ring-2 focus:ring-primary-500 focus:border-transparent"
            />
          </div>
        </form>

        {/* Filter Toggle */}
        <button
          onClick={() => setShowFilters(!showFilters)}
          className={`flex items-center gap-2 px-4 py-3 rounded-lg font-medium transition-colors ${
            showFilters
              ? 'bg-primary-100 dark:bg-primary-900/20 text-primary-700 dark:text-primary-300'
              : 'bg-gray-100 dark:bg-gray-700 text-gray-700 dark:text-gray-200 hover:bg-gray-200 dark:hover:bg-gray-600'
          }`}
        >
          <SlidersHorizontal className="h-4 w-4" />
          Filters
          {(filters.category || filters.tags.length > 0 || filters.priceModel || filters.rating) && (
            <span className="bg-primary-500 text-white text-xs px-2 py-0.5 rounded-full">
              {[filters.category, ...filters.tags, filters.priceModel, filters.rating].filter(Boolean).length}
            </span>
          )}
        </button>
      </motion.div>

      {/* Filters Panel */}
      {showFilters && (
        <motion.div
          initial={{ opacity: 0, height: 0 }}
          animate={{ opacity: 1, height: 'auto' }}
          exit={{ opacity: 0, height: 0 }}
          className="overflow-hidden"
        >
          <MarketplaceFilters
            filters={filters}
            onFilterChange={handleFilterChange}
            onClearFilters={() => setFilters({
              category: null,
              tags: [],
              priceModel: null,
              rating: null,
              sortBy: 'featured',
              searchQuery: '',
            })}
          />
        </motion.div>
      )}

      {/* Marketplace Stats */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5, delay: 0.2 }}
      >
        <MarketplaceStats />
      </motion.div>

      {/* Main Content */}
      <div className="grid grid-cols-1 xl:grid-cols-4 gap-6">
        {/* Agent Grid */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5, delay: 0.3 }}
          className="xl:col-span-4"
        >
          <AgentGrid
            filters={filters}
            viewMode={viewMode}
            searchQuery={searchQuery}
          />
        </motion.div>
      </div>

      {/* Featured Section */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5, delay: 0.4 }}
        className="bg-gradient-to-r from-primary-50 to-secondary-50 dark:from-primary-900/20 dark:to-secondary-900/20 rounded-xl p-6"
      >
        <div className="flex items-center gap-2 mb-4">
          <TrendingUp className="h-6 w-6 text-primary-600 dark:text-primary-400" />
          <h2 className="text-xl font-semibold text-gray-900 dark:text-white">
            Trending This Week
          </h2>
        </div>
        
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {/* This will show trending agents */}
          <AgentGrid
            filters={{ ...filters, sortBy: 'trending' }}
            viewMode="grid"
            searchQuery=""
            limit={6}
            showHeader={false}
          />
        </div>
      </motion.div>

      {/* Getting Started Section */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5, delay: 0.5 }}
        className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700 p-6"
      >
        <h2 className="text-xl font-semibold text-gray-900 dark:text-white mb-4">
          New to JuliaSphere?
        </h2>
        
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          <div className="text-center">
            <div className="w-12 h-12 bg-primary-100 dark:bg-primary-900/20 rounded-lg flex items-center justify-center mx-auto mb-3">
              <Search className="h-6 w-6 text-primary-600 dark:text-primary-400" />
            </div>
            <h3 className="font-medium text-gray-900 dark:text-white mb-2">Discover Agents</h3>
            <p className="text-sm text-gray-600 dark:text-gray-400">
              Browse our curated collection of AI agents for every use case
            </p>
          </div>
          
          <div className="text-center">
            <div className="w-12 h-12 bg-secondary-100 dark:bg-secondary-900/20 rounded-lg flex items-center justify-center mx-auto mb-3">
              <Grid3X3 className="h-6 w-6 text-secondary-600 dark:text-secondary-400" />
            </div>
            <h3 className="font-medium text-gray-900 dark:text-white mb-2">Deploy Instantly</h3>
            <p className="text-sm text-gray-600 dark:text-gray-400">
              One-click deployment with automatic scaling and monitoring
            </p>
          </div>
          
          <div className="text-center">
            <div className="w-12 h-12 bg-success-100 dark:bg-success-900/20 rounded-lg flex items-center justify-center mx-auto mb-3">
              <TrendingUp className="h-6 w-6 text-success-600 dark:text-success-400" />
            </div>
            <h3 className="font-medium text-gray-900 dark:text-white mb-2">Create & Earn</h3>
            <p className="text-sm text-gray-600 dark:text-gray-400">
              Build your own agents and earn from deployments
            </p>
          </div>
        </div>
        
        <div className="flex justify-center mt-6">
          <button className="px-6 py-3 bg-primary-600 text-white rounded-lg hover:bg-primary-700 transition-colors font-medium">
            Get Started
          </button>
        </div>
      </motion.div>
    </div>
  )
}