
import raylib, rlgl, raymath, rmem, reasings, rcamera, tables, ../libs/position2d, tile, ../libs/textures, json, ../libs/uuid, drawable, ../libs/collision, ../libs/rectangle2points

type
    PlayerControls* = object
        key*: raylib.KeyboardKey
        action*: string

    Player* = ref object of Drawable
        direction*: string = "down"
        sprite*: string
        speed*: int32 = 4
        offsetX*: int32
        offsetY*: int32
        uuid*: string
        controls*: seq[PlayerControls]
        renderCollisionMask*:bool = false
        renderPosition*:bool = false

proc createPlayer*(): Player =
    var player = Player()
    player.uuid = uuid.generateV4()
    return player

method clone*(self: Player): Player =
    var player = createPlayer()
    player.position.x = self.position.x
    player.position.y = self.position.y
    return player

method move*(player: var Player, direction: string) =
    if direction == "up":
        player.position.y -= player.speed
    if direction == "down":
        player.position.y += player.speed
    if direction == "left":
        player.position.x -= player.speed
    if direction == "right":
        player.position.x += player.speed

method getBounds*(self: Player): Bounds =
    return Bounds(
        x1: self.position.x + self.offsetX + 8,
        y1: self.position.y + 48,
        x2: self.position.x + self.offsetX + self.w - 8,
        y2: self.position.y + 48 + 2
    )

method directionBlocked*(player: Player, direction: string, tiles: seq[Tile]): bool =
    var testPlayer = player.clone()

    testPlayer.move(direction)

    for tile in tiles:
        if testPlayer.getBounds().intersects(tile.getBounds()):
            return true

    return false

method bindControls*(player: var Player, newcontrols: seq[PlayerControls]) =
    player.controls = newcontrols

method handleControls*(player: var Player, tiles: seq[Tile]): bool =
    var controlsUsed = false
    for control in player.controls:
        if raylib.isKeyDown(control.key):
            if control.action in ["up","down","left","right"]:
                controlsUsed = true
                player.direction = control.action
                if not player.directionBlocked(player.direction, tiles):
                    player.move(player.direction)
            if control.action in ["debug"]:
                player.renderCollisionMask = not player.renderCollisionMask
                player.renderPosition = not player.renderPosition

    return controlsUsed

method render*(self: Player, textures: seq[TextureRef]) =
    textures.drawTextureByName("player_" & self.direction, self.position.x, self.position.y, White)

    if self.renderPosition:
        drawText("Player: " & $self.position , self.position.x, self.position.y - 20, 10, BLACK)

    if self.renderCollisionMask:
        let b = self.getBounds()
        drawRectangleByPoints(b.x1, b.y1, b.x2, b.y2, RED)

method transfer*(player: Player): JsonNode =
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
