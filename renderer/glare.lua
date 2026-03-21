-- renderer/glare.lua
-- Effet glare sur le header du menu.
-- Utilise le scaleform natif GTA V "mp_menu_glare".
-- Usage :
--   Glare.Init()                        -- demander le chargement (non-bloquant)
--   Glare.Draw(x, y, width, height)     -- appeler chaque frame dans le thread de rendu
--   Glare.Cleanup()                     -- libérer quand le menu est fermé

Glare = {}

local _handle = 0       -- handle retourné par RequestScaleformMovie (0 = non demandé)
local _loaded = false   -- true une fois HasScaleformMovieLoaded confirmé

--- Demande le chargement du scaleform mp_menu_glare (non-bloquant).
--- Plusieurs appels sont sûrs : court-circuit si déjà demandé ou chargé.
function Glare.Init()
    if _loaded or _handle ~= 0 then return end
    _handle = RequestScaleformMovie("mp_menu_glare")
end

--- Dessine l'effet glare dans la zone spécifiée (pixels 1080p).
--- Appelle Glare.Init() si le chargement n'a pas encore été demandé.
--- Vérifie HasScaleformMovieLoaded chaque frame jusqu'au chargement — zéro Wait().
---@param x      number  Coin haut-gauche X en pixels
---@param y      number  Coin haut-gauche Y en pixels
---@param width  number  Largeur en pixels
---@param height number  Hauteur en pixels
function Glare.Draw(x, y, width, height)
    if _handle == 0 then
        Glare.Init()    -- demande le chargement au premier appel
        return          -- skip ce frame, dessine dès la frame suivante
    end
    if not _loaded then
        if HasScaleformMovieLoaded(_handle) then
            _loaded = true
        else
            return      -- scaleform pas encore prêt, skip ce frame
        end
    end
    -- Draw.Scaleform gère la normalisation pixels → coordonnées normalisées
    Draw.Scaleform(_handle, x, y, width, height, nil)
end

--- Libère le handle scaleform et réinitialise l'état du module.
function Glare.Cleanup()
    if _handle > 0 then
        SetScaleformMovieAsNoLongerNeeded(_handle)
    end
    _handle = 0
    _loaded = false
end
