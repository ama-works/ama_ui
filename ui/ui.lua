-- ============================================================================
-- ui/ui.lua
-- Façade ama_ui pour api_nativeui
-- ============================================================================
-- API publique simplifiée, inspirée de RageUI mais sans ses anti-patterns.
--
-- PRINCIPES :
--   • Les items sont créés une seule fois (pas recréés chaque frame)
--   • Pas de boucle while manuelle, pas de Citizen.Wait — géré par MenuPool
--   • Callbacks nommés clairs : onSelected, onListChange, onSliderChange,
--     onChecked, onUnChecked  (traduits en interne vers onSelect / onChange)
--   • RightLabel supporté dans les options Button (compat RageUI)
--   • Sous-menu bindé directement via 4e paramètre de Button
--
-- USAGE RAPIDE :
--   local menu = ama_ui.CreateMenu("Titre", "Sous-titre")
--
--   menu:Button("GodMode", "Active l'invincibilité", {
--       onSelected = function(item) SetPlayerInvincible(PlayerId(), true) end
--   })
--
--   menu:Checkbox("NoClip", false, "", {
--       onChecked   = function(item) EnableNoClip(true)  end,
--       onUnChecked = function(item) EnableNoClip(false) end
--   })
--
--   RegisterCommand("mymenu", function()
--       ama_ui.Visible(menu)    -- toggle (ouvre/ferme)
--   end, false)
-- ============================================================================

ama_ui = ama_ui or {}

-- ============================================================================
-- [1] NORMALISATION DES CALLBACKS
-- Traduit les noms ama_ui → noms API interne (onSelect / onChange)
-- ============================================================================

---@param actions table|nil
---@return table|nil
local function NormalizeActions(actions)
    if not actions or type(actions) ~= "table" then return actions end

    local n = {}

    -- onSelected → onSelect (Button, List, SliderProgress, Heritage)
    if type(actions.onSelected) == "function" then
        n.onSelect = actions.onSelected
    elseif type(actions.onSelect) == "function" then
        n.onSelect = actions.onSelect
    end

    -- Priorité onChange : onListChange > onSliderChange > onChange
    if type(actions.onListChange) == "function" then
        n.onChange = actions.onListChange

    elseif type(actions.onSliderChange) == "function" then
        n.onChange = actions.onSliderChange

    elseif type(actions.onChange) == "function" then
        n.onChange = actions.onChange

    -- onChecked / onUnChecked → onChange (Checkbox)
    elseif actions.onChecked or actions.onUnChecked then
        local cbChecked   = actions.onChecked
        local cbUnChecked = actions.onUnChecked
        n.onChange = function(item)
            if item.checked and type(cbChecked) == "function" then
                cbChecked(item)
            elseif not item.checked and type(cbUnChecked) == "function" then
                cbUnChecked(item)
            end
        end
    end

    return n
end

-- ============================================================================
-- [2] CRÉATION DE MENUS
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
--- La navigation "retour" est gérée automatiquement.
---@param parent   table  Menu parent
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
-- [3] VISIBILITÉ
-- ============================================================================

--- Ouvre, ferme ou bascule la visibilité d'un menu.
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

--- Retourne true si le menu est actuellement visible.
---@param menu table
---@return boolean
function ama_ui.IsVisible(menu)
    return menu ~= nil and menu.visible == true
end

-- ============================================================================
-- [4] ITEMS — Surcharges Menu:
-- Chaque surcharge adapte la signature ama_ui vers l'API interne,
-- normalise les callbacks, et ajoute les fonctionnalités façade.
-- ============================================================================

-- ─── Button ──────────────────────────────────────────────────────────────────
-- Signature ama_ui  : menu:Button(label, description, actions)
-- Avec RightLabel   : menu:Button(label, description, {RightLabel="..."}, actions)
-- Avec sous-menu    : menu:Button(label, description, actions, submenu)
-- API interne       : Menu:Button(text, description, enabled, actions)

local _Button = Menu.Button

function Menu:Button(label, description, optsOrActions, extra)
    local actions   = optsOrActions
    local submenu   = extra
    local rightLabel = nil

    -- Cas { RightLabel = "..." } en 3e paramètre (compat RageUI)
    if type(optsOrActions) == "table" and optsOrActions.RightLabel ~= nil then
        rightLabel = optsOrActions.RightLabel
        actions  = extra   -- les actions sont passées en 4e
        submenu  = nil

    -- Cas sous-menu direct en 4e paramètre (sans RightLabel)
    elseif type(extra) == "table" and extra.id ~= nil then
        actions = optsOrActions
        submenu = extra
    end

    local item = _Button(self, label, description, true, NormalizeActions(actions))

    if rightLabel then
        item.rightLabel = rightLabel
    end

    if submenu and submenu.id then
        self:BindSubmenu(item, submenu)
    end

    return item
end

-- ─── Checkbox ────────────────────────────────────────────────────────────────
-- Signature ama_ui  : menu:Checkbox(label, checked, description, actions)
-- API interne       : Menu:Checkbox(text, checked, description, actions)
-- (identique — on normalise onChecked/onUnChecked → onChange)

local _Checkbox = Menu.Checkbox

function Menu:Checkbox(label, checked, description, actions)
    return _Checkbox(self, label, checked, description, NormalizeActions(actions))
end

-- ─── List ────────────────────────────────────────────────────────────────────
-- Signature ama_ui  : menu:List(label, {valeurs}, index, description, actions)
-- API interne       : Menu:List(text, items, index, description, actions)
-- (identique — on normalise onListChange → onChange)

local _List = Menu.List

function Menu:List(label, items, index, description, actions)
    return _List(self, label, items, index, description, NormalizeActions(actions))
end

-- ─── Slider ──────────────────────────────────────────────────────────────────
-- Alias simplifié de SliderProgress.
-- Signature ama_ui  : menu:Slider(label, value, max, description, style, actions)
-- API interne       : menu:SliderProgress(text, start, max, desc, style, enabled, actions)

function Menu:Slider(label, value, max, description, style, actions)
    return self:SliderProgress(label, value, max, description, style, true, NormalizeActions(actions))
end

-- ─── Heritage ────────────────────────────────────────────────────────────────
-- Signature ama_ui  : menu:Heritage(label, min, max, value, step, description, actions)
-- API interne       : Menu:Heritage(text, min, max, value, step, desc, style, enabled, actions)

local _Heritage = Menu.Heritage

function Menu:Heritage(label, min, max, value, step, description, actions)
    return _Heritage(self, label, min, max, value, step, description, nil, true, NormalizeActions(actions))
end




-- ============================================================================
-- [5] READY
-- ============================================================================

print("^2[ama_ui] Façade chargée^7")
