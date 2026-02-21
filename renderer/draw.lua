-- renderer/draw.lua
-- Base minimale: Rect + Sprite.
-- Coordonnées: pixels dans l'espace de référence (1080p, via Cache.GetResolution()).

Draw = {}

local cachedResolution
local cachedInvW, cachedInvH  -- 1/width, 1/height — évite la division par frame
local textureState = {}

local function GetResolution()
    if not cachedResolution then
        cachedResolution = Cache.GetResolution()
        cachedInvW = 1.0 / cachedResolution.width
        cachedInvH = 1.0 / cachedResolution.height
    end
    return cachedResolution
end

local function EnsureTexture(dict)
    if not dict or dict == "" then return false end

    local state = textureState[dict]
    if state == "loaded" then return true end

    if HasStreamedTextureDictLoaded(dict) then
        textureState[dict] = "loaded"
        return true
    end

    if state ~= "requested" then
        RequestStreamedTextureDict(dict, true)
        textureState[dict] = "requested"
    end
    return false
end

--- Dessine un rectangle (version optimisée: inline normalize, multiplication au lieu de division)
function Draw.Rect(x, y, w, h, color)
    GetResolution()  -- ensure cachedInvW/H
    local nw = w * cachedInvW
    local nh = h * cachedInvH
    DrawRect(
        x * cachedInvW + nw * 0.5,
        y * cachedInvH + nh * 0.5,
        nw, nh,
        color and color.r or 255,
        color and color.g or 255,
        color and color.b or 255,
        color and color.a or 255
    )
end

--- Dessine une sprite (version optimisée)
function Draw.Sprite(dict, name, x, y, w, h, heading, r, g, b, a)
    if not dict or not name then return end
    if not EnsureTexture(dict) then return false end

    GetResolution()
    local nw = w * cachedInvW
    local nh = h * cachedInvH

    DrawSprite(
        dict, name,
        x * cachedInvW + nw * 0.5,
        y * cachedInvH + nh * 0.5,
        nw, nh,
        heading or 0.0,
        r or 255, g or 255, b or 255, a or 255
    )
    return true
end

-- Obtenir la résolution actuelle
function Draw.GetResolution()
    return GetResolution()
end
