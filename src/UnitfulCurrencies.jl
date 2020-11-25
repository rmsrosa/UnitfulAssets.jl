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

"""
    @currency code_symb name

Create a dimension and a reference unit for a currency.

The macros `@dimension` and `@refunit` are called with arguments derived
from `code_symb` and `name`.
"""
macro currency(code_symb, name)
    gap = Int('𝐀') - Int('A')
    code_abbr = string(code_symb)
    code_abbr_bold = join([Char(Int(c) + gap) for c in code_abbr])
    dimension = Symbol(code_abbr_bold)
    dim_abbr = string(code_symb) * "CURRENCY"
    dim_name = Symbol(code_abbr_bold * "𝐂𝐔𝐑𝐑𝐄𝐍𝐂𝐘")
    esc(quote
        Unitful.@dimension($dimension, $dim_abbr, $dim_name)
        Unitful.@refunit($code_symb, $code_abbr, $name, $dimension, true)
    end)
end

include("pkgdefaults.jl")

"""
    uconvert(u::Units, x::Quantity, e::ExchangeMarket)

Convert between currencies according to a market list of exchange pairs.

The exchange market must contain an exchange rate from `unit(x)` to `u`,
otherwise an error is thrown.

An `ArgumentError` is also thrown if either `unit(x)` or `u` is not a currency.

# Examples

Assuming `forex_exchmkt["2020-11-01"]` ExchangeMarket contains the key-value
pair `"EURBRL" => 6.685598`, then the following exchange takes place:

```jldoctest
julia> uconvert(u"BRL", 1u"EUR", forex_exchmkt["2020-11-01"])
6.685598 BRL
```
"""
function uconvert(u::Unitful.Units, x::Unitful.Quantity, e::ExchangeMarket)
    u_curr = string(Unitful.dimension(u))[1:3]
    x_curr = string(Unitful.dimension(x))[1:3]
    pair = x_curr * u_curr
    if pair in keys(e)
        rate = Main.eval(Meta.parse(string(e[pair]) * "u\"" * u_curr * "/" * x_curr * "\""))
        Unitful.uconvert(u, rate * x)
    else
        throw(ArgumentError(
            "No exchange rate available in the given exchange market" *
            "for the conversion from $(Unitful.unit(x)) to $u."
            )
        )            
    end
end

"""
    uconvert(u::Units, x::Quantity, e::ExchangeMarket, extended::Bool)

Convert between currencies, allowing for extensions.

If the given exchange market includes the conversion rate from `unit(x)`
to `u`, then the function `uconvert(u,x,e)` is invoked. Otherwise, if
`extended` is `true` and a conversion `rate` from `u` to `unit(x)` is
included in the exchange market, then `1/rate` is used for the conversion
of `x` to `u`.

STILL TO BE IMPLEMENTED: If `extended` is true and neither conversions from `unit(x)` to `u`
or `u` to `unit(x)` is given in the exchange market, then the function
looks for the first tertiary conversion in the exchange market (i.e.
an exchange rate from `unit(x)` to an intermediate unit `v` and an
exchange rate from `v` to `u`, so that the compound rate is used).
If there is no such conversion either, then an `ArgumentError` is thrown.

An `ArgumentError` is also thrown if either `unit(x)` or `u` is not a currency.

# Examples

Assuming `forex_exchmkt["2020-11-01"]` ExchangeMarket contains the key-value
pair `"EURBRL" => 6.685598`, then the following exchange takes place:

```jldoctest
julia> uconvert(u"BRL", 1u"EUR", forex_exchmkt["2020-11-01"])
6.685598 BRL
julia> uconvert(1u"BRL", 1u"BRL", forex_exchmkt["2020-11-01"])
0.149575251159283 EUR
```
"""
function uconvert(u::Unitful.Units, x::Unitful.Quantity, e::ExchangeMarket, extended::Bool)
    u_curr = string(Unitful.dimension(u))[1:3]
    x_curr = string(Unitful.dimension(x))[1:3]
    pair = x_curr * u_curr
    pairinv = u_curr * x_curr
    if !extended || pair in keys(e)
        uconvert(u, x, e)
    elseif extended && pairinv in keys(e)
        rate = Main.eval(Meta.parse(string(1/e[pairinv]) * "u\"" * u_curr * "/" * x_curr * "\""))
        Unitful.uconvert(u, rate * x)
    else
        throw(ArgumentError(
            "No extended exchange rate available in the given exchange" *
            "market for the conversion from $(Unitful.unit(x)) to $u."
            )
        ) 
    end
end

include("exchmkt_tools.jl")

# Register the above units and dimensions in Unitful
__init__() = Unitful.register(UnitfulCurrencies)

end # module
