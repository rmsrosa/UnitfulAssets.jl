
# ExchangeMarket constructors

"""
    CurrencyPair

Type for currency pairs.

Currency pairs are made of two String fields, a `base_curr` with the alphabetic
code ISO-4217 corresponding to the base currency and `quote_curr` with the
alphabetic ISO-4217 code corresponding to the quote currency.

The alphabetic codes are made of three-character long uppercase ascii letters,
so the structure's constructor checks whether this requirement is met,
otherwise an ArgumentError is thrown.

# Examples

```jldoctest
julia> CurrencyPair("EUR", "BRL")
CurrencyPair("EUR", "BRL")

julia> CurrencyPair("euro", "BRL")
ERROR: ArgumentError: The given code symbol pair ("euro", "BRL") is not allowed, both should be all in ascii uppercase letters and at least three-character long.
Stacktrace:
  ...
```
"""
struct CurrencyPair
    base_curr::String
    quote_curr::String
    CurrencyPair(base_curr, quote_curr) = is_asset_code(base_curr) && 
        is_asset_code(quote_curr) ? new(base_curr,quote_curr) : 
            throw(ArgumentError("The given code symbol pair "
                * "$((base_curr, quote_curr)) is not allowed, both should "
                * "be all in ascii uppercase letters and at least "
                * "three-character long."))
end

"""
    ExchangeRate

Type for exchange rates.

An exchange rate is simply a positive Number.

The structure's constructor checks whether this requirement is met,
otherwise an ArgumentError is thrown.

# Examples

```jldoctest
julia> ExchangeRate(1.2)
ExchangeRate(1.2)

julia> ExchangeRate(-2)
ERROR: ArgumentError: The exchange rate must be a positive number
Stacktrace:
  ...
```
"""
struct ExchangeRate
    value::Number
    ExchangeRate(r) = r > 0*Unitful.unit(r) ? new(r) :
        throw(ArgumentError("The exchange rate must be positive"))
end

"""
    ExchangeMarket

Type used for a dictionary of exchange rates pair quotes.
    
It is given as a Dict{CurrencyPair,ExchangeRate}, where the keys are
currency pairs with the base and quote currencies and the value
is the exchange rate for this pair (i..e. how much in quote currency
is needed to buy one unit of the base currency).

For instance, the exchange market

    exchmkt = ExchangeMarket(CurrencyPair("EUR", "USD") => ExchangeRate(1.164151))

contains the pair `CurrencyPair("EUR", "USD")` and the exchange rate
`ExchangeRate(1.164151)`, which means that one can buy 1 EUR with 1.164151 USD.
"""
ExchangeMarket = Dict{CurrencyPair, ExchangeRate}

"""
    get_rate(u::String, v::String, rate_value::Number)

Return the exchange rate as a Unitful.Quantity in proper currency units.
"""
function get_rate(u::String, v::String, rate_value::Number)
    return Main.eval(Meta.parse("(" * string(rate_value) * ")u\"" * u * "/" * v * "\""))
end

"""
    exist_currency(code_abbr::String)

Check whether `code_abbr` refers to a registered currency unit.
"""
function exist_currency(code_abbr)
    has_unit = m->(isdefined(m,Symbol(code_abbr)))
    return length(findall(has_unit, Unitful.unitmodules)) > 0
end

"""
    generate_exchmkt(d::Dict{Tuple{String,String},T}) where {T<:Number}

Generates an instance of an ExchangeMarket from a dictionary of base-quote-value rates.

# Examples

```jldoctest
julia> generate_exchmkt(Dict(("EUR", "USD") => 1.164151))
Dict{CurrencyPair,Float64} with 1 entry:
  CurrencyPair("EUR", "USD") => ExchangeRate(1.16415)
```
"""
function generate_exchmkt(d::Dict{Tuple{String,String},T}) where {T<:Number}
    valid_d = Dict(key => value for (key, value) in d if exist_currency(key[1]) && exist_currency(key[2]))
    return Dict([CurrencyPair(key[1], key[2]) => ExchangeRate(get_rate(key[2], key[1], value)) for (key,value) in valid_d])
end

"""
    generate_exchmkt(a::Array{Pair{Tuple{String,String},Float64},1})

Generates an instance of ExchangeMarket from an array of base-quote-value rates.

# Examples

```jldoctest
julia> generate_exchmkt([("EUR","USD") => 1.19536, ("USD","EUR") => 0.836570])
Dict{CurrencyPair,Float64} with 2 entries:
  CurrencyPair("EUR", "USD") => ExchangeRate(1.19536)
  CurrencyPair("USD", "EUR") => ExchangeRate(0.83657)
```
"""
function generate_exchmkt(a::Array{Pair{Tuple{String,String},T},1}) where {T<:Number}
    return generate_exchmkt(Dict(a))
end

"""
    generate_exchmkt(a::Array{Pair{Tuple{String,String},Float64},1})

Generates an instance of ExchangeMarket from a single of base-quote-value rate.

# Examples

```jldoctest
julia> generate_exchmkt(("EUR", "USD") => 1.164151)
Dict{CurrencyPair,Float64} with 1 entry:
  CurrencyPair("EUR", "USD") => ExchangeRate(1.16415)
```
"""
function generate_exchmkt(p::Pair{Tuple{String,String},T}) where {T<:Number}
    return generate_exchmkt([p])
end

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
    u_match = match(r"Currency\{([A-Z]{3})\}", string(Unitful.dimension(u)))
    x_match = match(r"Currency\{([A-Z]{3})\}", string(Unitful.dimension(x)))

    if (u_match !== nothing) && (x_match !== nothing)
        u_curr = u_match.captures[1]
        x_curr = x_match.captures[1]
        pair = CurrencyPair(x_curr, u_curr)
        pairinv = CurrencyPair(u_curr, x_curr)
        if mode == 1 && pair in keys(e)
            return Unitful.uconvert(u, e[pair].value * x)
        elseif mode == -1 && pairinv in keys(e)
            return Unitful.uconvert(u, x / e[pairinv].value)
        elseif mode == 2
            for (pair1, rate1) in e
                for (pair2, rate2) in e
                    if pair1.base_curr == x_curr && pair2.quote_curr == u_curr && pair1.quote_curr == pair2.base_curr
                        return Unitful.uconvert(u, rate1.value * rate2.value * x)
                    end
                end
            end
        elseif mode == -2
            for (pair1, rate1) in e
                for (pair2, rate2) in e
                    if pair1.base_curr == u_curr && pair2.quote_curr == x_curr && pair1.quote_curr == pair2.base_curr
                        return Unitful.uconvert(u, x / (rate1.value * rate2.value))
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
