import os, json, threadpool

proc sendJson*(chan: var Channel[string], json: JsonNode) =
    chan.send($json)