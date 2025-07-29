# src/RiskDashboard.jl

module RiskDashboard

using Dates
using VegaLite
using DataFrames
export log_asset_score, print_dashboard, export_to_csv, visual_dashboard

# Internal store for scores
const results = Dict{String, Vector{Tuple{Float64, String, DateTime}}}()

const ALERT_THRESHOLD = 4.5

"""
Log an asset's collapse score, interpretation, and timestamp
"""
function log_asset_score(asset::String, inputs, scoring_fn::Function, interpret_fn::Function)
    input_vec = collect(inputs)
    score = scoring_fn(input_vec)
    interpretation = interpret_fn(score)
    timestamp = now()

    entry = (score, interpretation, timestamp)

    if haskey(results, asset)
        push!(results[asset], entry)
    else
        results[asset] = [entry]
    end
end

"""
Print the dashboard summary of all assets with optional alerts
"""
function print_dashboard()
    println("\n📊 Collapse Risk Dashboard:")
    for (asset, entries) in results
        latest = last(entries)
        score, status, time = latest
        alert = score > ALERT_THRESHOLD ? " 🚨 ALERT" : ""
        println("- $asset: Ψ-score = $score, status = $status, time = $time$alert")
    end
end

"""
Export all results to a CSV file
"""
function export_to_csv(filename::String)
    open(filename, "w") do io
        println(io, "Asset,Score,Interpretation,Timestamp")
        for (asset, entries) in results
            for (score, interpretation, timestamp) in entries
                println(io, "$asset,$score,\"$interpretation\",$timestamp")
            end
        end
    end
end

"""
Visualize collapse risk scores using VegaLite
"""
function visual_dashboard()
    rows = String[]
    scores = Float64[]
    times = DateTime[]

    for (asset, entries) in results
        for (score, _, timestamp) in entries
            push!(rows, asset)
            push!(scores, score)
            push!(times, timestamp)
        end
    end

    df = DataFrame(Asset=rows, Score=scores, Timestamp=times)
    df |> @vlplot(:line, x=:Timestamp, y=:Score, color=:Asset, title="Ψ-Collapse Risk Over Time")
end

end # module
if abspath(PROGRAM_FILE) == @__FILE__
    scoring_fn(x) = sum(x) / length(x)
    interpret_fn(score) = score > 4.5 ? "High Risk" : "Stable"

    log_asset_score("Mars", [1.2, 1.5, 1.8], scoring_fn, interpret_fn)
    log_asset_score("Venus", [2.0, 2.3, 2.6], scoring_fn, interpret_fn)
    log_asset_score("Earth", [4.9, 5.0, 5.1], scoring_fn, interpret_fn)

    print_dashboard()
    export_to_csv("collapse_report.csv")
    visual_dashboard()
end
