import websocket, asyncdispatch, locks, strutils, threadpool, json, parseutils, ws, ../libs/channelutils, ../libs/threadsio

# Frontend <--> Backend
proc gameNetworkService*(io: ThreadsIO, address: string, port: int) {.async.} =

    proc run() {.async.} =
        try:
            let ws = await newWebSocket("ws://" & address & ":" & $port & "/ws")
            echo "✅ Connected"

            proc writer() {.async.} =
                while ws.readyState == Open:
                    withLock(io.toNetworkLock):
                        # echo "[NetworkService] Waiting for package"
                        let (hasMsg, receivedMsg) = io.toNetwork.tryRecv()
                        if hasMsg:
                            await ws.send(receivedMsg)
                    await sleepAsync(1)

            proc reader() {.async.} =
                while ws.readyState == Open:
                    let msg = await ws.receiveStrPacket()
                    withLock(io.toRendererLock):
                        io.toRenderer.send($msg)

            asyncCheck writer()
            await reader()

            await sleepAsync(1)
        except WebSocketClosedError:
            echo "Socket closed. "
            quit(0)
        except WebSocketProtocolMismatchError:
            echo "Socket client tried to use an unknown protocol: "
        except CatchableError as e:
            echo "❌ WebSocket error: ", e.msg
            quit(0)

    waitFor run()