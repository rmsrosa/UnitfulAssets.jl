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

Thus, the cost of the raw material is about USD$ 6.48 per T-shirt.

### Production cost

Suppose, now, that we have a small business to manufacture the T-shirts above. Besides the raw material expenses, we need eletricity for the sewing machine and the workplace, workers, rent, insurance, and so on. With that in mind, we assume we have a fixed overhead cost of USD$ 24000 per year for rent and the essential utilities, insurance and things like that; eletricity expenses for the sewing machine at USD$ 0.13 per kilowatt-hour; and labor at USD$ 10.50 per worker per hour.

In order to implement that, we add two nondimensional units, namely `tshirt` and `worker`, then we define the price constants above and two functions that give us the total cost and total material used. We do this as follows.

```julia
julia> using Unitful, UnitfulCurrencies

julia> module ProductionUnits
           using Unitful
           using Unitful: @unit
           @unit tshirt "tshirt" TShirt 1 false
           @unit worker "worker" Worker 1 false
       end

julia> Unitful.register(ProductionUnits);

julia> fabric = 15u"USD"/8u"yd"/44u"inch"
0.04261363636363636 USD inch⁻¹ yd⁻¹

julia> dyes = 20u"USD/lb"
20 USD lb⁻¹

julia> fixer = 8u"USD"/5u"lb"
1.6 USD lb⁻¹

julia> thread = 19u"USD"/1000u"yd"
0.019 USD yd⁻¹

julia> """
           raw_material(n::Unitful.Quantity)

       Return the amount of each raw material needed to manufacture `n` T-shirts.

       The argument `n` must be given in `tshirt` units.

       Returns a tuple with the following quantities, respectively:

       * The necessary amount of cotton fabric.

       * The necessary amount of dye.

       * The necessary amount of fixer.

       * The necessary amount of thread.

       """
       raw_material(n::Unitful.Quantity) = (1.6u"m^2" * n / u"tshirt", 2u"oz" * n / u"tshirt", 1u"oz" * n / u"tshirt", 48u"yd" * n / u"tshirt")
raw_material

julia> eletricity_price = 0.13u"USD/kW/hr"
0.13 USD hr⁻¹ kW⁻¹

julia> labor_price = 10.50u"USD/worker/hr"
10.5 USD hr⁻¹ worker⁻¹

julia> fixed_cost = 24000u"USD/yr"
24000 USD yr⁻¹

julia> """
           manufacturing_cost(n::Unitful.Quantity, t::Unitful.Quantity, tlim::Unitful.Quantity=40u"hr/worker/wk")

       Return the cost of manufacturing `n` T-shirts during a time period `t`.

       The argument `n` must be given in `tshirt` units, and `t`, in time units.
       The optional argument `tlim` is the time limit of work per worker, which       defaults to `40u"hr/worker/wk"`.

       Return a tuple with the following quantities, respectively:

       * The cost of the production, in US Dollars.

       * The cost per T-shirt.

       * The number of labor hours required to produce `n` t-shirts.

       * The minimum number of workers considering the limit given by `tlim`.

       * The eletricity required for the whole manufacturing process.
       """
       function production_cost(n::Unitful.Quantity, t::Unitful.Quantity, tlim::Unitful.Quantity=40u"hr/worker/wk")
           labor_hours = 2u"hr/tshirt" * n
           eletricity_spent = 2u"kW * hr/tshirt" * n
           total_cost = n * raw_material_price + labor_hours * labor_price + eletricity_spent * eletricity_price + fixed_cost * t
           cost_per_tshirt = total_cost / n
           min_num_workers = Int(ceil(labor_hours/tlim/t)) * u"worker"
           return total_cost, cost_per_tshirt, labor_hours, min_num_workers, eletricity_spent
       end
production_cost
```

Now, if we want to see the cost and everything else needed to produce 50 T-shirts *per week*, we do

```julia
julia> production_cost(50u"tshirt", 1u"wk")
(1845.3395288296892 USD, 36.906790576593785 USD tshirt⁻¹, 100 hr, 3 worker, 100 hr kW)

julia> raw_material(50u"tshirt")
(80.0 m², 100 oz, 50 oz, 2400 yd)
```

So, it costs about USD$ 36.91 per T-shirt in this case.

If we want to reduce the cost per T-shirt, we increase production, aiming for 2000 T-shirts *per month*, with workers working 44 hours per week:

```julia
julia> production_cost(2000u"tshirt", 30u"d", 44u"hr/worker/wk")
(57386.47643039496 USD, 28.693238215197482 USD tshirt⁻¹, 4000 hr, 22 worker, 4000 hr kW)

julia> raw_material(2000u"tshirt")
(3200.0 m², 4000 oz, 2000 oz, 96000 yd)
```

With that, we are able to reduce the cost per T-shirt to about USD$ 28.69.

**Exercises:**

1. Add *benefit costs* for each worker, so that the number of workers properly affects the cost.

2. Add a linear *revenue* function proportional to the number of T-shirts sold, with proportionality constant being the selling price per T-shirt.

3. Add an affine *profit* function, which is the difference between the revenue function and the cost function.

4. Find the *break-even* point, which is the number of T-shirts where profit vanishes, i.e. neiher profit nor loss incurred.

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

**Exercise:** In the ***Production Cost*** problem, suppose the raw materials come from a foreign country (or countries) and add an exchange market for properly taking into account the dependency of the production cost, the profit, and the break even point on the foreing currencies.

## To do

I have been doing this mostly for learning purposes. Who knows it might even turn out to be a useful package for the community. In any case, if someone wants to contribute, there are still a number of things to be added and I will be happy to have help.

Here are a few things to be done.

1. Add Github Actions to integrate test.

1. Add Github Actions to check code coverage.

1. Add tools to read exchange market from web sources other than [fixer.io](https://fixer.io) and [currencylayer.com](https://currencylayer.com).

1. Add an option to directly obtain the exchange rates from the web sources using a given API.

1. Maybe join all tools to read the exchange market from web sources in a single function, with the market source given as an argument, instead of having one function for each.

1. Add further tests.

1. Add Documentation.

## Related packages

After I started writing this package, I found out about [bhgomes/UnitfulCurrency.jl](https://github.com/bhgomes/UnitfulCurrency.jl), which, however, has been archived for unknown reasons.

 UnifulCurrency has a single dimension for all currencies, which has the side-effect of being able to `uconvert` different quantities without an exchange market rate. Moreover, all currencies are reference units for the same dimension. I don't know what further side-effects come out of that.

 There is no documentation and the README is short. It seems, though, that the exchange markets are defined for each pair, which is different than our approach, in which an exchange market contains a dictionary of currency pairs, allowing for more flexibility, in my point of view.

 I also found out about [JuliaFinance/Currencies.jl](https://github.com/JuliaFinance/Currencies.jl). There are some nice concepts there, distinguishing currencies, from assets and cash. Take this excerpt for instance:

 > "When a currency is thought of as a financial instrument (as opposed to a mere label), we choose to refer to it as "Cash" as it would appear, for example, in a balance sheet. Assets.jl provides a Cash instrument together with a specialized Position type that allows for basic algebraic manipulations of Cash and other financial instrument positions".

However, this package is not based on `Unitful`.

## License

This package is licensed under the [MIT license](https://opensource.org/licenses/MIT) (see file [LICENSE](LICENSE) in the root directory of the project).
