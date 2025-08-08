'use client'

import { useState, useEffect } from 'react'
import { useParams } from 'next/navigation'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { 
  ArrowLeft,
  Bot,
  Play,
  Pause,
  Square,
  Activity,
  Settings,
  Clock,
  Zap,
  AlertCircle,
  CheckCircle,
  XCircle
} from 'lucide-react'
import Link from 'next/link'
import { api } from '@/lib/api'

interface Agent {
  id: string
  name: string
  description: string
  state: 'CREATED' | 'RUNNING' | 'PAUSED' | 'STOPPED'
  trigger_type: 'PERIODIC' | 'WEBHOOK'
  blueprint: {
    tools: Array<{ name: string; config: any }>
    strategy: { name: string; config: any }
    trigger: { type: string; params: any }
  }
  created_at: string
  updated_at: string
  last_execution?: string
  execution_count?: number
  success_rate?: number
}

interface LogEntry {
  timestamp: string
  level: 'DEBUG' | 'INFO' | 'WARN' | 'ERROR'
  message: string
  execution_id?: string
  metadata?: any
}

const stateColors = {
  CREATED: 'bg-gray-100 text-gray-800',
  RUNNING: 'bg-green-100 text-green-800',
  PAUSED: 'bg-yellow-100 text-yellow-800',
  STOPPED: 'bg-red-100 text-red-800'
}

const logLevelColors = {
  DEBUG: 'text-gray-600',
  INFO: 'text-blue-600',
  WARN: 'text-yellow-600',
  ERROR: 'text-red-600'
}

const logLevelIcons = {
  DEBUG: Settings,
  INFO: CheckCircle,
  WARN: AlertCircle,
  ERROR: XCircle
}

