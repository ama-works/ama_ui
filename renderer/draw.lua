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

--- Dessine un rectangle avec coordonnées déjà normalisées (pré-calculées dans _Recalculate).
--- nx, ny : centre normalisé (0..1) ; nw, nh : taille normalisée (0..1)
--- r, g, b, a : composantes couleur directes (entiers 0-255, sans accès table)
--- Zéro multiplication, zéro division, zéro accès table par frame.
function Draw.RectRaw(nx, ny, nw, nh, r, g, b, a)
    DrawRect(nx, ny, nw, nh, r, g, b, a)
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

--- Dessine une sprite avec coordonnées déjà normalisées (pré-calculées dans _Recalculate).
--- nx, ny : centre normalisé ; nw, nh : taille normalisée.
--- Retourne false si la texture n'est pas encore chargée (EnsureTexture gère le chargement).
function Draw.SpriteRaw(dict, name, nx, ny, nw, nh, heading, r, g, b, a)
    if not EnsureTexture(dict) then return false end
    DrawSprite(dict, name, nx, ny, nw, nh, heading, r, g, b, a)
    return true
end

--- Expose cachedInvW et cachedInvH pour permettre la pré-normalisation dans _Recalculate.
--- Retourne les deux valeurs en une seule fonction pour éviter deux appels séparés.
function Draw.GetInvScale()
    GetResolution()  -- initialise si nécessaire
    return cachedInvW, cachedInvH
end

-- Obtenir la résolution actuelle
function Draw.GetResolution()
    return GetResolution()
end

--- Dessine un rectangle avec une bordure (4 Rect minces sur les bords).
--- x, y, w, h : position et taille en pixels 1080p (coin haut-gauche)
--- bw         : épaisseur de la bordure en pixels
--- borderColor: { r, g, b, a } couleur de la bordure
function Draw.RectBorder(x, y, w, h, color, bw, borderColor)
    GetResolution()

    -- Remplissage intérieur
    Draw.Rect(x, y, w, h, color)

    local br = borderColor and borderColor.r or 255
    local bg = borderColor and borderColor.g or 255
    local bb = borderColor and borderColor.b or 255
    local ba = borderColor and borderColor.a or 255
    local bord = bw or 1

    -- Bord haut
    local nBordH = bord * cachedInvH
    local nBordW = bord * cachedInvW

    -- Bord haut : pleine largeur, hauteur = bw, aligné sur le haut du rect
    local nw = w * cachedInvW
    local nh = h * cachedInvH
    local nx = x * cachedInvW + nw * 0.5
    local ny = y * cachedInvH

    DrawRect(nx, ny + nBordH * 0.5,  nw, nBordH, br, bg, bb, ba) -- haut
    DrawRect(nx, ny + nh - nBordH * 0.5, nw, nBordH, br, bg, bb, ba) -- bas
    DrawRect(nx - nw * 0.5 + nBordW * 0.5, ny + nh * 0.5, nBordW, nh, br, bg, bb, ba) -- gauche
    DrawRect(nx + nw * 0.5 - nBordW * 0.5, ny + nh * 0.5, nBordW, nh, br, bg, bb, ba) -- droite
end

--- Dégradé horizontal (colorFrom à gauche → colorTo à droite).
--- steps tranches verticales ; défaut 32.
function Draw.GradientH(x, y, w, h, colorFrom, colorTo, steps)
    GetResolution()
    steps = steps or 32

    local sliceW  = w / steps
    local nSliceW = sliceW * cachedInvW
    local nh      = h * cachedInvH
    local ny      = y * cachedInvH + nh * 0.5

    local stepsM1 = steps - 1  -- évite la division répétée dans la boucle

    for i = 0, stepsM1 do
        local t  = i / stepsM1
        local t1 = 1.0 - t
        -- Interpolation linéaire r/g/b/a
        local r = math.floor(colorFrom.r * t1 + colorTo.r * t + 0.5)
        local g = math.floor(colorFrom.g * t1 + colorTo.g * t + 0.5)
        local b = math.floor(colorFrom.b * t1 + colorTo.b * t + 0.5)
        local a = math.floor(colorFrom.a * t1 + colorTo.a * t + 0.5)

        local nx = (x + sliceW * i) * cachedInvW + nSliceW * 0.5
        DrawRect(nx, ny, nSliceW, nh, r, g, b, a)
    end
