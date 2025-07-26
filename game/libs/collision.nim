type
    Bounds* = object
        x1*: int32
        y1*: int32
        x2*: int32
        y2*: int32

method intersects*(a, b: Bounds): bool =
    return (a.x1 <= b.x2) and (a.x2 >= b.x1) and (a.y1 <= b.y2) and (a.y2 >= b.y1)