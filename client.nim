import raylib, rlgl, raymath, rmem, reasings, rcamera, tables, os, random, sequtils, std/algorithm, websocket, asyncdispatch, locks, strutils, threadpool, json, parseutils, ws
import game/player, game/textures, game/tile, game/position2d, game/screen, game/renderer, game/networking, game/threadsio

# global vars >:3
var address = "127.0.0.1"
var port = 3000

var renderThread: Thread[ThreadsIO]

var io = ThreadsIO()
# var toRenderer: Channel[string]
# var toNetwork: Channel[string]
# var toRendererLock: Lock
# var toNetworkLock: Lock

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

proc main =
    initLock(io.toRendererLock)
    initLock(io.toNetworkLock)

    io.toRenderer.open()
    io.toNetwork.open()

    # Renderer Thread
    createThread(renderThread, gameRenderCycle, io)

    # Networking Thread
    asyncCheck gameNetworkingCycle(io, address, port)

    # F
    joinThread(renderThread)
main()