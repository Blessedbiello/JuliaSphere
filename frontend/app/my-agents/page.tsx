'use client'

import { useState, useEffect } from 'react'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { 
  Play, 
  Pause, 
  Square, 
  Settings, 
  Trash2, 
  Activity, 
  Clock, 
  Zap,
  Bot,
  Plus
} from 'lucide-react'
import Link from 'next/link'
import { api } from '@/lib/api'

interface Agent {
  id: string
  name: string
  description: string
  state: 'CREATED' | 'RUNNING' | 'PAUSED' | 'STOPPED'
  trigger_type: 'PERIODIC' | 'WEBHOOK'
  created_at: string
  updated_at: string
  last_execution?: string
  execution_count?: number
  success_rate?: number
}

const stateColors = {
  CREATED: 'bg-gray-100 text-gray-800',
  RUNNING: 'bg-green-100 text-green-800',
  PAUSED: 'bg-yellow-100 text-yellow-800',
  STOPPED: 'bg-red-100 text-red-800'
}

const stateIcons = {
  CREATED: Bot,
  RUNNING: Play,
  PAUSED: Pause,
  STOPPED: Square
}

export default function MyAgentsPage() {
  const [agents, setAgents] = useState<Agent[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [activeTab, setActiveTab] = useState('all')

  useEffect(() => {
    loadAgents()
  }, [])

  const loadAgents = async () => {
    try {
      setLoading(true)
      const response = await api.get('/agents')
      setAgents(response.data || [])
      setError(null)
    } catch (err) {
      console.error('Failed to load agents:', err)
      setError('Failed to load agents. Please check that the backend is running.')
    } finally {
      setLoading(false)
    }
  }

  const updateAgentState = async (agentId: string, newState: string) => {
    try {
      await api.put(`/agents/${agentId}`, { state: newState })
      await loadAgents() // Reload agents to get updated state
    } catch (err) {
      console.error('Failed to update agent state:', err)
      alert('Failed to update agent state')
    }
  }

  const deleteAgent = async (agentId: string) => {
    if (!confirm('Are you sure you want to delete this agent? This action cannot be undone.')) {
      return
    }

    try {
      await api.delete(`/agents/${agentId}`)
      await loadAgents() // Reload agents after deletion
    } catch (err) {
      console.error('Failed to delete agent:', err)
      alert('Failed to delete agent')
    }
  }

  const triggerAgent = async (agentId: string) => {
    try {
      await api.post(`/agents/${agentId}/webhook`, {})
      alert('Agent triggered successfully!')
    } catch (err) {
      console.error('Failed to trigger agent:', err)
      alert('Failed to trigger agent')
    }
  }

  const filteredAgents = agents.filter(agent => {
    switch (activeTab) {
      case 'running':
        return agent.state === 'RUNNING'
      case 'paused':
        return agent.state === 'PAUSED'
      case 'stopped':
        return agent.state === 'STOPPED' || agent.state === 'CREATED'
      default:
        return true
    }
  })

  const AgentCard = ({ agent }: { agent: Agent }) => {
    const StateIcon = stateIcons[agent.state]
    
    return (
      <Card className="hover:shadow-md transition-shadow">
        <CardHeader className="pb-3">
          <div className="flex items-start justify-between">
            <div className="flex items-center gap-2">
              <StateIcon className="h-5 w-5 text-blue-600" />
              <div>
                <CardTitle className="text-lg">{agent.name}</CardTitle>
                <CardDescription className="mt-1">{agent.description}</CardDescription>
              </div>
            </div>
            <Badge className={stateColors[agent.state]}>
              {agent.state.toLowerCase()}
            </Badge>
          </div>
        </CardHeader>
        
        <CardContent className="pt-0">
          <div className="space-y-4">
            {/* Agent Stats */}
            <div className="grid grid-cols-3 gap-4 text-sm">
              <div className="text-center">
                <div className="font-medium text-gray-900">{agent.execution_count || 0}</div>
                <div className="text-gray-500">Executions</div>
              </div>
              <div className="text-center">
                <div className="font-medium text-gray-900">
                  {agent.success_rate ? `${(agent.success_rate * 100).toFixed(1)}%` : 'N/A'}
                </div>
                <div className="text-gray-500">Success Rate</div>
              </div>
              <div className="text-center">
                <div className="font-medium text-gray-900 capitalize">
                  {agent.trigger_type.toLowerCase()}
                </div>
                <div className="text-gray-500">Trigger</div>
              </div>
            </div>

            {/* Last Execution */}
            {agent.last_execution && (
              <div className="flex items-center gap-2 text-sm text-gray-600">
                <Clock className="h-4 w-4" />
                <span>Last run: {new Date(agent.last_execution).toLocaleDateString()}</span>
              </div>
            )}

            {/* Action Buttons */}
            <div className="flex gap-2 pt-2">
              {agent.state === 'RUNNING' && (
                <>
                  <Button
                    size="sm"
                    variant="outline"
                    onClick={() => updateAgentState(agent.id, 'PAUSED')}
                  >
                    <Pause className="h-4 w-4 mr-1" />
                    Pause
                  </Button>
                  <Button
                    size="sm"
                    variant="outline"
                    onClick={() => triggerAgent(agent.id)}
                  >
                    <Zap className="h-4 w-4 mr-1" />
                    Trigger
                  </Button>
                </>
              )}
              
              {(agent.state === 'PAUSED' || agent.state === 'CREATED') && (
                <Button
                  size="sm"
                  onClick={() => updateAgentState(agent.id, 'RUNNING')}
                >
                  <Play className="h-4 w-4 mr-1" />
                  Start
                </Button>
              )}
              
              {agent.state === 'RUNNING' && (
                <Button
                  size="sm"
                  variant="destructive"
                  onClick={() => updateAgentState(agent.id, 'STOPPED')}
                >
                  <Square className="h-4 w-4 mr-1" />
                  Stop
                </Button>
              )}

              <Button
                size="sm"
                variant="outline"
                asChild
              >
                <Link href={`/agents/${agent.id}`}>
                  <Activity className="h-4 w-4 mr-1" />
                  Details
                </Link>
              </Button>

              <Button
                size="sm"
                variant="outline"
                onClick={() => deleteAgent(agent.id)}
              >
                <Trash2 className="h-4 w-4 mr-1" />
                Delete
              </Button>
            </div>
          </div>
        </CardContent>
      </Card>
    )
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-64">
        <div className="text-center">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600 mx-auto"></div>
          <p className="mt-2 text-gray-600">Loading your agents...</p>
        </div>
      </div>
    )
  }

  if (error) {
    return (
      <div className="text-center py-12">
        <Bot className="h-12 w-12 text-gray-400 mx-auto mb-4" />
        <h3 className="text-lg font-medium text-gray-900 mb-2">Unable to Load Agents</h3>
        <p className="text-gray-600 mb-4">{error}</p>
        <Button onClick={loadAgents}>
          Try Again
        </Button>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">My Agents</h1>
          <p className="text-gray-600 mt-1">
            Manage and monitor your AI agents
          </p>
        </div>
        <Button asChild>
          <Link href="/builder">
            <Plus className="h-4 w-4 mr-2" />
            Create Agent
          </Link>
        </Button>
      </div>

      {/* Stats Overview */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <Card>
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-gray-600">Total Agents</p>
                <p className="text-2xl font-bold text-gray-900">{agents.length}</p>
              </div>
              <Bot className="h-8 w-8 text-blue-600" />
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-gray-600">Running</p>
                <p className="text-2xl font-bold text-green-600">
                  {agents.filter(a => a.state === 'RUNNING').length}
                </p>
              </div>
              <Play className="h-8 w-8 text-green-600" />
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-gray-600">Paused</p>
                <p className="text-2xl font-bold text-yellow-600">
                  {agents.filter(a => a.state === 'PAUSED').length}
                </p>
              </div>
              <Pause className="h-8 w-8 text-yellow-600" />
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-gray-600">Total Executions</p>
                <p className="text-2xl font-bold text-blue-600">
                  {agents.reduce((sum, a) => sum + (a.execution_count || 0), 0)}
                </p>
              </div>
              <Activity className="h-8 w-8 text-blue-600" />
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Agents List with Tabs */}
      <Tabs value={activeTab} onValueChange={setActiveTab}>
        <TabsList>
          <TabsTrigger value="all">All Agents</TabsTrigger>
          <TabsTrigger value="running">Running</TabsTrigger>
          <TabsTrigger value="paused">Paused</TabsTrigger>
          <TabsTrigger value="stopped">Stopped</TabsTrigger>
        </TabsList>

        <TabsContent value={activeTab} className="mt-6">
          {filteredAgents.length === 0 ? (
            <div className="text-center py-12">
              <Bot className="h-12 w-12 text-gray-400 mx-auto mb-4" />
              <h3 className="text-lg font-medium text-gray-900 mb-2">
                {activeTab === 'all' ? 'No agents yet' : `No ${activeTab} agents`}
              </h3>
              <p className="text-gray-600 mb-4">
                {activeTab === 'all' 
                  ? 'Create your first agent to get started with JuliaSphere'
                  : `You don't have any ${activeTab} agents at the moment`
                }
              </p>
              {activeTab === 'all' && (
                <Button asChild>
                  <Link href="/builder">
                    <Plus className="h-4 w-4 mr-2" />
                    Create Your First Agent
                  </Link>
                </Button>
              )}
            </div>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              {filteredAgents.map(agent => (
                <AgentCard key={agent.id} agent={agent} />
              ))}
            </div>
          )}
        </TabsContent>
      </Tabs>
    </div>
  )
}