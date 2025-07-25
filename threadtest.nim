# THIS WORKS! BUT...

import std/os # for sleep

var
  # create a channel to send/recv strings
  commChan: Channel[string]
  sender: Thread[void]
  recver: Thread[void]

proc sendMsg() =
  sleep(500)
  # send a message in the channel
  commChan.send("Hi")

proc recvMsg() =
  # block on the channel, waiting for output
  let msg: string = commChan.recv()
  echo "Received message: " & msg

# very important: channels must be opened before they can be used
commChan.open()
createThread(sender, sendMsg)
createThread(recver, recvMsg)
joinThreads(sender, recver)