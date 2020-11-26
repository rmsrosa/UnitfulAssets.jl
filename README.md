# UnitfulCurrencies

A supplemental units package for [Unitful.jl](https://github.com/PainterQubits/Unitful.jl) adding units for all currently active currencies in the world, along with tools to perform conversions based on exchange market rates.

**This package is not registered and is current under development.**

Currency dimensions are created for each currency, along with its reference
unit.

An `ExchangeMarket` type is also defined as an alias for
`Dict{Tuple{String,String},Real}`, in which the tuple key contains the
quote-ask currency pair (e.g. `("EUR", "USD")`) and the value is the
exchange rate for the pair.

Based on an given exchange market instance of `ExchangeMarket`, a conversion
can be made from the "quote" currency to the "base" currency. This conversion
is implemented as an extended dispatch for `Unitful.uconvert`.

For example, consider the following exchange market:

```julia
julia> using Unitful
julia> using UnitfulCurrencies
julia> exch_mkt = ExchangeMarket(
           ("EUR","USD") => 1.19172, ("USD","EUR") => 0.839125,
           ("USD","CAD") => 1.30015, ("CAD","USD") => 0.769144,
           ("USD","BRL") => 5.41576, ("BRL","USD") => 5.41239
       )
```

Then, the conversions between these currencies can be done as follows:

```julia
julia> uconvert(u"BRL", 100u"USD", test_mkt)
541.576 BRL
```

## License

This package is licensed under the [MIT license](https://opensource.org/licenses/MIT) (see file [LICENSE](LICENSE) in the root directory of the project).
