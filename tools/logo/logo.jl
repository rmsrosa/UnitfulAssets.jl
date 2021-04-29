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
        sethue("cornsilk") 
        squircle(Point(0,0), 280, 280, :fill, rt=2.2)
        sethue("gray10")
        setline(2)
        squircle(Point(0,0), 280, 280, :stroke, rt=2.2)
        rotate(-π/4)
    end

    @layer begin # Draw UnitfulAssets text
        sethue("gray10")
        fontface("Luminari") # "Luminari" "Trattatello" "Arial Rounded MT Bold" "Impact"
        fontsize(74)
        text("Unitful", O - (40, 100), halign=:center)
        text("Assets", O - (-50, 28), halign=:center)
    end

    @layer begin # Draw coins
        coin_width = 88
        coin_height = 36
        colors = ["royalblue", "mediumorchid3", "forestgreen", "brown3"]
        for h = -1:1
            for v = 0:3-2*h
                position = Point(110*h, 125-25*v)                
                for j=1:4
                    setcolor("gray40")
                    setdash("solid")
                    ellipse(position+(0,j), coin_width, coin_height, :stroke)
                    setcolor("gray10")
                    setdash("dotted")
                    ellipse(position+(0,j), coin_width, coin_height, :stroke)
                end
                setcolor("gray10")
                setdash("solid")
                ellipse(position+(0,5), coin_width, coin_height, :stroke)
                setcolor(colors[mod(v+h+1,4)+1])
                ellipse(position, coin_width, coin_height, :fill)
                setcolor("gray10")
                ellipse(position, coin_width, coin_height, :stroke)
            end
        end
    end

    finish()
end

for s = [1; 0.5; 0.18]
    Drawing(Int(s*width), Int(s*width), joinpath(@__DIR__, "logo_"*string(Int(s*width))*"x"*string(Int(s*width))*".png"))
    drawlogo(s)
end
