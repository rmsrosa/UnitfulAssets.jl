
# Currency constructors

"""
    is_currency_code(code_string::String)::Bool

Return whether or not `code_string` refers to a valid currency.

`code_string` is expected to be an alphabetic ISO-4217 currency code
(i.e. a three-letter uppercase ascii string corresponding to the
currency code symbol), like "EUR".

# Examples

```jldoctest
julia> is_currency_code("BRL")
true

julia> is_currency_code("euro")
false
```
"""
function is_currency_code(code_string::AbstractString)
    return match(r"^(?:[A-Z]{3})$", code_string) !== nothing
end

"""
    @currency code_symb name

Create a dimension and a reference unit for a currency.

The macros `@dimension` and `@refunit` are called with arguments derived
from `code_symb` and `name`.
"""
macro currency(code_symb, name)
    code_abbr = string(code_symb)
    if is_currency_code(code_abbr)
        gap = Int('𝐀') - Int('A')
        code_abbr_bold = join([Char(Int(c) + gap) for c in code_abbr])
        dimension = Symbol(code_abbr_bold)
        dim_abbr = "Currency{" * code_abbr * "}"
        dim_name = Symbol("Currency{" * code_abbr * "}")
        esc(quote
            Unitful.@dimension($dimension, $dim_abbr, $dim_name)
            Unitful.@refunit($code_symb, $code_abbr, $name, $dimension, true)
        end)
    else
        :(throw(ArgumentError("The given code symb is not allowed, it should be all in uppercase.")))
    end
end
