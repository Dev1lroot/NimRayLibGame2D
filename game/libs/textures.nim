import raylib, rlgl, raymath, rmem, reasings, rcamera, tables, os

type
    TextureRef* = object
        name*: string
        texture*: Texture2D

proc addTexture*(textures: var seq[TextureRef], name: string, path: string) =
    textures.add(TextureRef(name: name, texture: loadTexture(path)))

proc drawTextureByName*(textures: seq[TextureRef], name: string, x, y: int32, tint: Color) =
    for t in textures:
        if t.name == name:
            drawTexture(t.texture, x, y, tint)