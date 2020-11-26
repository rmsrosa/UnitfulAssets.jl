using Unitful
using UnitfulCurrencies
using Test

# create exchange market from a fixer.io file
fixer_exchmkt = Dict(
    "2020-11-01" => UnitfulCurrencies.get_fixer_exchmkt(
        "test/exchange_markets/2020-11-01_fixer.json"
    )
)
# create exchange market from a currencylayer file
currencylayer_exchmkt = Dict(
    "2020-11-25" => UnitfulCurrencies.get_currencylayer_exchmkt(
        "test/exchange_markets/2020-11-25_currencylayer.json"
    )
)
# rates on Nov 25, 2020, for testing purposes
test_mkt = ExchangeMarket(
    ("EUR","USD") => 1.19172, ("USD","EUR") => 0.839125,
    ("USD","CAD") => 1.30015, ("CAD","USD") => 0.769144,
    ("USD","BRL") => 5.41576, ("BRL","USD") => 5.41239
)

@testset "Currencies" begin
    # conversions
#    @test uconvert(u"€", 1u"EUR") == 1u"€"
    @test uconvert(u"BRL", 1u"EUR", fixer_exchmkt["2020-11-01"]) == 6.685598u"BRL"
    @test uconvert(u"kBRL", 2u"MEUR", fixer_exchmkt["2020-11-01"]) == 13371.196u"kBRL"
    @test uconvert(u"EUR", 1u"BRL", fixer_exchmkt["2020-11-01"], extended=true) == 0.149575251159283u"EUR"
    @test uconvert(u"CAD", 1u"USD", currencylayer_exchmkt["2020-11-25"]) == 1.30045u"CAD"
    @test uconvert(u"BRL", 2u"hUSD", currencylayer_exchmkt["2020-11-25"]) == 1064.8188u"BRL"   
    @test uconvert(u"USD", 1u"EUR", test_mkt) == 1.19172u"USD"
    @test uconvert(u"EUR", 1u"USD", test_mkt) == 0.839125u"EUR"
    @test uconvert(u"EUR", 1u"CAD", test_mkt, extended=true) == 0.645407959u"EUR"
    @test uconvert(u"CAD", 1u"EUR", test_mkt, extended=true) == 1.5494147579999997u"CAD"
    @test uconvert(u"BRL", 1000u"CAD", test_mkt, extended=true) ≈ 4165.50u"BRL" (atol=0.001u"BRL")
    @test_throws ArgumentError uconvert(u"EUR", 1u"BRL", fixer_exchmkt["2020-11-01"], extended=false)
    @test_throws ArgumentError uconvert(u"EUR", 1u"CAD", fixer_exchmkt["2020-11-01"], extended=false)
end