using Unitful
using UnitfulCurrencies
using Test

@testset "Currencies" begin

    fixer_mkt = Dict(
        "2020-11-01" => UnitfulCurrencies.get_fixer_mkt(
            "test/exchange_rates/2020-11-01_fixer.json"
        )
    )
    # conversions
    @test uconvert(u"BRL", 1u"EUR", fixer_mkt["2020-11-01"]) == 6.685598u"BRL"
end