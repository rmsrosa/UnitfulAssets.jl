__precompile__(true)
"""
    UnitfulCurrencies

Module extending Unitful.jl with currencies.

A currency dimension 𝐂 is created and most, if not all, active currencies
around the world are defined as units with dimension 𝐂. The Euro is set
as the reference unit for 𝐂.

An ExchangeMarket type is also defined as a Dict{String,Real} for containing
currency pairs (see `ExchangeMarket`).

Based on an given exchange market, a conversion can be made from a "quote"
currency to the "base" currency. This is implemented as an extended
dispatch for `uconvert`.
"""
module UnitfulCurrencies

using Unitful, CSV, JSON
using Unitful: @dimension, @refunit
import Unitful: uconvert

export ExchangeMarket

"""
    ExchangeMarket

Alias for the type used for exchange rates pairs, given as a
Dict{String,Float64}, where the key is expected to be a 
six-characters string containing the concatenation of the
alphabetic codes ISO-4217 of the base and quote currencies,
and the value is the exchange rate between these currencies.

For instance, the Dict

    exchmkt = Dict("EURUSD" => 1.164151)

is of ExchangeMarket type and it means that, in this exchange maket,
one can trade 1 EUR for 1.164151 USD, i.e. one can buy 1 EUR
with 1.164151 USD.
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
    curr_dim = join([Char(Int(c) + 119743) for c in curr_code]) * "_𝐂𝐮𝐫𝐫𝐞𝐧𝐜𝐲"
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

Convert between currencies according to a market list of exchange pairs.

# Examples

Assuming `forex_exchmkt["2020-11-01"]` ExchangeMarket contains the key-value
pair `"EURBRL" => 6.685598`, then the following exchange takes placee:

```jldoctest
julia> uconvert(u"BRL", 1u"EUR", forex_exchmkt["2020-11-01"])
6.685598 BRL
```
"""
function Unitful.uconvert(u::Unitful.Units, x::Unitful.Quantity, e::ExchangeMarket)
    if Unitful.dimension(u) == Unitful.dimension(x) == 𝐂
        pair =  string(Unitful.unit(x)) * string(u)
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

include("exchmkt_tools.jl")

# Register the above units and dimensions in Unitful
__init__() = Unitful.register(UnitfulCurrencies)

end # module
