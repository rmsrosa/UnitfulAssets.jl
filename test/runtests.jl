using Unitful
using UnitfulCurrencies
using Test

@testset "Currencies" begin

    # conversions
    @test uconvert(u"BRA", 1u"USD") == 5u"BRA"
end