__precompile__(true)
"""
    UnitfulCurrencies

Module extending Unitful.jl with currencies.
"""
module UnitfulCurrencies

using Unitful, CSV, JSON, Dates
using Unitful: uconvert, basefactors, @dimension, @unit, @refunit, Units
import Unitful: uconvert
#import Unitful: basefactors

"""
    ExchangePairs

Abstract supertype for all exchange pair rates.
"""
abstract type ExchangePairs end

Base.broadcastable(x::ExchangePairs) = Ref(x)

# Define currency dimension
@dimension  𝐂   "C"     Currency

# Set reference unit
base_curr = "EUR"
@refunit    EUR     "EUR"   Euro    𝐂   false

# Load currency info and define new currency units
curr_list = CSV.File("src/list_of_currencies.csv")

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

# Load exchange rates

exr_dir = "src/exchange_rates/"
jexr = Dict()
for entry in readdir(exr_dir)
    if entry[end-4:end] == ".json"
        j = JSON.parsefile(exr_dir * entry)
        jexr[j["date"]] = Dict("base" => j["base"], "rates" => j["rates"])
    end
end

# Set date to initialize rates in the unit definitions
date = "2020-01-01"

# Set reference unit, base currency, and base factor
base_curr = jexr[date]["base"]

#= eval(
    quote
        Unitful.@refunit $base_curr $base_curr $base_curr  "𝐂" false
    end
) =#
#Unitful.@refunit   EUR     "EUR"   Euro    𝐂   false


# define units
#= for (curr, rate) in jexr[date]["rates"]
    if curr != base_curr
        eval(
            quote
                Unitful.@unit_symbols($curr,$curr,𝐂,(1/$rate, 1))
                Unitful.abbr(::Unitful.Unit{Symbol($curr),𝐂}) = begin $curr end
            end
            )
    end
end =#

function set_exchange_rates(d::Date)
    date = string(d)
    if date in keys(jexr)
        println("Setting exchange rates for date $date")
        base_factor = jexr[date]["base"] == base_curr ? 1.0 : 1/jexr[date]["rates"][base_curr]
        for (curr, rate) in jexr[date]["rates"]
            if curr != base_curr
                rate_to_base = base_factor * rate
                basefactors[Symbol(curr)] = (1/rate_to_base, 1)
            end
        end
    else
        println("No exchange rates availabe for date $date")
    end
end

function set_exchange_rates(date::String)
    set_exchange_rates(Date(date))
end

function set_exchange_rates()
    nothing
end

"""
    uconvert(u::Units, x::Quantity, e::ExchangePairs)

Convert amount in currency `x` to the currency unit `u` based on a list
e of exchange pairs.

# Examples

```jldoctest
julia> uconvert(u"BRL", 1u"EUR", exchange_pairs("2020-10-01")) 
???
```
"""
Unitful.uconvert(u::Units, x::Quantity, e::ExchangePairs) 
    if "USD" * "EUR" in keys(ExchangePairs)
        = uconvert(u, edconvert(dimension(u), x, e))
    else
        throw(ArgumentError("No exchange pair available for USD and EUR"))
    end
end


# Register the above units and dimensions in Unitful
__init__() = Unitful.register(UnitfulCurrencies)

end # module
