import websocket, asyncdispatch, locks, strutils, threadpool, json, parseutils, ws, channelutils, threadsio

# Frontend <--> Backend
proc gameNetworkingCycle*(io: ThreadsIO, address: string, port: int) {.async.} =
    proc run() {.async.} =
        try:
            let ws = await newWebSocket("ws://" & address & ":" & $port & "/ws")
            echo "✅ Connected"

            while true:
                # CLIENT -> SERVER
                withLock(io.toNetworkLock):
                    let (hasMsg, receivedMsg) = io.toNetwork.tryRecv()
                    if hasMsg:
                        echo "[Networking] Sending message to server: ", receivedMsg
                        await ws.send(receivedMsg)

                # SERVER -> CLIENT
                if ws.readyState == Open:
                    let msg = await ws.receiveStrPacket()
                    withLock(io.toRendererLock):
                        io.toRenderer.send($msg)

                await sleepAsync(1)
        except CatchableError as e:
            echo "❌ WebSocket error: ", e.msg

    waitFor run()