export default function AgentDetailsPage() {
  const params = useParams()
  const agentId = params.id as string
  
  const [agent, setAgent] = useState<Agent | null>(null)
  const [logs, setLogs] = useState<LogEntry[]>([])
  const [output, setOutput] = useState<any>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    if (agentId) {
      loadAgentData()
    }
  }, [agentId])

  const loadAgentData = async () => {
    try {
      setLoading(true)
      
      // Load agent details, logs, and output in parallel
      const [agentResponse, logsResponse, outputResponse] = await Promise.allSettled([
        api.get(`/agents/${agentId}`),
        api.get(`/agents/${agentId}/logs`),
        api.get(`/agents/${agentId}/output`)
      ])

      if (agentResponse.status === 'fulfilled') {
        // Backend returns data nested in a data object
        setAgent(agentResponse.value.data.data || agentResponse.value.data)
      } else {
        throw new Error('Failed to load agent details')
      }

      if (logsResponse.status === 'fulfilled') {
        setLogs(logsResponse.value.data?.logs || [])
      }

      if (outputResponse.status === 'fulfilled') {
        setOutput(outputResponse.value.data)
      }

      setError(null)
    } catch (err) {
      console.error('Failed to load agent data:', err)
      setError('Failed to load agent data. Please check that the backend is running.')
    } finally {
      setLoading(false)
    }
  }

  const updateAgentState = async (newState: string) => {
    if (!agent) return

    try {
      await api.put(`/agents/${agent.id}`, { state: newState })
      setAgent({ ...agent, state: newState as any })
    } catch (err) {
      console.error('Failed to update agent state:', err)
      alert('Failed to update agent state')
    }
  }

  const triggerAgent = async () => {
    if (!agent) return

    try {
      await api.post(`/agents/${agent.id}/webhook`, {})
      alert('Agent triggered successfully!')
      // Reload data to get updated logs and output
      setTimeout(() => loadAgentData(), 2000)
    } catch (err) {
      console.error('Failed to trigger agent:', err)
      alert('Failed to trigger agent')
    }
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-64">
        <div className="text-center">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600 mx-auto"></div>
          <p className="mt-2 text-gray-600">Loading agent details...</p>
        </div>
      </div>
    )
  }

  if (error || !agent) {
    return (
      <div className="text-center py-12">
        <Bot className="h-12 w-12 text-gray-400 mx-auto mb-4" />
        <h3 className="text-lg font-medium text-gray-900 mb-2">Agent Not Found</h3>
        <p className="text-gray-600 mb-4">{error || 'The requested agent could not be found.'}</p>
        <Button asChild>
          <Link href="/my-agents">
            <ArrowLeft className="h-4 w-4 mr-2" />
            Back to My Agents
          </Link>
        </Button>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center gap-4">
        <Button variant="outline" size="sm" asChild>
          <Link href="/my-agents">
            <ArrowLeft className="h-4 w-4 mr-2" />
            Back
          </Link>
        </Button>
        
        <div className="flex-1">
          <div className="flex items-center gap-3">
            <Bot className="h-6 w-6 text-blue-600" />
            <h1 className="text-2xl font-bold text-gray-900">{agent.name}</h1>
            <Badge className={stateColors[agent.state || 'CREATED']}>
              {agent.state?.toLowerCase() || 'unknown'}
            </Badge>
          </div>
          <p className="text-gray-600 mt-1">{agent.description}</p>
        </div>

        {/* Action Buttons */}
        <div className="flex gap-2">
          {agent.state === 'RUNNING' && (
            <>
              <Button
                variant="outline"
                onClick={() => updateAgentState('PAUSED')}
              >
                <Pause className="h-4 w-4 mr-2" />
                Pause
              </Button>
              <Button
                onClick={() => triggerAgent()}
              >
                <Zap className="h-4 w-4 mr-2" />
                Trigger Now
              </Button>
            </>
          )}
          
          {(agent.state === 'PAUSED' || agent.state === 'CREATED') && (
            <Button onClick={() => updateAgentState('RUNNING')}>
              <Play className="h-4 w-4 mr-2" />
              Start
            </Button>
          )}
          
          {agent.state === 'RUNNING' && (
            <Button
              variant="destructive"
              onClick={() => updateAgentState('STOPPED')}
            >
              <Square className="h-4 w-4 mr-2" />
              Stop
            </Button>
          )}
        </div>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-gray-600">Executions</p>
                <p className="text-2xl font-bold text-gray-900">{agent.execution_count || 0}</p>
              </div>
              <Activity className="h-8 w-8 text-blue-600" />
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-gray-600">Success Rate</p>
                <p className="text-2xl font-bold text-green-600">
                  {agent.success_rate ? `${(agent.success_rate * 100).toFixed(1)}%` : 'N/A'}
                </p>
              </div>
              <CheckCircle className="h-8 w-8 text-green-600" />
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-gray-600">Trigger Type</p>
                <p className="text-2xl font-bold text-blue-600 capitalize">
                  {agent.trigger_type.toLowerCase()}
                </p>
              </div>
              <Zap className="h-8 w-8 text-blue-600" />
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-gray-600">Last Run</p>
                <p className="text-lg font-bold text-gray-900">
                  {agent.last_execution 
                    ? new Date(agent.last_execution).toLocaleDateString()
                    : 'Never'
                  }
                </p>
              </div>
              <Clock className="h-8 w-8 text-gray-600" />
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Tabbed Content */}
      <Tabs defaultValue="overview" className="space-y-4">
        <TabsList>
          <TabsTrigger value="overview">Overview</TabsTrigger>
          <TabsTrigger value="logs">Logs</TabsTrigger>
          <TabsTrigger value="output">Latest Output</TabsTrigger>
          <TabsTrigger value="configuration">Configuration</TabsTrigger>
        </TabsList>

        <TabsContent value="overview">
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            <Card>
              <CardHeader>
                <CardTitle>Agent Information</CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <div>
                  <label className="text-sm font-medium text-gray-600">ID</label>
                  <p className="font-mono text-sm bg-gray-50 p-2 rounded">{agent.id}</p>
                </div>
                <div>
                  <label className="text-sm font-medium text-gray-600">Created</label>
                  <p>{new Date(agent.created_at).toLocaleString()}</p>
                </div>
                <div>
                  <label className="text-sm font-medium text-gray-600">Last Updated</label>
                  <p>{new Date(agent.updated_at).toLocaleString()}</p>
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle>Tools & Strategy</CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <div>
                  <label className="text-sm font-medium text-gray-600">Strategy</label>
                  <p className="font-medium">{agent.blueprint?.strategy?.name || 'Not available'}</p>
                </div>
                <div>
                  <label className="text-sm font-medium text-gray-600">Tools ({agent.blueprint?.tools?.length || 0})</label>
                  <div className="space-y-2">
                    {agent.blueprint?.tools?.length > 0 ? (
                      agent.blueprint.tools.map((tool, index) => (
                        <div key={index} className="flex items-center justify-between p-2 bg-gray-50 rounded">
                          <span className="font-medium">{tool.name}</span>
                          <Badge variant="secondary">Tool</Badge>
                        </div>
                      ))
                    ) : (
                      <p className="text-gray-500">No tools data available</p>
                    )}
                  </div>
                </div>
              </CardContent>
            </Card>
          </div>
        </TabsContent>

        <TabsContent value="logs">
          <Card>
            <CardHeader>
              <CardTitle>Execution Logs</CardTitle>
              <CardDescription>Recent activity and system messages</CardDescription>
            </CardHeader>
            <CardContent>
              {logs.length === 0 ? (
                <div className="text-center py-8">
                  <Activity className="h-8 w-8 text-gray-400 mx-auto mb-2" />
                  <p className="text-gray-600">No logs available</p>
                </div>
              ) : (
                <div className="space-y-2 max-h-96 overflow-y-auto">
                  {logs.map((log, index) => {
                    const LevelIcon = logLevelIcons[log.level]
                    return (
                      <div key={index} className="flex items-start gap-3 p-3 bg-gray-50 rounded">
                        <LevelIcon className={`h-4 w-4 mt-0.5 ${logLevelColors[log.level]}`} />
                        <div className="flex-1 min-w-0">
                          <div className="flex items-center gap-2">
                            <Badge variant="outline" className="text-xs">
                              {log.level}
                            </Badge>
                            <span className="text-xs text-gray-500">
                              {new Date(log.timestamp).toLocaleString()}
                            </span>
                            {log.execution_id && (
                              <span className="text-xs text-gray-400 font-mono">
                                {log.execution_id.slice(0, 8)}
                              </span>
                            )}
                          </div>
                          <p className="text-sm text-gray-900 mt-1">{log.message}</p>
                          {log.metadata && (
                            <pre className="text-xs text-gray-600 mt-1 bg-white p-2 rounded border">
                              {JSON.stringify(log.metadata, null, 2)}
                            </pre>
                          )}
                        </div>
                      </div>
                    )
                  })}
                </div>
              )}
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="output">
          <Card>
            <CardHeader>
              <CardTitle>Latest Output</CardTitle>
              <CardDescription>Results from the most recent execution</CardDescription>
            </CardHeader>
            <CardContent>
              {!output ? (
                <div className="text-center py-8">
                  <Bot className="h-8 w-8 text-gray-400 mx-auto mb-2" />
                  <p className="text-gray-600">No output available</p>
                  <p className="text-sm text-gray-500 mt-1">Try triggering the agent to generate output</p>
                </div>
              ) : (
                <div className="space-y-4">
                  {output.execution_metadata && (
                    <div className="grid grid-cols-2 md:grid-cols-4 gap-4 p-4 bg-gray-50 rounded">
                      <div>
                        <label className="text-xs font-medium text-gray-600">Status</label>
                        <p className="text-sm font-medium">{output.execution_metadata.status}</p>
                      </div>
                      <div>
                        <label className="text-xs font-medium text-gray-600">Duration</label>
                        <p className="text-sm font-medium">{output.execution_metadata.duration_ms}ms</p>
                      </div>
                      <div>
                        <label className="text-xs font-medium text-gray-600">Tools Used</label>
                        <p className="text-sm font-medium">{output.execution_metadata.tools_used?.length || 0}</p>
                      </div>
                      <div>
                        <label className="text-xs font-medium text-gray-600">Cost</label>
                        <p className="text-sm font-medium">${output.execution_metadata.cost_incurred || '0.00'}</p>
                      </div>
                    </div>
                  )}
                  <div>
                    <label className="text-sm font-medium text-gray-600 mb-2 block">Output Data</label>
                    <pre className="text-sm bg-gray-900 text-gray-100 p-4 rounded overflow-x-auto">
                      {JSON.stringify(output.output, null, 2)}
                    </pre>
                  </div>
                </div>
              )}
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="configuration">
          <Card>
            <CardHeader>
              <CardTitle>Agent Configuration</CardTitle>
              <CardDescription>Blueprint and settings used to create this agent</CardDescription>
            </CardHeader>
            <CardContent>
              <pre className="text-sm bg-gray-900 text-gray-100 p-4 rounded overflow-x-auto">
                {JSON.stringify(agent.blueprint || {message: "Blueprint data not available from backend"}, null, 2)}
              </pre>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  )
}