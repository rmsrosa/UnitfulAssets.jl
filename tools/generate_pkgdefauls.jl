using DataFrames, CSV

df = CSV.read(joinpath("tools", "list_currency_iso.csv"), DataFrame, header=4)

dropmissing!(df, "Alphabetic Code")
unique!(df, :Currency)

nrows = size(df)[1]
df = hcat(DataFrame(Macro = fill("@intrument Currency", nrows)), combine(df, "Alphabetic Code" => :Code,
             :Currency => x -> replace.(titlecase.(x; strict=false), r" |’" => ""),
             renamecols=false))

CSV.write(joinpath("src", "pkgdefaults.jl"), df, delim="  ", header = false)