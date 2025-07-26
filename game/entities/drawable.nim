import ../libs/position2d, ../libs/textures

type
    Drawable* = ref object of RootObj
        position*: Position2D
        w*: int32
        h*: int32

method render*(self: Drawable, textures: seq[TextureRef]) {.base,gcsafe.} =
    echo "The object's render not implemented"
