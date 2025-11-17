using DataFrames, DataFramesMeta, CSV

d = CSV.read("../econometrics-phd/data/abb_aea_data.csv",DataFrame)

@chain d begin
    
end