import raylib, rlgl, raymath, rmem, reasings, rcamera, tables, os, random, sequtils, std/algorithm, websocket, asyncdispatch, locks, strutils, threadpool, json, parseutils, ws
import player, textures, tile, position2d, screen, networking, channelutils, threadsio

proc gameRenderCycle*(io: ThreadsIO) {.thread, gcsafe.} =
    
    var screen = Screen(w: 800, h: 600)
    var textures: seq[TextureRef] # crutch
    var player = createPlayer()
    var tiles: seq[Tile]
    var camera = Camera2D(
        target: Vector2(x: 0.0, y: 0.0),
        offset: Vector2(x: 400.0, y: 225.0),
        rotation: 0.0,
        zoom: 1.0
    )

    # Init window
    initWindow(screen.w, screen.h, "Game 2D")
    setTargetFPS(60)

    # Texture loading
    textures.addTexture("tile", "assets/textures/tile.png")
    for anim in ["left", "right", "up", "down"]:
        textures.addTexture("player_" & anim, "assets/textures/player_" & anim & ".png")

    tiles.add(createTile(-32, -32))
    tiles.add(createTile(32, 32))
    tiles.add(createTile(-32, 32))
    tiles.add(createTile(32, -32))

    # Render cycle
    while not windowShouldClose():

        # Network IO
        var msgReceived: bool
        var msg: string
        withLock(io.toRendererLock):
            let (hasMsg, receivedMsg) = io.toRenderer.tryRecv()
            msgReceived = hasMsg
            if hasMsg:
                msg = receivedMsg
                echo "[Renderer] Received message: " & msg
                try:
                    let data = parseJson(msg)
                    if data.hasKey("packet"):
                        echo "is packet"
                        if data["packet"].getStr() == "tiles":
                            echo "reloading tiles"
                            tiles = @[]
                            for tile in data["tiles"]:
                                tiles.add(createTile(int32(tile["x"].getInt()),int32(tile["y"].getInt())))
                except:
                    echo "damaged packet"

        # player navigation
        if isKeyDown(W) and not player.directionBlocked("up", tiles):
            player.moveUp()
        if isKeyDown(S) and not player.directionBlocked("down", tiles):
            player.moveDown()
        if isKeyDown(A) and not player.directionBlocked("left", tiles):
            player.moveLeft()
        if isKeyDown(D) and not player.directionBlocked("right", tiles):
            player.moveRight()
            io.toNetwork.sendJson(%*{ "packet": "player_move", "x": player.position.x, "y": player.position.y })

        # reorders world objects to appear properly (only needed after world update event)
        tiles.sort(proc(a, b: Tile): int {.closure.} =
            if a.position.y < b.position.y: -1
            elif a.position.y > b.position.y: 1
            else: 0
        )

        # Changing camera position
        camera.target.x = float32(player.position.x)
        camera.target.y = float32(player.position.y)

        # Init Drawing
        beginDrawing()
        beginMode2D(camera)
        clearBackground(RayWhite)

        # render tiles behind the player
        for tile in tiles:
            if player.position.y >= tile.position.y:
                textures.drawTextureByName(tile.name, tile.position.x, tile.position.y, White)

        # render the player itself
        player.render(textures)

        # render tiles in front of the player
        for tile in tiles:
            if player.position.y < tile.position.y:
                tile.render(textures)

        endDrawing()
    closeWindow()