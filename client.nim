import raylib, rlgl, raymath, rmem, reasings, rcamera, tables, os, random, sequtils, std/algorithm, websocket, asyncdispatch, locks, strutils, threadpool, json, parseutils, ws
import game/entities/player, game/libs/textures, game/entities/tile, game/libs/position2d, game/libs/screen, game/services/render, game/services/network, game/libs/threadsio

# global vars >:3
var address = "127.0.0.1"
var port = 3000

var renderThread: Thread[ThreadsIO]

var io = ThreadsIO()

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
    io.init()
    createThread(renderThread, gameRenderService, io)
    asyncCheck gameNetworkService(io, address, port)
    joinThread(renderThread)
main()