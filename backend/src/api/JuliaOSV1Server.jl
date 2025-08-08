module JuliaOSV1Server

using HTTP
using JSON3
using ..JuliaDB

include("server/src/JuliaOSServer.jl")
include("utils.jl")
include("openapi_server_extensions.jl")
include("validation.jl")
include("auth.jl")
include("error_handling.jl")

using .JuliaOSServer
using .Auth
using .ErrorHandling
using ..JuliaDB
using ..Agents: Agents, Triggers
# using ..MarketplaceAPI  # Temporarily disabled
using ...Resources: Errors

const server = Ref{Any}(nothing)

function ping(::HTTP.Request)
    @info "Triggered endpoint: GET /ping"
    return HTTP.Response(200, "")
end

function create_agent(req::HTTP.Request, create_agent_request::CreateAgentRequest;)::HTTP.Response
    try
        @info "Triggered endpoint: POST /agents"
        @info "Received request: $create_agent_request"
        
        @validate_model create_agent_request
        @info "Model validation passed"

        id = create_agent_request.id
        name = create_agent_request.name
        description = create_agent_request.description
        received_blueprint = create_agent_request.blueprint
        @info "Extracted basic fields: id=$id, name=$name"

        tools = Vector{Agents.ToolBlueprint}()
        for tool in received_blueprint.tools
            @info "Processing tool: $(tool.name)"
            push!(tools, Agents.ToolBlueprint(tool.name, tool.config))
        end
        @info "Processed $(length(tools)) tools"

        @info "Processing trigger: $(received_blueprint.trigger.type)"
        trigger_type = Triggers.trigger_name_to_enum(received_blueprint.trigger.type)
        trigger_params = Triggers.process_trigger_params(trigger_type, received_blueprint.trigger.params)
        @info "Trigger processing completed"

        @info "Creating internal blueprint with strategy: $(received_blueprint.strategy.name)"
        internal_blueprint = Agents.AgentBlueprint(
            tools,
            Agents.StrategyBlueprint(received_blueprint.strategy.name, received_blueprint.strategy.config),
            Agents.CommonTypes.TriggerConfig(trigger_type, trigger_params)
        )
        @info "Internal blueprint created"

        @info "Creating agent..."
        agent = Agents.create_agent(id, name, description, internal_blueprint)
        @info "Agent created, inserting into database..."
        
        JuliaDB.insert_agent(agent)
        @info "Agent inserted into database"
        
        @info "Created agent: $(agent.id) with state: $(agent.state)"
        
        @info "Initializing agent..."
        Agents.initialize(agent)
        @info "Agent initialized"
        
        @info "Creating agent summary..."
        agent_summary = summarize(agent)
        @info "Agent summary created"
        
        return HTTP.Response(201, agent_summary)
    catch e
        @error "Error in create_agent" exception=(e, catch_backtrace())
        return HTTP.Response(500, "Internal server error: $(string(e))")
    end
end

function delete_agent(req::HTTP.Request, agent_id::String;)::HTTP.Response
    @info "Triggered endpoint: DELETE /agents/$(agent_id)"
    Agents.delete_agent(agent_id)
    JuliaDB.delete_agent(agent_id)
    @info "Deleted agent $(agent_id)"
    return HTTP.Response(204)
end

function update_agent(req::HTTP.Request, agent_id::String, agent_update::AgentUpdate;)::HTTP.Response
    @info "Triggered endpoint: PUT /agents/$(agent_id)"
    @validate_model agent_update

    agent = get(Agents.AGENTS, agent_id) do
        @warn "Attempted update of non-existent agent: $(agent_id)"
        return nothing
    end
    if agent == nothing
        return HTTP.Response(404, "Agent not found")
    end
    new_state = Agents.string_to_agent_state(agent_update.state)
    Agents.set_agent_state(agent, new_state)
    JuliaDB.update_agent_state(agent.id, new_state)
    agent_summary = summarize(agent)
    return HTTP.Response(200, agent_summary)
end

function get_agent(req::HTTP.Request, agent_id::String;)::HTTP.Response
    @info "Triggered endpoint: GET /agents/$(agent_id)"
    
    try
        agent = get(Agents.AGENTS, agent_id) do
            @warn "Attempt to get non-existent agent: $(agent_id)"
            return nothing
        end
        
        if agent == nothing
            return ErrorHandling.not_found_error("Agent", agent_id; 
                request_id=get(req.context, "request_id", nothing))
        end

        agent_summary = summarize(agent)
        return ErrorHandling.success_response(agent_summary)
    catch e
        return ErrorHandling.handle_exception(e, get(req.context, "request_id", "unknown"))
    end
end

function list_agents(req::HTTP.Request;)::Vector{AgentSummary}
    @info "Triggered endpoint: GET /agents"
    agents = Vector{AgentSummary}()
    for (id, agent) in Agents.AGENTS
        push!(agents, summarize(agent))
    end
    return agents
end

