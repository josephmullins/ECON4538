# income_tools.jl
#
# Shared code for the ECON4538 recitations and assignments.
# Load it with:
#   include("income_tools.jl")                    # from recitations/
#   include("../recitations/income_tools.jl")     # from assignments/
#
# Contents:
#   1. Utility and the Tauchen approximation of an AR(1)      (Recitation 2)
#   2. Stationary distribution of a Markov chain              (Recitation 2)
#   3. Life-cycle savings model with taxes and transfers      (Recitations 2-3)
#   4. Tax functions and budget balance                       (Recitation 3)
#   5. Certainty equivalents and the welfare decomposition    (Lecture 2, Recitation 3)
#   6. PSID helpers                                           (Recitation 4)

using LinearAlgebra, Distributions, DataFrames, DataFramesMeta, CSV

# ------------------------------------------------------------------
# 1. Utility and Tauchen's method
# ------------------------------------------------------------------

# CRRA utility
utility(c, σ) = c^(1 - σ) / (1 - σ)

# Tauchen's method: approximate ε' = ρε + ζ, ζ ~ N(0,σ²), with an N-state Markov chain.
# Returns the grid and a transition matrix with Π[j,i] = Pr(next state j | current state i),
# so each *column* of Π sums to one.
function tauchen(N, ρ, σ)
    # Unconditional standard deviation of the process
    σ_y = σ / sqrt(1 - ρ^2)

    # Create the grid
    y_max = 3. * σ_y
    y_min = - 3. * σ_y
    grid = range(y_min, y_max, length=N)

    # Step size
    step = (y_max - y_min) / (N - 1)

    # Initialize transition matrix
    Π = zeros(N, N)

    # Standard normal distribution
    d = Normal(0, 1)

    # Fill in the transition matrix
    for i in 1:N
        for j in 1:N
            if j == 1
                # Probability of transitioning to the lowest state
                Π[j, i] = cdf(d, (grid[j] - ρ * grid[i] + step/2) / σ)
            elseif j == N
                # Probability of transitioning to the highest state
                Π[j, i] = 1 - cdf(d, (grid[j] - ρ * grid[i] - step/2) / σ)
            else
                # Probability of transitioning to intermediate states
                Π[j, i] = cdf(d, (grid[j] - ρ * grid[i] + step/2) / σ) -
                         cdf(d, (grid[j] - ρ * grid[i] - step/2) / σ)
            end
        end
    end
    return collect(grid), Π
end

# ------------------------------------------------------------------
# 2. Stationary distribution
# ------------------------------------------------------------------

# Stationary distribution π* of a chain with columns summing to one: Π π* = π*.
# π* is the eigenvector associated with the eigenvalue equal to one.
# Note: this is only unique if every state can eventually reach every other state.
# If Π is block-diagonal (e.g. a permanent fixed effect), there is one stationary
# distribution per block and you must choose the weights on the blocks yourself.
function solve_steady_state(Π)
    vals, e = eigen(Π)
    k = argmin(abs.(vals .- 1))   # eigenvalue closest to one
    v = real.(e[:, k])
    return v ./ sum(v)
end

# ------------------------------------------------------------------
# 3. Life-cycle savings model
# ------------------------------------------------------------------
# Parameters are passed as a named tuple p with fields:
#   T, asset_grid, income_grid (K_y × T, log income), β, r, Π, σ, net_income (a function)
# If p has no net_income field, net income equals gross income.
# net_income can be a function of income only, f(y), or of income and age, f(y, t).

apply_net_income(f, y, t) = applicable(f, y, t) ? f(y, t) : f(y)

# Solve the maximization problem at a single grid point (ai, yi) in period t
function solve_value(ai, yi, V, p, t)
    (;σ, β, Π, r, asset_grid, income_grid) = p
    net_income = get(p, :net_income, identity)
    a = asset_grid[ai]
    y = exp(income_grid[yi, t])
    y_net = apply_net_income(net_income, y, t)
    vmax = -Inf
    amax = 0.
    for ai_next in eachindex(asset_grid)
        a_next = asset_grid[ai_next]
        c = y_net + a - a_next/(1+r)
        if c > 0
            @views v = utility(c, σ) + β * dot(Π[:, yi], V[:, ai_next, t+1])
            if v > vmax
                vmax = v
                amax = a_next
            end
        end
    end
    return vmax, amax
