using DataFrames, CSV

for (csv_filename, asset_class, append_arg) in (
    ("list_currencies.csv", "@asset Currency", false),
    ("list_bonds.csv", "@asset Bond", true),
    ("list_commodities.csv", "@asset Commodity", true)
)
    df = CSV.read(joinpath("tools", csv_filename), DataFrame, header=4)

    dropmissing!(df, "Alphabetic Code")
    unique!(df, :Name)

    nrows = size(df)[1]
    println(csv_filename, nrows)
    df = hcat(DataFrame(Macro = fill(asset_class, nrows)), combine(df, "Alphabetic Code" => :Code,
            :Name => x -> replace.(titlecase.(x; strict=false), r" |’" => ""),
            renamecols=false)
    )
    println("done")
    CSV.write(joinpath("src", "pkgdefaults.jl"), df, delim="  ", header = false, append=append_arg)
end