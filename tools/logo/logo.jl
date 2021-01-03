using Luxor

width = 400

for s = [2; 1; 0.5; 0.2; 0.1]
    Drawing(Int(s*width), Int(s*width), joinpath(@__DIR__, "logo_"*string(Int(s*width))*"x"*string(Int(s*width))*".png"))
    origin()
    scale(s)
    include(joinpath(@__DIR__, "logo_structure.jl"))
    finish()
end
