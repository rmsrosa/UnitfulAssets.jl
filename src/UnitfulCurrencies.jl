__precompile__(true)
"""
    UnitfulCurrencies

Module extending Unitful.jl with currencies.

Currency dimensions are created for each currency, along with its reference
unit. All active currencies around the world are defined.

An `ExchangeMarket` type is also defined as an alias for
`Dict{Tuple{String,String},Real}`, in which the tuple key contains the
quote-ask currency pair (e.g. `("EUR", "USD")`) and the value is the
exchange rate for the pair.

Based on an given exchange market instance of `ExchangeMarket`, a conversion
can be made from the "quote" currency to the "base" currency. This conversion
is implemented as an extended dispatch for `Unitful.uconvert`.
"""
module UnitfulCurrencies

using Unitful #, CSV, JSON
using Unitful: @dimension, @refunit
import Unitful: uconvert

export ExchangeMarket, @currency

#= struct CurrencyPair{T<:String}
    base_curr::T
    quote_curr::T
end =#

"""
    ExchangeMarket

Alias for the type used for exchange rates pairs, given as a
Dict{Tuple{String,String},Float64}, where the key is expected 
to be a tuple of three-character strings containing the 
alphabetic codes ISO-4217 of the base and quote currencies,
respectively, and the value is the exchange rate for this pair
(i.e. how much in quote currency is needed to buy one unit of
the base currency).

For instance, the Dict

    exchmkt = ExchangeMarket(("EUR", "USD") => 1.164151)

is means that, in this exchange market, one can buy 1 EUR 
with 1.164151 USD.
"""
ExchangeMarket = Dict{Tuple{String,String},Real}

"""
    @currency code_symb name

Create a dimension and a reference unit for a currency.

The macros `@dimension` and `@refunit` are called with arguments derived
from `code_symb` and `name`.
"""
macro currency(code_symb, name)
    code_abbr = string(code_symb)
    if all(c -> 'A' <= c <= 'Z', code_abbr)
        gap = Int('𝐀') - Int('A')
        code_abbr_bold = join([Char(Int(c) + gap) for c in code_abbr])
        dimension = Symbol(code_abbr_bold)
        dim_abbr = string(code_symb) * "CURRENCY"
        dim_name = Symbol(code_abbr_bold * "𝐂𝐔𝐑𝐑𝐄𝐍𝐂𝐘")
        esc(quote
            Unitful.@dimension($dimension, $dim_abbr, $dim_name)
            Unitful.@refunit($code_symb, $code_abbr, $name, $dimension, true)
        end)
    else
        throw(ArgumentError("The code symbol `$code_symb` should be all in uppercase."))
    end
end

include("pkgdefaults.jl")

"""
    uconvert(u::Units, x::Quantity, e::ExchangeMarket; mode::Int=1)

Convert between currencies, allowing for inverse and secondary rates.

If mode=1, which is the default, a direct conversion is attempted, i.e. 
if the given exchange market includes the conversion rate from `unit(x)`
to `u`, then the conversion takes place with this rate.

If mode=-1 and the given exchange market includes the exchange rate from
`u` to `unit(x)`, then the conversion of `x` to `u` is achieved with the rate
which is the multiplicative inverse of the exchange rate from `u` to `unit(x)`.

If mode=2, and the given exchange market includes the exchange rate from
`unit(x)` to an intermediate currency `v` and from  `v` to `u`, then 
the exchange takes place with the product of these two exchange rates.
If there is more than one intermediate currency available, then the first
one encountered in a nested loop in which the second pair is in the
inner loop is the one chosen.

If mode=-2, a combination of `-1` and `2` is used, i.e. an intermediate
currency is used for the inverse exchange rate from `u` to `unit(x)`.

An `ArgumentError` is thrown if mode is none of the above or if `u` or `x`
are not currencies, or if the necessary exchange rates cannot be accomplished
with the given exchange market.

# Examples

Assuming `forex_exchmkt["2020-11-01"]` ExchangeMarket contains the key-value
pair `("EUR","BRL") => 6.685598`, then the following exchange takes place:

```jldoctest
julia> uconvert(u"BRL", 1u"EUR", forex_exchmkt["2020-11-01"])
6.685598 BRL
julia> uconvert(u"BRL", 1u"BRL", forex_exchmkt["2020-11-01"], mode=-1)
0.149575251159283 EUR
```
"""
function uconvert(u::Unitful.Units, x::Unitful.Quantity, e::ExchangeMarket; mode::Int=1)
    u_curr_str = string(Unitful.dimension(u))
    x_curr_str = string(Unitful.dimension(x))
    if length(u_curr_str) >= 3 && length(x_curr_str) >= 3 && all(c -> 'A' <= c <= 'Z', u_curr_str) && all(c -> 'A' <= c <= 'Z', x_curr_str)
        u_curr = u_curr_str[1:3]
        x_curr = x_curr_str[1:3]
        pair = (x_curr, u_curr)
        pairinv = (u_curr, x_curr)
        if mode == 1 && pair in keys(e)
            rate = Main.eval(Meta.parse(string(e[pair]) * "u\"" * u_curr * "/" * x_curr * "\""))
            return Unitful.uconvert(u, rate * x)
        elseif mode == -1 && pairinv in keys(e)
            rate = Main.eval(Meta.parse(string(1/e[pairinv]) * "u\"" * u_curr * "/" * x_curr * "\""))
            return Unitful.uconvert(u, rate * x)
        elseif mode == 2
            for (pair1, rate1) in e
                for (pair2, rate2) in e
                    if pair1[1] == x_curr && pair2[2] == u_curr && pair1[2] == pair2[1]
                        rate = Main.eval(Meta.parse(string(rate1 * rate2) * "u\"" * u_curr * "/" * x_curr * "\""))
                        return Unitful.uconvert(u, rate * x)
                    end
                end
            end
        elseif mode == -2
            for (pair1, rate1) in e
                for (pair2, rate2) in e
                    if pair1[1] == u_curr && pair2[2] == x_curr && pair1[2] == pair2[1]
                        rate = Main.eval(Meta.parse(string(1 / (rate1 * rate2) ) * "u\"" * u_curr * "/" * x_curr * "\""))
                        return Unitful.uconvert(u, rate * x)
                    end
                end
            end
        end
        throw(ArgumentError(
            "No such exchange rate available in the given exchange" *
            "market for the conversion from $(Unitful.unit(x)) to $u."
            )
        )
    else
        throw(ArgumentError("$u and $x must be currencies"))
    end
end

include("exchmkt_tools.jl")

# Register the above units and dimensions in Unitful
const localpromotion = Unitful.promotion # only needed with new dimensions
function __init__()
    Unitful.register(UnitfulCurrencies) # needed for new Units
    merge!(Unitful.promotion, localpromotion) # only needed with new dimensions
end

end # module
