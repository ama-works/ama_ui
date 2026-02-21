-- items/separator_jump.lua
-- Hérite de BaseItem. Separator qui "saute" : la navigation passe dessus sans pouvoir le sélectionner.
-- Affiche optionnellement un label centré.

UIMenuSeparatorJump = setmetatable({}, { __index = BaseItem })
UIMenuSeparatorJump.__index = UIMenuSeparatorJump

function UIMenuSeparatorJump.New(text)
    local self = BaseItem.New(UIMenuSeparatorJump, "separator_jump", text, "", false)
    self.isSeparator = true  -- flag pour le skip de navigation
    return self
end

function UIMenuSeparatorJump:DrawCustom(x, y, selected)
    local C = Config and Config.Separator or {}
    local H = Config and Config.Header or { size = { width = 431 } }
    local menuW = tonumber(H.size and H.size.width) or 431

    -- Ligne horizontale (optionnelle)
    --local line = C.line or {}
    --if line.enabled ~= false then
      ---  local lW = tonumber(line.width) or menuW
        --local lH = tonumber(line.height) or 1
        --local lCol = line.color or { r = 100, g = 100, b = 100, a = 200 }

        --local lX = x + (menuW - lW) * 0.5
        --local lY = y + (38 - lH) * 0.5
       -- Draw.Rect(lX, lY, lW, lH, lCol)
    --end

    -- Label centré (optionnel)
    if self.text ~= "" then
        local label = C.label or {}
        local font  = label.font or 0
        local size  = label.size or 0.26
        local color = label.color or { r = 200, g = 200, b = 200, a = 255 }
        local oY    = label.offsetY or 7

        Text.Draw(
            self.text,
            x + menuW * 0.5,
            y + oY,
            font,
            size,
            color,
            Text.Align.Center
        )
    end
end

DrawSeparatorJump = UIMenuSeparatorJump

return UIMenuSeparatorJump
