using DataFrames, DataFramesMeta, CSV, StatsPlots

d = CSV.read("../econometrics-phd/data/abb_aea_data.csv",DataFrame)

d[!,:logy] = log.(d.y)

# take a look at log-variance with age:
@chain d begin
    groupby(:age) 
    @subset sum(.!ismissing.(:y)) > 100 # limit to more than 100 observations
    groupby(:age) 
    @combine :var_logy = var(log.(:y))
    @df _ plot(:age,:var_logy)
end

# construct forward-lags
function forward_lag(d,l,var)
    d = @chain d begin
        @select :person :year $var
        @transform :year = :year .- l
        @rename $(Symbol(var,"_",l)) = $var
        leftjoin(d,_,on=[:person,:year])
    end
    return d
end

d = forward_lag(d,2,:logy)
d = forward_lag(d,4,:logy)
d = forward_lag(d,6,:logy)

# Let's examine the covariance at different lags:
lag = [2,4,6]
cov_lag = pairwise(cov,eachcol(d[!,[:logy,:logy_2,:logy_4,:logy_6]]),skipmissing = :pairwise)[:,1]


cov_growth = @chain d begin
    @transform begin 
        :Dlogy_2 = :logy_2 .- :logy
        :Dlogy_4 = :logy_4 .- :logy_2
        :Dlogy_6 = :logy_6 .- :logy_4
    end
    @select :Dlogy_2 :Dlogy_4 :Dlogy_6
    pairwise(cov,eachcol(_),skipmissing = :pairwise)
end