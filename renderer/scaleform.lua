-- renderer/scaleform.lua
-- Module OOP pour charger, utiliser et libérer des scaleforms GTA V.
-- Usage :
--   local sf = Scaleform.New("mp_big_message_freemode")
--   sf:CallMethod("SHOW_SHARD_WASTED_MP_MESSAGE", "Titre", "Sous-titre")
--   sf:Draw(x, y, w, h, color)   -- chaque frame dans un thread
--   sf:Release()                  -- libérer quand inutile

Scaleform = {}
Scaleform.__index = Scaleform

--- Crée et retourne une instance Scaleform.
--- Lance immédiatement la requête de chargement via RequestScaleformMovie.
---@param name string  Nom du scaleform GTA V (ex. "mp_big_message_freemode")
---@return table       Instance Scaleform
function Scaleform.New(name)
    local self = setmetatable({}, Scaleform)
    self._name   = name
    self._handle = RequestScaleformMovie(name)
    self._loaded = false
    return self
end

--- Vérifie si le scaleform est entièrement chargé.
---@return boolean
function Scaleform:IsLoaded()
    -- Ne pas court-circuiter sur self._loaded : on délègue toujours à la native
    -- afin que le linter puisse inférer correctement le type de retour.
    local loaded = self._loaded or HasScaleformMovieLoaded(self._handle)
    self._loaded = loaded
    return loaded
end

--- Attend que le scaleform soit chargé, avec timeout optionnel.
--- timeout_ms : durée max en millisecondes (nil = attente infinie)
---@param timeout_ms number|nil
function Scaleform:WaitForLoad(timeout_ms)
    local elapsed = 0
    while not self:IsLoaded() do
        Wait(0)
        if timeout_ms then
            -- Chaque itération = ~1 frame (≈16 ms à 60 fps)
            elapsed = elapsed + 16
            if elapsed >= timeout_ms then
                break
            end
        end
    end
end

--- Dessine le scaleform dans une zone rectangulaire (pixels 1080p).
--- Délègue à Draw.Scaleform — voir renderer/draw.lua.
---@param x     number  Coin haut-gauche X en pixels
---@param y     number  Coin haut-gauche Y en pixels
---@param w     number  Largeur en pixels
---@param h     number  Hauteur en pixels
---@param color table|nil  { r, g, b, a } ou nil
function Scaleform:Draw(x, y, w, h, color)
    if not self:IsLoaded() then return end
    Draw.Scaleform(self._handle, x, y, w, h, color)
end

--- Dessine le scaleform en plein écran.
---@param color table|nil  { r, g, b, a } ou nil
function Scaleform:DrawFullscreen(color)
    if not self:IsLoaded() then return end
    Draw.ScaleformFullscreen(self._handle, color)
end

--- Appelle une méthode du scaleform avec des arguments typés automatiquement.
--- Détection du type de chaque argument :
---   number  → BeginScaleformMovieMethodOnFrontend / AddParamFloat
---   string  → AddParamPlayerNameString
---   boolean → AddParamBool
---@param methodName string  Nom de la méthode scaleform (ex. "SHOW_SHARD_WASTED_MP_MESSAGE")
---@param ...                Arguments à passer à la méthode
function Scaleform:CallMethod(methodName, ...)
    if not self:IsLoaded() then return end

    BeginScaleformMovieMethod(self._handle, methodName)

    for _, arg in ipairs({...}) do
        local argType = type(arg)
        if argType == "number" then
            ScaleformMovieMethodAddParamFloat(arg)
        elseif argType == "string" then
            ScaleformMovieMethodAddParamPlayerNameString(arg)
        elseif argType == "boolean" then
            ScaleformMovieMethodAddParamBool(arg)
        end
        -- Les autres types (table, nil…) sont ignorés silencieusement
    end

    EndScaleformMovieMethod()
end

--- Libère le handle scaleform et réinitialise l'instance.
function Scaleform:Release()
    -- RequestScaleformMovie retourne 0 en cas d'échec ; on protège avec > 0.
    if (self._handle or 0) > 0 then
        SetScaleformMovieAsNoLongerNeeded(self._handle)
    end
    self._handle = nil
    self._loaded = false
end
