#= 
File containing tools/functions to created ExchangeMarket instances
from json files of some exchange market providers.

Currently, only tools for fixer.io and currencylayer.com providers
are implemented, and only for options "historical" and "latest".
 =#
"""
    get_fixer_exchmkt(::Dict)

Return an ExchangeMarket instance from a fixer.io Dict.
"""
function get_fixer_exchmkt(jfixer::Dict)
    base = jfixer["base"]
    return generate_exchmkt([(base,curr) => float(rate) for (curr,rate) in jfixer["rates"]])
end

"""
    get_fixer_exchmkt(::String)

Return an ExchangeMarket instance from a fixer.io json file.
"""
function get_fixer_exchmkt(filename::String)
    return get_fixer_exchmkt(JSON.parsefile(filename))
end

"""
    get_currencylayer_exchmkt(::String)

Return an ExchangeMarket instance from a currencylayer.com json file.
"""
function get_currencylayer_exchmkt(filename::String)
    return generate_exchmkt([(pair[1:3],pair[4:6]) => float(rate) for (pair,rate) in JSON.parsefile(filename)["quotes"]])
end
