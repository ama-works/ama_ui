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
local function WinCfg()
    if not _winCfg then
        _winCfg   = Config.Window or {}
        _winMenuW = (Config.Header and Config.Header.size and Config.Header.size.width) or 431
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
    local cfg = WinCfg()
    return (cfg.size and cfg.size.height) or 155
end

-- ─── Rendu ────────────────────────────────────────────────────────────────────

function UIMenuWindowHeritageItem:DrawCustom(x, y)
    local cfg, menuW = WinCfg()
    menuW = menuW or 431

    local panelH = (cfg.size and cfg.size.height) or 155

    -- ── 1. Fond du panneau ──────────────────────────────────────────────────
    -- Pour désactiver le sprite : mettre background.dict = nil dans Config.Window
    local bg     = cfg.background or {}
    local bgDict = bg.dict or "pause_menu_pages_char_mom_dad"
    local bgName = bg.name or "mumdadbg"
    local bc     = bg.color or { r = 255, g = 255, b = 255, a = 255 }
    Draw.Sprite(bgDict, bgName, x, y, menuW, panelH, bg.heading or 0.0,
        bc.r, bc.g, bc.b, bc.a)

    -- ── 2. Portraits ────────────────────────────────────────────────────────
    local port = cfg.portraits or {}
    local dict = port.dict or "char_creator_portraits"

    -- S'assurer que le dict est streamé (non-bloquant, 1 appel par frame max)
    if not HasStreamedTextureDictLoaded(dict) then
        RequestStreamedTextureDict(dict, false)
        return  -- on attend le chargement, rien à dessiner cette frame
    end

    -- Portrait mère (gauche) — taille depuis mom.size
    local momCfg    = port.mom or {}
    local momSize   = momCfg.size or 75
    local momX      = x + (momCfg.offsetX or 65)
    local momCentreY = y + (panelH - momSize) * 0.5
    local mc        = momCfg.color or { r = 255, g = 255, b = 255, a = 255 }
    local momSprite = ResolveSprite(self.mumIndex, momCfg.prefix or "female_", "special_female_", 21)
    Draw.Sprite(dict, momSprite, momX, momCentreY, momSize, momSize, 0.5, mc.r, mc.g, mc.b, mc.a)

    -- Portrait père (droite, symétrique) — taille depuis dad.size
    local dadCfg    = port.dad or {}
    local dadSize   = dadCfg.size or 75
    local dadX      = x + menuW - (dadCfg.offsetX or 65) - dadSize
    local dadCentreY = y + (panelH - dadSize) * 0.5
    local dc        = dadCfg.color or { r = 255, g = 255, b = 255, a = 255 }
    local dadSprite = ResolveSprite(self.dadIndex, dadCfg.prefix or "male_", "special_male_", 21)
    Draw.Sprite(dict, dadSprite, dadX, dadCentreY, dadSize, dadSize, 0.5, dc.r, dc.g, dc.b, dc.a)
end
