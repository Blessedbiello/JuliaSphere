module JuliaOSV1Server

using HTTP

include("server/src/JuliaOSServer.jl")
include("openapi_server_extensions.jl")

using .JuliaOSServer
using ..Agents: Agents, Triggers

const server = Ref{Any}(nothing)

function ping(::HTTP.Request)
    @info "Triggered endpoint: GET /ping"
    return HTTP.Response(200, "")
end

function create_agent(req::HTTP.Request, create_agent_request::CreateAgentRequest;)::AgentSummary
    @info "Triggered endpoint: POST /agents"

    id = create_agent_request.id
    received_blueprint = create_agent_request.blueprint

    tools = Vector{Agents.ToolBlueprint}()
    for tool in received_blueprint.tools
        push!(tools, Agents.ToolBlueprint(tool.name, tool.config))
    end

    trigger_type = Triggers.trigger_name_to_enum(received_blueprint.trigger.type)
    trigger_params = Triggers.process_trigger_params(trigger_type, received_blueprint.trigger.params)

    internal_blueprint = Agents.AgentBlueprint(
        tools,
        Agents.StrategyBlueprint(received_blueprint.strategy.name, received_blueprint.strategy.config),
        Agents.CommonTypes.TriggerConfig(trigger_type, trigger_params)
    )

    agent = Agents.create_agent(id, internal_blueprint)
    @info "Created agent: $(agent.id) with state: $(agent.state)"
    return AgentSummary(agent.id, Agents.agent_state_to_string(agent.state))
end

function delete_agent(req::HTTP.Request, agent_id::String;)::Nothing
    @info "Triggered endpoint: DELETE /agents/$(agent_id)"
    Agents.delete_agent(agent_id)
    @info "Deleted agent $(agent_id)"
    return nothing
end

function update_agent(req::HTTP.Request, agent_id::String, agent_update::AgentUpdate;)::AgentSummary
    @info "Triggered endpoint: PUT /agents/$(agent_id)"
    agent = get(Agents.AGENTS, agent_id) do
        error("Agent $(agent_id) does not exist!")
    end
    new_state = Agents.string_to_agent_state(agent_update.state)
    Agents.set_agent_state(agent, new_state)
    return AgentSummary(agent.id, Agents.agent_state_to_string(agent.state))
end

function get_agent(req::HTTP.Request, agent_id::String;)::AgentSummary
    @info "Triggered endpoint: GET /agents/$(agent_id)"
    agent = get(Agents.AGENTS, agent_id) do
        error("Agent $(agent_id) does not exist!")
    end
    return AgentSummary(agent.id, Agents.agent_state_to_string(agent.state))
end

function list_agents(req::HTTP.Request;)::Vector{AgentSummary}
    @info "Triggered endpoint: GET /agents"
    agents = Vector{AgentSummary}()
    for (id, agent) in Agents.AGENTS
        push!(agents, AgentSummary(id, Agents.agent_state_to_string(agent.state)))
    end
    return agents
end

function process_agent_webhook(req::HTTP.Request, agent_id::String; request_body::Dict{String,Any}=Dict{String,Any}(),)::Nothing
    @info "Triggered endpoint: POST /agents/$(agent_id)/webhook"
    agent = get(Agents.AGENTS, agent_id) do
        error("Agent $(agent_id) does not exist!")
    end
    if agent.trigger.type == Agents.CommonTypes.WEBHOOK_TRIGGER
        @info "Triggering agent $(agent_id) by webhook"
        if !isempty(request_body)
            @info "Passing payload to agent $(agent_id) webhook: $(request_body)"
            Agents.run(agent, request_body)
        else
            Agents.run(agent)
        end
    end
    return nothing
end

function get_agent_logs(req::HTTP.Request, agent_id::String;)::Dict{String, Any}
    @info "Triggered endpoint: GET /agents/$(agent_id)/logs"
    agent = get(Agents.AGENTS, agent_id) do
        error("Agent $(agent_id) does not exist!")
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

function run_server(port=8052)
    try
        router = HTTP.Router()
        router = JuliaOSServer.register(router, @__MODULE__; path_prefix="/api/v1")
        HTTP.register!(router, "GET", "/ping", ping)
        server[] = HTTP.serve!(router, port)
        wait(server[])
    catch ex
        @error("Server error", exception=(ex, catch_backtrace()))
    end
end

end # module JuliaOSV1Server