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
    # conversions
#    @test uconvert(u"€", 1u"EUR") == 1u"€"
    @test uconvert(u"BRL", 1u"EUR", fixer_exchmkt["2020-11-01"]) == 6.685598u"BRL"
    @test uconvert(u"kBRL", 2u"MEUR", fixer_exchmkt["2020-11-01"]) == 13371.196u"kBRL"
end