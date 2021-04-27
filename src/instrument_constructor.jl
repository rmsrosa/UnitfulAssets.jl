
# Currency constructors

"""
    is_instrument_code(code_string::String)::Bool

Return whether or not `code_string` refers to a valid instrument code.

Valid instrument codes must be all uppercase ascii characters
and at least three characters long

# Examples

```jldoctest
julia> is_instrument_code("BRL")
true

julia> is_instrument_code("euro")
false

julia> is_instrument_code("GOLD")
```
"""
function is_instrument_code(code_string::AbstractString)
    return match(r"^(?:[A-Z]{3,})$", code_string) !== nothing
end

"""
    @instrument instrument_type code_symb name

Create a dimension and a reference unit for an instrument.

The macros `@dimension` and `@refunit` are called with arguments derived
from `instrument_type`, `code_symb` and `name`.

# Examples

```jldoctest
julia> @instrument Currency USD "USD"
USD

julia> @instrument Metal GOLD "GOLD"
GOLD

julia> @instrument Stock DIS "DIS"
DIS
```
"""
macro instrument(instrument_type, code_symb, name)
    instrument_str = titlecase(string(instrument_type), strict=true)
    code_abbr = string(code_symb)
    if is_instrument_code(code_abbr)
        gap = Int('𝐀') - Int('A')
        code_abbr_bold = join([Char(Int(c) + gap) for c in code_abbr])
        dimension = Symbol(code_abbr_bold)
        dim_abbr = instrument_str * "{" * code_abbr * "}"
        dim_name = Symbol(dim_abbr)
        esc(quote
            Unitful.@dimension($dimension, $dim_abbr, $dim_name)
            Unitful.@refunit($code_symb, $code_abbr, $name, $dimension, true)
        end)
    else
        :(throw(ArgumentError("The given code symb is not allowed, it should be all in uppercase.")))
    end
end
