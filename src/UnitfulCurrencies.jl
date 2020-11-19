__precompile__(true)
"""
    UnitfulCurrencies

Module extending Unitful.jl with currencies.
"""
module UnitfulCurrencies

using Unitful, JSON, Dates
using Unitful: uconvert, basefactors, @dimension, @unit, @refunit
import Unitful: basefactors

"""
    ExchangeRate

Abstract supertype for all exchange rate types.
"""
abstract type ExchangeRate end

Base.broadcastable(x::ExchangeRate) = Ref(x)

# Define currency dimension

@dimension  𝐂   "C"     Currency

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
@refunit    EUR     "EUR"       Euro                𝐂           false
base_curr = "EUR"
base_factor = jexr[date]["base"] == base_curr ? 1.0 : 1/jexr[date]["rates"][base_curr]

# define units
for (curr, rate) in jexr[date]["rates"]
    if curr != base_curr
        rate_to_base = base_factor * rate
        eval(
            quote
                Unitful.@unit_symbols($curr,$curr,𝐂,(1/$rate_to_base, 1))
                Unitful.abbr(::Unitful.Unit{Symbol($curr),𝐂}) = $curr
            end
            )
    end
end

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

# Register the above units and dimensions in Unitful
__init__() = Unitful.register(UnitfulCurrencies)

end # module
