import axios, { AxiosInstance, AxiosRequestConfig, AxiosResponse } from 'axios'
import toast from 'react-hot-toast'

// Secure token storage utility
class SecureTokenStorage {
  private static instance: SecureTokenStorage
  private tokenKey = 'juliaos_auth_token'
  private refreshTokenKey = 'juliaos_refresh_token'

  static getInstance(): SecureTokenStorage {
    if (!SecureTokenStorage.instance) {
      SecureTokenStorage.instance = new SecureTokenStorage()
    }
    return SecureTokenStorage.instance
  }

  // Check if we're in a secure context
  private isSecureContext(): boolean {
    return typeof window !== 'undefined' && 
           (window.location.protocol === 'https:' || 
            window.location.hostname === 'localhost' ||
            window.location.hostname === '127.0.0.1')
  }

  // Store token securely using httpOnly cookies when possible
  setToken(token: string, refreshToken?: string): void {
    if (typeof window === 'undefined') return

    try {
      // Try to use httpOnly cookies if in secure context
      if (this.isSecureContext()) {
        // Store in httpOnly cookie via API endpoint (recommended)
        // For now, use sessionStorage as fallback
        sessionStorage.setItem(this.tokenKey, token)
        if (refreshToken) {
          sessionStorage.setItem(this.refreshTokenKey, refreshToken)
        }
      } else {
        // Fallback to sessionStorage (better than localStorage)
        sessionStorage.setItem(this.tokenKey, token)
        if (refreshToken) {
          sessionStorage.setItem(this.refreshTokenKey, refreshToken)
        }
      }
    } catch (error) {
      console.warn('Failed to store auth token securely:', error)
      // Last resort: in-memory storage (will be lost on page refresh)
      this.memoryToken = token
      this.memoryRefreshToken = refreshToken
    }
  }

  getToken(): string | null {
    if (typeof window === 'undefined') return null

    try {
      // Try sessionStorage first
      let token = sessionStorage.getItem(this.tokenKey)
      if (token) return token

      // Check localStorage as fallback for existing users
      token = localStorage.getItem('auth_token')
      if (token) {
        // Migrate to secure storage
        this.setToken(token)
        localStorage.removeItem('auth_token')
        return token
      }

      // Check in-memory storage
      return this.memoryToken || null
    } catch (error) {
      console.warn('Failed to retrieve auth token:', error)
      return this.memoryToken || null
    }
  }

  getRefreshToken(): string | null {
    if (typeof window === 'undefined') return null

    try {
      return sessionStorage.getItem(this.refreshTokenKey) || this.memoryRefreshToken || null
    } catch (error) {
      return this.memoryRefreshToken || null
    }
  }

  clearTokens(): void {
    if (typeof window === 'undefined') return

    try {
      sessionStorage.removeItem(this.tokenKey)
      sessionStorage.removeItem(this.refreshTokenKey)
      localStorage.removeItem('auth_token') // Clean up legacy storage
    } catch (error) {
      console.warn('Failed to clear tokens:', error)
    }

    this.memoryToken = null
    this.memoryRefreshToken = null
  }

  // In-memory storage as last resort
  private memoryToken: string | null = null
  private memoryRefreshToken: string | null = null
}

