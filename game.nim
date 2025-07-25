import raylib, rlgl, raymath, rmem, reasings, rcamera, tables, os, random, sequtils, std/algorithm
import game/player, game/textures, game/tile, game/position2d

const
  screenWidth = 800
  screenHeight = 600

proc main =
    initWindow(screenWidth, screenHeight, "Game2D")
    setTargetFPS(60)

    var textures: seq[TextureRef] # crutch

    textures.addTexture("tile", "assets/textures/tile.png")
    for anim in ["left", "right", "up", "down"]:
        textures.addTexture("player_" & anim, "assets/textures/player_" & anim & ".png")

    var player = createPlayer()
    var tiles: seq[Tile]

    for i in 0..100:
        tiles.add(
            Tile(
                name: "tile",
                position: Position2D(
                    x: int32(rand(20)*32),
                    y: int32(rand(20)*32)
                )
            )
        )

    while not windowShouldClose():
        if isKeyDown(W):
            player.moveUp()
        if isKeyDown(S):
            player.moveDown()
        if isKeyDown(A):
            player.moveLeft()
        if isKeyDown(D):
            player.moveRight()

        tiles.sort(proc(a, b: Tile): int {.closure.} =
            if a.position.y < b.position.y: -1
            elif a.position.y > b.position.y: 1
            else: 0
        )

        beginDrawing()
        clearBackground(RayWhite)

        # render tiles behind the player
        for tile in tiles:
            if player.position.y >= tile.position.y:
                textures.drawTextureByName(tile.name, tile.position.x, tile.position.y, White)

        # render the player itself
        textures.drawTextureByName("player_" & player.direction, player.position.x, player.position.y, White)

        # render tiles in front of the player
        for tile in tiles:
            if player.position.y < tile.position.y:
                textures.drawTextureByName(tile.name, tile.position.x, tile.position.y, White)

        endDrawing()
    closeWindow()
main()