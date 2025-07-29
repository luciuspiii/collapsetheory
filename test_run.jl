# test_run.jl

# ==============================
# 1. Imports & Setup
# ==============================
using Plots
using LinearAlgebra
using HTTP, JSON, Dates
push!(LOAD_PATH, joinpath(@__DIR__, "src"))
using RiskDashboard

# Initialize history storage
const psi_history = Dict{String, Vector{Tuple{DateTime, Float64}}}()
const borrow_history = Dict{String, Vector{Tuple{DateTime, Float64}}}()


# ==============================
# 2. Weighted Scoring Function
# ==============================
weights = [0.3, 0.2, 0.2, 0.2, 0.1]  # [volatility, volume, sentiment, RSI, tx_spike]

scoring_fn(inputs) = dot(inputs, weights)

interpret_fn(score) = score > 7.0 ? "CRITICAL" :
                      score > 5.0 ? "HIGH"     :
                      score > 3.5 ? "MODERATE" :
                                    "STABLE"

# ==============================
# 3. Live Data Fetchers
# ==============================

function get_price(asset::String)
    id = lowercase(asset) == "btc" ? "bitcoin" :
         lowercase(asset) == "eth" ? "ethereum" : error("Asset not supported")
    url = "https://api.coingecko.com/api/v3/simple/price?ids=$id&vs_currencies=usd"
    response = HTTP.get(url)
    data = JSON.parse(String(response.body))
    return data[id]["usd"]
end

function simulate_indicators(price)
    # crude normalization to stay in expected 0–10 input space
    volatility = 0.02 * price % 10
    volume     = 0.001 * price % 10
    sentiment  = (price % 100) / 10
    RSI        = 0.01 * price % 10
    tx_spike   = 0.0005 * price % 10
    return [volatility, volume, sentiment, RSI, tx_spike]
end

# ==============================
# 4. Log Live Scores
# ==============================

btc_price = get_price("BTC")
btc_inputs = simulate_indicators(btc_price)
log_asset_score("BTC_LIVE", btc_inputs, scoring_fn, interpret_fn)

eth_price = get_price("ETH")
eth_inputs = simulate_indicators(eth_price)
log_asset_score("ETH_LIVE", eth_inputs, scoring_fn, interpret_fn)

# Add static simulations if desired
log_asset_score("TSLA", [2.8, 2.5, 0.3, 2.1, 1.0], scoring_fn, interpret_fn)
log_asset_score("SOL",  [5.5, 3.3, 0.7, 4.8, 1.2], scoring_fn, interpret_fn)

# ==============================
# 5. Output
# ==============================
print_dashboard()
visual_dashboard()

export_to_csv("realworld_collapse_output.csv")

using HTTP, JSON, Dates, LinearAlgebra
using RiskDashboard  # scoring_fn and interpret_fn
using Printf

# Simulated feature extractor from price data
function simulate_indicators(price::Float64)
    # Simulate values for now — placeholder for real data
    volatility = rand(1.0:0.1:5.0)
    volume     = rand(1.0:0.1:5.0)
    sentiment  = rand(1.0:0.1:5.0)
    rsi        = rand(1.0:0.1:5.0)
    tx_spike   = rand(1.0:0.1:5.0)
    return [volatility, volume, sentiment, rsi, tx_spike]
end

# Run live scoring loop
function live_scoring_loop(n_seconds=30)
    while true
        try
            response = HTTP.get("https://api.coingecko.com/api/v3/simple/price?ids=bitcoin,ethereum,dogecoin&vs_currencies=usd")
            data = JSON.parse(String(response.body))

            for asset in ["bitcoin", "ethereum", "dogecoin"]
                price = data[asset]["usd"]
                indicators = simulate_indicators(price)
                score = scoring_fn(indicators)
                level = interpret_fn(score)
                timestamp = Dates.format(now(), "HH:MM:SS")

                @printf "[%s] %-8s | Price: \$%-8.2f | Score: %.2f | Status: %s\n" timestamp asset price score level
            end

            println("──────────────────────────────────────")
            sleep(n_seconds)
        catch e
            println("⚠️ Error: ", e)
            sleep(n_seconds)
        end
    end
end

using Plots

# Data storage for plotting
const score_history = Dict{String, Vector{Tuple{DateTime, Float64}}}(
    "bitcoin" => [],
    "ethereum" => [],
    "dogecoin" => []
)

# Live scoring + plotting loop
function live_scoring_plot_loop(n_seconds=30)
    plt = plot(title="Ψ-Collapse Risk Over Time",
               xlabel="Time", ylabel="Score",
               legend=:topright)

    while true
        try
            response = HTTP.get("https://api.coingecko.com/api/v3/simple/price?ids=bitcoin,ethereum,dogecoin&vs_currencies=usd")
            data = JSON.parse(String(response.body))
            timestamp = now()

            for asset in keys(score_history)
                price = data[asset]["usd"]
                indicators = simulate_indicators(price)
                score = scoring_fn(indicators)

                # Store timestamped score
                push!(score_history[asset], (timestamp, score))

                # Keep last 20 points
                if length(score_history[asset]) > 20
                    popfirst!(score_history[asset])
                end
            end

            # Replot
            plot!(plt; clear=true)
            for (asset, series) in score_history
                times = [t[1] for t in series]
                scores = [t[2] for t in series]
                plot!(plt, times, scores, label=uppercase(asset))
            end

            display(plt)
            sleep(n_seconds)
        catch e
            println("⚠️ Error: ", e)
            sleep(n_seconds)
        end
    end
end

function live_scoring_plot_loop(n_seconds=30)

    const score_history = Dict{String, Vector{Tuple{DateTime, Float64}}}(
        "bitcoin" => [],
        "ethereum" => [],
        "dogecoin" => []
    )

    plt = plot(title="Ψ-Collapse Risk Over Time",
               xlabel="Time", ylabel="Score",
               legend=:topright)

    while true
        try
            response = HTTP.get("https://api.coingecko.com/api/v3/simple/price?ids=bitcoin,ethereum,dogecoin&vs_currencies=usd")
            data = JSON.parse(String(response.body))
            timestamp = now()

            for asset in keys(score_history)
                price = data[asset]["usd"]
                indicators = simulate_indicators(price)
                score = scoring_fn(indicators)

                push!(score_history[asset], (timestamp, score))
                if length(score_history[asset]) > 20
                    popfirst!(score_history[asset])
                end
            end

            plot!(plt; clear=true)
            for (asset, series) in score_history
                times = [t[1] for t in series]
                scores = [t[2] for t in series]
                plot!(plt, times, scores, label=uppercase(asset))
            end

            display(plt)
            sleep(n_seconds)
        catch e
            println("⚠️ Error: ", e)
            sleep(n_seconds)
        end
    end
end
