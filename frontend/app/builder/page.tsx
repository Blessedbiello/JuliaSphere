'use client'

import { useState } from 'react'
import { motion } from 'framer-motion'
import { 
  Wand2, 
  Save, 
  Play, 
  Eye,
  ArrowLeft,
  ArrowRight,
  CheckCircle,
  Settings,
  Zap,
  Target
} from 'lucide-react'
import { StrategySelector } from '@/components/builder/StrategySelector'
import { ToolConfigurator } from '@/components/builder/ToolConfigurator'
import { TriggerSetup } from '@/components/builder/TriggerSetup'
import { AgentPreview } from '@/components/builder/AgentPreview'
import { CreateAgentForm, Tool } from '@/types'

const STEPS = [
  {
    id: 'strategy',
    title: 'Choose Strategy',
    description: 'Select the reasoning approach for your agent',
    icon: Wand2,
  },
  {
    id: 'tools',
    title: 'Configure Tools',
    description: 'Add and configure the tools your agent will use',
    icon: Settings,
  },
  {
    id: 'trigger',
    title: 'Setup Trigger',
    description: 'Define when and how your agent should activate',
    icon: Zap,
  },
  {
    id: 'preview',
    title: 'Review & Test',
    description: 'Preview your agent and test its configuration',
    icon: Eye,
  },
]

