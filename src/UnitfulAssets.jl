__precompile__(true)
"""
    UnitfulAssets

Module extending Unitful.jl with assets such as cash, stock, and commodites.

Dimensions and reference units are created for each asset. Cash assets associated
with all the active currencies around the world are defined, along with some
(metal) commidities and a few stocks.

An `ExchangeMarket` type is defined as `Dict{AssetPair,ExchangeRate}`, 
in which `AssetPair` is a tuple of Strings corresponding to the base and quote
assets, and `ExchangeRate` contains a positive Number with the corresponding
quote-ask rate for the pair.

Based on an given instance of `ExchangeMarket`, a conversion can be made
from the "quote" asset to the "base" asset. This conversion
is implemented as an extended dispatch for `Unitful.uconvert`.
"""
module UnitfulAssets

using Unitful, JSON
using Unitful: @dimension, @refunit
import Unitful: uconvert

export ExchangeMarket, generate_exchmkt

include("utils.jl")
include("assets.jl")
include("pkgdefaults.jl")
include("currency_symbols.jl")
include("exchmkt.jl")
include("exchmkt_extras.jl")

# Register the new units and dimensions in Unitful
const localpromotion = Unitful.promotion # only needed with new dimensions
function __init__()
    Unitful.register(UnitfulAssets) # needed for new Units
    merge!(Unitful.promotion, localpromotion) # only needed with new dimensions
end

end # module
