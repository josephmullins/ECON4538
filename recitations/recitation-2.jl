using LinearAlgebra
#- we're gonna do a life-cycle model
utility(c,σ) = c^(1 - σ) / (1 - σ)

# - function to iterate
function iterate_value_function!(p,V,A,t)
    for ai in axes(V,2), yi in axes(V,1)
        v,a_next = solve_value(ai,yi,V,p,t)
        V[yi,ai,t] = v
        A[yi,ai,t] = a_next
    end
end

function solve_value(ai,yi,V,p,t)
    (;σ,β,Π,r,asset_grid,income_grid) = p
    a = asset_grid[ai]
    y = exp(income_grid[yi,t])
    vmax = -Inf
    amax = 0
    for ai_next in eachindex(asset_grid)
        a_next = asset_grid[ai_next]
        c = y + a - a_next/(1+r)
        if c>0
            @views v = utility(c,σ) + β*dot(Π[:,yi],V[:,ai_next,t+1])
            if v>vmax
                vmax = v
                amax = a_next
            end
        end
    end
    return vmax,amax
end

# a function for tauchen approximation

function solve_model(p)
    (;T,Π,asset_grid) = p
    K_a = length(asset_grid)
    K_y = size(Π,1)
    V = zeros(K_y,K_a,T+1)
    A = zeros(K_y,K_a,T)
    for t in reverse(1:T)
        iterate_value_function!(p,V,A,t)
    end
    return (;V,A)
end

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