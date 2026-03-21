

-- items/checkbox.lua
-- Hérite de BaseItem.
--
-- SYNTAXE UNIFIÉE:
--   UIMenuCheckbox.New(text, checked, description, enabled, actions)
--   actions.onChange = function(item) ... end   ← item.checked = true/false
--   actions.onSelect = function(item) ... end   ← appui Entrée (après toggle)

UIMenuCheckbox = setmetatable({}, { __index = BaseItem })
UIMenuCheckbox.__index = UIMenuCheckbox

---@param text        string|nil
---@param checked     boolean|nil
---@param description string|nil
---@param enabled     boolean|nil
---@param actions     table|nil     { onChange=fn, onSelect=fn }
function UIMenuCheckbox.New(text, checked, description, enabled, actions)
    local self = BaseItem.New(UIMenuCheckbox, "checkbox", text, description, enabled)

    self.checked          = checked == true
    self.OnCheckboxChange = Event.New()

    -- Toggle automatique sur Entrée (comportement standard d'une checkbox)
    self.OnActivated.On(function()
        self:Toggle()
        if actions and type(actions.onSelect) == "function" then
            actions.onSelect(self)
        end
    end)

    if actions and type(actions.onChange) == "function" then
        self.OnCheckboxChange.On(function(it, _)
            actions.onChange(it)
        end)
    end

    return self
end

function UIMenuCheckbox:SetChecked(value)
    local new = value == true
    if new ~= self.checked then
        self.checked = new
        self.OnCheckboxChange.Emit(self, self.checked)
        if self.parent then self.parent._dirty = true end
    end
end

function UIMenuCheckbox:Toggle()
    self:SetChecked(not self.checked)
end

-- ─── Upvalues (fallback si DrawCustom appelé sans pré-calcul) ─────────────────
local _cbCfg, _cbMenuW, _cbItemH
local function CheckboxCfg()
    if not _cbCfg then
        _cbCfg   = Config.Checkbox or {}
        _cbMenuW = Config.Header.size.width
        _cbItemH = (Config.Layout and Config.Layout.itemHeight) or 35
    end
    return _cbCfg, _cbMenuW, _cbItemH
end

---@param x          number
---@param y          number
---@param isSelected boolean
---@param invW       number|nil  1/resW pre-calcule (pass depuis _DrawItems)
---@param invH       number|nil  1/resH pre-calcule (pass depuis _DrawItems)
function UIMenuCheckbox:DrawCustom(x, y, isSelected, invW, invH)
    -- Fallback si appele directement sans invW/invH
    if not invW or not invH then
        invW, invH = Draw.GetInvScale()
    end

    local isEnabled = (self.enabled == nil) and true or self.enabled

    -- Utilise les valeurs pre-calculees dans _Recalculate si disponibles
    if self._cbSpriteNX then
        local spriteName = self.checked and self._cbChecked or self._cbUnchecked
        local r, g, b, a
        if not isEnabled then
            r, g, b, a = self._cbColDisR, self._cbColDisG, self._cbColDisB, self._cbColDisA
        elseif isSelected then
            r, g, b, a = self._cbColSelR, self._cbColSelG, self._cbColSelB, self._cbColSelA
        else
            r, g, b, a = self._cbColDefR, self._cbColDefG, self._cbColDefB, self._cbColDefA
        end
        local cbNY = y * invH + self._cbNYOff
        Draw.SpriteRaw(self._cbDict, spriteName,
            self._cbSpriteNX, cbNY, self._cbNW, self._cbNH, 0.0, r, g, b, a)
        return
    end

    -- Fallback non-optimise (avant premier _Recalculate)
    local cfg, menuWidth, itemHeight = CheckboxCfg()
    local sp = cfg.sprite or {}

    local dict = sp.dict or "commonmenu"
    local name = self.checked
        and (sp.checked   or "shop_box_tickb")
        or  (sp.unchecked or "shop_box_blankb")

    local size    = sp.size or 32
    local spriteX = x + menuWidth - (sp.offsetRightX or 12) - size
    local spriteY = sp.offsetY ~= nil
        and (y + sp.offsetY)
        or  (y + (itemHeight - size) * 0.5)

    local tint = BaseItem.GetColor(sp.color, isEnabled, isSelected)
    local tr = tint and tint.r or 255
    local tg = tint and tint.g or 255
    local tb = tint and tint.b or 255
    local ta = tint and tint.a or 255

    Draw.Sprite(dict, name, spriteX, spriteY, size, size, 0.0, tr, tg, tb, ta)
end

DrawCheckbox = UIMenuCheckbox
return UIMenuCheckbox
