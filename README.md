# Voltage Unbalance Aware OPF (Julia)

This repository contains a **Julia implementation of Optimal Power Flow (OPF) models that incorporate voltage unbalance in distribution networks**. The framework evaluates different strategies for handling voltage unbalance in three-phase OPF formulations.

The project supports multiple OPF formulations including:

- **Default OPF** (no voltage unbalance consideration)
- **Hard VUF constraints**
- **Soft VUF penalization**
- **Hybrid limits**
- **Improved Hybrid Limits (IHL)** using the MPVUR/Zlin proxy

The models are designed for **low-voltage distribution systems with unbalanced loads and distributed generation**.

---

# Repository Structure

```
.
├── main.jl                  # Main entry point for running simulations
├── Default Gen cost.jl      # Default OPF implementation
├── VUF+Gen costs.jl         # OPF with VUF penalization
├── MPVUR+Gen costs.jl       # OPF using MPVUR / Zlin proxy
│
├── LVTestCase/
│   └── Master.dss           # OpenDSS network model
│
└── README.md
```

---

# Requirements

The code is written in **Julia**.

Recommended Julia version:

```
Julia ≥ 1.9
```

Main packages typically required:

- `JuMP`
- `Ipopt`
- `PowerModelsDistribution`
- `OpenDSSDirect`
- `Plots`

Install packages using:

```julia
using Pkg
Pkg.add([
    "JuMP",
    "Ipopt",
    "PowerModelsDistribution",
    "OpenDSSDirect",
    "Plots"
])
```

---

# Running the Simulation

The project is executed from:

```
main.jl
```

Run with:

```bash
julia main.jl
```

---

# Selecting the OPF Mode

Inside `main.jl`, choose the desired simulation mode:

```julia
selected_mode = 3
```

Available modes:

| Mode | Description |
|-----|-------------|
| **1** | Default OPF (no voltage unbalance consideration) |
| **2** | OPF with **hard VUF constraint** |
| **3** | OPF with **VUF penalization** |
| **4** | **Hybrid limits** (constraint + penalization) |
| **5** | **Improved Hybrid Limits (IHL)** using MPVUR proxy |

---

# Selecting Test Cases

Cases are defined in:

```julia
Case_Num = [1,2,3,4,5]
```

To run a single case:

```julia
Case_Num = [1]
```

---

# Voltage Unbalance Weights

The penalization weights are defined as:

```julia
M_values_set
N_values_set
```

To run a **single weight pair**:

```julia
single = 3
```

To run **all weight combinations**:

```julia
single = 0
```

---

# Output and Visualization

The following flags control output behavior:

```julia
PLOT_DISPLAY
SAVING_FIGURES_STATUS
PRINT_PERMISSION_personal
```

Example:

```julia
global PLOT_DISPLAY = true
global SAVING_FIGURES_STATUS = true
```

---

# Network Model

The test feeder is provided in:

```
LVTestCase/Master.dss
```

The model is solved through **PowerModelsDistribution**, which reads the OpenDSS network description.

---

# Research Context

The framework was developed for studying:

- **Voltage unbalance impacts in distribution OPF**
- **Economic valuation of power quality**
- **Distribution Locational Marginal Prices (DLMP) under unbalanced conditions**
- **Trade-offs between generation cost and power quality**

---

## 📜 Citation

If you use this repository in your research or publication, please cite:

```bibtex
@misc{zabihi2025impactvoltageunbalancedistribution,
  title        = {On the Impact of Voltage Unbalance on Distribution Locational Marginal Prices},
  author       = {Zabihi, Alireza and Badesa, Luis and Hernandez, Araceli},
  year         = {2025},
  eprint       = {2511.13971},
  archivePrefix= {arXiv},
  primaryClass = {eess.SY},
  url          = {https://arxiv.org/abs/2511.13971}
}
```

---

# Author

**Alireza Zabihi**  
PhD student at Universidad Politécnica de Madrid (UPM)


## Funding details

This work was supported by MICIU/AEI/10.13039/501100011033 and ERDF/EU under grant PID2022-141609OB-I00, and by the Madrid Government (Comunidad de Madrid-Spain) under the Multiannual Agreement 2023-2026 with Universidad Politécnica de Madrid, "Line A - Emerging PIs". The work of Alireza Zabihi was supported by the 2023 FPI- UPM call for Predoctoral Contracts within the framework of the 2021-2023 State Plan for Scientific, Technical, and Innovative Research.

<p align="center">
  <img src="figure1.jpg" width="70%" />
  <img src="figure2.png" width="20%" />
</p>
