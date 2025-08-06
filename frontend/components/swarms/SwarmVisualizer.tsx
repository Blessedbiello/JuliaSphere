'use client'

import { useEffect, useRef, useState, useCallback } from 'react'
import { useQuery } from 'react-query'
import dynamic from 'next/dynamic'
import { motion, AnimatePresence } from 'framer-motion'
import { AlertCircle, Loader2, RefreshCw } from 'lucide-react'
import { api } from '@/lib/api'
import { SwarmGraphData, GraphNode, GraphEdge } from '@/types'
import toast from 'react-hot-toast'

// Dynamically import CytoscapeComponent to avoid SSR issues
const CytoscapeComponent = dynamic(
  () => import('react-cytoscapejs'),
  { 
    ssr: false,
    loading: () => (
      <div className="flex items-center justify-center h-full">
        <Loader2 className="h-8 w-8 animate-spin text-primary-500" />
      </div>
    )
  }
)

interface SwarmVisualizerProps {
  onSwarmSelect?: (swarmId: string | null) => void
  onAgentSelect?: (agentId: string | null) => void
  selectedSwarmId?: string | null
  selectedAgentId?: string | null
  autoRefresh?: boolean
}

// Cytoscape.js styles
const cytoscapeStyles = [
  // Node styles
  {
    selector: 'node',
    style: {
      'width': 50,
      'height': 50,
      'background-color': '#3B82F6',
      'border-width': 2,
      'border-color': '#1E40AF',
      'label': 'data(label)',
      'text-valign': 'bottom',
      'text-halign': 'center',
      'text-margin-y': 5,
      'font-size': '12px',
      'font-weight': 600,
      'color': '#374151',
      'text-wrap': 'wrap',
      'text-max-width': '80px',
      'overlay-padding': '6px',
      'z-index': 10,
    }
  },
  // Node styles by strategy
  {
    selector: 'node[strategy = "plan_execute"]',
    style: {
      'background-color': '#8B5CF6',
      'border-color': '#7C3AED',
      'shape': 'diamond',
    }
  },
  {
    selector: 'node[strategy = "adder"]',
    style: {
      'background-color': '#10B981',
      'border-color': '#059669',
      'shape': 'circle',
    }
  },
  {
    selector: 'node[strategy = "blogger"]',
    style: {
      'background-color': '#F59E0B',
      'border-color': '#D97706',
      'shape': 'square',
    }
  },
  {
    selector: 'node[strategy = "telegram_moderator"]',
    style: {
      'background-color': '#EF4444',
      'border-color': '#DC2626',
      'shape': 'triangle',
    }
  },
  // Node status styles
  {
    selector: 'node[status = "healthy"]',
    style: {
      'border-color': '#10B981',
      'border-width': 3,
    }
  },
  {
    selector: 'node[status = "warning"]',
    style: {
      'border-color': '#F59E0B',
      'border-width': 3,
    }
  },
  {
    selector: 'node[status = "error"]',
    style: {
      'border-color': '#EF4444',
      'border-width': 3,
    }
  },
  {
    selector: 'node[status = "idle"]',
    style: {
      'border-color': '#6B7280',
      'border-width': 2,
      'opacity': 0.7,
    }
  },
  // Featured nodes
  {
    selector: 'node[is_featured = "true"]',
    style: {
      'border-width': 4,
      'border-style': 'double',
    }
  },
  // Selected node
  {
    selector: 'node:selected',
    style: {
      'border-width': 4,
      'border-color': '#EC4899',
      'background-color': '#F9A8D4',
      'z-index': 20,
    }
  },
  // Hovered node
  {
    selector: 'node:active',
    style: {
      'overlay-opacity': 0.2,
      'overlay-color': '#3B82F6',
    }
  },
  // Edge styles
  {
    selector: 'edge',
    style: {
      'width': 2,
      'line-color': '#9CA3AF',
      'target-arrow-color': '#9CA3AF',
      'target-arrow-shape': 'triangle',
      'curve-style': 'bezier',
      'label': 'data(label)',
      'font-size': '10px',
      'text-rotation': 'autorotate',
      'text-margin-x': 0,
      'text-margin-y': -10,
      'color': '#6B7280',
      'z-index': 1,
    }
  },
  // Edge styles by connection type
  {
    selector: 'edge[label = "delegates_to"]',
    style: {
      'line-color': '#3B82F6',
      'target-arrow-color': '#3B82F6',
      'line-style': 'solid',
    }
  },
  {
    selector: 'edge[label = "feeds_data_to"]',
    style: {
      'line-color': '#10B981',
      'target-arrow-color': '#10B981',
      'line-style': 'dashed',
    }
  },
  {
    selector: 'edge[label = "coordinates_with"]',
    style: {
      'line-color': '#F59E0B',
      'target-arrow-color': '#F59E0B',
      'line-style': 'dotted',
      'target-arrow-shape': 'circle',
    }
  },
  // Edge strength styles
  {
    selector: 'edge[strength >= 0.7]',
    style: {
      'width': 4,
      'opacity': 1,
    }
  },
  {
    selector: 'edge[strength >= 0.4][strength < 0.7]',
    style: {
      'width': 3,
      'opacity': 0.8,
    }
  },
  {
    selector: 'edge[strength < 0.4]',
    style: {
      'width': 2,
      'opacity': 0.6,
    }
  },
  // Selected edge
  {
    selector: 'edge:selected',
    style: {
      'line-color': '#EC4899',
      'target-arrow-color': '#EC4899',
      'width': 4,
      'z-index': 10,
    }
  },
]

