'use client'

import { useState } from 'react'
import { useQuery } from 'react-query'
import { motion, AnimatePresence } from 'framer-motion'
import { 
  Loader2, 
  AlertCircle, 
  Search,
  ChevronLeft,
  ChevronRight
} from 'lucide-react'
import { AgentCard } from './AgentCard'
import { api } from '@/lib/api'
import { MarketplaceAgent, FilterState, PaginationState } from '@/types'

interface AgentGridProps {
  filters: FilterState
  viewMode: 'grid' | 'list'
  searchQuery: string
  limit?: number
  showHeader?: boolean
}

export function AgentGrid({ 
  filters, 
  viewMode, 
  searchQuery,
  limit = 20,
  showHeader = true
}: AgentGridProps) {
  const [pagination, setPagination] = useState<PaginationState>({
    page: 1,
    limit,
    total: 0,
    hasNext: false,
    hasPrev: false,
  })

  // Build query parameters
  const queryParams = {
    page: pagination.page,
    limit: pagination.limit,
    search: searchQuery || filters.searchQuery || undefined,
    category: filters.category || undefined,
    tags: filters.tags.length > 0 ? filters.tags.join(',') : undefined,
    pricing_model: filters.priceModel || undefined,
    min_rating: filters.rating || undefined,
    sort_by: filters.sortBy,
    featured_only: filters.sortBy === 'featured' ? true : undefined,
  }

  // Fetch agents
  const { 
    data: response, 
    isLoading, 
    isError, 
    error,
    refetch 
  } = useQuery(
    ['agents', queryParams],
    () => api.marketplace.getAgents(queryParams).then(res => res.data),
    {
      keepPreviousData: true,
      onSuccess: (data) => {
        setPagination(prev => ({
          ...prev,
          total: data.total || 0,
          hasNext: data.has_next || false,
          hasPrev: data.has_prev || false,
        }))
      },
      onError: (err) => {
        console.error('Failed to fetch agents:', err)
      }
    }
  )

  const agents = response?.agents || []
  const totalCount = response?.total || 0

  const handlePageChange = (newPage: number) => {
    setPagination(prev => ({ ...prev, page: newPage }))
    // Scroll to top when changing pages
    window.scrollTo({ top: 0, behavior: 'smooth' })
  }

  const handleDeploy = (agentId: string) => {
    // TODO: Implement deployment logic
    console.log('Deploying agent:', agentId)
  }

  const handleFavorite = (agentId: string, favorited: boolean) => {
    // TODO: Implement favorite logic
    console.log('Favorite agent:', agentId, favorited)
  }

  if (isLoading) {
    return (
      <div className="space-y-4">
        {showHeader && (
          <div className="flex items-center justify-between">
            <div className="h-6 bg-gray-200 dark:bg-gray-700 rounded w-32 animate-pulse"></div>
            <div className="h-6 bg-gray-200 dark:bg-gray-700 rounded w-20 animate-pulse"></div>
          </div>
        )}
        
        <div className={`grid gap-6 ${
          viewMode === 'grid' 
            ? 'grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4' 
            : 'grid-cols-1'
        }`}>
          {Array.from({ length: limit > 12 ? 12 : limit }).map((_, i) => (
            <div 
              key={i}
              className={`bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 animate-pulse ${
                viewMode === 'grid' ? 'h-96' : 'h-32'
              }`}
            >
              <div className="p-6 space-y-4">
                <div className="h-4 bg-gray-200 dark:bg-gray-700 rounded"></div>
                <div className="h-4 bg-gray-200 dark:bg-gray-700 rounded w-3/4"></div>
                <div className="h-4 bg-gray-200 dark:bg-gray-700 rounded w-1/2"></div>
              </div>
            </div>
          ))}
        </div>
      </div>
    )
  }

  if (isError) {
    return (
      <div className="flex flex-col items-center justify-center py-12 text-center">
        <AlertCircle className="h-12 w-12 text-error-500 mb-4" />
        <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-2">
          Failed to Load Agents
        </h3>
        <p className="text-gray-600 dark:text-gray-400 mb-4">
          {error instanceof Error ? error.message : 'Something went wrong loading the agents.'}
        </p>
        <button
          onClick={() => refetch()}
          className="px-4 py-2 bg-primary-600 text-white rounded-lg hover:bg-primary-700 transition-colors"
        >
          Try Again
        </button>
      </div>
    )
  }

  if (agents.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center py-12 text-center">
        <Search className="h-12 w-12 text-gray-400 mb-4" />
        <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-2">
          No Agents Found
        </h3>
        <p className="text-gray-600 dark:text-gray-400 mb-4">
          {searchQuery || filters.searchQuery ? (
            <>No agents match your search criteria. Try adjusting your filters or search terms.</>
          ) : (
            <>No agents are available at the moment. Check back later!</>
          )}
        </p>
        {(searchQuery || filters.category || filters.tags.length > 0 || filters.priceModel || filters.rating) && (
          <button
            onClick={() => window.location.reload()}
            className="px-4 py-2 bg-gray-100 dark:bg-gray-700 text-gray-700 dark:text-gray-200 rounded-lg hover:bg-gray-200 dark:hover:bg-gray-600 transition-colors"
          >
            Clear Filters
          </button>
        )}
      </div>
    )
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      {showHeader && (
        <div className="flex items-center justify-between">
          <div>
            <h2 className="text-xl font-semibold text-gray-900 dark:text-white">
              {searchQuery || filters.searchQuery ? 'Search Results' : 'Available Agents'}
            </h2>
            <p className="text-sm text-gray-600 dark:text-gray-400 mt-1">
              {totalCount.toLocaleString()} {totalCount === 1 ? 'agent' : 'agents'} found
            </p>
          </div>
          
          <div className="text-sm text-gray-600 dark:text-gray-400">
            Page {pagination.page} of {Math.ceil(totalCount / pagination.limit)}
          </div>
        </div>
      )}

      {/* Agent Grid */}
      <motion.div
        layout
        className={`grid gap-6 ${
          viewMode === 'grid' 
            ? 'grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4' 
            : 'grid-cols-1'
        }`}
      >
        <AnimatePresence mode="popLayout">
          {agents.map((agent, index) => (
            <motion.div
              key={agent.id}
              layout
              initial={{ opacity: 0, scale: 0.9 }}
              animate={{ 
                opacity: 1, 
                scale: 1,
                transition: { delay: index * 0.05 }
              }}
              exit={{ opacity: 0, scale: 0.9 }}
              whileHover={{ y: -2 }}
            >
              <AgentCard
                agent={agent}
                viewMode={viewMode}
                onDeploy={handleDeploy}
                onFavorite={handleFavorite}
              />
            </motion.div>
          ))}
        </AnimatePresence>
      </motion.div>

      {/* Pagination */}
      {totalCount > pagination.limit && (
        <div className="flex items-center justify-between pt-6 border-t border-gray-200 dark:border-gray-700">
          <div className="text-sm text-gray-600 dark:text-gray-400">
            Showing {((pagination.page - 1) * pagination.limit + 1).toLocaleString()} to{' '}
            {Math.min(pagination.page * pagination.limit, totalCount).toLocaleString()} of{' '}
            {totalCount.toLocaleString()} agents
          </div>
          
          <div className="flex items-center gap-2">
            <button
              onClick={() => handlePageChange(pagination.page - 1)}
              disabled={!pagination.hasPrev}
              className="flex items-center gap-2 px-3 py-2 text-sm bg-white dark:bg-gray-800 border border-gray-300 dark:border-gray-600 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
            >
              <ChevronLeft className="h-4 w-4" />
              Previous
            </button>
            
            {/* Page Numbers */}
            <div className="flex items-center gap-1">
              {Array.from({ 
                length: Math.min(5, Math.ceil(totalCount / pagination.limit)) 
              }, (_, i) => {
                const totalPages = Math.ceil(totalCount / pagination.limit)
                let pageNum
                
                if (totalPages <= 5) {
                  pageNum = i + 1
                } else if (pagination.page <= 3) {
                  pageNum = i + 1
                } else if (pagination.page >= totalPages - 2) {
                  pageNum = totalPages - 4 + i
                } else {
                  pageNum = pagination.page - 2 + i
                }
                
                return (
                  <button
                    key={pageNum}
                    onClick={() => handlePageChange(pageNum)}
                    className={`w-8 h-8 text-sm rounded transition-colors ${
                      pagination.page === pageNum
                        ? 'bg-primary-600 text-white'
                        : 'bg-white dark:bg-gray-800 text-gray-700 dark:text-gray-200 border border-gray-300 dark:border-gray-600 hover:bg-gray-50 dark:hover:bg-gray-700'
                    }`}
                  >
                    {pageNum}
                  </button>
                )
              })}
            </div>
            
            <button
              onClick={() => handlePageChange(pagination.page + 1)}
              disabled={!pagination.hasNext}
              className="flex items-center gap-2 px-3 py-2 text-sm bg-white dark:bg-gray-800 border border-gray-300 dark:border-gray-600 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
            >
              Next
              <ChevronRight className="h-4 w-4" />
            </button>
          </div>
        </div>
      )}
    </div>
  )
}