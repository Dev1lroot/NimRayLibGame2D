import raylib, rlgl, raymath, rmem, reasings, rcamera, tables, os, random, sequtils, std/algorithm
import player, ../libs/screen, ../libs/position2d, ../libs/textures, drawable, ../libs/collision, ../libs/rectangle2points

type
    Tile* = ref object of Drawable
        name*: string
        offsetX*: int32
        offsetY*: int32 = 32
        renderCollisionMask*:bool = false;

proc createTile*(x, y: int32): Tile =
    var tile = Tile()
    tile.name = "tile"
    tile.position.x = x
    tile.position.y = y
    return tile

method getBounds*(self: Tile): Bounds =
    return Bounds(
        x1: self.position.x + self.offsetX,
        y1: self.position.y + self.offsetY,
        x2: self.position.x + self.offsetX + self.w,
        y2: self.position.y + self.offsetY + self.h
    )

method render*(self: Tile, textures: seq[TextureRef]) =
    textures.drawTextureByName(self.name, self.position.x, self.position.y, White)
    
    if self.renderCollisionMask:
        let b = self.getBounds()
        drawRectangleByPoints(b.x1, b.y1, b.x2, b.y2, RED)