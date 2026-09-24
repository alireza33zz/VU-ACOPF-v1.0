#=
plot_feeder_topology.jl

Parses an OpenDSS-style "Lines.txt" file (New Line.xxx ... Bus1=... Bus2=...
LineCode=... entries) and draws the feeder as a network diagram.

No bus coordinate (Buscoords) file is assumed to exist for this feeder, so the
layout is computed algorithmically as a rooted tree: the graph is walked
breadth-first from the substation, each bus is placed one level below its
parent, and horizontal positions are assigned so that every parent sits above
the centroid of its children (classic recursive tree layout). This produces a
clean, deterministic, publication-style radial diagram without needing
external coordinate data.

Only Plots.jl is required — no Graphs.jl / GraphRecipes dependency — to keep
this self-contained and fast to run on a 100+ node feeder. No legend is
drawn; every bus is labeled with its name/number from Lines.txt.

Usage:
    julia plot_feeder_topology.jl Lines.txt

Output:
    feeder_topology.png  (and .pdf) written next to the input file.
=#

using Plots
gr()  # fast, clean backend; swap for pgfplotsx() if you want true LaTeX/IEEE fonts

# -----------------------------------------------------------------------
# 1. Parse Lines.txt
# -----------------------------------------------------------------------

struct FeederLine
    name::String
    bus1::String
    bus2::String
    linecode::String
    length::Float64
end

function parse_lines_file(path::AbstractString)
    lines = FeederLine[]
    line_re = r"New\s+Line\.(\S+)\s+.*?Bus1\s*=\s*(\S+)\s+Bus2\s*=\s*(\S+)"i
    code_re = r"LineCode\s*=\s*(\S+)"i
    len_re  = r"Length\s*=\s*([\d.]+)"i

    for raw in eachline(path)
        s = strip(raw)
        (isempty(s) || startswith(s, "!")) && continue
        occursin("New Line.", s) || continue

        m = match(line_re, s)
        m === nothing && continue

        name = m.captures[1]
        bus1 = m.captures[2]
        bus2 = m.captures[3]

        cm = match(code_re, s)
        lm = match(len_re, s)
        code = cm === nothing ? "?" : cm.captures[1]
        len  = lm === nothing ? NaN : parse(Float64, lm.captures[1])

        push!(lines, FeederLine(name, bus1, bus2, code, len))
    end
    return lines
end

# -----------------------------------------------------------------------
# 2. Build adjacency + tree layout rooted at the substation
# -----------------------------------------------------------------------

function build_adjacency(lines::Vector{FeederLine})
    adj = Dict{String, Vector{String}}()
    for l in lines
        push!(get!(adj, l.bus1, String[]), l.bus2)
        push!(get!(adj, l.bus2, String[]), l.bus1)
    end
    return adj
end

"""
Breadth-first assign a parent + depth to every bus starting from `root`.
Returns (parent::Dict, depth::Dict, order::Vector{String}) where `order`
is BFS visitation order (root first).
"""
function bfs_tree(adj::Dict{String, Vector{String}}, root::AbstractString)
    parent = Dict{String, Union{String,Nothing}}(root => nothing)
    depth  = Dict{String, Int}(root => 0)
    order  = String[root]
    queue  = [root]

    while !isempty(queue)
        u = popfirst!(queue)
        for v in get(adj, u, String[])
            if !haskey(depth, v)
                parent[v] = u
                depth[v]  = depth[u] + 1
                push!(order, v)
                push!(queue, v)
            end
        end
    end
    return parent, depth, order
end

"""
Recursively assign x-coordinates: leaves get sequential integer slots,
internal nodes are centered over the mean x of their children.
Returns Dict{String,Float64} of x positions.
"""
function assign_x_positions(adj::Dict{String,Vector{String}}, parent, root::AbstractString)
    children = Dict{String, Vector{String}}()
    for (node, p) in parent
        p === nothing && continue
        push!(get!(children, p, String[]), node)
    end

    x = Dict{String, Float64}()
    next_leaf_slot = Ref(0.0)

    function place!(node::AbstractString)
        kids = get(children, node, String[])
        if isempty(kids)
            x[node] = next_leaf_slot[]
            next_leaf_slot[] += 1.0
        else
            for k in kids
                place!(k)
            end
            xs = [x[k] for k in kids]
            x[node] = sum(xs) / length(xs)
        end
    end

    place!(root)
    return x
end

# -----------------------------------------------------------------------
# 3. Plot
# -----------------------------------------------------------------------

function plot_feeder(lines::Vector{FeederLine}; root::AbstractString="Substation",
                      show_labels::Bool=false, outpath::AbstractString="feeder_topology")

    adj = build_adjacency(lines)
    haskey(adj, root) || error("Root bus \"$root\" not found in parsed topology.")

    parent, depth, order = bfs_tree(adj, root)
    xpos = assign_x_positions(adj, parent, root)
    ypos = Dict(b => -depth[b] for b in order)   # substation at top (y=0), feeder grows downward

    plt = plot(size=(1600, 1000), legend=false, framestyle=:none,
               background_color=:white, dpi=300,
               title="Modified IEEE 123-Bus Feeder Topology")

    seen_edge = Set{Tuple{String,String}}()
    for l in lines
        key = l.bus1 < l.bus2 ? (l.bus1, l.bus2) : (l.bus2, l.bus1)
        key in seen_edge && continue
        push!(seen_edge, key)
        (haskey(xpos, l.bus1) && haskey(xpos, l.bus2)) || continue
        plot!(plt, [xpos[l.bus1], xpos[l.bus2]], [ypos[l.bus1], ypos[l.bus2]],
              color=:black, lw=1.2, label="", alpha=0.85)
    end

    # Nodes: substation highlighted, everything else uniform. No legend.
    xs = [xpos[b] for b in order]
    ys = [ypos[b] for b in order]
    scatter!(plt, xs, ys, ms=3.2, mc=:steelblue, msc=:black, msw=0.4, label="")
    scatter!(plt, [xpos[root]], [ypos[root]], ms=9, marker=:square,
             mc=:crimson, msc=:black, msw=1, label="")

    if show_labels
        for b in order
            annotate!(plt, xpos[b], ypos[b] + 0.18, text(b, 6, :black, :center))
        end
    end

    savefig(plt, outpath * ".png")
    savefig(plt, outpath * ".pdf")
    println("Saved $(outpath).png and $(outpath).pdf  ($(length(order)) buses, $(length(lines)) lines)")
    return plt
end

# -----------------------------------------------------------------------
# 4. Run
# -----------------------------------------------------------------------

function main()
    infile = length(ARGS) >= 1 ? ARGS[1] : "123Buses/Lines.txt"
    lines = parse_lines_file(infile)
    isempty(lines) && error("No lines parsed from $infile — check the file format.")
    plot_feeder(lines; root="Substation", show_labels=true)
end

main()