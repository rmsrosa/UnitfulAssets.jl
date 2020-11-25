using DataFrames, CSV

curr_list = CSV.File("tools/list_of_currencies.csv")

df_csv = curr_list |> DataFrame

nrows = size(df_csv)[1]

df_mod = DataFrame()
df_mod.macrocall = fill("@currency", nrows)
df_mod.code = df_csv.Code
df_mod.abbr = df_csv.Currency

CSV.write("src/pkgdefaults.jl", df_mod, delim="  ", header = false)