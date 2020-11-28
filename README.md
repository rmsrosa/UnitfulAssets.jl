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

### Cost of raw material for a T-shirt

As an example, consider a T-shirt with a Julia logo that requires as raw material 1.6 square-meters of 150GSM (grams-per-square-meter) cotton fabric at USD\$15 per 44 in x 8 yards bolt; two ounces in dyes at USD\$20 per pound; one ounce of dye fixer at US\$8 per five pounds; and 48 yards in stitching thread at USD\$19 per 1000 yards. Then, we may calculate the cost of the raw material as follows.

```julia
julia> using Unitful, UnitfulCurrecies

julia> fabric = 15u"USD"/8u"yd"/44u"inch"
0.04261363636363636 USD inch⁻¹ yd⁻¹

julia> 1.6u"m^2" * fabric
0.06818181818181818 m² USD inch⁻¹ yd⁻¹

julia> fabric = 15u"USD"/8u"yd"/44u"inch"
0.04261363636363636 USD inch⁻¹ yd⁻¹

julia> dyes = 20u"USD/lb"
20 USD lb⁻¹

julia> fixer = 8u"USD"/5u"lb"
1.6 USD lb⁻¹

julia> thread = 19u"USD"/1000u"yd"
0.019 USD yd⁻¹

julia> cost_per_t_shirt = 1.6u"m^2" * fabric + 2u"oz" * dyes + 1u"oz" * fixer + 48u"yd" * thread;

julia> println("\nThe cost of raw material per t-shirt is of $cost_per_t_shirt")

The cost of raw material per t-shirt is of 6.447611931829924 USD
```

### Production cost

### Continuously varying interest rate

Now, let us suppose we have a £1,000 in a savings account in a British bank, with an expected variable interest rate for the next ten years of the form

