import raylib, rlgl, raymath, rmem, reasings, rcamera, tables

type
    Position2D* = object
        x*, y*: int32 = 0
    Player* = object
        position*: Position2D
        direction*: string
        speed*: int32

proc createPlayer*(): Player =
    var player = Player()
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

proc render*(player: var Player, textures: var Table[string, Texture2D]) =

    var x = 0
    #drawTexture(textures["player_" & dir], player.position.x, player.position.y, White)