end

--- Dégradé vertical (colorFrom en haut → colorTo en bas).
--- steps tranches horizontales ; défaut 32.
function Draw.GradientV(x, y, w, h, colorFrom, colorTo, steps)
    GetResolution()
    steps = steps or 32

    local sliceH  = h / steps
    local nSliceH = sliceH * cachedInvH
    local nw      = w * cachedInvW
    local nx      = x * cachedInvW + nw * 0.5

    local stepsM1 = steps - 1

    for i = 0, stepsM1 do
        local t  = i / stepsM1
        local t1 = 1.0 - t
        local r = math.floor(colorFrom.r * t1 + colorTo.r * t + 0.5)
        local g = math.floor(colorFrom.g * t1 + colorTo.g * t + 0.5)
        local b = math.floor(colorFrom.b * t1 + colorTo.b * t + 0.5)
        local a = math.floor(colorFrom.a * t1 + colorTo.a * t + 0.5)

        local ny = (y + sliceH * i) * cachedInvH + nSliceH * 0.5
        DrawRect(nx, ny, nw, nSliceH, r, g, b, a)
    end
end

--- Dessine une sprite avec des coordonnées UV personnalisées.
--- u1,v1 : coin haut-gauche UV (0.0–1.0) ; u2,v2 : coin bas-droit UV.
--- x, y, w, h en pixels 1080p — même convention que Draw.Sprite.
function Draw.SpriteUv(dict, name, x, y, w, h, u1, v1, u2, v2, heading, r, g, b, a)
    if not dict or not name then return end
    if not EnsureTexture(dict) then return false end

    GetResolution()
    local nw = w * cachedInvW
    local nh = h * cachedInvH

    _DrawSpriteUv(
        dict, name,
        x * cachedInvW + nw * 0.5,
        y * cachedInvH + nh * 0.5,
        nw, nh,
        u1 or 0.0, v1 or 0.0,
        u2 or 1.0, v2 or 1.0,
        heading or 0.0,
        r or 255, g or 255, b or 255, a or 255
    )
    return true
end

--- Dessine un scaleform dans une zone rectangulaire.
--- x, y : coin haut-gauche en pixels 1080p → converti en centre normalisé.
--- color : { r, g, b, a } ou nil (255,255,255,255 par défaut).
function Draw.Scaleform(handle, x, y, w, h, color)
    if not handle or handle == 0 then return end
    GetResolution()

    local nw = w * cachedInvW
    local nh = h * cachedInvH

    DrawScaleformMovie(
        handle,
        x * cachedInvW + nw * 0.5,
        y * cachedInvH + nh * 0.5,
        nw, nh,
        color and color.r or 255,
        color and color.g or 255,
        color and color.b or 255,
        color and color.a or 255,
        0   -- type (toujours 0 pour les scaleforms 2D)
    )
end

--- Dessine un scaleform en plein écran.
--- color : { r, g, b, a } ou nil (255,255,255,255 par défaut).
function Draw.ScaleformFullscreen(handle, color)
    if not handle or handle == 0 then return end
    DrawScaleformMovieFullscreen(
        handle,
        color and color.r or 255,
        color and color.g or 255,
        color and color.b or 255,
        color and color.a or 255,
        0   -- type
    )
end

--- Libère un dictionnaire de textures et réinitialise son état interne.
function Draw.ReleaseTexture(dict)
    if not dict or dict == "" then return end
    SetStreamedTextureDictAsNoLongerNeeded(dict)
    textureState[dict] = nil
end

--- Libère toutes les textures chargées et vide la table d'état.
function Draw.ReleaseAllTextures()
    for dict, state in pairs(textureState) do
        if state == "loaded" then
            SetStreamedTextureDictAsNoLongerNeeded(dict)
        end
    end
    -- Vide complètement la table plutôt que d'itérer à nouveau
    textureState = {}
end
