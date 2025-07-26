import locks, threadpool
type
    ThreadsIO* = ref object
        toRendererLock*: Lock
        toNetworkLock*: Lock
        toRenderer*: Channel[string]
        toNetwork*: Channel[string]