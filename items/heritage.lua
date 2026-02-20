-- items/heritage.lua
-- Hérite de BaseItem. Slider "héritage" avec icônes female/male et fill-from-center.

local ITEM_HEIGHT = (Config.Layout and Config.Layout.itemHeight) or 35

local function GetItemHeight()
    return (Config.Layout and Config.Layout.itemHeight) or 35
end
-- Puis remplacer ITEM_HEIGHT par GetItemHeight() dans DrawCustom
-- OU: utiliser le même pattern upvalue que les autres items
local _heriCfg, _heriItemH
local function HeriCfg()
    if not _heriCfg then
        _heriCfg   = Config.Heritage or {}
        _heriItemH = (Config.Layout and Config.Layout.itemHeight) or 35
    end
    return _heriCfg, _heriItemH
end

UIMenuSliderHeritageItem = setmetatable({}, { __index = BaseItem })
UIMenuSliderHeritageItem.__index = UIMenuSliderHeritageItem

---@param text string|nil
---@param min number|nil
---@param max number|nil
---@param value number|nil
---@param step number|nil
---@param description string|nil
---@param style table|nil
---@param enabled boolean|nil
---@param actions table|nil
function UIMenuSliderHeritageItem.New(text, min, max, value, step, description, style, enabled, actions)
    local self = BaseItem.New(UIMenuSliderHeritageItem, "heritage", text, description, enabled)

    self.min = min or 0
    self.max = max or 100
    self.value = value or 0
    self.style = style or { step = step or 1 }
    if not self.style.step then self.style.step = step or 1 end

    self.OnSliderChanged = Event.New()

    if actions then
        if type(actions.onSelected) == "function" then
            self.OnActivated.On(function()
                actions.onSelected(self, self.value, self.max)
            end)
        end
        if type(actions.onChange) == "function" then
            self.OnSliderChanged.On(function(_, val)
                actions.onChange(self, val)
            end)
        end
    end

    return self
end

-- Next, Prev, SetValue, SetMax, GetStep → hérités de BaseItem

function UIMenuSliderHeritageItem:DrawCustom(x, y, selected)
    local C = Config and Config.Heritage or {}
    local H = Config and Config.Header or {size={width=431}}

    local isEnabled = (self.enabled == nil) and true or self.enabled

    -- Dimensions
    local icon = tonumber(C.icons and C.icons.size) or 20
    local gap  = tonumber(C.icons and C.icons.gap)  or 6
    local barW = tonumber(C.bar and C.bar.width)     or 120
    local barH = tonumber(C.bar and C.bar.height)    or 8
    local menuW   = tonumber(H.size and H.size.width) or 431
    local offsetX = tonumber(C.offsetRightX) or 12

    -- Position (right-aligned inside menu)
    local rightEdge = x + menuW - offsetX
    local barX = rightEdge - icon - gap - barW
    local by   = y + (ITEM_HEIGHT - barH) * 0.5

    -- 1. Background bar (ZERO-ALLOC)
    local barC = C.bar and C.bar.color or {}
    local bg = BaseItem.ResolveColor(barC.background, barC.backgroundSelected, barC.backgroundDisabled, isEnabled, selected)
    if not bg then bg = {r=93,g=182,b=229,a=255} end
    Draw.Rect(barX, by, barW, barH, bg)

    -- 2. Fill from center
    local range    = self.max - self.min
    local centerVal = (C.bar and C.bar.centerValue) or ((self.min + self.max) * 0.5)
    local pct       = (range > 0) and ((self.value  - self.min) / range) or 0
    local centerPct = (range > 0) and ((centerVal   - self.min) / range) or 0.5

    local centerPx = barX + barW * centerPct
    local valuePx  = barX + barW * pct

    local fillX, fillW
    if valuePx >= centerPx then
        fillX = centerPx
        fillW = valuePx - centerPx
    else
        fillX = valuePx
        fillW = centerPx - valuePx
    end

    if fillW > 0 then
        local fCol = BaseItem.ResolveColor(barC.fill, barC.fillSelected, barC.fillDisabled, isEnabled, selected)
        if not fCol then fCol = {r=57,g=119,b=200,a=255} end
        Draw.Rect(fillX, by, fillW, barH, fCol)
    end

    -- 3. Divider (FIXED at center, drawn on top)
    local div  = C.divider or {}
    local dW   = tonumber(div.width)  or 2
    local dH   = tonumber(div.height) or 20
    local dCol = BaseItem.GetColor(div.color, isEnabled, selected) or {r=0,g=0,b=0,a=255}

    local halfBar = barW * 0.5
    local centerX = barX + halfBar
    local divX = centerX - (dW * 0.5)
    local divY = by + (barH - dH) * 0.5
    Draw.Rect(divX, divY, dW, dH, dCol)

    -- 4. Icons (couleurs séparées female / male, ZERO-ALLOC)
    local ics  = C.icons or {}
    local dict = ics.dict or "mpleaderboard"
    local icC  = ics.color or {}
    local fC   = icC.female or {}
    local mC   = icC.male   or {}
    local _defaultWhite = {r=255,g=255,b=255,a=255}
    local fCol = (selected and fC.selected or fC.default) or _defaultWhite
    local mCol = (selected and mC.selected or mC.default) or _defaultWhite
    local iy   = y + (ITEM_HEIGHT - icon) * 0.5
    Draw.Sprite(dict, ics.left  or "leaderboard_female_icon", barX - gap - icon, iy, icon, icon, 0, fCol.r, fCol.g, fCol.b, fCol.a)
    Draw.Sprite(dict, ics.right or "leaderboard_male_icon",   barX + barW + gap,  iy, icon, icon, 0, mCol.r, mCol.g, mCol.b, mCol.a)
end

-- Alias de compatibilité
DrawSliderHeritage = UIMenuSliderHeritageItem