// Layout options
const layoutOptions = {
  name: 'cose-bilkent',
  quality: 'proof',
  nodeDimensionsIncludeLabels: true,
  refresh: 4,
  fit: true,
  padding: 30,
  randomize: false,
  nodeRepulsion: 4500,
  idealEdgeLength: 50,
  edgeElasticity: 0.45,
  nestingFactor: 0.1,
  gravity: 0.25,
  numIter: 2500,
  tile: false,
  animate: 'end',
  animationDuration: 1000,
  tilingPaddingVertical: 10,
  tilingPaddingHorizontal: 10,
}

export function SwarmVisualizer({
  onSwarmSelect,
  onAgentSelect,
  selectedSwarmId,
  selectedAgentId,
  autoRefresh = true,
}: SwarmVisualizerProps) {
  const cyRef = useRef<any>(null)
  const [isInitialized, setIsInitialized] = useState(false)
  const [lastRefresh, setLastRefresh] = useState(Date.now())

  // Fetch swarm graph data
  const { 
    data: graphData, 
    isLoading, 
    error, 
    refetch,
    isRefetching 
  } = useQuery<SwarmGraphData>(
    ['swarmGraphData', lastRefresh],
    () => api.marketplace.getSwarmGraphData().then(res => res.data),
    {
      refetchInterval: autoRefresh ? 10000 : false, // Refresh every 10 seconds if auto-refresh is on
      onError: (error: any) => {
        console.error('Failed to fetch swarm data:', error)
        toast.error('Failed to load swarm visualization')
      },
      onSuccess: (data) => {
        console.log('Swarm graph data loaded:', data)
      }
    }
  )

  // Auto-refresh functionality
  useEffect(() => {
    if (autoRefresh) {
      const interval = setInterval(() => {
        setLastRefresh(Date.now())
      }, 10000) // Refresh every 10 seconds
      
      return () => clearInterval(interval)
    }
  }, [autoRefresh])

  // Initialize Cytoscape
  const initializeCytoscape = useCallback((cy: any) => {
    if (!cy || isInitialized) return
    
    cyRef.current = cy
    setIsInitialized(true)

    // Node click handler
    cy.on('tap', 'node', (event: any) => {
      const node = event.target
      const agentId = node.data('id')
      
      console.log('Node clicked:', agentId)
      onAgentSelect?.(agentId)
      
      // Highlight connected edges
      const connectedEdges = node.connectedEdges()
      cy.elements().removeClass('highlighted')
      node.addClass('highlighted')
      connectedEdges.addClass('highlighted')
    })

    // Edge click handler
    cy.on('tap', 'edge', (event: any) => {
      const edge = event.target
      const sourceId = edge.data('source')
      const targetId = edge.data('target')
      
      console.log('Edge clicked:', sourceId, '->', targetId)
      
      // Highlight the edge and connected nodes
      cy.elements().removeClass('highlighted')
      edge.addClass('highlighted')
      edge.source().addClass('highlighted')
      edge.target().addClass('highlighted')
    })

    // Background click handler
    cy.on('tap', (event: any) => {
      if (event.target === cy) {
        // Clicked on background
        cy.elements().removeClass('highlighted')
        onAgentSelect?.(null)
        onSwarmSelect?.(null)
      }
    })

    // Double-click to fit view
    cy.on('dblclick', (event: any) => {
      if (event.target === cy) {
        cy.fit(undefined, 50)
      }
    })

    console.log('Cytoscape initialized')
  }, [isInitialized, onAgentSelect, onSwarmSelect])

  // Update graph when data changes
  useEffect(() => {
    if (!cyRef.current || !graphData) return

    const cy = cyRef.current
    
    try {
      // Clear existing elements
      cy.elements().remove()
      
      // Add new elements
      if (graphData.elements) {
        cy.add(graphData.elements.nodes)
        cy.add(graphData.elements.edges)
        
        // Run layout
        const layout = cy.layout(layoutOptions)
        layout.run()
        
        console.log('Graph updated with', graphData.elements.nodes.length, 'nodes and', graphData.elements.edges.length, 'edges')
      }
    } catch (error) {
      console.error('Error updating graph:', error)
      toast.error('Failed to update graph visualization')
    }
  }, [graphData])

  // Highlight selected agent
  useEffect(() => {
    if (!cyRef.current) return

    const cy = cyRef.current
    
    // Clear previous selections
    cy.elements().removeClass('selected highlighted')
    
    if (selectedAgentId) {
      const selectedNode = cy.$(`node[id="${selectedAgentId}"]`)
      if (selectedNode.length > 0) {
        selectedNode.addClass('selected highlighted')
        selectedNode.connectedEdges().addClass('highlighted')
        
        // Center on selected node
        cy.center(selectedNode)
      }
    }
  }, [selectedAgentId])

  const handleRefresh = useCallback(() => {
    setLastRefresh(Date.now())
    refetch()
  }, [refetch])

  if (error) {
    return (
      <div className="flex flex-col items-center justify-center h-full text-center p-8">
        <AlertCircle className="h-12 w-12 text-error-500 mb-4" />
        <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-2">
          Failed to Load Swarm Data
        </h3>
        <p className="text-gray-600 dark:text-gray-400 mb-4">
          Unable to fetch the swarm visualization data. Please check if the JuliaOS backend is running.
        </p>
        <button
          onClick={handleRefresh}
          className="flex items-center gap-2 px-4 py-2 bg-primary-600 text-white rounded-lg hover:bg-primary-700 transition-colors"
        >
          <RefreshCw className="h-4 w-4" />
          Retry
        </button>
      </div>
    )
  }

  if (isLoading) {
    return (
      <div className="flex flex-col items-center justify-center h-full">
        <Loader2 className="h-12 w-12 animate-spin text-primary-500 mb-4" />
        <p className="text-gray-600 dark:text-gray-400">Loading swarm visualization...</p>
      </div>
    )
  }

  if (!graphData || !graphData.elements || graphData.elements.nodes.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center h-full text-center p-8">
        <div className="w-16 h-16 bg-gray-200 dark:bg-gray-700 rounded-full flex items-center justify-center mb-4">
          <span className="text-2xl">🤖</span>
        </div>
        <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-2">
          No Active Swarms
        </h3>
        <p className="text-gray-600 dark:text-gray-400 mb-4">
          No agent coordination patterns detected. Create some agents and run them to see swarm formations.
        </p>
        <button
          onClick={handleRefresh}
          className="flex items-center gap-2 px-4 py-2 bg-primary-600 text-white rounded-lg hover:bg-primary-700 transition-colors"
        >
          <RefreshCw className="h-4 w-4" />
          Check for Swarms
        </button>
      </div>
    )
  }

  return (
    <div className="relative h-full w-full">
      {/* Loading overlay */}
      <AnimatePresence>
        {isRefetching && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="absolute top-4 right-4 z-20 bg-white dark:bg-gray-800 rounded-lg shadow-lg border border-gray-200 dark:border-gray-700 px-3 py-2"
          >
            <div className="flex items-center gap-2">
              <Loader2 className="h-4 w-4 animate-spin text-primary-500" />
              <span className="text-sm text-gray-600 dark:text-gray-400">Updating...</span>
            </div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Stats overlay */}
      <div className="absolute top-4 left-4 z-10 bg-white dark:bg-gray-800 rounded-lg shadow-lg border border-gray-200 dark:border-gray-700 px-4 py-3">
        <div className="flex items-center gap-4 text-sm">
          <div className="flex items-center gap-1">
            <div className="w-2 h-2 bg-primary-500 rounded-full"></div>
            <span className="text-gray-600 dark:text-gray-400">
              {graphData.stats.total_agents} Agents
            </span>
          </div>
          <div className="flex items-center gap-1">
            <div className="w-2 h-2 bg-secondary-500 rounded-full"></div>
            <span className="text-gray-600 dark:text-gray-400">
              {graphData.stats.swarm_count} Swarms
            </span>
          </div>
          <div className="flex items-center gap-1">
            <div className="w-2 h-2 bg-success-500 rounded-full"></div>
            <span className="text-gray-600 dark:text-gray-400">
              {graphData.stats.total_connections} Connections
            </span>
          </div>
        </div>
      </div>

      {/* Legend */}
      <div className="absolute bottom-4 left-4 z-10 bg-white dark:bg-gray-800 rounded-lg shadow-lg border border-gray-200 dark:border-gray-700 px-4 py-3">
        <h4 className="text-sm font-semibold text-gray-900 dark:text-white mb-2">Legend</h4>
        <div className="space-y-2 text-xs">
          <div className="flex items-center gap-2">
            <div className="w-3 h-3 bg-blue-500 rounded-full border-2 border-blue-700"></div>
            <span className="text-gray-600 dark:text-gray-400">Default Agent</span>
          </div>
          <div className="flex items-center gap-2">
            <div className="w-3 h-3 bg-purple-500 rounded border-2 border-purple-700" style={{ clipPath: 'polygon(50% 0%, 0% 100%, 100% 100%)' }}></div>
            <span className="text-gray-600 dark:text-gray-400">Plan & Execute</span>
          </div>
          <div className="flex items-center gap-2">
            <div className="w-3 h-3 bg-green-500 rounded-full border-2 border-green-700"></div>
            <span className="text-gray-600 dark:text-gray-400">Simple Logic</span>
          </div>
          <div className="flex items-center gap-2">
            <div className="w-3 h-3 bg-orange-500 rounded border-2 border-orange-700"></div>
            <span className="text-gray-600 dark:text-gray-400">Content Creation</span>
          </div>
        </div>
      </div>

      {/* Cytoscape container */}
      <div className="cytoscape-container h-full w-full">
        <CytoscapeComponent
          elements={[]}
          style={{ width: '100%', height: '100%' }}
          stylesheet={cytoscapeStyles}
          layout={layoutOptions}
          cy={initializeCytoscape}
          wheelSensitivity={0.1}
          minZoom={0.3}
          maxZoom={3}
        />
      </div>
    </div>
  )
}