__precompile__(true)
"""
    UnitfulCurrencies

Module extending Unitful.jl with currencies.
"""
module UnitfulCurrencies

using Unitful, CSV, JSON
using Unitful: @dimension, @refunit
import Unitful: uconvert

export ExchangeMarket

"""
    ExchangeMarket

Alias for the type used for (one-way) exchange rates, given as
a Dict{String,Float64}, where the key is expected to be a 
six-characters string.

For instance, the following instance
"""
ExchangeMarket = Dict{String,Real}

# Define currency dimension
@dimension  𝐂   "C"     Currency

# Set reference unit
base_curr = "EUR"
@refunit    EUR     "EUR"   Euro    𝐂   false

# Load currency info and define new currency units
curr_list = CSV.File("src/list_of_currencies.csv")

# Initialize 
for row in curr_list
    curr_code = row.Code
    curr_name = row.Currency
    if curr_code != base_curr
        eval(
            quote
                Unitful.@unit_symbols($curr_code,$curr_name,𝐂,(1.0, 1))
                Unitful.abbr(::Unitful.Unit{Symbol($curr_name),𝐂}) = begin $curr_code end
            end
            )
    end
end

"""
    uconvert(u::Units, x::Quantity, e::ExchangeMarket)

Convert currency amount `x` to the currency unit `u` based on a list
of exchange pairs.

# Examples

```jldoctest
julia> uconvert(u"BRL", 1u"EUR", exchange_pairs("2020-10-01")) 
???
```
"""
function Unitful.uconvert(u::Unitful.Units, x::Unitful.Quantity, e::ExchangeMarket)
    if Unitful.dimension(u) == Unitful.dimension(x) == 𝐂
        pair = string(Unitful.unit(x)) * string(u)
        if pair in keys(e)
            Unitful.uconvert(u, e[pair] * x)
        else
            throw(ArgumentError(
                "No exchange rate available in the given exchange market" *
                "for the conversion from $(Unitful.unit(x)) to $u."
                )
            )            
        end
    else
        throw(ArgumentError(
            "The first two arguments $u and $x must have the dimension of currency"
            )
        )
    end
end

"""
    get_fixer_mkt(::Dict)

Return an ExchangeMarket Dict from a Dict constructed from fixer.io json file.
"""
function get_fixer_mkt(jfixer::Dict)
    base = jfixer["base"]
    return Dict([base * curr => rate for (curr,rate) in jfixer["rates"]])
end

"""
    get_fixer_mkt(::String)

Return an ExchangeMarket Dict from a fixer.io json file of currency pairs.
"""
function get_fixer_mkt(filename::String)
    return get_fixer_mkt(JSON.parsefile(filename))
end

"""
    get_currencylayer_mkt(::String)

Return an ExchangeMarket Dict from a fixer.io json file of currency pairs.
"""
function get_currencylayer_mkt(filename::String)
    return JSON.parsefile(filename)["rates"]
end

# Register the above units and dimensions in Unitful
__init__() = Unitful.register(UnitfulCurrencies)

end # module
