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
-- REGISTRY — lookups cross-resource pour Visible/IsVisible
-- ============================================================================
-- Stocke id → real menu. Permet à Visible/IsVisible de retrouver le vrai menu
-- même si le proxy est sérialisé par FiveM lors d'un appel cross-resource.
local _menuRegistry = {}

-- ============================================================================
-- HELPERS — proxy pour les objets retournés via exports cross-resource
-- ============================================================================
-- FiveM sérialise les tables retournées par exports via MsgPack.
-- Les metatables sont strippées → menu:Window() serait nil depuis une autre resource.
-- Solution : exposer les méthodes comme propriétés DIRECTES (survivent comme
-- __cfx_functionReference), bound sur le vrai objet via closure.

-- Proxy pour UIMenuWindowHeritageItem (retourné par menu:Window())
local function _makeWinProxy(win)
    local w = win
    return {
        SetMum   = function(_, idx)    w:SetMum(idx)     end,
        SetDad   = function(_, idx)    w:SetDad(idx)     end,
        heritage = function(_, mu, da) w:heritage(mu, da) end,
    }
end

-- Proxy pour UIMenuList (retourné par menu:List())
-- Expose les méthodes de mutation utilisables cross-resource
local function _makeListProxy(item)
    local it = item
    if not it then return nil end
    return {
        SetIndex = function(_, idx)   it:SetIndex(idx)   end,
        SetItems = function(_, items) it:SetItems(items)  end,
        SetLabel = function(_, lbl)   it:SetLabel(lbl)    end,
    }
end

-- ============================================================================
-- CRÉATION DE MENUS
-- ============================================================================

--- Crée un nouveau menu et l'enregistre dans le MenuPool.
--- Retourne un proxy avec méthodes directes pour compatibilité cross-resource.
---@param title    string
---@param subtitle string
---@param opts     table|nil   { x=number, y=number }
---@return table proxy
function ama_ui.CreateMenu(title, subtitle, opts)
    local x = opts and opts.x or nil
    local y = opts and opts.y or nil
    local menu = Menu.New(title, subtitle, x, y)
    MenuPool.Add(menu)
    _menuRegistry[menu.id] = menu

    -- Proxy : bound methods capturent 'm' (le vrai menu dans le contexte ama_ui).
    -- Les fonctions directes dans la table survivent à la sérialisation MsgPack
    -- sous forme de __cfx_functionReference appelables depuis d'autres resources.
    -- Le premier argument '_' est l'objet sérialisé passé par l'appelant (self),
    -- ignoré car 'm' est toujours le vrai menu.
    local m = menu
    local proxy = { id = menu.id }

    -- Items
    proxy.Window         = function(_, mu, da) return _makeWinProxy(Menu.Window(m, mu, da)) end
    proxy.Button         = function(_, ...)    return Menu.Button(m, ...)          end
    proxy.List           = function(_, ...)    return _makeListProxy(Menu.List(m, ...)) end
    proxy.Checkbox       = function(_, ...)    return Menu.Checkbox(m, ...)        end
    proxy.Slider         = function(_, ...)    return Menu.Slider(m, ...)          end
    proxy.SliderProgress = function(_, ...)    return Menu.SliderProgress(m, ...)  end
    proxy.Heritage       = function(_, ...)    return Menu.Heritage(m, ...)        end
    proxy.Separator      = function(_, ...)    return Menu.Separator(m, ...)       end
    proxy.Progress       = function(_, ...)    return Menu.Progress(m, ...)        end
    proxy.SetPanels      = function(_, ...)    return Menu.SetPanels(m, ...)       end
    proxy.AddItem        = function(_, ...)    return Menu.AddItem(m, ...)         end
    proxy.Refresh        = function(_)         return Menu.Refresh(m)              end

    -- Contrôle visibilité
    proxy.Open   = function() m:Open()   end
    proxy.Close  = function() m:Close()  end
    proxy.Toggle = function() m:Toggle() end

    -- Souscription aux événements (cross-resource safe — callbacks stockés comme cfx refs)
    -- IMPORTANT: utiliser .On(cb) et non :On(cb) — Event.On() capture 'self' par upvalue,
    -- le colon passerait l'Event lui-même comme 1er arg et ignorerait cb.
    proxy.OnClose      = function(_, cb) m.OnMenuClosed.On(cb) end
    proxy.OnItemSelect = function(_, cb) m.OnItemSelect.On(cb) end
    proxy.OnNavChange  = function(_, cb) m.OnIndexChange.On(cb) end

    -- Navigation / sous-menus
    proxy.BindSubmenu = function(_, ...) return Menu.BindSubmenu(m, ...) end

    -- Accès aux champs live du vrai menu (same-resource uniquement)
    setmetatable(proxy, {
        __index    = function(_, k) return m[k] end,
        __newindex = function(_, k, v) m[k] = v end,
    })

    return proxy
