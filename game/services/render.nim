import raylib, rlgl, raymath, rmem, reasings, rcamera, tables, os, random, sequtils, std/algorithm, websocket, asyncdispatch, locks, strutils, threadpool, json, parseutils, ws
import ../entities/player, ../libs/textures, ../entities/tile, ../libs/position3d, ../libs/screen, network, ../libs/channelutils, ../libs/threadsio, ../entities/drawable

proc processGameData(package: JsonNode, players: var seq[Player], tiles: var seq[Tile]): bool =
    var reorderRequired = false

    if package.hasKey("packet"):

        # import tiles
        if package.hasKey("tiles"):
            # echo "[RenderService] Received tiles"
            tiles = @[]
            reorderRequired = true
            for tile in package["tiles"]:
                tiles.add(createTile(
                    tile["name"].getStr(), 
                    int32(tile["x"].getInt()),
                    int32(tile["y"].getInt())
                ))

        # import players
        if package.hasKey("players"):
            # echo "[RenderService] Received players"
            players = @[]
            reorderRequired = true
            for player in package["players"]:
                var p        = Player();
                p.uuid       = player["uuid"].getStr()
                p.position.x = int32(player["position"]["x"].getInt())
                p.position.y = int32(player["position"]["y"].getInt())
                p.position.z = 48
                p.direction  = player["direction"].getStr()
                players.add(p)
    return reorderRequired

proc gameRenderService*(io: ThreadsIO) {.thread, gcsafe.} =
    
    var screen = Screen(w: 800, h: 600)
    var textures: seq[TextureRef] # crutch
    var player = createPlayer()
    var reorderRequired = false
    
    player.bindControls(@[
        PlayerControls(key: W, action: "up"),
        PlayerControls(key: A, action: "left"),
        PlayerControls(key: S, action: "down"),
        PlayerControls(key: D, action: "right"),
        PlayerControls(key: F3, action: "debug"),
    ]);

    var tiles: seq[Tile]
    var players: seq[Player]
    var camera = Camera2D(
        target: Vector2(x: 0.0, y: 0.0),
        offset: Vector2(x: 400.0, y: 225.0),
        rotation: 0.0,
        zoom: 2.0
    )

    # Init window
    setConfigFlags(flags(WindowResizable))
    initWindow(screen.w, screen.h, "Game 2D")
    setTargetFPS(60)

    # Texture loading
    for t in ["sand","forest","water","grass","tile","rock","snow"]:
        textures.addTexture("water", "assets/textures/" & t & ".png")
    for anim in ["left", "right", "up", "down"]:
        textures.addTexture("player_" & anim, "assets/textures/player_" & anim & ".png")

    # Render cycle
    while not windowShouldClose():

        # Receiving resized window
        screen.w = getScreenWidth()
        screen.h = getScreenHeight()

        # Network IO
        var msgReceived: bool
        var msg: string
        withLock(io.toRendererLock):
            let (hasMsg, receivedMsg) = io.toRenderer.tryRecv()
            msgReceived = hasMsg
            if hasMsg:
                msg = receivedMsg
                try:
                    let data = parseJson(msg)
                    if data.processGameData(players, tiles):
                        reorderRequired = true
                except:
                    discard

        # player navigation
        if player.handleControls(tiles):
            reorderRequired = true
            withLock(io.toNetworkLock):
                io.toNetwork.sendJson(player.transfer())

        # Changing camera position
        camera.followPlayer(player)
        camera.offset.x = float32(screen.w div 2)
        camera.offset.y = float32(screen.h div 2)

        # Init Drawing
        beginDrawing()
        beginMode2D(camera)
        clearBackground(RayWhite)

        var renderQueue: seq[Drawable] = @[]
        renderQueue.add player
        for p in players:
            if p.uuid != player.uuid:
                renderQueue.add p
        for t in tiles:
            if abs(player.position.x - t.position.x) < screen.w:
                if abs(player.position.y - t.position.y) < screen.h:
                    renderQueue.add t

        # reorders world objects to appear properly (only needed after world update event)
        if reorderRequired:
            renderQueue.sort(proc(a, b: Drawable): int {.closure.} =
                if a.position.y + a.position.z < b.position.y + b.position.z: -1
                elif a.position.y + a.position.z > b.position.y + b.position.z: 1
                else: 0
            )

        # draws everything
        for drawable in renderQueue:
            drawable.render(textures)

        # render tiles in front of the player
        # for tile in tiles:
        #     if player.position.y < tile.position.y:
        #         tile.render(textures)

        endDrawing()
    closeWindow()
    quit(1)