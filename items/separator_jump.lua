-- items/separator_jump.lua
-- Hérite de BaseItem. Separator qui "saute" : la navigation passe dessus sans pouvoir le sélectionner.
-- Affiche optionnellement un label centré.

UIMenuSeparatorJump = setmetatable({}, { __index = BaseItem })
UIMenuSeparatorJump.__index = UIMenuSeparatorJump

local _sepMenuW, _sepLabelFont, _sepLabelSize, _sepLabelColor, _sepLabelOffY
local function SepCfg()
    if not _sepMenuW then
        local C = Config and Config.Separator or {}
        _sepMenuW      = (Config and Config.Header and Config.Header.size and Config.Header.size.width) or 431
        local label    = C.label or {}
        _sepLabelFont  = label.font  or 0
        _sepLabelSize  = label.size  or 0.26
        _sepLabelColor = label.color or { r = 200, g = 200, b = 200, a = 255 }
        _sepLabelOffY  = label.offsetY or 7
    end
end

function UIMenuSeparatorJump.New(text)
    local self = BaseItem.New(UIMenuSeparatorJump, "separator_jump", text, "", false)
    self.isSeparator = true  -- flag pour le skip de navigation
    return self
end

function UIMenuSeparatorJump:DrawCustom(x, y, selected)
    if self.text == "" then return end
    SepCfg()
    Text.Draw(self.text, x + _sepMenuW * 0.5, y + _sepLabelOffY,
        _sepLabelFont, _sepLabelSize, _sepLabelColor, Text.Align.Center)
end

DrawSeparatorJump = UIMenuSeparatorJump

return UIMenuSeparatorJump
