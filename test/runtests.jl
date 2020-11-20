using Unitful
using UnitfulCurrencies
using Test

@testset "Currencies" begin

    # conversions
    @test uconvert(u"BRL", 1u"USD") > 0u"BRL"
end