// Create axios instance with default config
const createApiClient = (): AxiosInstance => {
  const baseURL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8052/api/v1'
  const tokenStorage = SecureTokenStorage.getInstance()
  
  const client = axios.create({
    baseURL,
    timeout: 30000, // 30 seconds
    headers: {
      'Content-Type': 'application/json',
    },
    // Enable credentials for cookie-based auth when implemented
    withCredentials: true,
  })

  // Request interceptor
  client.interceptors.request.use(
    (config) => {
      // Add auth token if available
      const token = tokenStorage.getToken()
      if (token) {
        config.headers.Authorization = `Bearer ${token}`
      }
      
      // Add CSRF token if available
      const csrfToken = typeof window !== 'undefined' ? 
        document.querySelector('meta[name="csrf-token"]')?.getAttribute('content') : null
      if (csrfToken) {
        config.headers['X-CSRF-Token'] = csrfToken
      }
      
      // Log requests in development
      if (process.env.NODE_ENV === 'development') {
        console.log(`🚀 API Request: ${config.method?.toUpperCase()} ${config.url}`)
      }
      
      return config
    },
    (error) => {
      return Promise.reject(error)
    }
  )

  // Response interceptor
  client.interceptors.response.use(
    (response: AxiosResponse) => {
      // Log successful responses in development
      if (process.env.NODE_ENV === 'development') {
        console.log(`✅ API Response: ${response.config.method?.toUpperCase()} ${response.config.url}`, response.data)
      }
      
      // Handle token refresh in response headers
      const newToken = response.headers['x-new-token']
      if (newToken) {
        tokenStorage.setToken(newToken)
      }
      
      return response
    },
    async (error) => {
      const originalRequest = error.config

      // Handle common error scenarios
      if (error.response) {
        const { status, data } = error.response
        
        switch (status) {
          case 401:
            // Try to refresh token if available
            const refreshToken = tokenStorage.getRefreshToken()
            if (refreshToken && !originalRequest._retry) {
              originalRequest._retry = true
              
              try {
                // Attempt token refresh
                const refreshResponse = await client.post('/auth/refresh', {
                  refresh_token: refreshToken
                })
                
                const newToken = refreshResponse.data.access_token
                const newRefreshToken = refreshResponse.data.refresh_token
                
                tokenStorage.setToken(newToken, newRefreshToken)
                
                // Retry original request with new token
                originalRequest.headers.Authorization = `Bearer ${newToken}`
                return client(originalRequest)
              } catch (refreshError) {
                // Refresh failed, clear tokens and redirect to login
                tokenStorage.clearTokens()
                toast.error('Session expired. Please log in again.')
                if (typeof window !== 'undefined') {
                  window.location.href = '/login'
                }
                return Promise.reject(refreshError)
              }
            } else {
              // No refresh token or retry already attempted
              tokenStorage.clearTokens()
              toast.error('Authentication required')
              if (typeof window !== 'undefined') {
                window.location.href = '/login'
              }
            }
            break
          case 403:
            toast.error('Access denied')
            break
          case 404:
            // Don't show toast for 404s, let components handle them
            break
          case 429:
            const retryAfter = error.response.headers['retry-after']
            const message = retryAfter ? 
              `Too many requests. Please wait ${retryAfter} seconds.` : 
              'Too many requests. Please slow down.'
            toast.error(message)
            break
          case 500:
            toast.error('Server error. Please try again later.')
            break
          default:
            // Handle structured error responses
            const errorMessage = data?.error?.message || data?.error || data?.message || 'An error occurred'
            toast.error(errorMessage)
        }
        
        // Log errors in development with more context
        if (process.env.NODE_ENV === 'development') {
          console.error(`❌ API Error: ${error.config?.method?.toUpperCase()} ${error.config?.url}`, {
            status,
            data,
            headers: error.response.headers,
            request_id: data?.error?.request_id
          })
        }
      } else if (error.request) {
        // Network error
        toast.error('Network error. Please check your connection.')
        console.error('❌ Network Error:', error.request)
      } else {
        // Something else happened
        toast.error('An unexpected error occurred')
        console.error('❌ Unexpected Error:', error.message)
      }
      
      return Promise.reject(error)
    }
  )

  return client
}

export const apiClient = createApiClient()

// Export secure token storage for use in authentication flows
export const tokenStorage = SecureTokenStorage.getInstance()

