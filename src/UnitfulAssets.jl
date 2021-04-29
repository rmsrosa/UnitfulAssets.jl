__precompile__(true)
"""
    UnitfulAssets

Module extending Unitful.jl with currencies.

Currency dimensions are created for each currency, along with its reference
unit. All active currencies around the world are defined.

An `ExchangeMarket` type is defined as `Dict{CurrencyPair,ExchangeRate}`, 
in which `CurrencyPair` is a tuple of Strings with the ISO-4217 alphabetic
codes corresponding to the base and quote currencies and `ExchangeRate`
contains a positive Number with the corresponding quote-ask rate for the pair.

Based on an given exchange market instance of `ExchangeMarket`, a conversion
can be made from the "quote" currency to the "base" currency. This conversion
is implemented as an extended dispatch for `Unitful.uconvert`.
"""
module UnitfulAssets

using Unitful, JSON
using Unitful: @dimension, @refunit
import Unitful: uconvert

export Market, generate_mkt

include("assets_constructor.jl")
include("pkgdefaults.jl")
include("currency_symbols.jl")
include("mkt_constructor.jl")
include("exchmkt_tools.jl")

# Register the new units and dimensions in Unitful
const localpromotion = Unitful.promotion # only needed with new dimensions
function __init__()
    Unitful.register(UnitfulAssets) # needed for new Units
    merge!(Unitful.promotion, localpromotion) # only needed with new dimensions
end

end # module
