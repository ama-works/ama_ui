---@diagnostic disable: undefined-global
-- items/windows.lua
-- UIMenuWindowHeritageItem — Panneau portrait mère/père (style NativeUI Heritage Window)
--
-- SYNTAXE:
--   local win = UIMenuWindowHeritageItem.New(mumIndex, dadIndex)
--   win:SetMum(3)        -- changer la mère  (0-20)
--   win:SetDad(7)        -- changer le père  (0-23)
--   win:heritage(3, 7)   -- raccourci SetMum + SetDad
--
-- Sprites GTA V natifs :
--   dict mère/père  → "char_creator_portraits"  /  "female_0".."female_20", "male_0".."male_23"
--   dict fond       → "pause_menu_pages_char_mom_dad" / "mumdadbg"

UIMenuWindowHeritageItem = setmetatable({}, { __index = BaseItem })
UIMenuWindowHeritageItem.__index = UIMenuWindowHeritageItem

-- ─── Upvalues config (lazy, 0 lookup par frame) ───────────────────────────────
local _winCfg, _winMenuW
local _winH
local _winBgDict, _winBgName, _winBgHeading, _winBgR, _winBgG, _winBgB, _winBgA
local _winPortDict
local _winMomSize, _winMomOffX, _winMomPrefix, _winMomSpecPrefix, _winMomR, _winMomG, _winMomB, _winMomA
local _winDadSize, _winDadOffX, _winDadPrefix, _winDadSpecPrefix, _winDadR, _winDadG, _winDadB, _winDadA
local function WinCfg()
    if not _winCfg then
        _winCfg   = Config.Window or {}
        _winMenuW = (Config.Header and Config.Header.size and Config.Header.size.width) or 431
        _winH     = (_winCfg.size and _winCfg.size.height) or 155
        local bg  = _winCfg.background or {}
        _winBgDict, _winBgName, _winBgHeading = bg.dict or "pause_menu_pages_char_mom_dad", bg.name or "mumdadbg", bg.heading or 0.0
        local bc  = bg.color or { r=255, g=255, b=255, a=255 }
        _winBgR, _winBgG, _winBgB, _winBgA = bc.r or 255, bc.g or 255, bc.b or 255, bc.a or 255
        local port   = _winCfg.portraits or {}
        _winPortDict = port.dict or "char_creator_portraits"
        local mom = port.mom or {}
        _winMomSize, _winMomOffX = mom.size or 75, mom.offsetX or 65
        _winMomPrefix, _winMomSpecPrefix = mom.prefix or "female_", "special_female_"
        local mc  = mom.color or { r=255, g=255, b=255, a=255 }
        _winMomR, _winMomG, _winMomB, _winMomA = mc.r or 255, mc.g or 255, mc.b or 255, mc.a or 255
        local dad = port.dad or {}
        _winDadSize, _winDadOffX = dad.size or 75, dad.offsetX or 65
        _winDadPrefix, _winDadSpecPrefix = dad.prefix or "male_", "special_male_"
        local dc  = dad.color or { r=255, g=255, b=255, a=255 }
        _winDadR, _winDadG, _winDadB, _winDadA = dc.r or 255, dc.g or 255, dc.b or 255, dc.a or 255
    end
    return _winCfg, _winMenuW
end

-- Résout le nom de sprite selon l'index :
--   mère  0-20 → "female_X"       index 21    → "special_female_0"
--   père  0-20 → "male_X"         indices 21-23 → "special_male_0".."special_male_2"
local function ResolveSprite(index, stdPrefix, specPrefix, specialStart)
    if index < specialStart then
        return stdPrefix .. tostring(index)
    else
        return specPrefix .. tostring(index - specialStart)
    end
end

-- ─── Constructeur ─────────────────────────────────────────────────────────────

---@param mumIndex number|nil  Index mère  0-20 (défaut 0)
---@param dadIndex number|nil  Index père  0-20 (défaut 0)
function UIMenuWindowHeritageItem.New(mumIndex, dadIndex)
    local self = BaseItem.New(UIMenuWindowHeritageItem, "window", "", nil, true)

    self.mumIndex = math.max(0, math.min(21, tonumber(mumIndex) or 0))
    self.dadIndex = math.max(0, math.min(23, tonumber(dadIndex) or 0))

    -- Pré-charger le dict portraits (non-bloquant)
    local dict = ((Config.Window or {}).portraits or {}).dict or "char_creator_portraits"
    RequestStreamedTextureDict(dict, false)

    return self
end

-- ─── Méthodes ─────────────────────────────────────────────────────────────────

--- Mettre à jour l'index mère et forcer le redraw
---@param index number 0-20
function UIMenuWindowHeritageItem:SetMum(index)
    local v = math.max(0, math.min(21, tonumber(index) or 0))
    if self.mumIndex ~= v then
        self.mumIndex = v
        if self.parent then self.parent._dirty = true end
    end
end

--- Mettre à jour l'index père et forcer le redraw
---@param index number 0-23
function UIMenuWindowHeritageItem:SetDad(index)
    local v = math.max(0, math.min(23, tonumber(index) or 0))
    if self.dadIndex ~= v then
        self.dadIndex = v
        if self.parent then self.parent._dirty = true end
    end
end

--- Raccourci : mettre à jour mère ET père en une seule ligne
---@param mumIndex number 0-20
---@param dadIndex number 0-23
function UIMenuWindowHeritageItem:heritage(mumIndex, dadIndex)
    self:SetMum(mumIndex)
    self:SetDad(dadIndex)
end

--- Override hauteur : le panneau est plus haut qu'un item normal
---@return number hauteur en px
function UIMenuWindowHeritageItem:GetHeight()
    WinCfg()
    return _winH
end

-- ─── Rendu ────────────────────────────────────────────────────────────────────

function UIMenuWindowHeritageItem:DrawCustom(x, y)
    WinCfg()

    -- Fond du panneau (EnsureTexture gère le streaming en interne)
    Draw.Sprite(_winBgDict, _winBgName, x, y, _winMenuW, _winH, _winBgHeading,
        _winBgR, _winBgG, _winBgB, _winBgA)

    -- Portraits (EnsureTexture + textureState cache — pas de HasStreamedTextureDictLoaded)
    local momSprite  = ResolveSprite(self.mumIndex, _winMomPrefix, _winMomSpecPrefix, 21)
    local momX       = x + _winMomOffX
    local momY       = y + (_winH - _winMomSize) * 0.9
    Draw.Sprite(_winPortDict, momSprite, momX, momY, _winMomSize, _winMomSize, 0.5,
        _winMomR, _winMomG, _winMomB, _winMomA)

    local dadSprite  = ResolveSprite(self.dadIndex, _winDadPrefix, _winDadSpecPrefix, 21)
    local dadX       = x + _winMenuW - _winDadOffX - _winDadSize
    local dadY       = y + (_winH - _winDadSize) * 0.9
    Draw.Sprite(_winPortDict, dadSprite, dadX, dadY, _winDadSize, _winDadSize, 0.5,
        _winDadR, _winDadG, _winDadB, _winDadA)
end