function process_agent_webhook(req::HTTP.Request, agent_id::String; request_body::Dict{String,Any}=Dict{String,Any}(),)::HTTP.Response
    @info "Triggered endpoint: POST /agents/$(agent_id)/webhook"
    agent = get(Agents.AGENTS, agent_id) do
        @warn "Attempted webhook trigger of non-existent agent: $(agent_id)"
        return nothing
    end
    if agent == nothing
        return HTTP.Response(404, "Agent not found")
    end
    if agent.trigger.type == Agents.CommonTypes.WEBHOOK_TRIGGER
        try
            if isempty(request_body)
                Agents.run(agent)
            else
                Agents.run(agent, request_body)
            end
            return HTTP.Response(200)
        catch e
            if isa(e, Errors.InvalidPayload)
                return HTTP.Response(400,
                    JSON3.write((error = "invalid_payload", detail = e.msg)))
            else
                @error "Unhandled exception in webhook" exception = (e, catch_backtrace())
                return HTTP.Response(500, JSON3.write((error = "internal_error")))
            end
        end
    end
end

function get_agent_logs(req::HTTP.Request, agent_id::String;)::Union{HTTP.Response, Dict{String, Any}}
    @info "Triggered endpoint: GET /agents/$(agent_id)/logs"
    agent = get(Agents.AGENTS, agent_id) do
        @warn "Attempt to get logs of non-existent agent: $(agent_id)"
        return nothing
    end
    if agent == nothing
        return HTTP.Response(404, "Agent not found")
    end
    # TODO: implement pagination
    return Dict{String, Any}("logs" => agent.context.logs)
end

function get_agent_output(req::HTTP.Request, agent_id::String;)::Dict{String, Any}
    @info "Triggered endpoint: GET /agents/$(agent_id)/output"
    @info "NYI, not actually getting agent $(agent_id) output..."
    return Dict{String, Any}()
end

function list_strategies(req::HTTP.Request;)::Vector{StrategySummary}
    @info "Triggered endpoint: GET /strategies"
    strategies = Vector{StrategySummary}()
    for (name, spec) in Agents.Strategies.STRATEGY_REGISTRY
        push!(strategies, StrategySummary(name))
    end
    return strategies
end

function list_tools(req::HTTP.Request;)::Vector{ToolSummary}
    @info "Triggered endpoint: GET /tools"
    tools = Vector{ToolSummary}()
    for (name, tool) in Agents.Tools.TOOL_REGISTRY
        push!(tools, ToolSummary(name, ToolSummaryMetadata(tool.metadata.description)))
    end
    return tools
end

function run_server(host::AbstractString="0.0.0.0", port::Integer=8052)
    try
        # Initialize database connection
        @info "Initializing database connection..."
        db_host = get(ENV, "DB_HOST", "localhost")
        db_port = get(ENV, "DB_PORT", "5435")
        db_user = get(ENV, "DB_USER", "postgres")
        db_password = get(ENV, "DB_PASSWORD", "postgres")
        db_name = get(ENV, "DB_NAME", "postgres")
        
        conn_string = "host=$db_host port=$db_port user=$db_user password=$db_password dbname=$db_name"
        JuliaDB.initialize_connection(conn_string)
        @info "Database connection pool initialized"
        
        # Load existing agents from database
        @info "Loading existing agents from database..."
        JuliaDB.load_state()
        agent_count = length(Agents.AGENTS)
        @info "Loaded $agent_count agents from database"
        
        # Create main router with CORS middleware
        function cors_middleware(handler)
            return function(req::HTTP.Request)
                # Get origin from request headers
                origin = "http://localhost:3000"  # default
                for (key, value) in HTTP.headers(req)
                    if lowercase(string(key)) == "origin"
                        origin = string(value)
                        break
                    end
                end
                
                # Handle preflight OPTIONS requests
                if req.method == "OPTIONS"
                    return HTTP.Response(200, [
                        "Access-Control-Allow-Origin" => origin,
                        "Access-Control-Allow-Methods" => "GET, POST, PUT, DELETE, OPTIONS",
                        "Access-Control-Allow-Headers" => "Content-Type, Authorization, X-CSRF-Token",
                        "Access-Control-Allow-Credentials" => "true",
                        "Access-Control-Max-Age" => "86400"
                    ])
                end
                
                # Process the request
                response = handler(req)
                
                # Add CORS headers to all responses
                HTTP.setheader(response, "Access-Control-Allow-Origin" => origin)
                HTTP.setheader(response, "Access-Control-Allow-Methods" => "GET, POST, PUT, DELETE, OPTIONS")
                HTTP.setheader(response, "Access-Control-Allow-Headers" => "Content-Type, Authorization, X-CSRF-Token")
                HTTP.setheader(response, "Access-Control-Allow-Credentials" => "true")
                
                return response
            end
        end
        
        router = HTTP.Router()
        
        # Register core routes directly 
        core_router = JuliaOSServer.register(router, @__MODULE__; path_prefix="/api/v1")
        
        # Register basic routes with CORS
        HTTP.register!(router, "GET", "/ping", cors_middleware(ping))
        
        # Register marketplace routes
        # MarketplaceAPI.register_routes!(router; path_prefix="/api/v1")  # Temporarily disabled
        
        @info "Starting JuliaOS server on $host:$port"
        @info "Available endpoints:"
        @info "  GET /ping - Health check"
        @info "  API routes under /api/v1/"
        @info "  CORS enabled for frontend integration"
        
        # Wrap entire router with CORS middleware
        cors_router = cors_middleware(router)
        server[] = HTTP.serve!(cors_router, host, port)
        wait(server[])
    catch ex
        @error("Server error", exception=(ex, catch_backtrace()))
    end
end

end # module JuliaOSV1Server