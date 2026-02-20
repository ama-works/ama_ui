-- core/pool.lua
MenuPool = {}

-- Stockage des menus
local _menus = {}
local _activeMenu = nil
local _isProcessing = false


-- Ajouter un menu au pool
function MenuPool.Add(menu)
    if not menu or not menu.id then
        print("^1[MenuPool] Erreur: Menu invalide^7")
        return false
    end
    
    -- Vérifier si le menu existe déjà
    if _menus[menu.id] then
        print("^3[MenuPool] Attention: Menu avec l'ID " .. menu.id .. " existe déjà^7")
        return false
    end
    
    _menus[menu.id] = menu
    
    -- Si c'est le premier menu et qu'il est visible, le définir comme actif
    if menu.visible and not _activeMenu then
        _activeMenu = menu
    end
    
    return true
end

--- Ajouter un menu avec une configuration rapide
---@param menu table Configuration du menu (doit inclure un champ 'id')
-- Retirer un menu du pool
function MenuPool.Remove(menu)
    if not menu or not menu.id then
        return false
    end
    
    -- Si c'est le menu actif, le désactiver
    if _activeMenu and _activeMenu.id == menu.id then
        _activeMenu = nil
    end
    
    -- Fermer le menu s'il est ouvert
    if menu.visible then
        menu:Close()
    end
    
    _menus[menu.id] = nil
    return true
end

-- Retirer un menu par son ID
---@param menuId string ID du menu à retirer
function MenuPool.RemoveById(menuId)
    if not menuId or not _menus[menuId] then
        return false
    end
    
    local menu = _menus[menuId]
    return MenuPool.Remove(menu)
end

--- Vérifier si un menu est dans le pool
-- Obtenir un menu par son ID
function MenuPool.GetById(menuId)
    return _menus[menuId]
end

-- Obtenir tous les menus
function MenuPool.GetAll()
    local menuList = {}
    for _, menu in pairs(_menus) do
        table.insert(menuList, menu)
    end
    return menuList
end

-- Obtenir le nombre de menus dans le pool
function MenuPool.Count()
    local count = 0
    for _ in pairs(_menus) do
        count = count + 1
    end
    return count
end

-- Obtenir le menu actif
function MenuPool.GetActive()
    return _activeMenu
end

-- Définir le menu actif
---@param menu table Menu à définir comme actif (doit être dans le pool)
function MenuPool.SetActive(menu)
    if not menu then
        _activeMenu = nil
        return
    end
    
    -- Vérifier que le menu est dans le pool
    if not _menus[menu.id] then
        print("^1[MenuPool] Erreur: Le menu n'est pas dans le pool^7")
        return false
    end
    
    _activeMenu = menu
    return true
end

-- Fermer tous les menus
function MenuPool.CloseAll()
    for _, menu in pairs(_menus) do
        if menu.visible then
            menu:Close()
        end
    end
    _activeMenu = nil
end

--- Fermer un menu spécifique
---@param exceptMenu table Menu à fermer
-- Fermer tous les menus sauf un
function MenuPool.CloseAllExcept(exceptMenu)
    for _, menu in pairs(_menus) do
        if menu.visible and menu.id ~= exceptMenu.id then
            menu:Close()
        end
    end
end

-- Vérifier si un menu est ouvert
function MenuPool.IsAnyMenuOpen()
    for _, menu in pairs(_menus) do
        if menu.visible then
            return true
        end
    end
    return false
end

-- Obtenir tous les menus ouverts
function MenuPool.GetOpenMenus()
    local openMenus = {}
    for _, menu in pairs(_menus) do
        if menu.visible then
            table.insert(openMenus, menu)
        end
    end
    return openMenus
end

-- Process tous les menus (inputs, logique)
function MenuPool.Process()
    if _isProcessing then return end
    _isProcessing = true
    
    -- Mettre à jour le cache si nécessaire
    Cache.Update()
    
    -- Process le menu actif en priorité
    if _activeMenu and _activeMenu.visible then
        _activeMenu:Process()
    else
        -- Si le menu actif n'est plus visible, trouver un autre menu visible
        _activeMenu = nil
        for _, menu in pairs(_menus) do
            if menu.visible then
                _activeMenu = menu
                menu:Process()
                break
            end
        end
    end
    
    _isProcessing = false
end

-- Dessiner uniquement le menu actif (et ses parents si sous-menu)
function MenuPool.Draw()
    if _activeMenu and _activeMenu.visible then
        -- Dessiner la hiérarchie (parent → enfant)
        local current = _activeMenu
        local chain = {}
        while current do
            table.insert(chain, 1, current)
            current = current.parentMenu
        end
        for _, menu in ipairs(chain) do
            if menu.visible then
                menu:Draw()
            end
        end
    end
end

-- Refresh tous les menus (recalculer les positions, etc.)
function MenuPool.RefreshAll()
    for _, menu in pairs(_menus) do
        if menu.Refresh then
            menu:Refresh()
        end
    end
end

-- Nettoyer tous les menus (libérer les ressources)
function MenuPool.Cleanup()
    for _, menu in pairs(_menus) do
        if menu.Destroy then
            menu:Destroy()
        end
    end
    _menus = {}
    _activeMenu = nil
end

