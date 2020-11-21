#= 
File containing tools/functions to created ExchangeMarket instances
from json files of some exchange market providers.

Currently, tools for fixer.io and currencylayer.com providers are implemented.
 =#
"""
    get_fixer_exchmkt(::Dict)

Return an ExchangeMarket Dict from a fixer.io Dict.
"""
function get_fixer_exchmkt(jfixer::Dict)
    base = jfixer["base"]
    return Dict([base * curr => rate for (curr,rate) in jfixer["rates"]])
end

"""
    get_fixer_exchmkt(::String)

Return an ExchangeMarket Dict from a fixer.io json file.
"""
function get_fixer_exchmkt(filename::String)
    return get_fixer_exchmkt(JSON.parsefile(filename))
end

"""
    get_currencylayer_exchmkt(::String)

Return an ExchangeMarket Dict from a currenylayer.com json file.
"""
function get_currencylayer_exchmkt(filename::String)
    return JSON.parsefile(filename)["rates"]
end
