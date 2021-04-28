
# Asset constructors

"""
    is_asset_code(code_string::String)::Bool

Return whether or not `code_string` refers to a valid asset code.

Valid asset codes must be all uppercase and with at most one colon. 

# Examples

```jldoctest
julia> is_asset_code("BRL")
true

julia> is_asset_code("GOLD")
true

julia> is_asset_code("GOLD")
true

julia> is_asset_code("euro")
false
```
"""
function is_asset_code(code_string::AbstractString)
    return match(r"^(?:[A-Z]{1,})(?:\:[A-Z]{1,})?$", code_string) !== nothing
end

"""
    @asset asset_type code_symb name

Create a dimension and a reference unit for an asset.

The macros `@dimension` and `@refunit` are called with arguments derived
from `asset_type`, `code_symb` and `name`.

# Examples

```jldoctest
julia> @asset Currency USD "USD"
USD

julia> @asset Metal GOLD "GOLD"
GOLD

julia> @asset Stock DIS "DIS"
DIS
```
"""
macro asset(asset_type, code_symb, name)
    asset_str = titlecase(string(asset_type), strict=true)
    code_abbr = string(code_symb)
    if is_asset_code(code_abbr)
        gap = Int('𝐀') - Int('A')
        code_abbr_bold = join([Char(Int(c) + gap) for c in code_abbr])
        dimension = Symbol(code_abbr_bold)
        dim_abbr = asset_str * "{" * code_abbr * "}"
        dim_name = Symbol(dim_abbr)
        esc(quote
            Unitful.@dimension($dimension, $dim_abbr, $dim_name)
            Unitful.@refunit($code_symb, $code_abbr, $name, $dimension, true)
        end)
    else
        :(throw(ArgumentError("The given code symb is not allowed, it should be all in uppercase.")))
    end
end
