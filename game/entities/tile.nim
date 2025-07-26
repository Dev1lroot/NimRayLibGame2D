import raylib, rlgl, raymath, rmem, reasings, rcamera, tables, os, random, sequtils, std/algorithm
import player, ../libs/screen, ../libs/position2d, ../libs/textures

type
    Tile* = object
        name*: string
        position*: Position2D
        w*: int32
        h*: int32
        offsetX*: int32
        offsetY*: int32

proc createTile*(x, y: int32): Tile =
    var tile = Tile(
        name: "tile",
        position: Position2D(
            x: x, 
            y: y
        ), 
        w: 32,
        h: 32
    )
    return tile
proc render*(tile: Tile, textures: seq[TextureRef]) =
    textures.drawTextureByName(tile.name, tile.position.x, tile.position.y, White)
    drawRectangle(tile.position.x, tile.position.y, tile.w, tile.h, RED)