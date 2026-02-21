-- ============================================================================
-- ui/ui.lua
-- Façade ama_ui
-- ============================================================================
-- API publique simplifiée.
--
-- SYNTAXE :
--   local menu = ama_ui.CreateMenu("Titre", "Sous-titre")
--
--   menu:Button("GodMode", "Active l'invincibilité", {
--       onSelected = function(item) SetPlayerInvincible(PlayerId(), true) end
--   })
--
--   menu:Button("Sous-menu →", "desc", {}, sousMenu)
--
--   menu:Button("NoClip", "desc", { RightLabel = "ON/OFF" }, {
--       onSelected = function(item) ... end
--   })
--
--   menu:Checkbox("NoClip", false, "desc", {
--       onChecked   = function(item) ... end,
--       onUnChecked = function(item) ... end
--   })
--
--   menu:List("Arme", WeaponLabels, 1, "desc", {
--       onListChange = function(item) ... end,
--       onSelected   = function(item) ... end
--   })
--
--   menu:Slider("Armure", 50, 100, "desc", { step = 5 }, {
--       onSliderChange = function(item) ... end
--   })
--
--   menu:Heritage("Visage", 0, 100, 50, 1, "desc", {
--       onSliderChange = function(item) ... end
--   })
--
--   local win = menu:Window(3, 7)
--   win:SetMum(3)
--   win:SetDad(7)
--
--   RegisterCommand("mymenu", function()
--       ama_ui.Visible(menu)
--   end, false)
-- ============================================================================
-- Note : NormalizeActions et toutes les méthodes Menu sont désormais dans
--        core/menu.lua — pas de redéfinition nécessaire ici.
-- ============================================================================

ama_ui = ama_ui or {}

-- ============================================================================
-- CRÉATION DE MENUS
-- ============================================================================

--- Crée un nouveau menu et l'enregistre dans le MenuPool.
---@param title    string
---@param subtitle string
---@param opts     table|nil   { x=number, y=number }
---@return table menu
function ama_ui.CreateMenu(title, subtitle, opts)
    local x = opts and opts.x or nil
    local y = opts and opts.y or nil
    local menu = Menu.New(title, subtitle, x, y)
    MenuPool.Add(menu)
    return menu
end

--- Crée un sous-menu lié à un menu parent.
---@param parent   table
---@param title    string
---@param subtitle string
---@param opts     table|nil   { x=number, y=number }
---@return table sous-menu
function ama_ui.CreateSubMenu(parent, title, subtitle, opts)
    local sub = ama_ui.CreateMenu(title, subtitle, opts)
    sub.parentMenu = parent
    return sub
end

-- ============================================================================
-- VISIBILITÉ
-- ============================================================================

--- Toggle / ouvre / ferme un menu.
---   ama_ui.Visible(menu)        → toggle
---   ama_ui.Visible(menu, true)  → forcer ouvert
---   ama_ui.Visible(menu, false) → forcer fermé
---@param menu  table
---@param state boolean|nil
function ama_ui.Visible(menu, state)
    if state == nil then
        menu:Toggle()
    elseif state then
        if not menu.visible then menu:Open() end
    else
        if menu.visible then menu:Close() end
    end
end

--- Retourne true si le menu est visible.
---@param menu table
---@return boolean
function ama_ui.IsVisible(menu)
    return menu ~= nil and menu.visible == true
end

-- ============================================================================
-- READY
-- ============================================================================

print("^2[ama_ui] Façade chargée^7")
