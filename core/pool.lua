-- core/pool.lua
-- Optimisé: compteurs atomiques, pas d'itération pour IsAnyMenuOpen/Count

MenuPool = {}

local _menus        = {}
local _activeMenu   = nil
local _isProcessing = false
local _openCount    = 0
local _totalCount   = 0
local _cacheFrame   = 0

function MenuPool.Add(menu)
    if not menu or not menu.id then
        print("^1[MenuPool] Erreur: Menu invalide^7")
        return false
    end
    if _menus[menu.id] then
        print("^3[MenuPool] Attention: Menu avec l'ID " .. menu.id .. " existe déjà^7")
        return false
    end
    _menus[menu.id] = menu
    _totalCount = _totalCount + 1
    if menu.visible and not _activeMenu then
        _activeMenu = menu
        _openCount = _openCount + 1
    end
    return true
end

function MenuPool.Remove(menu)
    if not menu or not menu.id then return false end
    if not _menus[menu.id] then return false end
    if _activeMenu and _activeMenu.id == menu.id then _activeMenu = nil end
    if menu.visible then menu:Close() end
    _menus[menu.id] = nil
    _totalCount = _totalCount - 1
    return true
end

function MenuPool.RemoveById(menuId)
    if not menuId or not _menus[menuId] then return false end
    return MenuPool.Remove(_menus[menuId])
end

function MenuPool.GetById(menuId) return _menus[menuId] end

