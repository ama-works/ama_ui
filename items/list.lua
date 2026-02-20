-- items/list.lua
-- Hérite de BaseItem. Liste avec flèches gauche/droite et valeur texte.

--[[UIMenuList = setmetatable({}, { __index = BaseItem })
UIMenuList.__index = UIMenuList

function UIMenuList.New(text, items, index, description)
	local self = BaseItem.New(UIMenuList, "list", text, description, true)

	self.items = items or {}
	self.index = index or 1
	self.OnListChanged = Event.New()

	return self
end

-- SetEnabled() hérité de BaseItem (avec auto-dirty)

function UIMenuList:SetItems(items)
	self.items = items or {}
	self.index = math.min(self.index, #self.items)
end

function UIMenuList:SetIndex(index)
	if #self.items == 0 then return end
	local clamped = math.max(1, math.min(index, #self.items))
	if clamped ~= self.index then
		self.index = clamped
		self._cachedCaption = nil
		self._cachedWidth = nil
		self.OnListChanged.Emit(self, self.index, self:GetSelectedItem())
	end
end

function UIMenuList:Next()
	if #self.items == 0 then return end
	local nextIndex = self.index + 1
	if nextIndex > #self.items then
		nextIndex = 1
	end
	self:SetIndex(nextIndex)
end

function UIMenuList:Prev()
	if #self.items == 0 then return end
	local prevIndex = self.index - 1
	if prevIndex < 1 then
		prevIndex = #self.items
	end
	self:SetIndex(prevIndex)
end

function UIMenuList:GetSelectedItem()
	if #self.items == 0 then return nil end
	return self.items[self.index]
end

-- Upvalues: évite les lookups Config répétés par frame
local _listCfg, _listMenuW

local function ListCfg()
	if not _listCfg then
		_listCfg  = Config.List or {}
		_listMenuW = Config.Header.size.width
	end
	return _listCfg, _listMenuW
end

function UIMenuList:DrawCustom(x, y, isSelected)
	if #self.items == 0 then return end

	local cfg, menuWidth = ListCfg()
	local valueCfg = cfg.value or cfg.text or {}
	local uiCfg = cfg.ui or {}
	local labelCfg = cfg.label or {}

	local isEnabled = (self.enabled == nil) and true or self.enabled
	local valueColor = BaseItem.GetColor(valueCfg.color, isEnabled, isSelected)

	local valueRightX = x + menuWidth - (valueCfg.offsetRightX or valueCfg.offsetX or 0)
	local textY = y + (valueCfg.offsetY or labelCfg.offsetY or 0)

	local rawValue = tostring(self.items[self.index] or "")

	-- Ellipsize la valeur seule (pour garder les flèches visibles)
	local font = valueCfg.font or 0
	local size = valueCfg.size or 0.26

	local showArrows = not (uiCfg.onlyOnSelected == true and not isSelected)
	local maxRawWidth
	if showArrows and self._listRawMaxWidthWithArrows ~= nil then
		maxRawWidth = self._listRawMaxWidthWithArrows
	elseif (not showArrows) and self._listRawMaxWidthNoArrows ~= nil then
		maxRawWidth = self._listRawMaxWidthNoArrows
	else
		-- Fallback: dynamic right column width (~33% menu)
		local valueColumnWidth = math.floor(menuWidth * 0.33)
		if showArrows then
			local left = uiCfg.left or "←"
			local right = uiCfg.right or "→"
			local arrowsWidth = Text.GetWidth(left .. "  " .. right, font, size)
			maxRawWidth = math.max(0, valueColumnWidth - arrowsWidth)
		else
			maxRawWidth = valueColumnWidth
		end
	end

	if maxRawWidth and maxRawWidth > 0 then
		rawValue = Text.Ellipsize(rawValue, maxRawWidth, font, size)
	end

	local drawText
	if showArrows then
		local left = uiCfg.left or "←"
		local right = uiCfg.right or "→"
		drawText = string.format("%s %s %s", left, rawValue, right)
	else
		drawText = rawValue
	end

	Text.Draw(
		drawText,
		valueRightX,
		textY,
		font,
		size,
		valueColor,
		Text.Align.Right
	)
end

-- Alias explicite
DrawList = UIMenuList

return UIMenuList]]

-- items/list.lua
-- Hérite de BaseItem.
--
-- SYNTAXE UNIFIÉE:
--   UIMenuList.New(text, items, index, description, actions)
--   actions.onChange = function(item) ... end   ← item.index / item:GetSelectedItem()
--   actions.onSelect = function(item) ... end   ← appui Entrée

UIMenuList = setmetatable({}, { __index = BaseItem })
UIMenuList.__index = UIMenuList

---@param text        string|nil
---@param items       table|nil
---@param index       number|nil
---@param description string|nil
---@param actions     table|nil     { onChange=fn, onSelect=fn }
function UIMenuList.New(text, items, index, description, actions)
    local self = BaseItem.New(UIMenuList, "list", text, description, true)

    self.items         = items or {}
    self.index         = index or 1
    self.OnListChanged = Event.New()

    if actions then
        if type(actions.onSelect) == "function" then
            self.OnActivated.On(function() actions.onSelect(self) end)
        end
        if type(actions.onChange) == "function" then
            self.OnListChanged.On(function(it, _, _)
                actions.onChange(it)
            end)
        end
    end

    return self
end

-- ─── Navigation ───────────────────────────────────────────────────────────────

function UIMenuList:SetItems(items)
    self.items = items or {}
    self.index = math.min(self.index, math.max(1, #self.items))
end

function UIMenuList:SetIndex(index)
    if #self.items == 0 then return end
    local clamped = math.max(1, math.min(index, #self.items))
    if clamped ~= self.index then
        self.index          = clamped
        self._cachedCaption = nil
        self._cachedWidth   = nil
        self.OnListChanged.Emit(self, self.index, self:GetSelectedItem())
        if self.parent then self.parent._dirty = true end
    end
end

function UIMenuList:Next()
    if #self.items == 0 then return end
    self:SetIndex(self.index < #self.items and self.index + 1 or 1)
end

function UIMenuList:Prev()
    if #self.items == 0 then return end
    self:SetIndex(self.index > 1 and self.index - 1 or #self.items)
end

function UIMenuList:GetSelectedItem()
    if #self.items == 0 then return nil end
    return self.items[self.index]
end

-- ─── Upvalues ─────────────────────────────────────────────────────────────────
local _listCfg, _listMenuW
local function ListCfg()
    if not _listCfg then
        _listCfg   = Config.List or {}
        _listMenuW = Config.Header.size.width
    end
    return _listCfg, _listMenuW
end

-- ─── Dessin ───────────────────────────────────────────────────────────────────

function UIMenuList:DrawCustom(x, y, isSelected)
    if #self.items == 0 then return end

    local cfg, menuWidth = ListCfg()
    local valueCfg = cfg.value or cfg.text or {}
    local uiCfg    = cfg.ui    or {}
    local labelCfg = cfg.label or {}

    local isEnabled  = (self.enabled == nil) and true or self.enabled
    local valueColor = BaseItem.GetColor(valueCfg.color, isEnabled, isSelected)

    local valueRightX = x + menuWidth - (valueCfg.offsetRightX or valueCfg.offsetX or 0)
    local textY       = y + (valueCfg.offsetY or labelCfg.offsetY or 0)
    local font        = valueCfg.font or 0
    local size        = valueCfg.size or 0.26

    local rawValue   = tostring(self.items[self.index] or "")
    local showArrows = not (uiCfg.onlyOnSelected == true and not isSelected)

    local maxRawWidth
    if showArrows and self._listRawMaxWidthWithArrows ~= nil then
        maxRawWidth = self._listRawMaxWidthWithArrows
    elseif (not showArrows) and self._listRawMaxWidthNoArrows ~= nil then
        maxRawWidth = self._listRawMaxWidthNoArrows
    else
        local colW = math.floor(menuWidth * 0.33)
        if showArrows then
            local arrowsW = Text.GetWidth((uiCfg.left or "←") .. "  " .. (uiCfg.right or "→"), font, size)
            maxRawWidth = math.max(0, colW - arrowsW)
        else
            maxRawWidth = colW
        end
    end

    if maxRawWidth and maxRawWidth > 0 then
        rawValue = Text.Ellipsize(rawValue, maxRawWidth, font, size)
    end

    local drawText = showArrows
        and string.format("%s %s %s", uiCfg.left or "←", rawValue, uiCfg.right or "→")
        or  rawValue

    Text.Draw(drawText, valueRightX, textY, font, size, valueColor, Text.Align.Right)
end

DrawList = UIMenuList
return UIMenuList
