using Luxor

width = 400

"""
    drawlogo(s)

Draw the UnitfulCurrencies logo with the given scale `s`.
"""
function drawlogo(s)

    origin()
    scale(s)

    @layer begin # Draw background
        rotate(π/4)
        sethue(0.77, 1, 0.77) # light kind of green
        squircle(Point(0,0), 280, 280, :fill, rt=2.2)
        sethue("black")
        setline(2)
        squircle(Point(0,0), 280, 280, :stroke, rt=2.2)
        rotate(-π/4)
    end

    @layer begin # Draw UnitfulCurrencies
        sethue("black")
        fontface("Verdana-Bold")
        fontsize(50)
        text("Unitful", O - (80, 110), halign=:center)
        text("Currencies", O - (-20, 50), halign=:center)
    end

    @layer begin # Draw coins
        coin_width = 88
        coin_height = 44
        colors = ["royalblue", "mediumorchid3", "forestgreen", "brown3"]
        for h = -1:1
            for v = 0:3-2*h
                position = Point(110*h, 125-25*v)
                setcolor(colors[mod(v+h+1,4)+1])
                ellipse(position, coin_width, coin_height, :fill)
            end
        end
    end

    finish()
end

for s = [1; 0.5; 0.18]
    Drawing(Int(s*width), Int(s*width), joinpath(@__DIR__, "logo_"*string(Int(s*width))*"x"*string(Int(s*width))*".png"))
    drawlogo(s)
end
