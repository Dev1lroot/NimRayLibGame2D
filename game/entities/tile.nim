import raylib, rlgl, raymath, rmem, reasings, rcamera, tables, os, random, sequtils, std/algorithm
import player, ../libs/screen, ../libs/position2d, ../libs/textures, drawable

type
    Tile* = ref object of Drawable
        name*: string
        offsetX*: int32
        offsetY*: int32

proc createTile*(x, y: int32): Tile =
    var tile = Tile()
    tile.name = "tile"
    tile.position.x = x
    tile.position.y = y
    tile.w = 32
    tile.h = 32
    return tile
method render*(self: Tile, textures: seq[TextureRef]) =
    textures.drawTextureByName(self.name, self.position.x, self.position.y, White)
    drawRectangle(self.position.x, self.position.y, self.w, self.h, RED)