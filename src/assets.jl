
# Asset constructors

"""
    @asset asset_type code_symb name

Create a dimension and a reference unit for an asset.

The macros `@dimension` and `@refunit` are called with arguments derived
from `asset_type`, `code_symb` and `name`.

# Examples

```jldoctest
julia> @asset Cash USD "USD"
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
      
    code_abbr_bold = boldify(code_abbr)
    dimension = Symbol(code_abbr_bold)
    dim_abbr = asset_str * "{" * code_abbr_bold * "}"
    dim_name = Symbol(dim_abbr)

    esc(quote
        Unitful.@dimension($dimension, $dim_abbr, $dim_name)
        Unitful.@refunit($code_symb, $code_abbr, $name, $dimension, true)
    end)
end
