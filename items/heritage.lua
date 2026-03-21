-- items/heritage.lua
-- Herite de BaseItem. Slider "heritage" avec icones female/male et fill-from-center.

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
---@param description string|nil
---@param enabled boolean|nil
---@param actions table|nil   { step=number, onSelect=fn, onChange=fn }
function UIMenuSliderHeritageItem.New(text, min, max, value, description, enabled, actions)
    local self = BaseItem.New(UIMenuSliderHeritageItem, "heritage", text, description, enabled)

    self.min   = min   or 0
    self.max   = max   or 100
    self.value = value or 0
    self._step = (actions and tonumber(actions.step)) or 1

    self.OnProgressChanged = Event.New()

    if actions then
        if type(actions.onSelect) == "function" then
            self.OnActivated.On(function()
                actions.onSelect(self, self.value, self.max)
            end)
        end
        if type(actions.onChange) == "function" then
            self.OnProgressChanged.On(function(_, val)
                actions.onChange(self, val)
            end)
        end
    end

    return self
end

-- Next, Prev, SetValue, SetMax, GetStep → hérités de BaseItem

---@param x          number
---@param y          number
---@param selected   boolean
---@param invW       number|nil  1/resW pre-calcule
---@param invH       number|nil  1/resH pre-calcule
function UIMenuSliderHeritageItem:DrawCustom(x, y, selected, invW, invH)
    if not invW or not invH then
        invW, invH = Draw.GetInvScale()
    end

    local isEnabled = (self.enabled == nil) and true or self.enabled

    -- Chemin optimise : valeurs pre-calculees dans _Recalculate
    if self._hBarNX then
        local barNY = y * invH + self._hBarNYOff

        -- 1. Fond barre
        Draw.RectRaw(self._hBarNX, barNY, self._hBarNW, self._hBarNH,
            self._hBarBgR, self._hBarBgG, self._hBarBgB, self._hBarBgA)

        -- 2. Fill from center
        local range     = self.max - self.min
        local centerVal = self._hCenterVal or ((self.min + self.max) * 0.5)
        local pct       = (range > 0) and ((self.value  - self.min) / range) or 0
        local centerPct = (range > 0) and ((centerVal   - self.min) / range) or 0.5
        if pct     < 0 then pct     = 0 elseif pct     > 1 then pct     = 1 end
        if centerPct < 0 then centerPct = 0 elseif centerPct > 1 then centerPct = 1 end

        -- Conversion en coordonnees normalisees depuis les extremes de la barre
        local barLeft  = self._hBarNX - self._hBarNW * 0.5
        local centerNX = barLeft + self._hBarNW * centerPct
        local valueNX  = barLeft + self._hBarNW * pct

        local fillNX, fillNW
        if valueNX >= centerNX then
            fillNW = valueNX - centerNX
            fillNX = centerNX + fillNW * 0.5
        else
            fillNW = centerNX - valueNX
            fillNX = valueNX  + fillNW * 0.5
        end

        if fillNW > 0 then
            Draw.RectRaw(fillNX, barNY, fillNW, self._hBarNH,
                self._hBarFiR, self._hBarFiG, self._hBarFiB, self._hBarFiA)
        end

        -- 3. Divider (centre fixe)
        local divNY = y * invH + self._hDivNYOff
        local divR, divG, divB, divA
        if selected then
            divR, divG, divB, divA = self._hDivSelR, self._hDivSelG, self._hDivSelB, self._hDivSelA
        else
            divR, divG, divB, divA = self._hDivDefR, self._hDivDefG, self._hDivDefB, self._hDivDefA
        end
        local divCenterNX = self._hBarNX  -- centre de la barre = centre du diviseur
        Draw.RectRaw(divCenterNX, divNY, self._hDivNW, self._hDivNH, divR, divG, divB, divA)

        -- 4. Icones female/male
        local iconNY = y * invH + self._hIconNYOff
        local fR, fG, fB, fA, mR, mG, mB, mA
        if selected then
            fR, fG, fB, fA = self._hFemSelR, self._hFemSelG, self._hFemSelB, self._hFemSelA
            mR, mG, mB, mA = self._hMalSelR, self._hMalSelG, self._hMalSelB, self._hMalSelA
        else
            fR, fG, fB, fA = self._hFemDefR, self._hFemDefG, self._hFemDefB, self._hFemDefA
            mR, mG, mB, mA = self._hMalDefR, self._hMalDefG, self._hMalDefB, self._hMalDefA
        end
        Draw.SpriteRaw(self._hIconDict, self._hIconLeft,
            self._hIconLeftNX,  iconNY, self._hIconNW, self._hIconNH, 0.0, fR, fG, fB, fA)
        Draw.SpriteRaw(self._hIconDict, self._hIconRight,
            self._hIconRightNX, iconNY, self._hIconNW, self._hIconNH, 0.0, mR, mG, mB, mA)
        return
    end

    -- Fallback non-optimise (avant premier _Recalculate)
    local C, itemHeight = HeriCfg()
    local H = Config and Config.Header or {size={width=431}}

    local icon  = tonumber(C.icons and C.icons.size) or 20
    local gap   = tonumber(C.icons and C.icons.gap)  or 6
    local barW  = tonumber(C.bar and C.bar.width)     or 120
    local barH  = tonumber(C.bar and C.bar.height)    or 8
    local menuW = tonumber(H.size and H.size.width)   or 431
    local offsetX = tonumber(C.offsetRightX) or 12

    local rightEdge = x + menuW - offsetX
    local barX = rightEdge - icon - gap - barW
    local by   = y + (itemHeight - barH) * 0.5

    local barC = C.bar and C.bar.color or {}
    local bg   = BaseItem.ResolveColor(barC.background, barC.backgroundSelected, barC.backgroundDisabled, isEnabled, selected)
    if not bg then bg = {r=93,g=182,b=229,a=255} end
    Draw.Rect(barX, by, barW, barH, bg)

    local range     = self.max - self.min
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

    local div  = C.divider or {}
    local dW   = tonumber(div.width)  or 2
    local dH   = tonumber(div.height) or 20
    local dCol = BaseItem.GetColor(div.color, isEnabled, selected) or {r=0,g=0,b=0,a=255}
    local centerX = barX + barW * 0.5
    local divX = centerX - (dW * 0.5)
    local divY = by + (barH - dH) * 0.5
    Draw.Rect(divX, divY, dW, dH, dCol)

    local ics  = C.icons or {}
    local dict = ics.dict or "mpleaderboard"
    local icC  = ics.color or {}
    local fC   = icC.female or {}
    local mC   = icC.male   or {}
    local _defaultWhite = {r=255,g=255,b=255,a=255}
    local fColT = (selected and fC.selected or fC.default) or _defaultWhite
    local mColT = (selected and mC.selected or mC.default) or _defaultWhite
    local iy = y + (itemHeight - icon) * 0.5
    Draw.Sprite(dict, ics.left  or "leaderboard_female_icon", barX - gap - icon, iy, icon, icon, 0, fColT.r, fColT.g, fColT.b, fColT.a)
    Draw.Sprite(dict, ics.right or "leaderboard_male_icon",   barX + barW + gap,  iy, icon, icon, 0, mColT.r, mColT.g, mColT.b, mColT.a)
end

-- Alias de compatibilité
DrawSliderHeritage = UIMenuSliderHeritageItem
