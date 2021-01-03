pt1 = Point(200, -200)
pt12 = Point(0, -160)
pt2 = Point(-200, -200)
pt23 = Point(-160, 0)
pt3 = Point(-200, 200)
pt34 = Point(0, 160)
pt4 = Point(200, 200)
pt41 = Point(160,0)

curve(pt1, pt12, pt2)
curve(pt2, pt23, pt3)
curve(pt3, pt34, pt4)
curve(pt4, pt41, pt1)
sethue("white")
fillpath()

curve(pt1, pt12, pt2)
curve(pt2, pt23, pt3)
curve(pt3, pt34, pt4)
curve(pt4, pt41, pt1)
sethue("black")
setline(1)
strokepath()

@layer begin
    sethue("black")
    fontface("Verdana-Bold") # "Georgia" or "Verdana"
    fontsize(50)
    text("Unitful", O - (80, 110), halign=:center)
    text("Currencies", O - (-20, 50), halign=:center)
    fontsize(30)
    coin_width = 80
    coin_height = 40
    colors = ["royalblue", "mediumorchid3", "forestgreen", "brown3"]
    for h = -1:1
        for v = 0:3-2*h
            position = Point(100*h, 125-25*v)
            setcolor(colors[mod(v+h+1,4)+1])
            ellipse(position, coin_width, coin_height, :fill)
        end
    end
end