export default function BuilderPage() {
  const [currentStep, setCurrentStep] = useState(0)
  const [agent, setAgent] = useState<CreateAgentForm>({
    name: '',
    description: '',
    strategy: '',
    strategyConfig: {},
    tools: [],
    triggerType: '',
    triggerParams: {},
  })

  const [isSaving, setIsSaving] = useState(false)
  const [isTesting, setIsTesting] = useState(false)

  const handleAgentChange = (updates: Partial<CreateAgentForm>) => {
    setAgent(prev => ({ ...prev, ...updates }))
  }

  const handleNextStep = () => {
    if (currentStep < STEPS.length - 1) {
      setCurrentStep(currentStep + 1)
    }
  }

  const handlePrevStep = () => {
    if (currentStep > 0) {
      setCurrentStep(currentStep - 1)
    }
  }

  const handleSave = async () => {
    setIsSaving(true)
    try {
      // TODO: Implement agent creation API call
      await new Promise(resolve => setTimeout(resolve, 2000)) // Simulate API call
      console.log('Saving agent:', agent)
      // toast.success('Agent saved successfully!')
    } catch (error) {
      console.error('Failed to save agent:', error)
      // toast.error('Failed to save agent')
    } finally {
      setIsSaving(false)
    }
  }

  const handleTest = async () => {
    setIsTesting(true)
    try {
      // TODO: Implement agent testing
      await new Promise(resolve => setTimeout(resolve, 3000)) // Simulate test
      console.log('Testing agent:', agent)
      // toast.success('Agent test completed!')
    } catch (error) {
      console.error('Failed to test agent:', error)
      // toast.error('Agent test failed')
    } finally {
      setIsTesting(false)
    }
  }

  const isStepComplete = (stepIndex: number) => {
    switch (stepIndex) {
      case 0: // Strategy
        return agent.strategy && agent.name && agent.description
      case 1: // Tools
        return agent.tools.length > 0
      case 2: // Trigger
        return agent.triggerType && Object.keys(agent.triggerParams).length > 0
      case 3: // Preview
        return true
      default:
        return false
    }
  }

  const canProceedToNext = isStepComplete(currentStep)

  const renderStepContent = () => {
    switch (STEPS[currentStep].id) {
      case 'strategy':
        return (
          <StrategySelector
            selectedStrategy={agent.strategy}
            strategyConfig={agent.strategyConfig}
            agentName={agent.name}
            agentDescription={agent.description}
            onStrategyChange={(strategy, config) => 
              handleAgentChange({ strategy, strategyConfig: config })
            }
            onBasicInfoChange={(name, description) => 
              handleAgentChange({ name, description })
            }
          />
        )
      case 'tools':
        return (
          <ToolConfigurator
            selectedTools={agent.tools}
            onToolsChange={(tools) => handleAgentChange({ tools })}
          />
        )
      case 'trigger':
        return (
          <TriggerSetup
            triggerType={agent.triggerType}
            triggerParams={agent.triggerParams}
            onTriggerChange={(triggerType, triggerParams) => 
              handleAgentChange({ triggerType, triggerParams })
            }
          />
        )
      case 'preview':
        return (
          <AgentPreview
            agent={agent}
            onTest={handleTest}
            isTesting={isTesting}
          />
        )
      default:
        return null
    }
  }

  return (
    <div className="max-w-7xl mx-auto space-y-8">
      {/* Header */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        className="text-center"
      >
        <h1 className="text-4xl font-bold text-gray-900 dark:text-white mb-4">
          Agent Builder
        </h1>
        <p className="text-xl text-gray-600 dark:text-gray-400 max-w-2xl mx-auto">
          Create powerful AI agents without code using our visual builder
        </p>
      </motion.div>

      {/* Progress Steps */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.1 }}
        className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700 p-6"
      >
        <div className="flex items-center justify-between mb-8">
          {STEPS.map((step, index) => {
            const Icon = step.icon
            const isActive = index === currentStep
            const isComplete = isStepComplete(index)
            const isPast = index < currentStep

            return (
              <div key={step.id} className="flex items-center">
                <div className="flex flex-col items-center">
                  <button
                    onClick={() => setCurrentStep(index)}
                    className={`w-12 h-12 rounded-full flex items-center justify-center transition-all duration-200 ${
                      isActive
                        ? 'bg-primary-600 text-white shadow-lg scale-110'
                        : isComplete || isPast
                        ? 'bg-success-600 text-white'
                        : 'bg-gray-200 dark:bg-gray-700 text-gray-600 dark:text-gray-400'
                    }`}
                  >
                    {isComplete && !isActive ? (
                      <CheckCircle className="h-6 w-6" />
                    ) : (
                      <Icon className="h-6 w-6" />
                    )}
                  </button>
                  
                  <div className="mt-3 text-center">
                    <div className={`font-medium text-sm ${
                      isActive 
                        ? 'text-primary-600 dark:text-primary-400'
                        : isComplete || isPast
                        ? 'text-success-600 dark:text-success-400'
                        : 'text-gray-600 dark:text-gray-400'
                    }`}>
                      {step.title}
                    </div>
                    <div className="text-xs text-gray-500 dark:text-gray-400 mt-1 max-w-24">
                      {step.description}
                    </div>
                  </div>
                </div>

                {/* Connector Line */}
                {index < STEPS.length - 1 && (
                  <div className={`h-0.5 w-16 mx-4 transition-colors ${
                    isPast || (isComplete && index < currentStep)
                      ? 'bg-success-400'
                      : 'bg-gray-300 dark:bg-gray-600'
                  }`} />
                )}
              </div>
            )
          })}
        </div>

        {/* Step Content */}
        <div className="min-h-[500px]">
          <motion.div
            key={currentStep}
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: -20 }}
            transition={{ duration: 0.3 }}
          >
            {renderStepContent()}
          </motion.div>
        </div>

        {/* Step Navigation */}
        <div className="flex items-center justify-between pt-6 border-t border-gray-200 dark:border-gray-700">
          <button
            onClick={handlePrevStep}
            disabled={currentStep === 0}
            className="flex items-center gap-2 px-6 py-3 text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
          >
            <ArrowLeft className="h-4 w-4" />
            Previous
          </button>

          <div className="flex items-center gap-3">
            {currentStep === STEPS.length - 1 ? (
              <>
                <button
                  onClick={handleTest}
                  disabled={isTesting || !canProceedToNext}
                  className="flex items-center gap-2 px-6 py-3 bg-secondary-600 text-white rounded-lg hover:bg-secondary-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
                >
                  {isTesting ? (
                    <>
                      <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin" />
                      Testing...
                    </>
                  ) : (
                    <>
                      <Play className="h-4 w-4" />
                      Test Agent
                    </>
                  )}
                </button>
                
                <button
                  onClick={handleSave}
                  disabled={isSaving || !canProceedToNext}
                  className="flex items-center gap-2 px-6 py-3 bg-primary-600 text-white rounded-lg hover:bg-primary-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
                >
                  {isSaving ? (
                    <>
                      <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin" />
                      Saving...
                    </>
                  ) : (
                    <>
                      <Save className="h-4 w-4" />
                      Save Agent
                    </>
                  )}
                </button>
              </>
            ) : (
              <button
                onClick={handleNextStep}
                disabled={!canProceedToNext}
                className="flex items-center gap-2 px-6 py-3 bg-primary-600 text-white rounded-lg hover:bg-primary-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
              >
                Next
                <ArrowRight className="h-4 w-4" />
              </button>
            )}
          </div>
        </div>
      </motion.div>

      {/* Help Section */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.2 }}
        className="bg-gradient-to-r from-primary-50 to-secondary-50 dark:from-primary-900/20 dark:to-secondary-900/20 rounded-xl p-6"
      >
        <div className="flex items-center gap-3 mb-4">
          <Target className="h-6 w-6 text-primary-600 dark:text-primary-400" />
          <h3 className="text-lg font-semibold text-gray-900 dark:text-white">
            Building Your First Agent?
          </h3>
        </div>
        
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4 text-sm">
          <div className="bg-white dark:bg-gray-800 p-4 rounded-lg">
            <h4 className="font-medium text-gray-900 dark:text-white mb-2">1. Choose a Strategy</h4>
            <p className="text-gray-600 dark:text-gray-400">
              Select how your agent will think and make decisions. Each strategy has different strengths.
            </p>
          </div>
          
          <div className="bg-white dark:bg-gray-800 p-4 rounded-lg">
            <h4 className="font-medium text-gray-900 dark:text-white mb-2">2. Add Tools</h4>
            <p className="text-gray-600 dark:text-gray-400">
              Tools give your agent capabilities. Start with basic tools and add more as needed.
            </p>
          </div>
          
          <div className="bg-white dark:bg-gray-800 p-4 rounded-lg">
            <h4 className="font-medium text-gray-900 dark:text-white mb-2">3. Set Triggers</h4>
            <p className="text-gray-600 dark:text-gray-400">
              Define when your agent should activate. This could be on a schedule, webhook, or manual trigger.
            </p>
          </div>
        </div>
      </motion.div>
    </div>
  )
}