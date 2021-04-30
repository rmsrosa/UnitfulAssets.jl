#= 
File containing further dispatches of `generate_exchmkt` to allow
generating ExchangeMarket instances from json files of some internet
exchange market providers.

Currently, only tools for fixer.io and currencylayer.com providers
are implemented.
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

Return an `ExchangeMarket` instance from a currencylayer.com Dict.
"""
function generate_exchmkt(exch_data::Dict, ::Val{:currencylayer})
    return generate_exchmkt([(pair[1:3],pair[4:6]) => float(rate) for (pair,rate) in exch_data["quotes"]])
end

"""
    generate_exchmkt(filename::String, ::Val{T}) where T

Return an `ExchangeMarket` instance from a filename and the symbol T
associated with the appropriate parser for that market.
"""
function generate_exchmkt(filename::String, ::Val{T}) where T
    return generate_exchmkt(JSON.parsefile(filename), Val(T))
end
