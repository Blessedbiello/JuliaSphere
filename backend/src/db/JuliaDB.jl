module JuliaDB

include("utils.jl")
include("connection_management.jl")
include("updating.jl")
include("loading.jl")

# Export functions for external use
export execute_query, initialize_connection, get_connection, load_state

end