![formula](https://render.githubusercontent.com/render/math?math=\qquad\qquad\text{rate}(t)=\left(0.015%2B0.5\frac{(t/\text{yr})^2}{(1%2B(t/\text{yr})^3)}\right)/yr),

and suppose we want to estimate how much we will have after ten years. This can be implemented as follows.

```julia
julia> using Unitful, UnitfulCurrencies, DifferentialEquations

julia> rate(t) = (1.5 + 5(t * u"1/yr")^2 * ( 1 + (t * u"1/yr")^3)^-1)*u"percent/yr"
rate (generic function with 1 method)

julia> f(u,rate,t) = rate(t) * u
f (generic function with 1 method)

julia> tspan = Tuple([0.0,10.0]*u"yr")
(0.0 yr, 10.0 yr)

julia> u₀ = 1000.0u"GBP"
1000.0 GBP

julia> prob = ODEProblem(f,u₀,tspan,rate)
ODEProblem with uType Quantity{Float64,GBPCURRENCY,Unitful.FreeUnits{(GBP,),GBPCURRENCY,nothing}} and tType Quantity{Float64,𝐓,Unitful.FreeUnits{(yr,),𝐓,nothing}}. In-place: false
timespan: (0.0 yr, 10.0 yr)
u0: 1000.0 GBP

julia> savings = solve(prob);

julia> println("After $(savings.t[end]), we expect to have $(savings.u[end])")
After 10.0 yr, we expect to have 1303.6211777402004 GBP
```

Thus, we expect to have about £1,303.62 in our savings account, after ten years.

### Exchange markets

For exchanging money, consider, for example, the following exchange market:

```julia
julia> using Unitful

julia> using UnitfulCurrencies

julia> test_mkt = ExchangeMarket(
           ("EUR","USD") => 1.19536, ("USD","EUR") => 0.836570,
           ("EUR","GBP") => 1.11268, ("GBP","EUR") => 0.898734,
           ("USD","CAD") => 1.29849, ("CAD","USD") => 0.770125,
           ("USD","BRL") => 5.33897, ("BRL","USD") => 0.187302
       )
Dict{Tuple{String,String},Real} with 8 entries:
  ("USD", "BRL") => 5.33897
  ("BRL", "USD") => 0.187302
  ("EUR", "USD") => 1.19536
  ("GBP", "EUR") => 0.898734
  ("USD", "EUR") => 0.83657
  ("EUR", "GBP") => 1.11268
  ("CAD", "USD") => 0.770125
  ("USD", "CAD") => 1.29849
```

Then, the conversions between these currencies can be done as follows:

```julia
julia> uconvert(u"BRL", 100u"USD", test_mkt)
533.8969999999999 BRL
```

This means that I need about `533.90 BRL` to buy `100 USD`.

If I have dollars and I want to buy about `500 BRL`, we do it the other way around:

```julia
julia> uconvert(u"USD", 500u"BRL", test_mkt)
93.651 USD
```

Now, if, instead, I have `500 BRL` and I want to see how many dollars I can buy with it, I need the same exchange rate as in the first conversion, but in a inverse relation, which is accomplished with the option argument `mode=-1`, so that

```julia
julia> uconvert(u"USD", 500u"BRL", test_mkt, mode=-1)
93.65102257551551 USD
```

Another situation is when we don't have a currency pair in the given exchange market, such as `("EUR", "CAD")`, which is not in `test_mkt`. In this case we can use an intermediate currency, if available. In the example market, `USD` works. The exchange with an intermediate currency is achieved with `mode=2`:

```julia
julia> uconvert(u"CAD", 100u"EUR", test_mkt, mode=2)
155.21630064 CAD
```

Now, if we have `150 CAD` and want to see how many Euros we can buy with it, we use `mode=-2`:

```julia
julia> uconvert(u"EUR", 150u"CAD", test_mkt, mode=-2)
96.63933451674102 EUR
```

### Continuously varying interest rate in a foreign bank

Now, considering again the example above of continuously varying interest rate, suppose that I am actually in Brazil and I want to see the evolution of my savings in terms of Brazillian Reais (Disclaimer: I don't have such an account!). Suppose, also, that this happened ten years ago, so we can use some real exchange rates. In this case, I use an exchange rate time series, as follows.

```julia
julia> BRLGBP_timeseries = Dict(
           "2011-01-01" => ExchangeMarket(("BRL","GBP") => 0.38585),
           "2012-01-01" => ExchangeMarket(("BRL","GBP") => 0.34587),
           "2013-01-01" => ExchangeMarket(("BRL","GBP") => 0.29998),
           "2014-01-01" => ExchangeMarket(("BRL","GBP") => 0.25562),
           "2015-01-02" => ExchangeMarket(("BRL","GBP") => 0.24153),
           "2016-01-03" => ExchangeMarket(("BRL","GBP") => 0.17093),
           "2017-01-02" => ExchangeMarket(("BRL","GBP") => 0.24888),
           "2018-01-02" => ExchangeMarket(("BRL","GBP") => 0.22569),
           "2019-01-04" => ExchangeMarket(("BRL","GBP") => 0.21082),
           "2020-01-04" => ExchangeMarket(("BRL","GBP") => 0.18784)
       );

julia> uconvert.(u"BRL", 1000u"GBP", values(BRLGBP_timeseries), mode=-1)'
1×10 LinearAlgebra.Adjoint{Quantity{Float64,BRLCURRENCY,Unitful.FreeUnits{(BRL,),BRLCURRENCY,nothing}},Array{Quantity{Float64,BRLCURRENCY,Unitful.FreeUnits{(BRL,),BRLCURRENCY,nothing}},1}}:
 2591.68 BRL  2891.26 BRL  4018.0 BRL  4743.38 BRL  …  4140.27 BRL  3912.06 BRL  4430.86 BRL  5323.68 BRL
```

Notice the optional argument `mode=-1`, so it uses the inverse rate for the conversion. This is different than using the rate for the pair `("GBP", "BRL")` since we don't want to buy `GBP` with `BRL`, and neither do we want the direct rate for `("BRL", "GBP")` since we don't want to buy a specific amount of `BRL` with `GBP`. Instead, we want to find out how much `BRL` we can buy with a given amount of `GBP`, so we use the inverse of the rate `("BRL", "GBP")`.

## License

This package is licensed under the [MIT license](https://opensource.org/licenses/MIT) (see file [LICENSE](LICENSE) in the root directory of the project).
