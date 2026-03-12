# main.jl
# ─────────────────────────────────────────────────────────────────────────────
# Entry point for running OPF simulations
#
# Supported modes:
# 1 → Default OPF
# 2 → Hard VUF limits
# 3 → Soft VUF limits (penalization)
# 4 → Hybrid limits
# 5 → IHL limits (Zlin proxy)
# ─────────────────────────────────────────────────────────────────────────────


# ─────────────────────────────────────────────────────────────────────────────
# MODE SELECTION
# ─────────────────────────────────────────────────────────────────────────────

selected_mode = 2   # ← choose 1..5

if selected_mode == 1
    global VUF_STATUS = false
    global DEFAULT_OPF_personal = true
    global proxy = 0

elseif selected_mode == 2
    global VUF_STATUS = true
    global DEFAULT_OPF_personal = true
    global proxy = 0

elseif selected_mode == 3
    global VUF_STATUS = false
    global DEFAULT_OPF_personal = false
    global proxy = 1

elseif selected_mode == 4
    global VUF_STATUS = true
    global DEFAULT_OPF_personal = false
    global proxy = 1

elseif selected_mode == 5
    global VUF_STATUS = true
    global DEFAULT_OPF_personal = false
    global proxy = 2

else
    error("Invalid mode selected. Choose a value between 1 and 5.")
end


# ─────────────────────────────────────────────────────────────────────────────
# OTHER GLOBAL FLAGS
# ─────────────────────────────────────────────────────────────────────────────

global PLOT_DISPLAY = false
global SAVING_FIGURES_STATUS = false
global PRINT_PERMISSION_personal = false


# ─────────────────────────────────────────────────────────────────────────────
# LOAD CORE ALGORITHMS
# ─────────────────────────────────────────────────────────────────────────────

include("Default Gen cost.jl")
include("VUF+Gen costs.jl")
include("MPVUR+Gen costs.jl")


# ─────────────────────────────────────────────────────────────────────────────
# CASE SELECTION
# ─────────────────────────────────────────────────────────────────────────────

Case_Num = 1 # Use for labeling outputs.

file_path = "LVTestCase/Master.dss"


# ─────────────────────────────────────────────────────────────────────────────
# OPF CONFIGURATION
# ─────────────────────────────────────────────────────────────────────────────

struct OPFConfig
    sbase_default::Float64
    power_scale_factor::Float64
    v_upper_bound::Float64
    v_lower_bound::Float64
    thermal::Float64
    VUF_level::Float64
    print_level::Int
end

config = OPFConfig(
    1.0,      # sbase_default
    1000.0,   # power_scale_factor
    1.10,     # v_upper_bound
    0.94,     # v_lower_bound
    1000.0,   # thermal
    1.0,      # VUF_level
    1         # print_level
)


# ─────────────────────────────────────────────────────────────────────────────
# WEIGHT PARAMETERS
# ─────────────────────────────────────────────────────────────────────────────

M_values_set = [1.0, 0.5, 1.0, 1.5, 2.0, 3.0, 10.0, 30.0, 0.75, 0.1]
N_values_set = [0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0]

# choose one pair or run all
single = 3   # set to 0 to run all pairs

if single != 0
    M_values = [M_values_set[single]]
    N_values = [N_values_set[single]]
else
    M_values = M_values_set
    N_values = N_values_set
end


# ─────────────────────────────────────────────────────────────────────────────
# MAIN RUN LOOP
# ─────────────────────────────────────────────────────────────────────────────

for case in Case_Num

    if DEFAULT_OPF_personal == true

        global combined_extension = "_default_case$case"
        global separate_extension = combined_extension

        println()
        printstyled("Running default OPF case $case"; color=:red)
        println()

        default_opf(file_path)

    else

        for i in 1:length(M_values)

            M = M_values[i]
            N = N_values[i]

            if proxy == 1

                global combined_extension = "_VUF+Gen_$(M)_$(N)_case$case"
                global separate_extension = combined_extension

                println()
                printstyled(
                    "Running VUF+Gen case $case with M=$M and N=$N";
                    color=:red
                )
                println()

                VUF_Gen_costs(file_path, M, N)

            elseif proxy == 2

                global combined_extension = "_Zlin+Gen_$(M)_$(N)_case$case"
                global separate_extension = combined_extension

                println()
                printstyled(
                    "Running Zlin+Gen case $case with M=$M and N=$N";
                    color=:red
                )
                println()

                Zlin_Gen_costs(file_path, M, N)

            end
        end
    end
end