__precompile__(true)
"""
    UnitfulCurrencies

Module extending Unitful.jl with currencies.
"""
module UnitfulCurrencies

using Unitful

"""
    ExchangeRate

Abstract supertype for all exchange rate types.
"""
abstract type ExchangeRate end

Base.broadcastable(x::ExchangeRate) = Ref(x)


# Define currencies

@dimension 𝐂    "C"         Currency

@refunit USD    "USD\$"     USDollar            𝐂           false
@unit BRA       "BR\$"      BrazilianReais      USD/5       false


# Register the above units and dimensions in Unitful
__init__() = Unitful.register(UnitfulCurrencies)

end # module
