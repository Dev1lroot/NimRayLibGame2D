
import raylib, rlgl, raymath, rmem, reasings, rcamera, tables, ../libs/position2d, tile, ../libs/textures, json, ../libs/uuid

type
    Player* = object
        position*: Position2D
        direction*: string
        speed*: int32
        w*: int32
        h*: int32
        offsetX*: int32
        offsetY*: int32
        uuid*: string

proc createPlayer*(): Player =
    var player = Player()
    player.w = 32
    player.h = 32
    player.direction = "down"
    player.speed = 4;
    player.uuid = uuid.generateV4()
    return player

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

proc moveUp*(player: var Player, tiles: seq[Tile]) =
    player.direction = "up"
    if not player.directionBlocked(player.direction, tiles):
        player.position.y -= player.speed
        
proc moveDown*(player: var Player, tiles: seq[Tile]) =
    player.direction = "down"
    if not player.directionBlocked(player.direction, tiles):
        player.position.y += player.speed

proc moveLeft*(player: var Player, tiles: seq[Tile]) =
    player.direction = "left"
    if not player.directionBlocked(player.direction, tiles):
        player.position.x -= player.speed

proc moveRight*(player: var Player, tiles: seq[Tile]) =
    player.direction = "right"
    if not player.directionBlocked(player.direction, tiles):
        player.position.x += player.speed

proc render*(player: Player, textures: seq[TextureRef]) =
    textures.drawTextureByName("player_" & player.direction, player.position.x, player.position.y, White)

proc transfer*(player: Player): JsonNode =
    # echo "[Player] Preparing data to transfer"
    return %*{
        "packet": "player_move",
        "player": {
            "uuid": player.uuid,
            "position": {
                "x": player.position.x, 
                "y": player.position.y, 
            },
            "direction": player.direction
        }
    }