// API helper functions
export const api = {
  // Generic CRUD operations
  get: <T = any>(url: string, config?: AxiosRequestConfig): Promise<AxiosResponse<T>> =>
    apiClient.get(url, config),
  
  post: <T = any>(url: string, data?: any, config?: AxiosRequestConfig): Promise<AxiosResponse<T>> =>
    apiClient.post(url, data, config),
  
  put: <T = any>(url: string, data?: any, config?: AxiosRequestConfig): Promise<AxiosResponse<T>> =>
    apiClient.put(url, data, config),
  
  patch: <T = any>(url: string, data?: any, config?: AxiosRequestConfig): Promise<AxiosResponse<T>> =>
    apiClient.patch(url, data, config),
  
  delete: <T = any>(url: string, config?: AxiosRequestConfig): Promise<AxiosResponse<T>> =>
    apiClient.delete(url, config),

  // Marketplace specific endpoints
  marketplace: {
    // Agent discovery
    getAgents: (params?: {
      category?: string
      tags?: string[]
      featured_only?: boolean
      sort_by?: string
      limit?: number
      offset?: number
    }) => {
      const searchParams = new URLSearchParams()
      if (params) {
        Object.entries(params).forEach(([key, value]) => {
          if (value !== undefined && value !== null) {
            if (Array.isArray(value)) {
              value.forEach(v => searchParams.append(key, v.toString()))
            } else {
              searchParams.append(key, value.toString())
            }
          }
        })
      }
      return apiClient.get(`/marketplace/agents?${searchParams.toString()}`)
    },

    getAgent: (agentId: string) =>
      apiClient.get(`/marketplace/agents/${agentId}`),

    publishAgent: (agentId: string, data: any) =>
      apiClient.post(`/marketplace/agents/${agentId}/publish`, data),

    deployAgent: (agentId: string, config?: any) =>
      apiClient.post(`/marketplace/agents/${agentId}/deploy`, { config }),

    // Categories and stats
    getCategories: () =>
      apiClient.get('/marketplace/categories'),

    getStats: () =>
      apiClient.get('/marketplace/stats'),

    // Analytics
    getAnalyticsOverview: () =>
      apiClient.get('/marketplace/analytics/overview'),

    getLeaderboard: (params?: { limit?: number; metric?: string }) => {
      const searchParams = new URLSearchParams()
      if (params) {
        Object.entries(params).forEach(([key, value]) => {
          if (value !== undefined) {
            searchParams.append(key, value.toString())
          }
        })
      }
      return apiClient.get(`/marketplace/analytics/leaderboard?${searchParams.toString()}`)
    },

    getAgentPerformance: (agentId: string) =>
      apiClient.get(`/marketplace/analytics/agents/${agentId}/performance`),

    getAgentTimeseries: (agentId: string, days?: number) => {
      const params = days ? `?days=${days}` : ''
      return apiClient.get(`/marketplace/analytics/agents/${agentId}/timeseries${params}`)
    },

    // Execution tracking
    startExecution: (agentId: string, data?: any) =>
      apiClient.post(`/marketplace/analytics/agents/${agentId}/execution/start`, data),

    completeExecution: (executionId: string, data: any) =>
      apiClient.post(`/marketplace/analytics/executions/${executionId}/complete`, data),

    // Swarm coordination
    getSwarms: () =>
      apiClient.get('/marketplace/swarms'),

    getSwarmPerformance: (swarmId: string) =>
      apiClient.get(`/marketplace/swarms/${swarmId}/performance`),

    triggerSwarmAnalysis: (timeWindowHours?: number) =>
      apiClient.post('/marketplace/swarms/analyze', { time_window_hours: timeWindowHours }),

    getAgentConnections: (agentId: string) =>
      apiClient.get(`/marketplace/agents/${agentId}/connections`),

    getSwarmGraphData: () =>
      apiClient.get('/marketplace/swarms/graph-data'),
  },

  // Core JuliaOS endpoints
  agents: {
    list: () => apiClient.get('/agents'),
    get: (agentId: string) => apiClient.get(`/agents/${agentId}`),
    create: (data: any) => apiClient.post('/agents', data),
    update: (agentId: string, data: any) => apiClient.put(`/agents/${agentId}`, data),
    delete: (agentId: string) => apiClient.delete(`/agents/${agentId}`),
    webhook: (agentId: string, data?: any) => apiClient.post(`/agents/${agentId}/webhook`, data),
    logs: (agentId: string) => apiClient.get(`/agents/${agentId}/logs`),
    output: (agentId: string) => apiClient.get(`/agents/${agentId}/output`),
  },

  // Tools and strategies
  tools: {
    list: () => apiClient.get('/tools'),
  },

  strategies: {
    list: () => apiClient.get('/strategies'),
  },
}

// Export default as well for convenience
export default apiClient

// Type definitions for common API responses
export interface ApiResponse<T = any> {
  data: T
  message?: string
  error?: string
}

export interface PaginatedResponse<T = any> {
  data: T[]
  total: number
  page: number
  limit: number
  hasNext: boolean
  hasPrev: boolean
}

// Error handling utilities
export class ApiError extends Error {
  constructor(
    message: string,
    public status?: number,
    public code?: string,
    public data?: any
  ) {
    super(message)
    this.name = 'ApiError'
  }
}

export const handleApiError = (error: any): never => {
  if (error.response) {
    throw new ApiError(
      error.response.data?.message || error.response.data?.error || 'API Error',
      error.response.status,
      error.response.data?.code,
      error.response.data
    )
  } else if (error.request) {
    throw new ApiError('Network Error', 0, 'NETWORK_ERROR')
  } else {
    throw new ApiError(error.message || 'Unknown Error', 0, 'UNKNOWN_ERROR')
  }
}