import ws, asyncdispatch, strformat, times, os, strutils

var port = 3000
var clients: seq[WebSocket] = @[]

# To do ! All params must be transfered from Launcher
for param in commandLineParams():
    if param.startsWith("--port:"):
        if param.split(":").len == 2:
            port = int32(parseInt(param.split(":")[1]))
            echo "Setting port to: " & $port


proc handleClient(client: WebSocket) {.async.} =
    try:
        echo &"📥 Client connected"
        clients.add(client)
        await client.sendStrPacket("hello world")

        while client.readyState == Open:
            let msg = await client.recvStrPacket()
            echo &"📨 Received message: {msg}"
    except CatchableError as e:
        echo &"⚠️ Error: {e.msg}"
    finally:
        echo &"❌ Disconnected"
        clients.keepItIfIt(it != client)

proc broadcastLoop() {.async.} =
    while true:
        await sleepAsync(1000)
        let now = now().format("HH:mm:ss")
        for client in clients:
            if client.readyState == Open:
                try:
                    await client.sendStrPacket("tick " & now)
                except CatchableError:
                    discard

proc main() {.async.} =
    asyncCheck broadcastLoop()
    await serve(Port(port), "/ws", handleClient)
    while true:
        await sleepAsync(1000_000)

waitFor main()
