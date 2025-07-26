import random, strutils

proc generateV4*(): string =
  var bytes: array[16, byte]
  for i in 0 ..< 16:
    bytes[i] = rand(255).byte

  # Установим версию UUID (4)
  bytes[6] = (bytes[6] and 0x0F) or 0x40

  # Установим вариант (variant 1: 10xx xxxx)
  bytes[8] = (bytes[8] and 0x3F) or 0x80

  # Сформируем строку UUID
  result = ""
  for i, b in bytes:
    result.add(b.toHex(2))
    if i in [3, 5, 7, 9]:
      result.add("-")