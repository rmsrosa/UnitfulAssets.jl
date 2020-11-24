using DataFrames, CSV

curr_list = CSV.File("tools/list_of_currencies.csv")

df_csv = curr_list |> DataFrame

nrows = size(df_csv)[1]

gap = Int('𝐀') - Int('A')
df_mod = DataFrame()
df_mod.macrocall = fill("@currency", nrows)
df_mod.code = df_csv.Code
df_mod.symb = ["\"" * code * "\"" for code in df_csv.Code]
df_mod.abbr = df_csv.Currency
df_mod.dimension = [join([Char(Int(c) + gap) for c in code]) * "_𝐂𝐔𝐑𝐑𝐄𝐍𝐂𝐘" for code in df_csv.Code];
df_mod.dim_name = ["\"" * code * "_Currency\"" for code in df_csv.Code]
df_mod.tf = fill("true", nrows)
df_mod[1:10,:]

CSV.write("src/pkgdefaults.jl", df_mod, delim="  ", header = false)