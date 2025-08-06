#!/usr/bin/env julia

"""
Investigation System Test Suite

Tests the blockchain investigation system components individually
to identify and fix any remaining issues.
"""

println("🧪 Testing JuliaOS Investigation System Components")
println("=" ^ 60)

# Test 1: Module Loading
println("1️⃣ Testing module imports...")
try
    push!(LOAD_PATH, "src")
    include("src/JuliaOSBackend.jl")
    using .JuliaOSBackend
    using .JuliaOSBackend.Agents.CommonTypes
    using .JuliaOSBackend.Agents.Tools
    using .JuliaOSBackend.Agents.Strategies
    println("✅ All modules loaded successfully")
except e
    println("❌ Module loading failed: $(e)")
    println("💡 Make sure you're running from the backend/ directory")
    exit(1)
end

# Test 2: Tool Registry
println("\n2️⃣ Testing tool registry...")
try
    available_tools = collect(keys(Tools.TOOL_REGISTRY))
    println("📋 Available tools: $(length(available_tools))")
    
    investigation_tools = ["solana_rpc", "transaction_tracer", "mixer_detector", 
                          "twitter_research", "thread_generator"]
    
    for tool in investigation_tools
        if tool in available_tools
            println("✅ $(tool) - registered")
        else
            println("❌ $(tool) - NOT FOUND")
        end
    end
except e
    println("❌ Tool registry test failed: $(e)")
end

# Test 3: Strategy Registry  
println("\n3️⃣ Testing strategy registry...")
try
    available_strategies = collect(keys(Strategies.STRATEGY_REGISTRY))
    println("📋 Available strategies: $(length(available_strategies))")
    
    if "juliaxbt_investigation" in available_strategies
        println("✅ juliaxbt_investigation - registered")
    else
        println("❌ juliaxbt_investigation - NOT FOUND")
    end
except e
    println("❌ Strategy registry test failed: $(e)")
end

# Test 4: Individual Tool Creation
println("\n4️⃣ Testing individual tool instantiation...")
test_tools = ["solana_rpc", "transaction_tracer", "mixer_detector"]

for tool_name in test_tools
    try
        if haskey(Tools.TOOL_REGISTRY, tool_name)
            tool_spec = Tools.TOOL_REGISTRY[tool_name]
            config = tool_spec.config_type()
            println("✅ $(tool_name) - config created successfully")
            
            # Test with dummy data
            test_task = if tool_name == "solana_rpc"
                Dict("method" => "getHealth", "params" => [])
            elseif tool_name == "transaction_tracer"
                Dict("start_address" => "11111111111111111111111111111111")
            elseif tool_name == "mixer_detector" 
                Dict("address" => "11111111111111111111111111111111")
            else
                Dict()
            end
            
            println("  📝 Test task created for $(tool_name)")
        else
            println("❌ $(tool_name) - not in registry")
        end
    catch e
        println("❌ $(tool_name) - instantiation failed: $(e)")
    end
end

# Test 5: Environment Variables
println("\n5️⃣ Testing environment variables...")
required_env_vars = ["GEMINI_API_KEY"]
optional_env_vars = ["TWITTER_BEARER_TOKEN", "SOLANA_RPC_URL"]

for env_var in required_env_vars
    if haskey(ENV, env_var) && !isempty(ENV[env_var])
        println("✅ $(env_var) - configured")
    else
        println("❌ $(env_var) - MISSING (required)")
        println("  💡 Set this in your .env file")
    end
end

for env_var in optional_env_vars
    if haskey(ENV, env_var) && !isempty(ENV[env_var])
        println("✅ $(env_var) - configured")
    else
        println("⚠️  $(env_var) - not set (optional)")
    end
end

# Test 6: Basic API Connectivity
println("\n6️⃣ Testing basic API connectivity...")

# Test Solana RPC
try
    using HTTP, JSON3
    
    response = HTTP.post(
        "https://api.mainnet-beta.solana.com",
        ["Content-Type" => "application/json"],
        JSON3.write(Dict(
            "jsonrpc" => "2.0",
            "id" => 1,
            "method" => "getHealth",
            "params" => []
        ));
        connect_timeout=10
    )
    
    if response.status == 200
        println("✅ Solana RPC - accessible")
    else
        println("⚠️  Solana RPC - unexpected status: $(response.status)")
    end
catch e
    println("❌ Solana RPC - connection failed: $(e)")
end

# Test 7: Investigation Strategy Creation
println("\n7️⃣ Testing investigation strategy creation...")
try
    if haskey(Strategies.STRATEGY_REGISTRY, "juliaxbt_investigation")
        strategy_spec = Strategies.STRATEGY_REGISTRY["juliaxbt_investigation"]
        config = strategy_spec.config_type()
        println("✅ Investigation strategy config created")
        
        input_type = strategy_spec.input_type
        if input_type !== nothing
            println("✅ Investigation input type available: $(input_type)")
        end
    else
        println("❌ Investigation strategy not found in registry")
    end
catch e
    println("❌ Investigation strategy test failed: $(e)")
end

# Test Summary
println("\n" ^ 2)
println("🏁 Test Summary")
println("=" ^ 30)
println("✅ If you see mostly green checkmarks above, the system is ready to use")
println("❌ Red X marks indicate issues that need to be resolved")
println("⚠️  Yellow warnings indicate optional components that could be configured")
println()
println("📚 Next Steps:")
println("  1. Configure missing environment variables in .env")
println("  2. Run: julia investigation_demo.jl <address> to test full system")
println("  3. Check the logs for any runtime issues")
println()
println("🔍 For detailed investigation capabilities, see:")
println("  - backend/src/agents/community/README.md")
println("  - INVESTIGATION_SYSTEM_SUMMARY.md")