end

--- Crée un sous-menu lié à un menu parent.
---@param parent   table   proxy ou menu réel
---@param title    string
---@param subtitle string
---@param opts     table|nil
---@return table proxy
function ama_ui.CreateSubMenu(parent, title, subtitle, opts)
    local sub = ama_ui.CreateMenu(title, subtitle, opts)
    local parentId = type(parent) == "table" and parent.id or nil
    local realParent = (parentId and _menuRegistry[parentId]) or parent
    local realSub    = _menuRegistry[sub.id]
    if realSub and realParent then
        realSub.parentMenu = realParent
    end
    return sub
end

-- ============================================================================
-- VISIBILITÉ
-- ============================================================================

--- Toggle / ouvre / ferme un menu.
---   ama_ui.Visible(menu)        → toggle
---   ama_ui.Visible(menu, true)  → forcer ouvert
---   ama_ui.Visible(menu, false) → forcer fermé
--- Accepte un proxy (cross-resource) ou un menu réel.
---@param menuOrProxy table
---@param state       boolean|nil
function ama_ui.Visible(menuOrProxy, state)
    local id = type(menuOrProxy) == "table" and menuOrProxy.id or nil
    local menu = (id and _menuRegistry[id]) or menuOrProxy
    if not menu then return end

    if state == nil then
        menu:Toggle()
    elseif state then
        if not menu.visible then menu:Open() end
    else
        if menu.visible then menu:Close() end
    end
end

--- Retourne true si le menu est visible.
--- Accepte un proxy (cross-resource) ou un menu réel.
---@param menuOrProxy table
---@return boolean
function ama_ui.IsVisible(menuOrProxy)
    local id = type(menuOrProxy) == "table" and menuOrProxy.id or nil
    local menu = (id and _menuRegistry[id]) or menuOrProxy
    return menu ~= nil and menu.visible == true
end

-- ============================================================================
-- PANELS — accessibles via getSharedObject
-- Les panels sont chargés avant ui.lua (ordre fxmanifest) → globaux disponibles
-- ============================================================================
ama_ui.StatisticsPanel         = StatisticsPanel
ama_ui.StatisticsPanelAdvanced = StatisticsPanelAdvanced
ama_ui.ColorPanel              = ColorPanel
ama_ui.GridPanel               = GridPanel
ama_ui.GridPanelH              = GridPanelH
ama_ui.GridPanelV              = GridPanelV
ama_ui.PercentagePanel         = PercentagePanel

-- ============================================================================
-- UTILITAIRES
-- ============================================================================

--- Alias façade → item:SetDynDesc(fn)  (chainable, compatible cross-resource)
---@param item table   item ama_ui (Button, List, Checkbox, etc.)
---@param fn   function  fn(item) → string
---@return table item (chainable)
function ama_ui.DynDesc(item, fn)
    item:SetDynDesc(fn)
    return item
end

-- ============================================================================
-- EXPORT getSharedObject (uniquement dans la resource ama_ui)
-- Guard : si ui.lua est chargé via @ama_ui/... dans une autre resource,
-- ne PAS écraser le getSharedObject de cette resource (ex: es_extended).
-- ============================================================================
if GetCurrentResourceName() == 'ama_ui' then
    exports('getSharedObject', function()
        return ama_ui
    end)
end

-- ============================================================================
-- READY
-- ============================================================================

print("^2[ama_ui] Façade chargée^7")
