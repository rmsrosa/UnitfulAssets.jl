using Unitful
using UnitfulCurrencies
using Test

@testset "Currencies" begin
    # read exchange market from a fixer.io file
    fixer_exchmkt = Dict(
        "2020-11-01" => UnitfulCurrencies.get_fixer_exchmkt(
            "test/exchange_markets/2020-11-01_fixer.json"
        )
    )
    # rates obtained on Nov 25, 2020, for testing purposes
    test_mkt = Dict{String,Real}(
        "EURUSD" => 1.19172, "USDEUR" => 0.839125,
        "USDCAD" => 1.30015, "CADUSD" => 0.769144,
        "USDBRL" => 5.41576, "BRLUSD" => 5.41239
        )

    # conversions
#    @test uconvert(u"€", 1u"EUR") == 1u"€"
    @test uconvert(u"BRL", 1u"EUR", fixer_exchmkt["2020-11-01"]) == 6.685598u"BRL"
    @test uconvert(u"kBRL", 2u"MEUR", fixer_exchmkt["2020-11-01"]) == 13371.196u"kBRL"
    @test uconvert(u"EUR", 1u"BRL", fixer_exchmkt["2020-11-01"], extended=true) == 0.149575251159283u"EUR"
    @test uconvert(u"USD", 1u"EUR", test_mkt) == 1.19172u"USD"
    @test uconvert(u"EUR", 1u"USD", test_mkt) == 0.839125u"EUR"
    @test uconvert(u"EUR", 1u"CAD", test_mkt, extended=true) == 0.645407959u"EUR"
    @test uconvert(u"CAD", 1u"EUR", test_mkt, extended=true) == 1.5494147579999997u"CAD"
    @test uconvert(u"BRL", 1000u"CAD", test_mkt, extended=true) ≈ 4165.50u"BRL" (atol=0.001u"BRL")
    @test_throws ArgumentError uconvert(u"EUR", 1u"BRL", fixer_exchmkt["2020-11-01"], extended=false)
    @test_throws ArgumentError uconvert(u"EUR", 1u"CAD", fixer_exchmkt["2020-11-01"], extended=false)
end