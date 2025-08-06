'use client'

import { useState, useEffect } from 'react'
import { motion } from 'framer-motion'
import { useQuery } from 'react-query'
import { 
  X, 
  Star, 
  DollarSign, 
  Tag, 
  Filter,
  RotateCcw
} from 'lucide-react'
import { FilterState, Category } from '@/types'
import { api } from '@/lib/api'

interface MarketplaceFiltersProps {
  filters: FilterState
  onFilterChange: (filters: Partial<FilterState>) => void
  onClearFilters: () => void
}

const PRICE_MODELS = [
  { value: 'free', label: 'Free', icon: '🆓' },
  { value: 'one_time', label: 'One-time Purchase', icon: '💰' },
  { value: 'subscription', label: 'Subscription', icon: '📅' },
  { value: 'usage_based', label: 'Pay per Use', icon: '⚡' },
]

const RATING_OPTIONS = [
  { value: 4.5, label: '4.5+ Stars', stars: 5 },
  { value: 4.0, label: '4.0+ Stars', stars: 4 },
  { value: 3.5, label: '3.5+ Stars', stars: 4 },
  { value: 3.0, label: '3.0+ Stars', stars: 3 },
]

export function MarketplaceFilters({ 
  filters, 
  onFilterChange, 
  onClearFilters 
}: MarketplaceFiltersProps) {
  const [availableTags, setAvailableTags] = useState<string[]>([])
  const [tagInput, setTagInput] = useState('')

  // Fetch categories
  const { data: categories } = useQuery<Category[]>(
    'categories',
    () => api.marketplace.getCategories().then(res => res.data),
    {
      onSuccess: (data) => {
        // Extract unique tags from categories (if available)
        // This is a placeholder - in real implementation, you'd have a separate tags endpoint
        const tags = ['automation', 'content', 'trading', 'analytics', 'communication', 'productivity', 'ai', 'nlp', 'data']
        setAvailableTags(tags)
      }
    }
  )

  const handleCategoryChange = (category: string | null) => {
    onFilterChange({ category })
  }

  const handlePriceModelChange = (priceModel: string | null) => {
    onFilterChange({ priceModel })
  }

  const handleRatingChange = (rating: number | null) => {
    onFilterChange({ rating })
  }

  const handleTagAdd = (tag: string) => {
    if (!filters.tags.includes(tag)) {
      onFilterChange({ tags: [...filters.tags, tag] })
    }
    setTagInput('')
  }

  const handleTagRemove = (tagToRemove: string) => {
    onFilterChange({ tags: filters.tags.filter(tag => tag !== tagToRemove) })
  }

  const handleTagInputKeyPress = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && tagInput.trim()) {
      handleTagAdd(tagInput.trim())
    }
  }

  const renderStars = (count: number) => {
    return Array.from({ length: 5 }, (_, i) => (
      <Star
        key={i}
        className={`h-3 w-3 ${
          i < count
            ? 'text-yellow-400 fill-current'
            : 'text-gray-300 dark:text-gray-600'
        }`}
      />
    ))
  }

  const hasActiveFilters = filters.category || filters.tags.length > 0 || filters.priceModel || filters.rating

  return (
    <motion.div
      initial={{ opacity: 0, y: -20 }}
      animate={{ opacity: 1, y: 0 }}
      className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700 p-6"
    >
      {/* Header */}
      <div className="flex items-center justify-between mb-6">
        <div className="flex items-center gap-2">
          <Filter className="h-5 w-5 text-primary-600 dark:text-primary-400" />
          <h3 className="text-lg font-semibold text-gray-900 dark:text-white">
            Filters
          </h3>
          {hasActiveFilters && (
            <span className="bg-primary-100 dark:bg-primary-900/20 text-primary-700 dark:text-primary-300 text-xs px-2 py-1 rounded-full">
              Active
            </span>
          )}
        </div>
        
        {hasActiveFilters && (
          <button
            onClick={onClearFilters}
            className="flex items-center gap-2 px-3 py-1.5 text-sm text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white transition-colors"
          >
            <RotateCcw className="h-4 w-4" />
            Clear All
          </button>
        )}
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {/* Categories */}
        <div className="space-y-3">
          <h4 className="font-medium text-gray-900 dark:text-white text-sm">Category</h4>
          <div className="space-y-2">
            <label className="flex items-center">
              <input
                type="radio"
                name="category"
                checked={filters.category === null}
                onChange={() => handleCategoryChange(null)}
                className="w-4 h-4 text-primary-600 border-gray-300 dark:border-gray-600 focus:ring-primary-500"
              />
              <span className="ml-2 text-sm text-gray-700 dark:text-gray-300">All Categories</span>
            </label>
            
            {categories?.map((category) => (
              <label key={category.name} className="flex items-center">
                <input
                  type="radio"
                  name="category"
                  checked={filters.category === category.name}
                  onChange={() => handleCategoryChange(category.name)}
                  className="w-4 h-4 text-primary-600 border-gray-300 dark:border-gray-600 focus:ring-primary-500"
                />
                <span className="ml-2 text-sm text-gray-700 dark:text-gray-300">
                  {category.name}
                  <span className="ml-1 text-gray-500">({category.agent_count})</span>
                </span>
              </label>
            ))}
          </div>
        </div>

        {/* Price Model */}
        <div className="space-y-3">
          <h4 className="font-medium text-gray-900 dark:text-white text-sm flex items-center gap-2">
            <DollarSign className="h-4 w-4" />
            Pricing
          </h4>
          <div className="space-y-2">
            <label className="flex items-center">
              <input
                type="radio"
                name="priceModel"
                checked={filters.priceModel === null}
                onChange={() => handlePriceModelChange(null)}
                className="w-4 h-4 text-primary-600 border-gray-300 dark:border-gray-600 focus:ring-primary-500"
              />
              <span className="ml-2 text-sm text-gray-700 dark:text-gray-300">All Pricing</span>
            </label>
            
            {PRICE_MODELS.map((model) => (
              <label key={model.value} className="flex items-center">
                <input
                  type="radio"
                  name="priceModel"
                  checked={filters.priceModel === model.value}
                  onChange={() => handlePriceModelChange(model.value)}
                  className="w-4 h-4 text-primary-600 border-gray-300 dark:border-gray-600 focus:ring-primary-500"
                />
                <span className="ml-2 text-sm text-gray-700 dark:text-gray-300 flex items-center gap-1">
                  <span>{model.icon}</span>
                  {model.label}
                </span>
              </label>
            ))}
          </div>
        </div>

        {/* Rating */}
        <div className="space-y-3">
          <h4 className="font-medium text-gray-900 dark:text-white text-sm flex items-center gap-2">
            <Star className="h-4 w-4" />
            Rating
          </h4>
          <div className="space-y-2">
            <label className="flex items-center">
              <input
                type="radio"
                name="rating"
                checked={filters.rating === null}
                onChange={() => handleRatingChange(null)}
                className="w-4 h-4 text-primary-600 border-gray-300 dark:border-gray-600 focus:ring-primary-500"
              />
              <span className="ml-2 text-sm text-gray-700 dark:text-gray-300">Any Rating</span>
            </label>
            
            {RATING_OPTIONS.map((option) => (
              <label key={option.value} className="flex items-center">
                <input
                  type="radio"
                  name="rating"
                  checked={filters.rating === option.value}
                  onChange={() => handleRatingChange(option.value)}
                  className="w-4 h-4 text-primary-600 border-gray-300 dark:border-gray-600 focus:ring-primary-500"
                />
                <span className="ml-2 text-sm text-gray-700 dark:text-gray-300 flex items-center gap-1">
                  {renderStars(option.stars)}
                  <span className="ml-1">{option.label}</span>
                </span>
              </label>
            ))}
          </div>
        </div>

        {/* Tags */}
        <div className="space-y-3">
          <h4 className="font-medium text-gray-900 dark:text-white text-sm flex items-center gap-2">
            <Tag className="h-4 w-4" />
            Tags
          </h4>
          
          {/* Tag Input */}
          <div className="relative">
            <input
              type="text"
              placeholder="Add tag..."
              value={tagInput}
              onChange={(e) => setTagInput(e.target.value)}
              onKeyPress={handleTagInputKeyPress}
              className="w-full px-3 py-2 text-sm bg-gray-50 dark:bg-gray-700 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-primary-500 focus:border-transparent"
            />
          </div>

          {/* Available Tags */}
          <div className="flex flex-wrap gap-1">
            {availableTags.filter(tag => !filters.tags.includes(tag)).slice(0, 6).map((tag) => (
              <button
                key={tag}
                onClick={() => handleTagAdd(tag)}
                className="px-2 py-1 text-xs bg-gray-100 dark:bg-gray-700 text-gray-700 dark:text-gray-300 rounded-full hover:bg-primary-100 dark:hover:bg-primary-900/20 hover:text-primary-700 dark:hover:text-primary-300 transition-colors"
              >
                {tag}
              </button>
            ))}
          </div>

          {/* Selected Tags */}
          {filters.tags.length > 0 && (
            <div className="space-y-2">
              <div className="text-xs font-medium text-gray-500 dark:text-gray-400">Selected:</div>
              <div className="flex flex-wrap gap-1">
                {filters.tags.map((tag) => (
                  <span
                    key={tag}
                    className="inline-flex items-center gap-1 px-2 py-1 text-xs bg-primary-100 dark:bg-primary-900/20 text-primary-700 dark:text-primary-300 rounded-full"
                  >
                    {tag}
                    <button
                      onClick={() => handleTagRemove(tag)}
                      className="hover:text-primary-900 dark:hover:text-primary-100"
                    >
                      <X className="h-3 w-3" />
                    </button>
                  </span>
                ))}
              </div>
            </div>
          )}
        </div>
      </div>
    </motion.div>
  )
}