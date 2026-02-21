-- items/checkbox.lua
-- HÃ©rite de BaseItem. Affiche une box cochÃ©e/dÃ©cochÃ©e (sprite GTA).

--[[UIMenuCheckbox = setmetatable({}, { __index = BaseItem })
UIMenuCheckbox.__index = UIMenuCheckbox

---@param text string|nil
---@param checked boolean|nil
---@param description string|nil
function UIMenuCheckbox.New(text, checked, description)
	local self = BaseItem.New(UIMenuCheckbox, "checkbox", text, description, true)

	self.checked = checked == true
	self.OnCheckboxChange = Event.New()

	-- Toggle par dÃ©faut quand on "Select" l'item
	self.OnActivated.On(function()
		self:Toggle()
	end)

	return self
end

function UIMenuCheckbox:SetChecked(value)
	local newValue = value == true
	if newValue ~= self.checked then
		self.checked = newValue
		self.OnCheckboxChange.Emit(self, self.checked)
	end
end

function UIMenuCheckbox:Toggle()
	self:SetChecked(not self.checked)
end

-- SetEnabled() hÃ©ritÃ© de BaseItem (avec auto-dirty)

-- Upvalues: Ã©vite les lookups Config rÃ©pÃ©tÃ©s par frame
local _cbCfg, _cbMenuW, _cbItemH

local function CheckboxCfg()
	if not _cbCfg then
		_cbCfg   = Config.Checkbox or {}
		_cbMenuW = Config.Header.size.width
		_cbItemH = (Config.Layout and Config.Layout.itemHeight) or 35
	end
	return _cbCfg, _cbMenuW, _cbItemH
end

function UIMenuCheckbox:DrawCustom(x, y, isSelected)
	local cfg, menuWidth, itemHeight = CheckboxCfg()
	local spriteCfg = cfg.sprite or {}

	local dict = spriteCfg.dict or "commonmenu"
	local name = self.checked and (spriteCfg.checked or "shop_box_tickb") or (spriteCfg.unchecked or "shop_box_blankb")

	local size = spriteCfg.size or 32
	local spriteX = x + menuWidth - (spriteCfg.offsetRightX or 12) - size
	local spriteY = (spriteCfg.offsetY ~= nil) and (y + spriteCfg.offsetY) or (y + (itemHeight - size) * 0.5)

	local isEnabled = (self.enabled == nil) and true or self.enabled
	local tint = BaseItem.GetColor(spriteCfg.color, isEnabled, isSelected)
	local tr, tg, tb, ta = tint and tint.r or 255, tint and tint.g or 255, tint and tint.b or 255, tint and tint.a or 255

	Draw.Sprite(dict, name, spriteX, spriteY, size, size, 0.0, tr, tg, tb, ta)
end

-- Alias de compatibilitÃ©
DrawCheckbox = UIMenuCheckbox

return UIMenuCheckbox]]

-- items/checkbox.lua
-- Hérite de BaseItem.
--
-- SYNTAXE UNIFIÉE:
--   UIMenuCheckbox.New(text, checked, description, actions)
--   actions.onChange = function(item) ... end   ← item.checked = true/false
--   actions.onSelect = function(item) ... end   ← appui Entrée (après toggle)

UIMenuCheckbox = setmetatable({}, { __index = BaseItem })
UIMenuCheckbox.__index = UIMenuCheckbox

---@param text        string|nil
---@param checked     boolean|nil
---@param description string|nil
---@param actions     table|nil     { onChange=fn, onSelect=fn }
function UIMenuCheckbox.New(text, checked, description, actions)
    local self = BaseItem.New(UIMenuCheckbox, "checkbox", text, description, true)

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

-- ─── Upvalues ─────────────────────────────────────────────────────────────────
local _cbCfg, _cbMenuW, _cbItemH
local function CheckboxCfg()
    if not _cbCfg then
        _cbCfg   = Config.Checkbox or {}
        _cbMenuW = Config.Header.size.width
        _cbItemH = (Config.Layout and Config.Layout.itemHeight) or 35
    end
    return _cbCfg, _cbMenuW, _cbItemH
end

function UIMenuCheckbox:DrawCustom(x, y, isSelected)
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

    local isEnabled = (self.enabled == nil) and true or self.enabled
    local tint      = BaseItem.GetColor(sp.color, isEnabled, isSelected)
    local tr = tint and tint.r or 255
    local tg = tint and tint.g or 255
    local tb = tint and tint.b or 255
    local ta = tint and tint.a or 255

    Draw.Sprite(dict, name, spriteX, spriteY, size, size, 0.0, tr, tg, tb, ta)
end

DrawCheckbox = UIMenuCheckbox
return UIMenuCheckbox