end

# Calculate V_t given V_{t+1} at every grid point
function iterate_value_function!(p, V, A, t)
    for ai in axes(V, 2), yi in axes(V, 1)
        v, a_next = solve_value(ai, yi, V, p, t)
        V[yi, ai, t] = v
        A[yi, ai, t] = a_next
    end
end

# Backward induction from T to 1, with V_{T+1} = 0
function solve_model(p)
    (;T, Π, asset_grid) = p
    K_a = length(asset_grid)
    K_y = size(Π, 1)
    V = zeros(K_y, K_a, T+1)
    A = zeros(K_y, K_a, T)
    for t in reverse(1:T)
        iterate_value_function!(p, V, A, t)
    end
    return (;V, A)
end

# ------------------------------------------------------------------
# 4. Taxes and transfers
# ------------------------------------------------------------------

no_tax(x) = x

# net income λ y^(1-τ): τ governs progressivity, λ the average level
progressive_tax(x, λ, τ) = λ * x^(1-τ)

# λ that makes average net income equal average gross income under the distribution pi_star
# (when mean income varies with age, call this separately for each age t)
function solve_lambda(τ, ygrid, pi_star)
    return dot(pi_star, ygrid) / dot(pi_star, ygrid.^(1-τ))
end

# ------------------------------------------------------------------
# 5. Certainty equivalents and the welfare decomposition (notation from Lecture 2)
# ------------------------------------------------------------------

# 𝒱(c): value of consuming c for sure in each of T periods
V_cert(c, p) = (1 - p.β^p.T) / (1 - p.β) * utility(c, p.σ)

# certainty equivalent c̄ that solves 𝒱(c̄) = V
cert_equiv(V, p) = ((1 - p.σ) * (1 - p.β) / (1 - p.β^p.T) .* V) .^ (1 / (1 - p.σ))

# Decompose the welfare gain of moving from regime A to regime B.
#   V_A, V_B : values at the start of life (one per initial state)
#   pi_A, pi_B : distribution of initial states in each regime
# Returns consumption equivalents with (1+ω) = (1+ω_I)(1+ω_R), where
#   1+ω   = (W^B/W^A)^(1/(1-σ))                                total gain
#   1+ω_I = C̄^B/C̄^A                                           insurance
#   1+ω_R = [(W^B/𝒱(C̄^B)) / (W^A/𝒱(C̄^A))]^(1/(1-σ))          redistribution
function welfare_decomposition(V_A, V_B, pi_A, p; pi_B = pi_A)
    σ = p.σ
    W_A = dot(pi_A, V_A)
    W_B = dot(pi_B, V_B)
    Cbar_A = dot(pi_A, cert_equiv(V_A, p))
    Cbar_B = dot(pi_B, cert_equiv(V_B, p))
    ω = (W_B / W_A)^(1/(1-σ)) - 1
    ω_I = Cbar_B / Cbar_A - 1
    ω_R = ((W_B / V_cert(Cbar_B, p)) / (W_A / V_cert(Cbar_A, p)))^(1/(1-σ)) - 1
    return (;ω, ω_I, ω_R, W_A, W_B, Cbar_A, Cbar_B)
end

# ------------------------------------------------------------------
# 6. PSID helpers
# ------------------------------------------------------------------

# Load the PSID extract. Income y is converted to thousands of dollars.
# Trimming rule: drop household-years with income below y_min dollars (default $1,000).
# This removes a small number of observations (mostly recorded as $1) that would
# otherwise dominate the variance of log income.
function load_psid(path; y_min = 1000)
    d = CSV.read(path, DataFrame)
    d = @chain d begin
        @subset :y .>= y_min
        @transform :y = :y ./ 1000
        @transform :logy = log.(:y)
    end
    return d
end

# Add the value of `var` from l years later for the same person, named var_l
function forward_lag(d, l, var)
    d_lag = @chain d begin
        @select :person :year $var
        @transform :year = :year .- l
        @rename $(Symbol(var, "_", l)) = $var
    end
    d = leftjoin(d, d_lag, on=[:person, :year])
    return d
end
