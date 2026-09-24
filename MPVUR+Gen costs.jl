"""
This script performs a three-phase optimal power flow (OPF) calculation using the PowerModelsDistribution package in Julia. 
It includes the ability to add custom constraints. 
The script is modular and generic, allowing for easy integration of new constraints and configurations.
"""

using PowerModelsDistribution
using JuMP
using Ipopt
using DataFrames



FUNCTION_DIR = joinpath(@__DIR__, "Functions")

include(joinpath(FUNCTION_DIR, "Default Configuration.jl"));
include(joinpath(FUNCTION_DIR, "Configure Solver.jl"));
include(joinpath(FUNCTION_DIR, "Initialize Model.jl"));
include(joinpath(FUNCTION_DIR, "Calculate VUF.jl"));
include(joinpath(FUNCTION_DIR, "Format Results.jl"));
include(joinpath(FUNCTION_DIR, "Print Results.jl"));
include(joinpath(FUNCTION_DIR, "Solve OPF with Zlin.jl"));
include(joinpath(FUNCTION_DIR, "Test OPF with Zlin.jl"));
include(joinpath(FUNCTION_DIR, "Print Network Structure.jl"));
include(joinpath(FUNCTION_DIR, "Balanced 3ph DER.jl"));
include(joinpath(FUNCTION_DIR, "PQ Curve.jl"));
include(joinpath(FUNCTION_DIR, "Dual Variables.jl"));
include(joinpath(FUNCTION_DIR, "Shadow Prices.jl"));
include(joinpath(FUNCTION_DIR, "Thermal Limit.jl"));
include(joinpath(FUNCTION_DIR, "Voltage Magnitude.jl"));
include(joinpath(FUNCTION_DIR, "VUF Constriant.jl"));

#=
config = OPFConfig(
    1.0,    # sbase_default
    1000.0, # power_scale_factor
    1.10,   # v_upper_bound
    0.94,   # v_lower_bound
    25.0,    # thermal (added +5.0 to the default value)
    2.0,    # VUF_level
    1       # print_level
)


# Example usage:
file_path = "Test2.dss"
=#
function Zlin_Gen_costs(file_path::String, M::Float64, N::Float64)
solution, pm, results_df = test_opf_with_Zlin(file_path, M, N); #Second number is for Gen cost

print_network_structure(solution, pm);

end