function MenuPool.GetAll()
    local menuList = {}
    for _, menu in pairs(_menus) do menuList[#menuList + 1] = menu end
    return menuList
end

function MenuPool.Count() return _totalCount end
function MenuPool.IsAnyMenuOpen() return _openCount > 0 end
function MenuPool.GetActive() return _activeMenu end

function MenuPool.SetActive(menu)
    if not menu then _activeMenu = nil; return true end
    if not _menus[menu.id] then
        print("^1[MenuPool] Erreur: Le menu n'est pas dans le pool^7")
        return false
    end
    _activeMenu = menu
    return true
end

function MenuPool.CloseAll()
    for _, menu in pairs(_menus) do if menu.visible then menu:Close() end end
    _activeMenu = nil
end

function MenuPool.CloseAllExcept(exceptMenu)
    for _, menu in pairs(_menus) do
        if menu.visible and menu.id ~= exceptMenu.id then menu:Close() end
    end
end

function MenuPool.GetOpenMenus()
    local openMenus = {}
    for _, menu in pairs(_menus) do
        if menu.visible then openMenus[#openMenus + 1] = menu end
    end
    return openMenus
end

function MenuPool.Process()
    if _isProcessing then return end
    _isProcessing = true
    _cacheFrame = _cacheFrame + 1
    if _cacheFrame >= 60 then
        Cache.Update()
        _cacheFrame = 0
    end
    if _activeMenu and _activeMenu.visible then
        _activeMenu:Process()
    else
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

function MenuPool.Draw()
    if not (_activeMenu and _activeMenu.visible) then return end
    local chain = {}
    local current = _activeMenu
    while current do chain[#chain + 1] = current; current = current.parentMenu end
    for i = #chain, 1, -1 do if chain[i].visible then chain[i]:Draw() end end
end

function MenuPool.RefreshAll()
    for _, menu in pairs(_menus) do if menu.Refresh then menu:Refresh() end end
end

function MenuPool.Cleanup()
    for _, menu in pairs(_menus) do if menu.Destroy then menu:Destroy() end end
    _menus = {}; _activeMenu = nil; _openCount = 0; _totalCount = 0
end

function MenuPool.GetStats()
    return { totalMenus = _totalCount, visibleMenus = _openCount,
             activeMenu = _activeMenu and _activeMenu.id or "none" }
end

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

function MenuPool.DisableProcessing() _isProcessing = true end
function MenuPool.EnableProcessing()  _isProcessing = false end
function MenuPool.Exists(menuId) return _menus[menuId] ~= nil end

function MenuPool.FindByTitle(title)
    for _, menu in pairs(_menus) do if menu.title == title then return menu end end
    return nil
end

function MenuPool.GetParent(menu) return menu and menu.parentMenu or nil end

function MenuPool.GetChildren(menu)
    if not menu or not menu.children then return {} end
    local children = {}
    for _, child in pairs(menu.children) do children[#children + 1] = child end
    return children
end

function MenuPool.GetHierarchy(menu)
    local hierarchy = {}
    local current = menu
    while current do table.insert(hierarchy, 1, current); current = current.parentMenu end
    return hierarchy
end

function MenuPool.CloseHierarchy(menu)
    if not menu then return end
    local hierarchy = MenuPool.GetHierarchy(menu)
    for i = #hierarchy, 1, -1 do if hierarchy[i].visible then hierarchy[i]:Close() end end
end

MenuPool.OnMenuOpened        = Event.New()
MenuPool.OnMenuClosed        = Event.New()
MenuPool.OnActiveMenuChanged = Event.New()
MenuPool._renderThread       = nil

function MenuPool.NotifyMenuOpened(menu)
    MenuPool.SetActive(menu)
    _openCount = _openCount + 1
    MenuPool.OnMenuOpened.Emit(menu)
    MenuPool.OnActiveMenuChanged.Emit(menu)
    if not MenuPool._renderThread then
        MenuPool._renderThread = CreateThread(function()
            local _profEnabled = Config.Debug
            local _fCount, _fSum, _fMax, _fLastReport = 0, 0, 0, GetGameTimer()
            while MenuPool.IsAnyMenuOpen() do
                Wait(0)
                local t0 = GetGameTimer()
                MenuPool.Process()
                MenuPool.Draw()

                --old version
                --[[if _profEnabled then
                    local dt = GetGameTimer() - t0
                    _fCount = _fCount + 1
                    _fSum   = _fSum + dt
                    if dt > _fMax then _fMax = dt end
                    local now = GetGameTimer()
                    if now - _fLastReport >= 5000 then
                        print(string.format(
                            "^3[MenuPool] Profil 5s → avg=%.2fms max=%.2fms frames=%d^7",
                            _fSum / _fCount, _fMax, _fCount))
                        _fCount = 0; _fSum = 0; _fMax = 0; _fLastReport = now
                    end
                end]]
                -- new version 

                -- ✅ FIX : deux boucles séparées selon le mode debug
                -- Zéro overhead en production
                if _profEnabled then
                -- Boucle debug : profiling complet
                     while MenuPool.IsAnyMenuOpen() do
                Wait(0)
                local t0 = GetGameTimer()
                MenuPool.Process()
                MenuPool.Draw()
               local dt = GetGameTimer() - t0
               _fCount = _fCount + 1 ; _fSum = _fSum + dt
               if dt > _fMax then _fMax = dt end
                local now = GetGameTimer()
               if now - _fLastReport >= 5000 then
                     print(string.format("^3[MenuPool] avg=%.2fms max=%.2fms frames=%d^7",
                        _fSum/_fCount, _fMax, _fCount))
                        _fCount=0 ; _fSum=0 ; _fMax=0 ; _fLastReport=now
                    end
                end
            else
            -- ✅ Boucle production : AUCUN appel natif superflu
           while MenuPool.IsAnyMenuOpen() do
           Wait(0)
           MenuPool.Process()
        MenuPool.Draw()
    end
end
            end
            MenuPool._renderThread = nil
        end)
    end
end

function MenuPool.NotifyMenuClosed(menu)
    _openCount = math.max(0, _openCount - 1)
    if _activeMenu and _activeMenu.id == menu.id then
        if _openCount == 0 then
            _activeMenu = nil
            MenuPool.OnActiveMenuChanged.Emit(nil)
        else
            local foundActive = false
            for _, m in pairs(_menus) do
                if m.visible and m.id ~= menu.id then
                    MenuPool.SetActive(m)
                    MenuPool.OnActiveMenuChanged.Emit(m)
                    foundActive = true
                    break
                end
            end
            if not foundActive then _activeMenu = nil; MenuPool.OnActiveMenuChanged.Emit(nil) end
        end
    end
    MenuPool.OnMenuClosed.Emit(menu)
end

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then MenuPool.Cleanup() end
end)

if Config.Debug then
    RegisterCommand('menupool_debug', function() MenuPool.Debug() end, false)
    RegisterCommand('menupool_close_all', function()
        MenuPool.CloseAll()
        print("^2Tous les menus ont été fermés^7")
    end, false)
end

return MenuPool
