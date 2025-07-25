import raylib, rlgl, raymath, rmem, reasings, rcamera, tables, os
import game/player, game/textures

const
  screenWidth = 800
  screenHeight = 450

proc main =
    initWindow(screenWidth, screenHeight, "Game2D")
    setTargetFPS(60)

    var textures: seq[TextureRef]

    for anim in ["left", "right", "up", "down"]:
        textures.addTexture("player_" & anim, "player_" & anim & ".png")

    var player = createPlayer()

    while not windowShouldClose():
        if isKeyDown(W):
            player.moveUp()
        if isKeyDown(S):
            player.moveDown()
        if isKeyDown(A):
            player.moveLeft()
        if isKeyDown(D):
            player.moveRight()
        beginDrawing()
        clearBackground(RayWhite)
        textures.drawTextureByName("player_" & player.direction, player.position.x, player.position.y, White)
        endDrawing()
    closeWindow()
main()