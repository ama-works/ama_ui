

-- items/list.lua
-- Hérite de BaseItem.
--
-- SYNTAXE UNIFIÉE:
--   UIMenuList.New(text, items, index, description, enabled, actions)
--   actions.onChange = function(item) ... end   ← item.index / item:GetSelectedItem()
--   actions.onSelect = function(item) ... end   ← appui Entrée

UIMenuList = setmetatable({}, { __index = BaseItem })
UIMenuList.__index = UIMenuList

---@param text        string|nil
---@param items       table|nil
---@param index       number|nil
---@param description string|nil
---@param enabled     boolean|nil
---@param actions     table|nil     { onChange=fn, onSelect=fn }
function UIMenuList.New(text, items, index, description, enabled, actions)
    local self = BaseItem.New(UIMenuList, "list", text, description, enabled)

    self.items         = items or {}
    self.index         = index or 1
    self.OnListChanged = Event.New()

    if actions then
        if type(actions.onSelect) == "function" then
            -- Passe un table simple (cross-resource safe) — pas de refs circulaires
            self.OnActivated.On(function() actions.onSelect({ index = self.index }) end)
        end
        if type(actions.onChange) == "function" then
            -- idx = 2e argument de OnListChanged.Emit(self, self.index, ...)
            self.OnListChanged.On(function(_, idx, _)
                actions.onChange({ index = idx })
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

function UIMenuList:DrawCustom(x, y, isSelected, invW, invH)
    if #self.items == 0 then return end

    local cfg, menuWidth = ListCfg()
    local valueCfg = cfg.value or cfg.text or {}
    local uiCfg    = cfg.ui    or {}

    local isEnabled  = (self.enabled == nil) and true or self.enabled
    local valueColor = BaseItem.GetColor(valueCfg.color, isEnabled, isSelected)

    -- Utilisation des variables pre-calculees de _Recalculate
    local font  = self._font or valueCfg.font or 0
    local size  = self._scale or valueCfg.size or 0.26

    local rawValue   = tostring(self.items[self.index] or "")
    local showArrows = not (uiCfg.onlyOnSelected == true and not isSelected)

    local drawText = showArrows
        and ((uiCfg.left or "←") .. " " .. rawValue .. " " .. (uiCfg.right or "→"))
        or  rawValue

    local nx = self._listValueRightNX or ((x + menuWidth - (valueCfg.offsetRightX or valueCfg.offsetX or 0)) * invW)
    local ny = y * invH + (self._textNYOff or 0)
    Text.DrawRaw(drawText, nx, ny, font, size, valueColor.r or 255, valueColor.g or 255, valueColor.b or 255, valueColor.a or 255, 2, nx)
end

DrawList = UIMenuList
return UIMenuList
