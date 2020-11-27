# UnitfulCurrencies

A supplemental units package for [Unitful.jl](https://github.com/PainterQubits/Unitful.jl) adding units for all currently active currencies in the world, along with tools to perform conversions based on exchange market rates.

**This package is not registered and is current under development.**

## Summary

Currency dimensions are created for each currency, along with its reference
unit. Being an extension of [Unitful.jl](https://github.com/PainterQubits/Unitful.jl), currency units play nicely along with Unitful's quantities.

An `ExchangeMarket` type is also defined as an alias for
`Dict{Tuple{String,String},Real}`, in which the tuple key contains the
quote-ask currency pair (e.g. `("EUR", "USD")`) and the value is the
exchange rate for the pair.

Based on an given exchange market instance of `ExchangeMarket`, a conversion
can be made from the "quote" currency to the "base" currency. This conversion
is implemented as an extended dispatch for `Unitful.uconvert`.

## Examples

Let us see some examples using `UnitfulCurrencies.jl`.

### Cost of a product

As an example, let us say we have a product P that depends on two other products, P₁ and P₂, whose costs C₁ and C₂ are given as

```julia
julia> using Unitful

julia> using UnitfulCurrecies

julia> C₁ = 0.45u"USD/lb"
0.45 USD lb⁻¹

julia> C₂ = 0.78u"USD/lb"
0.78 USD lb⁻¹
```

Suppose we need one pound of P₁ and a half pound of P₂ to produce one unit of P. Thus, the cost of producing 100 pieces of product P is

```julia
julia> 100 * 1.0u"lb" * C₁ + 0.5u"lb" * C₂
45.39 USD
```

### Continuously varying interest rate

### Exchange markets

For exchanging money, consider, for example, the following exchange market:

```julia
julia> using Unitful

julia> using UnitfulCurrencies

julia> exch_mkt = ExchangeMarket(
           ("EUR","USD") => 1.19172, ("USD","EUR") => 0.839125,
           ("USD","CAD") => 1.30015, ("CAD","USD") => 0.769144,
           ("USD","BRL") => 5.41576, ("BRL","USD") => 5.41239
       )
Dict{Tuple{String,String},Real} with 6 entries:
  ("USD", "BRL") => 5.41576
  ("BRL", "USD") => 5.41239
  ("EUR", "USD") => 1.19172
  ("USD", "EUR") => 0.839125
  ("CAD", "USD") => 0.769144
  ("USD", "CAD") => 1.30015
```

Then, the conversions between these currencies can be done as follows:

```julia
julia> uconvert(u"BRL", 100u"USD", test_mkt)
541.576 BRL
```

## License

This package is licensed under the [MIT license](https://opensource.org/licenses/MIT) (see file [LICENSE](LICENSE) in the root directory of the project).
