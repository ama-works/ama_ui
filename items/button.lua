-- items/button.lua
-- Item "bouton" simple — hérite de BaseItem.
-- Sert de bouton d'action ou de lien vers un sous-menu (submenu à implémenter plus tard).
--
-- Usage:
--   local btn = UIMenuButton.New("Mon Bouton", "Description", true, function()
--       print("Bouton activé!")
--   end)
--   menu:AddItem(btn)

--[[UIMenuButton = setmetatable({}, { __index = BaseItem })
UIMenuButton.__index = UIMenuButton

---@param text string|nil         Label du bouton
---@param description string|nil  Description affichée en bas du menu
---@param enabled boolean|nil     true par défaut
---@param callback function|nil   Fonction appelée quand le bouton est activé (Enter)
---@return table  instance UIMenuButton
function UIMenuButton.New(text, description, enabled, callback)
    local self = BaseItem.New(UIMenuButton, "button", text, description, enabled)

    self.submenu = nil -- placeholder pour plus tard (sous-menu)

    if type(callback) == "function" then
        self.OnActivated.On(callback)
    end

    return self
end

-- Pas de DrawCustom() pour l'instant (le label est déjà dessiné par menu.lua)
-- Plus tard: dessiner une flèche "→" à droite si self.submenu ~= nil

-- Alias de compatibilité
DrawButton = UIMenuButton

return UIMenuButton]]


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

DrawButton = UIMenuButton
return UIMenuButton