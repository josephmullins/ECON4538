using LinearAlgebra
#- we're gonna do a life-cycle model
# utility, solve_value, iterate_value_function!, solve_model, tauchen are in income_tools.jl
include("income_tools.jl")

T = 60
p = (;
    T,
    asset_grid = LinRange(0,100,1_000),
    income_grid = zeros(5,T),
    β = 0.96,
    r = 0.04,
    Π = I(5),
    σ = -2.
)

solve_model(p)
model = solve_model(p);

# next: setup tauchen, and set up an age polynomial in income