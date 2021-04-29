
# ExchangeMarket constructor

"""
    AssetsPair

Type for asset pairs exchange/trade.

Asset pairs are made of two String fields, a `base_asset` and a `quote_asset`.


# Examples

```jldoctest
julia> AssetsPair("EUR", "BRL")
AssetsPair("EUR", "BRL")

julia> AssetsPair("euro", "BRL")
ERROR: ArgumentError: The given code symbol pair ("euro", "BRL") is not allowed, both should be all in ascii uppercase letters and at least three-character long.
Stacktrace:
  ...
```
"""
struct AssetsPair
    base_asset::String
    quote_asset::String
    AssetsPair(base_asset, quote_asset) = is_asset_code(base_asset) && 
        is_asset_code(quote_asset) ? new(base_asset,quote_asset) : 
            throw(ArgumentError("The given code symbol pair "
                * "$((base_asset, quote_asset)) is not allowed, both should "
                * "be all in ascii uppercase letters and at least "
                * "three-character long."))
end

"""
    Rate

Type for exchange/stock rates.

A rate is simply a positive Number.

The structure's constructor checks whether this requirement is met,
otherwise an ArgumentError is thrown.

# Examples

```jldoctest
julia> Rate(1.2)
Rate(1.2)

julia> Rate(-2)
ERROR: ArgumentError: The exchange rate must be a positive number
Stacktrace:
  ...
```
"""
struct Rate
    value::Number
    Rate(r) = r > Unitful.zero(r) ? new(r) :
        throw(ArgumentError("The rate must be positive"))
end

"""
    ExchangeMarket

Type used for a dictionary of `AssetsPair() => Rate()` pair quotes.
    
It is given as a Dict{AssetsPair, Rate}, where the keys are
the pairs with the base and quote assets and the value
is the exchange/trade rate for this pair (i..e. how much in quote units
is needed to buy/trande one unit of the base asset).

For instance, the market

    mkt = ExchangeMarket(AssetsPair("EUR", "USD") => Rate(1.164151))

contains the pair `AssetsPair("EUR", "USD")` and the exchange rate
`Rate(1.164151)`, which means that one can buy 1 EUR with 1.164151 USD.
"""
ExchangeMarket = Dict{AssetsPair, Rate}

"""
    get_rate(u::String, v::String, rate_value::Number)

Return the exchange rate as a Unitful.Quantity in proper currency units.
"""
function get_rate(u::String, v::String, rate_value::Number)
    return Main.eval(Meta.parse("(" * string(rate_value) * ")u\"" * u * "/" * v * "\""))
end

"""
    is_asset(code_abbr::String)

Check whether `code_abbr` refers to a registered asset.
"""
function is_asset(code_abbr)
    has_unit = m->(isdefined(m,Symbol(code_abbr)))
    return length(findall(has_unit, Unitful.unitmodules)) > 0
end

"""
    generate_exchmkt(d::Dict{Tuple{String,String},T}) where {T<:Number}

Generate an instance of `ExchangeMarket` from a dictionary of base-quote-value rates.

# Examples

```jldoctest
julia> generate_exchmkt(Dict(("EUR", "USD") => 1.164151))
Dict{AssetsPair,Float64} with 1 entry:
  AssetsPair("EUR", "USD") => Rate(1.16415)
```
"""
function generate_exchmkt(d::Dict{Tuple{String,String},T}) where {T<:Number}
    valid_d = Dict(key => value for (key, value) in d if is_asset(key[1]) && is_asset(key[2]))
    return Dict([AssetsPair(key[1], key[2]) => Rate(get_rate(key[2], key[1], value)) for (key,value) in valid_d])
end

"""
    generate_exchmkt(a::Array{Pair{Tuple{String,String},Float64},1})

Generate an instance of `ExchangeMarket` from an array of base-quote-value rates.

# Examples

```jldoctest
julia> generate_exchmkt([("EUR","USD") => 1.19536, ("USD","EUR") => 0.836570])
Dict{AssetsPair,Float64} with 2 entries:
  AssetsPair("EUR", "USD") => Rate(1.19536)
  AssetsPair("USD", "EUR") => Rate(0.83657)
```
"""
function generate_exchmkt(a::Array{Pair{Tuple{String,String},T},1}) where {T<:Number}
    return generate_exchmkt(Dict(a))
end

"""
    generate_exchmkt(a::Array{Pair{Tuple{String,String},Float64},1})

Generates an instance of `ExchangeMarket` from a single of base-quote-value rate.

# Examples

```jldoctest
julia> generate_exchmkt(("EUR", "USD") => 1.164151)
Dict{AssetsPair,Float64} with 1 entry:
  AssetsPair("EUR", "USD") => Rate(1.16415)
```
"""
function generate_exchmkt(p::Pair{Tuple{String,String},T}) where {T<:Number}
    return generate_exchmkt([p])
end

"""
    uconvert(u::Units, x::Quantity, e::ExchangeMarket; mode::Int=1)

Convert between assets, allowing for inverse and secondary rates.

If mode=1, which is the default, a direct conversion is attempted, i.e. 
if the given market includes the conversion rate from `unit(x)` to `u`,
then the conversion takes place with this rate.

If mode=-1 and the given market includes the rate from `u` to `unit(x)`,
then the conversion of `x` to `u` is achieved with the rate which is the 
multiplicative inverse of the exchange rate from `u` to `unit(x)`.

If mode=2, and the given market includes the rate from
`unit(x)` to an intermediate asset `v` and from  `v` to `u`, then 
the exchange/trade takes place with the product of these two rates.
If there is more than one intermediate rates available, then the first
one encountered in a nested loop in which the second pair is in the
inner loop is the one chosen.

If mode=-2, a combination of `-1` and `2` is used, i.e. an intermediate
asset is used for the inverse rate from `u` to `unit(x)`.

An `ArgumentError` is thrown if mode is none of the above or if `u` or `x`
are not assets, or if the necessary rates cannot be found.

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
    u_match = match(r"[a-zA-Z]+\{([A-Z]{3})\}", string(Unitful.dimension(u)))
    x_match = match(r"[a-zA-Z]+\{([A-Z]{3})\}", string(Unitful.dimension(x)))

    if (u_match !== nothing) && (x_match !== nothing)
        u_asset = u_match.captures[1]
        x_asset = x_match.captures[1]
        pair = AssetsPair(x_asset, u_asset)
        pairinv = AssetsPair(u_asset, x_asset)
        if mode == 1 && pair in keys(e)
            return Unitful.uconvert(u, e[pair].value * x)
        elseif mode == -1 && pairinv in keys(e)
            return Unitful.uconvert(u, x / e[pairinv].value)
        elseif mode == 2
            for (pair1, rate1) in e
                for (pair2, rate2) in e
                    if pair1.base_asset == x_asset && pair2.quote_asset == u_asset && pair1.quote_asset == pair2.base_asset
                        return Unitful.uconvert(u, rate1.value * rate2.value * x)
                    end
                end
            end
        elseif mode == -2
            for (pair1, rate1) in e
                for (pair2, rate2) in e
                    if pair1.base_asset == u_asset && pair2.quote_asset == x_asset && pair1.quote_asset == pair2.base_asset
                        return Unitful.uconvert(u, x / (rate1.value * rate2.value))
                    end
                end
            end
        end
        throw(ArgumentError(
            "No such rate available in the given market" *
            "for the conversion from $(Unitful.unit(x)) to $u."
            )
        )
    else
        throw(ArgumentError("$u and $x must be proper assets"))
    end
end
