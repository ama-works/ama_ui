-- items/button.lua
-- Item "bouton" simple — hérite de BaseItem.
-- Sert de bouton d'action ou de lien vers un sous-menu (submenu à implémenter plus tard).
--
-- Usage:
--   local btn = UIMenuButton.New("Mon Bouton", "Description", true, function()
--       print("Bouton activé!")
--   end)
--   menu:AddItem(btn)

-- Pas de DrawCustom() pour l'instant (le label est déjà dessiné par menu.lua)
-- Plus tard: dessiner une flèche "→" à droite si self.submenu ~= nil

-- Alias de compatibilité
--DrawButton = UIMenuButton

--return UIMenuButton]]


-- items/button.lua
-- Hérite de BaseItem.
--
-- SYNTAXE UNIFIÉE:
--   UIMenuButton.New(text, description, enabled, actions)
--   actions.onSelect = function(item) ... end

UIMenuButton = setmetatable({}, { __index = BaseItem })
UIMenuButton.__index = UIMenuButton

---@param text        string|nil
---@param description string|nil
---@param enabled     boolean|nil   true par défaut
---@param actions     table|nil     { onSelect = function(item) end }
function UIMenuButton.New(text, description, enabled, actions)
    local self = BaseItem.New(UIMenuButton, "button", text, description, enabled)

    self.submenu = nil

    if actions then
        if type(actions.onSelect) == "function" then
            self.OnActivated.On(function() actions.onSelect(self) end)
        end
        -- Rétrocompat: ancien pattern callback direct (function seul)
    elseif type(actions) == "function" then
        self.OnActivated.On(function() actions(self) end)
    end

    return self
end

--- Dessine les badges et le rightLabel (appelé par menu.lua après le label standard)
---@param x          number   coin gauche du menu (px)
---@param y          number   coin haut de l'item (px)
---@param isSelected boolean
---@param invW       number   1/screenWidth
---@param invH       number   1/screenHeight
function UIMenuButton:DrawCustom(_x, y, isSelected, invW, invH)
    if not self.rightBadge and not self.leftBadge and not self.rightLabel then return end
    if not invW or not invH then invW, invH = Draw.GetInvScale() end

    local isEnabled = (self.enabled == nil) and true or self.enabled
    local badgeY    = y * invH + (self._badgeNYOff or 0)

    -- ─── Left Badge ──────────────────────────────────────────────────────────
    if self.leftBadge and self._badgeLeftNX then
        local bd = type(self.leftBadge) == "function" and self.leftBadge(isSelected) or nil
        if bd and bd.texture and bd.texture ~= "" then
            local c = bd.color
            Draw.SpriteRaw(bd.dict, bd.texture,
                self._badgeLeftNX, badgeY, self._badgeNW, self._badgeNH,
                0.0, c.r, c.g, c.b, c.a)
        end
    end

    -- ─── Right Badge ─────────────────────────────────────────────────────────
    if self.rightBadge and self._badgeRightNX then
        local bd = type(self.rightBadge) == "function" and self.rightBadge(isSelected) or nil
        if bd and bd.texture and bd.texture ~= "" then
            local c = bd.color
            Draw.SpriteRaw(bd.dict, bd.texture,
                self._badgeRightNX, badgeY, self._badgeNW, self._badgeNH,
                0.0, c.r, c.g, c.b, c.a)
        end
    end

    -- ─── Right Label ─────────────────────────────────────────────────────────
    if self.rightLabel and self._rlNX then
        local lCfg    = (Config.Button and Config.Button.label) or {}
        local colorSet = lCfg.color or {}
        local col = isSelected and colorSet.selected
               or  (isEnabled  and colorSet.default)
               or  colorSet.disabled
               or  { r=245, g=242, b=242, a=255 }
        Text.DrawRaw(tostring(self.rightLabel), self._rlNX,
            y * invH + (self._textNYOff or 0),
            lCfg.font or 0, lCfg.size or 0.26,
            col.r, col.g, col.b, col.a, 2)
    end
end

DrawButton = UIMenuButton
return UIMenuButton