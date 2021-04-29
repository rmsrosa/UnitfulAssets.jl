using Unitful, UnitfulAssets

module ProductionUnits
    using Unitful
    using Unitful: @unit
    @unit tshirt "tshirt" TShirt 1 false
    @unit worker "worker" Worker 1 false
end

Unitful.register(ProductionUnits);

fabric = 15u"USD"/8u"yd"/44u"inch"
dyes = 20u"USD/lb"
fixer = 8u"USD"/5u"lb"
thread = 19u"USD"/1000u"yd"

# raw_material_cost = 1.6u"m^2" * fabric + 2u"oz" * dyes + 1u"oz" * fixer + 48u"yd" * thread

raw_price_table = (fabric, dyes, fixer, thread)

"""
    raw_material(n::Unitful.Quantity)

Return the amount of each raw material needed to manufacture `n` T-shirts.

The argument `n` must be given in `tshirt` units.

Returns a tuple with the following quantities, respectively:
* The necessary amount of cotton fabric.
* The necessary amount of dye.
* The necessary amount of fixer.
* The necessary amount of thread.

"""
raw_material(n::Unitful.Quantity) = (1.6u"m^2" * n / u"tshirt", 2u"oz" * n / u"tshirt", 1u"oz" * n / u"tshirt", 48u"yd" * n / u"tshirt")

raw_material_price = sum(raw_material(1u"tshirt") .*  raw_price_table)

eletricity_price = 0.13u"USD/kW/hr"
labor_price = 10.50u"USD/worker/hr"
fixed_cost = 24000u"USD/yr"

"""
    manufacturing_cost(n::Unitful.Quantity, t::Unitful.Quantity, tlim::Unitful.Quantity=40u"hr/worker/wk")

Return the cost of manufacturing `n` T-shirts during a time period `t`.

The argument `n` must be given in `tshirt` units, and `t`, in time units.
The optional argument `tlim` is the time limit of work per worker, which
defaults to `40u"hr/worker/wk"`.

Return a tuple with the following quantities, respectively:
* The cost of the production, in US Dollars.
* The cost per T-shirt.
* The number of labor hours required to produce `n` t-shirts.
* The minimum number of workers considering the limit given by `tlim`.
* The eletricity required for the whole manufacturing process.
"""
function production_cost(n::Unitful.Quantity, t::Unitful.Quantity, tlim::Unitful.Quantity=40u"hr/worker/wk")
    labor_hours = 2u"hr/tshirt" * n
    eletricity_spent = 2u"kW * hr/tshirt" * n
    total_cost = n * raw_material_price + labor_hours * labor_price + eletricity_spent * eletricity_price + fixed_cost * t
    cost_per_tshirt = total_cost / n
    min_num_workers = Int(ceil(labor_hours/tlim/t)) * u"worker"
    return total_cost, cost_per_tshirt, labor_hours, min_num_workers, eletricity_spent
end

production_cost(50u"tshirt", 1u"wk")
raw_material(50u"tshirt")

production_cost(2000u"tshirt", 30u"d", 44u"hr/worker/wk")
raw_material(2000u"tshirt")