-- Obtenir les statistiques du pool
function MenuPool.GetStats()
    local stats = {
        totalMenus = 0,
        visibleMenus = 0,
        activeMenu = _activeMenu and _activeMenu.id or "none"
    }
    
    for _, menu in pairs(_menus) do
        stats.totalMenus = stats.totalMenus + 1
        if menu.visible then
            stats.visibleMenus = stats.visibleMenus + 1
        end
    end
    
    return stats
end

-- Debug: Afficher les informations du pool
function MenuPool.Debug()
    local stats = MenuPool.GetStats()
    print("^2=== MenuPool Debug ===^7")
    print("Total menus: " .. stats.totalMenus)
    print("Visible menus: " .. stats.visibleMenus)
    print("Active menu: " .. stats.activeMenu)
    print("^2=====================^7")
    
    for id, menu in pairs(_menus) do
        local status = menu.visible and "^2OPEN^7" or "^1CLOSED^7"
        local itemCount = menu.items and #menu.items or 0
        print(string.format("  [%s] %s - Items: %d %s", id, menu.title or "Untitled", itemCount, status))
    end
end

-- Désactiver le processing (pour debug)
function MenuPool.DisableProcessing()
    _isProcessing = true
end

-- Réactiver le processing
function MenuPool.EnableProcessing()
    _isProcessing = false
end

-- Vérifier si un menu existe
---@param menuId string ID du menu à vérifier
function MenuPool.Exists(menuId)
    return _menus[menuId] ~= nil
end

--- Obtenir tous les menus d'un certain type (ex: "default", "dialog", etc.)
---@param title string Type de menu à filtrer
-- Trouver un menu par son titre
function MenuPool.FindByTitle(title)
    for _, menu in pairs(_menus) do
        if menu.title and menu.title == title then
            return menu
        end
    end
    return nil
end

--- Trouver tous les menus d'un certain type
-- Obtenir le menu parent d'un menu donné
function MenuPool.GetParent(menu)
    if not menu or not menu.parentMenu then
        return nil
    end
    return menu.parentMenu
end

-- Obtenir tous les enfants d'un menu
function MenuPool.GetChildren(menu)
    if not menu or not menu.children then
        return {}
    end
    
    local children = {}
    for _, child in pairs(menu.children) do
        table.insert(children, child)
    end
    return children
end

-- Obtenir la hiérarchie complète d'un menu
function MenuPool.GetHierarchy(menu)
    local hierarchy = {}
    local current = menu
    
    while current do
        table.insert(hierarchy, 1, current)  -- Insérer au début
        current = current.parentMenu
    end
    
    return hierarchy
end

-- Fermer la hiérarchie d'un menu (fermer le menu et tous ses parents)
function MenuPool.CloseHierarchy(menu)
    if not menu then return end
    
    local hierarchy = MenuPool.GetHierarchy(menu)
    for i = #hierarchy, 1, -1 do
        if hierarchy[i].visible then
            hierarchy[i]:Close()
        end
    end
end

-- Event: Quand un menu est ouvert
MenuPool.OnMenuOpened = Event.New()

-- Event: Quand un menu est fermé
MenuPool.OnMenuClosed = Event.New()

-- Event: Quand le menu actif change
MenuPool.OnActiveMenuChanged = Event.New()

-- Notifier l'ouverture d'un menu
--function MenuPool.NotifyMenuOpened(menu)
--    MenuPool.SetActive(menu)
--    MenuPool.OnMenuOpened.Emit(menu)
 --   MenuPool.OnActiveMenuChanged.Emit(menu)
--end

-- Dans pool.lua - ajouter des events natifs:
MenuPool._renderThread = nil

function MenuPool.NotifyMenuOpened(menu)
    MenuPool.SetActive(menu)
    MenuPool.OnMenuOpened.Emit(menu)
    MenuPool.OnActiveMenuChanged.Emit(menu)
    
    -- ⚡ Démarrer le thread de rendu seulement si besoin
    if not MenuPool._renderThread then
        MenuPool._renderThread = CreateThread(function()
            while MenuPool.IsAnyMenuOpen() do
                Wait(0)
                MenuPool.Process()
                MenuPool.Draw()
            end
            MenuPool._renderThread = nil
        end)
    end
end

-- Notifier la fermeture d'un menu
function MenuPool.NotifyMenuClosed(menu)
    if _activeMenu and _activeMenu.id == menu.id then
        -- Chercher un autre menu visible
        local foundActive = false
        for _, m in pairs(_menus) do
            if m.visible and m.id ~= menu.id then
                MenuPool.SetActive(m)
                MenuPool.OnActiveMenuChanged.Emit(m)
                foundActive = true
                break
            end
        end
        
        if not foundActive then
            _activeMenu = nil
            MenuPool.OnActiveMenuChanged.Emit(nil)
        end
    end
    
    MenuPool.OnMenuClosed.Emit(menu)
end

-- Auto-cleanup au redémarrage de la resource
---@param resourceName string Nom de la resource qui s'arrête
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        MenuPool.Cleanup()
    end
end)

-- Commande de debug (optionnelle)
if Config.Debug then
    RegisterCommand('menupool_debug', function()
        MenuPool.Debug()
    end, false)
    
    RegisterCommand('menupool_close_all', function()
        MenuPool.CloseAll()
        print("^2Tous les menus ont été fermés^7")
    end, false)
end

return MenuPool