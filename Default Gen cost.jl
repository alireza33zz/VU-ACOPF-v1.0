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
include(joinpath(FUNCTION_DIR, "Solve OPF.jl"));
include(joinpath(FUNCTION_DIR, "Test OPF.jl"));
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
    20.0,    # thermal
    1.0,    # VUF_level
    1       # print_level
)

global VUF_STATUS = false

combined_extension = "_case5"
separate_extension = combined_extension;

# Example usage:
file_path = "Test2.dss"
=#
function default_opf(file_path::String)
solution, pm, results_df = test_opf(file_path);

print_network_structure(solution, pm);

end

#=
"""
Main function to solve OPF with custom constraints
"""
function solve_opf2(file_path::String, config::OPFConfig=default_config())
    # Parse network file
    eng = parse_file(file_path)

    # Initialize model
    math = initialize_model(eng, config)

    # Initialize PowerModelsDistribution model
    pm = instantiate_mc_model(math, ACPUPowerModel, build_mc_opf)
    pm.data["per_unit"] = false

    ensuring_balance_operation_of_3ph_DERs(math, pm);

    for i in 1:length(pm.var[:it][:pmd][:nw][0][:pg][1])
        @constraint(pm.model, pm.var[:it][:pmd][:nw][0][:pg][1][i]^2 + pm.var[:it][:pmd][:nw][0][:qg][1][i]^2 <= pm.data["gen"]["1"]["pmax"][i]^2)
    end

    # Print keys in pg dictionary
    # println("Keys in pg dictionary: ", keys(pm.var[:it][:pmd][:nw][0][:pg]))

    # Print contents of pg dictionary
    # for (key, value) in pm.var[:it][:pmd][:nw][0][:pg]
    #     println("Key: ", key, " Value: ", value)
    # end

    # Print keys in gen dictionary
    # println("Keys in gen dictionary: ", keys(pm.data["gen"]))

    # Add custom Objective function
    #
    JuMP.@objective(pm.model, Min, sum(pm.data["gen"][string(i)]["cost"][2] + 
    pm.data["gen"][string(i)]["cost"][1] * pg for (i, pg_array) in pm.var[:it][:pmd][:nw][0][:pg], 
    pg in pg_array if haskey(pm.data["gen"], string(i))))
    #
    #=
    JuMP.@objective(pm.model, Min, sum(pm.data["gen"][string(i)]["cost"][2] + 
    pm.data["gen"][string(i)]["cost"][1] * (pg + qg) for (i, pg_array) in pm.var[:it][:pmd][:nw][0][:pg], 
    (pg, qg) in zip(pg_array, pm.var[:it][:pmd][:nw][0][:qg][i]) if haskey(pm.data["gen"], string(i))))
    =#
    # Configure and run solver
    solver = configure_solver(config)
    solution = optimize_model!(pm, optimizer=solver)

    # Print formatted results
    print_formatted_results(solution, pm)

    return solution, pm, format_results(solution, pm)
end

"""
Test function with default settings
"""
function test_opf2(file_path::String)
    # Define custom configuration
    config = OPFConfig(
        1.0,    # sbase_default
        1000.0, # power_scale_factor
        1       # print_level
    )
   
    # Solve OPF with VUF constraint
    solution, pm, results_df = solve_opf2(file_path, config)
    
    return solution, pm, results_df
end

# Example usage:
file_path = "Test2.dss"
solution2, pm2, results_df2 = test_opf2(file_path);

# Optional: Diagnostic function to understand network structure

print_network_structure(solution2);
=#

