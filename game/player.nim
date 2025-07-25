
import raylib, rlgl, raymath, rmem, reasings, rcamera, tables, position2d, tile
import textures as bbbbbbbbb

type
    Player* = object
        position*: Position2D
        direction*: string
        speed*: int32
        w*: int32
        h*: int32
        offsetX*: int32
        offsetY*: int32

proc createPlayer*(): Player =
    var player = Player()
    player.w = 32
    player.h = 32
    player.direction = "down"
    player.speed = 4;
    return player

proc moveUp*(player: var Player) =
    player.position.y -= player.speed
    player.direction = "up"
proc moveDown*(player: var Player) =
    player.position.y += player.speed
    player.direction = "down"
proc moveLeft*(player: var Player) =
    player.position.x -= player.speed
    player.direction = "left"
proc moveRight*(player: var Player) =
    player.position.x += player.speed
    player.direction = "right"

proc isCollidesWith*(player: Player, tile: Tile): bool =
    let
        leftA = tile.position.x
        rightA = tile.position.x + tile.w
        topA = tile.position.y
        bottomA = tile.position.y + tile.h

        leftB = player.position.x
        rightB = player.position.x + player.w
        topB = player.position.y
        bottomB = player.position.y + player.h

    if rightA <= leftB or rightB <= leftA or bottomA <= topB or bottomB <= topA:
        return false
    else:
        return true

proc directionBlocked*(player: Player, dir: string, tiles: seq[Tile]): bool =
    var testPlayer = player

    case dir
    of "up":
        testPlayer.position.y -= testPlayer.speed
    of "down":
        testPlayer.position.y += testPlayer.speed
    of "left":
        testPlayer.position.x -= testPlayer.speed
    of "right":
        testPlayer.position.x += testPlayer.speed
    else:
        return false

    for tile in tiles:
        if testPlayer.isCollidesWith(tile):
            return true

    return false

proc render*(player: Player, textures: seq[TextureRef]) =
    textures.drawTextureByName("player_" & player.direction, player.position.x, player.position.y, White)