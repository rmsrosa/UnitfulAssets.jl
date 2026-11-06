# UnitfulAssets.jl release notes

## v0.4.0

### Breaking changes

- **Minimum Julia version is now 1.10** (previously 1.2).
- **`JSON` compatibility is now `1`** (previously `0.21`). Environments that
  pin `JSON` 0.21 through another package will no longer resolve together with
  this version.
- **Rates keep their number type.** `generate_exchmkt` now preserves the type of
  the rate values you provide. Previously, `Decimal` rates were silently converted
  to `Float64`; they now remain `Decimal` (`Rational` and `FixedDecimal` rates
  are unaffected). Code that relied on the old `Float64` result may see
  different values or types.

  Because of a method ambiguity between Unitful.jl and Decimals.jl, using
  `Decimal` values with units requires defining the following once:

  ```julia
  Unitful.Quantity{T,D,U}(x::Decimal) where {T,D,U} =
      invoke(Unitful.Quantity{T,D,U}, Tuple{Number}, x)
  ```

  See the README section "Decimal, fixed decimals and rational rates".

### Fixes

- Fixed `generate_exchmkt` failing with `Symbol ... was found in the globally
  registered unit module UnitfulAssets but was not in the provided list of unit
  modules` on recent Unitful versions. Exchange rates are now built by looking
  units up in all registered unit modules instead of evaluating `u"..."`
  expressions in `Main`, so the result no longer depends on what is loaded in
  the caller's `Main` module.
- Tests run again on current Julia versions.
- Updated the JSON-file parsers (fixer.io and currencylayer) for JSON.jl v1.
- Fixed typos in docstrings.

### Documentation

- Rewrote the README section on `Decimal`, `FixedDecimal` and `Rational`
  rates, including a warning to construct `Decimal` values from strings
  (`parse(Decimal, "1.19536")`) and not from floating-point literals, and a note
  on `FixedDecimal` rounding.

### Maintenance

- Updated CI (including the LTS Julia test version).

## v0.3.0 and earlier

See the [GitHub releases](https://github.com/rmsrosa/UnitfulAssets.jl/releases).