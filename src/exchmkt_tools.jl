#= 
File containing tools/functions to create ExchangeMarket instances
from json files of some exchange market providers.

Currently, only tools for fixer.io and currencylayer.com providers
are implemented, and only for options "historical" and "latest".
=#
"""
    generate_exchmkt(exch_data::Dict, ::Val{:fixer})

Return an `ExchangeMarket` instance from a fixer.io Dict.
"""
function generate_exchmkt(exch_data::Dict, ::Val{:fixer})
    base = exch_data["base"]
    return generate_exchmkt([(base,curr) => float(rate) for (curr,rate) in exch_data["rates"]])
end

"""
    generate_exchmkt(exch_data::Dict, ::Val{:currencylayer})

Return a `ExchangeMarket` instance from a currencylayer.com json file.
"""
function generate_exchmkt(exch_data::Dict, ::Val{:currencylayer})
    return generate_exchmkt([(pair[1:3],pair[4:6]) => float(rate) for (pair,rate) in exch_data["quotes"]])
end

"""
    generate_exchmkt(filename::String, ::Val{T}) where T

Return a `ExchangeMarket` instance from a filename and the symbol T
associated with the appriate parser of the market.
"""
function generate_exchmkt(filename::String, ::Val{T}) where T
    return generate_exchmkt(JSON.parsefile(filename), Val(T))
end
