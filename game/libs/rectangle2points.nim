import raylib, rlgl

proc drawRectangleByPoints*(x1, y1, x2, y2: int, color: Color) =
    let
        x = if x1 < x2: x1 else: x2
        y = if y1 < y2: y1 else: y2
        w = abs(x2 - x1)
        h = abs(y2 - y1)
    drawRectangle(int32(x), int32(y), int32(w), int32(h), color)