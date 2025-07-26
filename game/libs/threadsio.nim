import locks, threadpool
type
    ThreadsIO* = ref object
        toRendererLock*: Lock
        toNetworkLock*: Lock
        toRenderer*: Channel[string]
        toNetwork*: Channel[string]

proc init*(io: var ThreadsIO) =
    initLock(io.toRendererLock)
    initLock(io.toNetworkLock)

    io.toRenderer.open()
    io.toNetwork.open()