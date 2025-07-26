
import raylib, rlgl, raymath, rmem, reasings, rcamera, tables, ../libs/position2d, tile, ../libs/textures, json, ../libs/uuid, drawable

type
    PlayerControls* = object
        key*: raylib.KeyboardKey
        action*: string

    Player* = ref object of Drawable
        direction*: string
        sprite*: string
        speed*: int32
        offsetX*: int32
        offsetY*: int32
        uuid*: string
        controls*: seq[PlayerControls]

proc createPlayer*(): Player =
    var player = Player()
    player.w = 32
    player.h = 32
    player.direction = "up"
    player.speed = 4;
    player.uuid = uuid.generateV4()
    return player

proc move*(player: var Player, direction: string) =
    if direction == "up":
        player.position.y -= player.speed
    if direction == "down":
        player.position.y += player.speed
    if direction == "left":
        player.position.x -= player.speed
    if direction == "right":
        player.position.x += player.speed

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

    testPlayer.move(dir)

    for tile in tiles:
        if testPlayer.isCollidesWith(tile):
            return true

    return false

proc bindControls*(player: var Player, newcontrols: seq[PlayerControls]) =
    player.controls = newcontrols

proc handleControls*(player: var Player, tiles: seq[Tile]): bool =
    var controlsUsed = false
    for control in player.controls:
        if raylib.isKeyDown(control.key):
            if control.action in ["up","down","left","right"]:
                controlsUsed = true
                player.direction = control.action
                if not player.directionBlocked(player.direction, tiles):
                    player.move(player.direction)
    return controlsUsed

method render*(self: Player, textures: seq[TextureRef]) =
    textures.drawTextureByName("player_" & self.direction, self.position.x, self.position.y, White)

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

method followPlayer*(camera: var Camera2D, player: Player) =
    camera.target.x = float32(player.position.x)
    camera.target.y = float32(player.position.y)
