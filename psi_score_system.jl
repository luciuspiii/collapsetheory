
using HTTP
using JSON3
using Dates
using Plots

# --- HISTORY STRUCTURES ---
psi_history = Dict{String, Vector{Tuple{DateTime, Float64}}}()
borrow_history = Dict{String, Vector{Tuple{DateTime, Float64}}}()

# --- FEED 1: Price Delta (24hr % Change) ---
function fetch_price_delta(token::String)
    # Placeholder logic, replace with live feed
    old_price = 0.00002
    new_price = 0.000021
    return (new_price - old_price) / old_price
end

# --- FEED 2: Borrow Pressure from Drift ---
function fetch_borrow_pressure_drift(token::String)
    try
        response = HTTP.get("https://api.drift.trade/v1/pools")
        data = JSON3.read(String(response.body))
        # Example: find the token and extract pressure
        return 0.05  # Placeholder value
    catch e
        @warn "Failed to fetch borrow pressure: $e"
        return missing
    end
end

# --- FEED 3: Rate of Holder Gain ---
function rate_gain_of_holders(token::String)
    prev_count = 10000
    current_count = 10200
    return (current_count - prev_count) / prev_count
end

# --- FEED 4: Liquidation Spike ---
function fetch_liquidation_spike(token::String)
    # Placeholder logic
    recent_liquidations = 1_500_000.0
    baseline = 500_000.0
    return (recent_liquidations - baseline) / baseline
end

# --- FEED 5: Supply Change ---
function fetch_supply_change(token::String)
    prev_supply = 100_000_000_000.0
    current_supply = 100_500_000_000.0
    return (current_supply - prev_supply) / prev_supply
end

# --- PSI SCORE ---
function compute_psi_score(asset::String)
    delta = fetch_price_delta(asset)
    borrow = fetch_borrow_pressure_drift(asset)
    r_h = rate_gain_of_holders(asset)
    liquidation = fetch_liquidation_spike(asset)
    supply = fetch_supply_change(asset)

    return delta * 0.25 + borrow * 0.2 + r_h * 0.2 + liquidation * 0.15 + supply * -0.2
end

# --- HISTORY TRACKING ---
function update_history!(asset::String, psi::Float64, borrow::Float64, t::DateTime)
    push!(get!(psi_history, asset, []), (t, psi))
    push!(get!(borrow_history, asset, []), (t, borrow))
end

# --- PLOTTER ---
function plot_psi_vs_borrow(asset::String)
    plt = plot(title="Ψ-score vs Borrow Rate: $asset", xlabel="Time", ylabel="Value")

    if haskey(psi_history, asset)
        times = [Dates.value(t) for (t, _) in psi_history[asset]]
        scores = [s for (_, s) in psi_history[asset]]
        plot!(plt, times, scores, label="Ψ-score", color=:blue)
    end

    if haskey(borrow_history, asset)
        times = [Dates.value(t) for (t, _) in borrow_history[asset]]
        rates = [r for (_, r) in borrow_history[asset]]
        plot!(plt, times, rates, label="Borrow Rate", color=:red, linestyle=:dash)
    end

    display(plt)
end
