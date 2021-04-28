using Unitful
using UnitfulCurrencies
using Test
using Decimals

using UnitfulCurrencies: @asset

module TestCurrency
    using Unitful
    using UnitfulCurrencies
    using UnitfulCurrencies: @asset

    @asset Currency TSP TestPataca
end

const localpromotion = Unitful.promotion # needed for the new currency dimension
Unitful.register(TestCurrency) # needed for new Units
merge!(Unitful.promotion, localpromotion) # only needed with new dimensions

module TestCurrencySymbol
    using Unitful
    using UnitfulCurrencies

    @unit ¥ "¥" YuanSign 1.0u"CNY" true
end

Unitful.register(TestCurrencySymbol) # needed for new Units


# create exchange market from a fixer.io json file
fixer_exchmkt = Dict(
    "2020-11-01" => UnitfulCurrencies.get_fixer_exchmkt(
        joinpath(@__DIR__, "exchange_markets", "2020-11-01_fixer.json")
    )
)
# create exchange market from a currencylayer json file
currencylayer_exchmkt = Dict(
    "2020-11-25" => UnitfulCurrencies.get_currencylayer_exchmkt(
        joinpath(@__DIR__, "exchange_markets", "2020-11-25_currencylayer.json")
    )
)
# rates on Nov 27, 2020
exch_mkt_27nov2020 = generate_exchmkt([
    ("EUR","USD") => 1.19536, ("USD","EUR") => 0.836570,
    ("EUR","GBP") => 1.11268, ("GBP","EUR") => 0.898734,
    ("USD","CAD") => 1.29849, ("CAD","USD") => 0.770125,
    ("USD","BRL") => 5.33897, ("BRL","USD") => 0.187302
])

# rates with rational numbers
exch_mkt_from_dict_and_rationals = generate_exchmkt(Dict([
    ("EUR","USD") => 119536//100000, ("USD","EUR") => 836570//1000000
]))

# rates with decimals
exch_mkt_from_dict_and_decimals = generate_exchmkt(Dict([
    ("EUR","USD") => Decimal(1.19536), ("USD","EUR") => Decimal(0.836570)
]))

test_exch_mkt = generate_exchmkt(("EUR","TSP") => 1234567.89)

# rates to test broadcasting
BRLGBP_timeseries = Dict(
    "2011-01-01" => generate_exchmkt(("BRL","GBP") => 0.38585),
    "2012-01-01" => generate_exchmkt(("BRL","GBP") => 0.34587),
    "2013-01-01" => generate_exchmkt(("BRL","GBP") => 0.29998),
    "2014-01-01" => generate_exchmkt(("BRL","GBP") => 0.25562),
    "2015-01-02" => generate_exchmkt(("BRL","GBP") => 0.24153),
    "2016-01-03" => generate_exchmkt(("BRL","GBP") => 0.17093),
    "2017-01-02" => generate_exchmkt(("BRL","GBP") => 0.24888),
    "2018-01-02" => generate_exchmkt(("BRL","GBP") => 0.22569),
    "2019-01-04" => generate_exchmkt(("BRL","GBP") => 0.21082),
    "2020-01-04" => generate_exchmkt(("BRL","GBP") => 0.18784)
)

@testset "Currencies" begin
    # conversions
    @test Unitful.Quantity(1,u"EUR") == 1u"EUR"
    @test Unitful.unit(1u"BRL") == u"BRL"
    @test Unitful.unit(1u"TSP") == u"TSP"
    @test UnitfulCurrencies.exist_currency("USD")
    @test UnitfulCurrencies.exist_currency("TSP")
    @test ! UnitfulCurrencies.exist_currency("ABC")
    @test typeof(UnitfulCurrencies.@asset Currency AAA TripleAs) <: Unitful.FreeUnits
    @test_throws ArgumentError UnitfulCurrencies.@asset Currency aaa tripleas
end

@testset "UnitSymbols" begin
    @test uconvert(u"€", 1u"EUR") == 1u"€"
    @test uconvert(u"USdollar", 1u"USD") == 1u"USdollar"
    @test uconvert(u"CAdollar", 1u"CAD") == 1u"CAdollar"
    @test uconvert(u"BRL", 1u"Real") == 1u"BRL"
    @test uconvert(u"£", 1u"GBP") == 1u"£"
    @test uconvert(u"¥", 1u"CNY") == 1u"¥"
end

@testset "Exchanges" begin
    @test uconvert(u"BRL", 1u"EUR", fixer_exchmkt["2020-11-01"]) == 6.685598u"BRL"
    @test uconvert(u"kBRL", 2u"MEUR", fixer_exchmkt["2020-11-01"]) == 13371.196u"kBRL"
    @test uconvert(u"EUR", 1u"BRL", fixer_exchmkt["2020-11-01"], mode=-1) == 0.149575251159283u"EUR"
    @test uconvert(u"CAD", 1u"USD", currencylayer_exchmkt["2020-11-25"]) == 1.30045u"CAD"
    @test uconvert(u"BRL", 2u"hUSD", currencylayer_exchmkt["2020-11-25"]) == 1064.8188u"BRL"
    @test uconvert(u"USD", 1u"EUR", exch_mkt_27nov2020) == 1.19536u"USD"
    @test uconvert(u"EUR", 1u"USD", exch_mkt_27nov2020, mode=-1) == 0.8365680631776201u"EUR"
    @test uconvert(u"CAD", 1u"EUR", exch_mkt_27nov2020, mode=2) == 1.5521630063999998u"CAD"
    @test uconvert(u"EUR", 1u"CAD", exch_mkt_27nov2020, mode=-2) == 0.6442622301116068u"EUR"
    @test uconvert(u"BRL", 1000u"CAD", exch_mkt_27nov2020, mode=2) == 4111.674271249999u"BRL"
    @test uconvert(u"BRL", 1000u"CAD", exch_mkt_27nov2020, mode=-2) == 4111.6768608248185u"BRL"
    @test uconvert.(u"BRL", 1000u"GBP", values(BRLGBP_timeseries), mode=-1) ≈ [2591.68, 2891.26, 4018.00, 4743.38, 5850.35, 3333.56, 4140.27, 3912.06, 4430.86, 5323.68]u"BRL" (atol=0.01u"BRL")
    @test uconvert(u"EUR", Decimal(1.5)u"USD", exch_mkt_from_dict_and_decimals) == Decimal(0, 1254855, -6) * u"EUR"
    @test uconvert(u"EUR", Decimal(1.5)u"USD", exch_mkt_from_dict_and_decimals, mode=-1) == Decimal(0, 125485209476643019676, -20)u"EUR"
    @test uconvert(u"EUR", (3//2)u"USD", exch_mkt_from_dict_and_rationals) == (250971//200000)u"EUR"
    @test uconvert(u"EUR", (3//2)u"USD", exch_mkt_from_dict_and_rationals, mode=-1) == (9375//7471)u"EUR"
    @test uconvert(u"TSP", 1u"EUR", test_exch_mkt) == 1234567.89u"TSP"
    @test_throws ArgumentError uconvert(u"EUR", 1u"BRL", fixer_exchmkt["2020-11-01"])
    @test_throws ArgumentError uconvert(u"CAD", 1u"BRL", fixer_exchmkt["2020-11-01"], mode=2)
    @test_throws ArgumentError uconvert(u"EUR", 1u"CAD", exch_mkt_27nov2020)
    @test_throws ArgumentError uconvert(u"m",1u"km", exch_mkt_27nov2020)
    @test_throws ArgumentError generate_exchmkt(("EUR","USD") => Decimal(-1.0))
end

nothing