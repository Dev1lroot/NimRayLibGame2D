import raylib, rlgl, raymath, rmem, reasings, rcamera, tables, os, random, sequtils, std/algorithm, websocket, asyncdispatch, locks, strutils, threadpool, json, parseutils, ws
import ../entities/player, ../libs/textures, ../entities/tile, ../libs/position2d, ../libs/screen, network, ../libs/channelutils, ../libs/threadsio

proc processGameData(package: JsonNode, players: var seq[Player], tiles: var seq[Tile]) =
    if package.hasKey("packet"):

        # import tiles
        if package.hasKey("tiles"):
            # echo "[RenderService] Received tiles"
            tiles = @[]
            for tile in package["tiles"]:
                tiles.add(createTile(int32(tile["x"].getInt()),int32(tile["y"].getInt())))

        # import players
        if package.hasKey("players"):
            # echo "[RenderService] Received players"
            players = @[]
            for player in package["players"]:
                var p        = Player();
                p.uuid       = player["uuid"].getStr()
                p.position.x = int32(player["position"]["x"].getInt())
                p.position.y = int32(player["position"]["y"].getInt())
                p.direction  = player["direction"].getStr()
                players.add(p)

proc gameRenderService*(io: ThreadsIO) {.thread, gcsafe.} =
    
    var screen = Screen(w: 800, h: 600)
    var textures: seq[TextureRef] # crutch
    var player = createPlayer()
    
    player.bindControls(@[
        PlayerControls(key: W, action: "up"),
        PlayerControls(key: A, action: "left"),
        PlayerControls(key: S, action: "down"),
        PlayerControls(key: D, action: "right"),
    ]);

    var tiles: seq[Tile]
    var players: seq[Player]
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
                try:
                    let data = parseJson(msg)
                    data.processGameData(players, tiles)
                except:
                    discard

        # player navigation
        if player.handleControls(tiles):
            withLock(io.toNetworkLock):
                io.toNetwork.sendJson(player.transfer())

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

        for p in players:
            if p.uuid != player.uuid:
                p.render(textures)

        # render the player itself (our player is always on top of others) to fix 
        player.render(textures)

        # render tiles in front of the player
        for tile in tiles:
            if player.position.y < tile.position.y:
                tile.render(textures)

        endDrawing()
    closeWindow()
    quit(1)