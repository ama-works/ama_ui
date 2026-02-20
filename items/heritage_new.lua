--[[UIMenuSliderHeritageItem = {}
UIMenuSliderHeritageItem.__index = UIMenuSliderHeritageItem

function UIMenuSliderHeritageItem.New(text, min, max, value, step)
    local self = setmetatable({
        type = "heritage", text = text or "Heritage",
        min = min or 0, max = max or 100, value = value or 0, step = step or 1,
        OnSliderChanged = Event.New()
    }, UIMenuSliderHeritageItem)
    return self
end

function UIMenuSliderHeritageItem:Next()
    if self.value < self.max then self.value = self.value + self.step; self.OnSliderChanged.Emit(self, self.value) end
end

function UIMenuSliderHeritageItem:Prev()
    if self.value > self.min then self.value = self.value - self.step; self.OnSliderChanged.Emit(self, self.value) end
end

function UIMenuSliderHeritageItem:DrawCustom(x, y, selected)
    local C = Config and Config.Heritage or {}
    local H = Config and Config.Header or {size={width=431}}
    
    -- Dimensions - Force tonumber to avoid type errors
    local icon = tonumber(C.icons and C.icons.size) or 40
    local gap = tonumber(C.icons and C.icons.gap) or 6
    local barW = tonumber(C.bar and C.bar.width) or 120
    local barH = tonumber(C.bar and C.bar.height) or 8
    local menuW = tonumber(H.size and H.size.width) or 431
    local offsetX = tonumber(C.offsetRightX) or 12

    -- Position calculation
    local rightEdge = x + menuW - offsetX
    local barX = rightEdge - icon - gap - barW
    local by = y + (38 - barH) * 0.5

    -- 1. Background
    local barC = C.bar and C.bar.color or {}
    local bg = selected and barC.backgroundSelected or barC.background or {r=0,g=0,b=0,a=100}
    Draw.Rect(barX, by, barW, barH, bg)

    -- 2. Divider (Fixed at center)
    local div = C.divider or {}
    local dW = tonumber(div.width) or 2
    local dH = tonumber(div.height) or 20
    local divC = div.color or {}
    local dCol = selected and divC.selected or divC.default or {r=255,g=255,b=255,a=255}
    
    local halfBar = barW * 0.5
    local divX = barX + halfBar - (dW * 0.5)
    local divY = by + (barH - dH) * 0.5
    Draw.Rect(divX, divY, dW, dH, dCol)

    -- 3. Slider (Movable)
    local sli = C.slider or {}
    local sW = tonumber(sli.width) or 4
    local sH = tonumber(sli.height) or 20
    local sliC = sli.color or {}
    local sCol = selected and sliC.selected or sliC.default or {r=0,g=0,b=255,a=255}
    
    local range = self.max - self.min
    local pct = (range > 0) and ((self.value - self.min) / range) or 0
    
    local slideX = barX + (barW * pct) - (sW * 0.5)
    local slideY = by + (barH - sH) * 0.5
    Draw.Rect(slideX, slideY, sW, sH, sCol)

    -- 4. Icons
    local ics = C.icons or {}
    local dict = ics.dict or "mpleaderboard"
    local iy = y + (38 - icon) * 0.5
    Draw.Sprite(dict, ics.left or "leaderboard_female_icon", barX - gap - icon, iy, icon, icon, 0, 255, 255, 255, 255)
    Draw.Sprite(dict, ics.right or "leaderboard_male_icon", barX + barW + gap, iy, icon, icon, 0, 255, 255, 255, 255)
end

DrawSliderHeritage = UIMenuSliderHeritageItem]]