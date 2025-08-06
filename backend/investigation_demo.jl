#!/usr/bin/env julia

"""
juliaXBT-Style Blockchain Investigation Demo

This script demonstrates the community-contributed blockchain investigation 
agent swarm that conducts comprehensive investigations in the style of juliaXBT.

Usage:
    julia investigation_demo.jl <target_address> [investigation_type] [suspected_activity]

Examples:
    julia investigation_demo.jl DjVE6JNiYqPL2QXyCUUh8rNjHrbz9hXHNYt99MQ59qw1 full mixer
    julia investigation_demo.jl ABC123... quick scam  
    julia investigation_demo.jl XYZ789... social_only hack
"""

using Pkg
Pkg.activate(".")

# Load JuliaOS modules
push!(LOAD_PATH, "src")
include("src/JuliaOSBackend.jl")
using .JuliaOSBackend
using .JuliaOSBackend.Agents
using .JuliaOSBackend.Agents.CommonTypes

function main()
    println("🔍 juliaXBT-Style Blockchain Investigation System")
    println("=" ^ 60)
    
    # Parse command line arguments
    target_address = length(ARGS) >= 1 ? ARGS[1] : "DjVE6JNiYqPL2QXyCUUh8rNjHrbz9hXHNYt99MQ59qw1"
    investigation_type = length(ARGS) >= 2 ? ARGS[2] : "full"
    suspected_activity = length(ARGS) >= 3 ? ARGS[3] : "unknown"
    
    println("🎯 Target Address: $(target_address)")
    println("📊 Investigation Type: $(investigation_type)")
    println("🚨 Suspected Activity: $(suspected_activity)")
    println()
    
    try
        # Create the investigation agent
        println("🤖 Creating juliaXBT Investigation Agent...")
        
        agent_blueprint = CommonTypes.AgentBlueprint(
            strategy = CommonTypes.StrategyBlueprint("juliaxbt_investigation", Dict{String,Any}()),
            tools = [
                CommonTypes.ToolBlueprint("solana_rpc", Dict{String,Any}()),
                CommonTypes.ToolBlueprint("transaction_tracer", Dict{String,Any}()),
                CommonTypes.ToolBlueprint("mixer_detector", Dict{String,Any}()),
                CommonTypes.ToolBlueprint("twitter_research", Dict{String,Any}()),
                CommonTypes.ToolBlueprint("thread_generator", Dict{String,Any}())
            ],
            trigger = CommonTypes.WEBHOOK_TRIGGER,  # Use webhook trigger for demo
            trigger_params = Dict{String,Any}()
        )
        
        agent = create_agent(
            "juliaxbt_investigator_demo",
            "juliaXBT Investigation Agent",
            "Conducts comprehensive blockchain investigations with social media intelligence",
            agent_blueprint
        )
        
        println("✅ Agent created successfully!")
        println("🔧 Available tools: $(length(agent.context.tools))")
        println()
        
        # Set agent to running state
        set_agent_state(agent, CommonTypes.RUNNING_STATE)
        println("▶️  Agent state: RUNNING")
        println()
        
        # Create investigation input
        investigation_input = Dict(
            "target_address" => target_address,
            "investigation_type" => investigation_type,
            "suspected_activity" => suspected_activity,
            "tip_source" => "demo",
            "urgency_level" => "normal"
        )
        
        println("🚀 Starting investigation...")
        println("⏱️  This may take several minutes depending on blockchain activity...")
        println()
        
        # Run the investigation
        start_time = time()
        result = run(agent, investigation_input)
        end_time = time()
        
        # Display results
        println("🎉 Investigation completed!")
        println("⏱️  Total time: $(round(end_time - start_time, digits=2)) seconds")
        println()
        
        # Parse investigation logs
        println("📋 Investigation Log:")
        println("-" ^ 40)
        for (i, log_entry) in enumerate(result.logs)
            println("$(i). $(log_entry)")
        end
        println()
        
        # Display memory/results if available
        if !isempty(result.memories)
            println("💾 Investigation Results:")
            println("-" ^ 40)
            for (key, value) in result.memories
                if startswith(key, "investigation_")
                    println("Investigation ID: $(key)")
                    if haskey(value, "final_assessment")
                        assessment = value["final_assessment"]
                        println("  Risk Level: $(assessment["risk_level"])")
                        println("  Key Findings: $(length(assessment["key_findings"]))")
                        for finding in assessment["key_findings"]
                            println("    - $(finding)")
                        end
                    end
                    println()
                end
            end
        end
        
        println("✨ Demo completed successfully!")
        
    catch e
        println("❌ Investigation failed!")
        println("Error: $(string(e))")
        if isa(e, MethodError) || isa(e, UndefVarError)
            println("\n💡 Tip: Make sure the JuliaOS backend is running and all dependencies are installed.")
            println("Run: julia --project=. -e 'using Pkg; Pkg.instantiate()'")
        end
        return 1
    end
    
    return 0
end

function print_usage()
    println("""
Usage: julia investigation_demo.jl <target_address> [investigation_type] [suspected_activity]

Parameters:
  target_address      - Solana address to investigate (required)
  investigation_type  - Type of investigation (optional, default: "full")
                       Options: full, quick, blockchain_only, social_only
  suspected_activity  - Type of suspected activity (optional, default: "unknown") 
                       Options: mixer, scam, hack, laundering, unknown

Examples:
  julia investigation_demo.jl DjVE6JNiYqPL2QXyCUUh8rNjHrbz9hXHNYt99MQ59qw1
  julia investigation_demo.jl ABC123... full mixer
  julia investigation_demo.jl XYZ789... quick scam
  julia investigation_demo.jl DEF456... social_only hack

Investigation Types:
  - full: Complete blockchain + social media investigation
  - quick: Fast blockchain analysis only  
  - blockchain_only: Deep blockchain analysis without social media
  - social_only: Social media research without blockchain tracing

Suspected Activities:
  - mixer: Money laundering through mixing services
  - scam: Fraudulent schemes and rug pulls
  - hack: Stolen funds and exploits
  - laundering: General money laundering activity
  - unknown: General suspicious activity investigation
""")
end

# Handle help requests
if length(ARGS) > 0 && ARGS[1] in ["--help", "-h", "help"]
    print_usage()
    exit(0)
end

# Run the demo
exit_code = main()
exit(exit_code)