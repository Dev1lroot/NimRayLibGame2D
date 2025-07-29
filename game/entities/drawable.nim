import ../libs/position3d, ../libs/textures

type
    Drawable* = ref object of RootObj
        position*: Position3D
        w*: int32 = 32
        h*: int32 = 32

method render*(self: Drawable, textures: seq[TextureRef]) {.base,gcsafe.} =
    echo "The object's render not implemented"
