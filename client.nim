import raylib, rlgl, raymath, rmem, reasings, rcamera, tables, os, random, sequtils, std/algorithm, websocket, asyncdispatch, locks, strutils, threadpool, json, parseutils, ws

# yes its a crutch but im tired of import/variable collisions
import game/player as aaaaaaaaaa, game/textures as bbbbbbbbb, game/tile as ccccccccc, game/position2d as dddddddddd, game/screen as eeeeeeee

# global vars >:3
var address = "127.0.0.1"
var port = 3000
var sendQueue: seq[string]
var toRenderCycle: seq[string]
var toRenderCycleLock: Lock
var queueLock: Lock
var posLock: Lock
var renderThread: Thread[void]
const MaxMessages = 1024

var messageBuffer: array[MaxMessages, array[256, char]]
var messageCount: int
var bufferLock: Lock

# To do ! All params must be transfered from Launcher
for param in commandLineParams():
    if param.startsWith("--port:"):
        if param.split(":").len == 2:
            port = int32(parseInt(param.split(":")[1]))
            echo "Setting port to: " & $port
    if param.startsWith("--addr:"):
        if param.split(":").len == 2:
            address = param.split(":")[1]
            echo "Setting address to: " & address

# Frontend<->Backend
proc gameNetworkingCycle() {.async.} =
    proc run() {.async.} =
        try:
            let ws = await newWebSocket("ws://" & address & ":" & $port & "/ws")
            echo "✅ Connected"

            while true:
                # CLIENT INPUT
                block readSendQueue:
                    withLock queueLock:
                        if sendQueue.len > 0:
                            let msg = sendQueue[0]
                            sendQueue.delete(0)
                            await ws.send(msg)

                # SERVER INPUT
                if ws.readyState == Open:
                    let msg = await ws.receiveStrPacket()
                    withLock bufferLock:
                        if msg.len > 0 and messageCount < MaxMessages:
                            copyMem(addr messageBuffer[messageCount][0], addr msg[0], min(msg.len, 255))
                            messageBuffer[messageCount][min(msg.len, 255)] = '\0' # null-terminated
                            inc messageCount
                    echo $msg

                await sleepAsync(10)
        except CatchableError as e:
            echo "❌ WebSocket error: ", e.msg

    waitFor run()

proc gameRenderCycle {.thread, gcsafe.} =
    
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
    var localMessages: seq[string] = @[]

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
        var localMessages: seq[string] = @[]

        withLock bufferLock:
            for i in 0..<messageCount:
                localMessages.add($cast[cstring](addr messageBuffer[i]))
            messageCount = 0

        # Checking collisions
        # for tile in tiles:
            # if tile.isCollidesWith(player):
                #ss

        # player navigation
        if isKeyDown(W) and not player.directionBlocked("up", tiles):
            player.moveUp()
        if isKeyDown(S) and not player.directionBlocked("down", tiles):
            player.moveDown()
        if isKeyDown(A) and not player.directionBlocked("left", tiles):
            player.moveLeft()
        if isKeyDown(D) and not player.directionBlocked("right", tiles):
            player.moveRight()

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

proc main =
  initLock(queueLock)
  initLock(posLock)

  # Стартуем render в потоке
  createThread(renderThread, gameRenderCycle)

  # Стартуем networking отдельно
  asyncCheck gameNetworkingCycle()

  # Ждём завершения render-потока
  joinThread(renderThread)
main()