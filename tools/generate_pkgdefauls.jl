using DataFrames, CSV

df = CSV.read(joinpath("tools", "list_currency_iso.csv"), DataFrame, header=4)

dropmissing!(df, "Alphabetic Code")

nrows = size(df)[1]

#= df = combine(df, [Macro = fill("@currency", nrows)], "Alphabetic Code" => :Code,
             :Currency => x -> replace.(titlecase.(x; strict=false), r" |’" => ""),
             renamecols=false) =#

df = crossjoin(DataFrame(Macro = fill("@currency", nrows)), combine(df, "Alphabetic Code" => :Code,
             :Currency => x -> replace.(titlecase.(x; strict=false), r" |’" => ""),
             renamecols=false))



#= df_mod_new = DataFrame()
df_mod_new.macrocall = fill("@currency", nrows)
df_mod_new.abbr = df_curr_new[:,:Code]
df_mod_new.code = df_curr_new[:,:Currency] =#

CSV.write("src/pkgdefaults.jl", df, delim="  ", header = false)