module CollapseEngine

export collapse_risk_score, interpret_score

"Compute the ψ-Collapse Risk Score based on market signals"
function collapse_risk_score(
    liquidity_entropy::Float64,
    tweet_signal::Float64,
    psi_score::Float64,
    ivv::Float64,
    gremlin_heat::Float64,
    reflection_lag::Float64
)::Float64
    return (
        0.25 * liquidity_entropy +
        0.20 * tweet_signal +
        0.25 * psi_score +
        0.10 * ivv +
        0.10 * gremlin_heat +
        0.10 * reflection_lag
    )
end

"Interpret the risk score into categories"
function interpret_score(score::Float64)::String
    if score < 0.3
        return "🟢 Stable: Healthy hype cycle."
    elseif score < 0.6
        return "🟡 Caution: Memory lagging—keep watch."
    elseif score < 0.8
        return "🟠 Warning: Pre-collapse—mirror heating."
    else
        return "🔴 Critical: Collapse imminent—short, escape, or invert."
    end
end

end # module
