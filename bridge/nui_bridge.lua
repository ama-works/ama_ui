-- ============================================================================
-- client/nui_bridge.lua
-- ============================================================================
-- Bridge entre l'API Lua et le NUI React
-- Sérialise l'état du menu et l'envoie à React via SendNUIMessage
-- 
-- IMPORTANT : Ce fichier remplace les fonctions Draw natives (DrawRect, etc.)
--             La logique métier reste identique, seul le rendu change.
-- ============================================================================

-- ============================================================================
-- [1] SÉRIALISATION — Convertit l'état Lua en JSON pour React
-- ============================================================================

--- Sérialise un menu de création de personnage
---@param menu table Le menu à sérialiser
---@return table État formaté pour React
local function SerializeCharacterMenu(menu)
    if not menu or not menu.items then 
        return nil 
    end
    
    local items = menu.items
    
    -- Structure attendue par React (voir brief_claude_code.md)
    return {
        -- Selectors (Mom/Dad)
        mom = items[1] and items[1]:GetSelectedItem() or "elizabeth",
        dad = items[2] and items[2]:GetSelectedItem() or "benjamin",
        
        -- Sliders (Ressemblance 1/2)
        resemblance1 = items[3] and items[3].value or 50,
        resemblance2 = items[4] and items[4].value or 80,
        
        -- Color picker (Skin tone)
        skinTone = items[5] and items[5].value or 1,
        
        -- Text input (Name)
        name = items[6] and items[6].text or "Jhon Dhoe",
        
        -- Progress bar (Nose)
        nose = items[7] and items[7].value or 50,
        
        -- Catégorie active
        category = menu._activeCategory or "face",
        
        -- Grille d'items (Cheeks, Hair, Makeup, etc.)
        items = {
            { label = "Cheeks 1", value = menu._itemValues and menu._itemValues.cheeks1 or 0 },
            { label = "Cheeks 2", value = menu._itemValues and menu._itemValues.cheeks2 or 0 },
            { label = "Hair 1", value = menu._itemValues and menu._itemValues.hair1 or 0 },
            { label = "Hair 2", value = menu._itemValues and menu._itemValues.hair2 or 0 },
            { label = "Makeup 1", value = menu._itemValues and menu._itemValues.makeup1 or 0 },
            { label = "Makeup 2", value = menu._itemValues and menu._itemValues.makeup2 or 0 },
            { label = "Blush 1", value = menu._itemValues and menu._itemValues.blush1 or 0 },
            { label = "Blush 2", value = menu._itemValues and menu._itemValues.blush2 or 0 },
        },
        
        -- Stats (panneau droit)
        stats = {
            sex = menu._characterSex or "F / M",
            id = menu._characterId or 1,
            job = menu._characterJob or "unemployed",
            money = menu._characterMoney or 10,
            maxMoney = menu._characterMaxMoney or 100,
            date = menu._characterDate or "12/04/1978",
            gender = menu._characterGender or "Male"
        },
        
        -- Graphique circulaire (Mom/Dad %)
        momPercent = menu._momPercent or 28,
        dadPercent = menu._dadPercent or 89
    }
end

--- Sérialise un menu générique (pour d'autres types de menus)
---@param menu table
---@return table
local function SerializeGenericMenu(menu)
    if not menu or not menu.items then 
        return nil 
    end
    
    local serializedItems = {}
    
    for i, item in ipairs(menu.items) do
        local serialized = {
            type = item.type,
            text = item.text,
            description = item.description or "",
            enabled = (item.enabled == nil) and true or item.enabled,
            selected = (i == menu.currentItem)
        }
        
        -- Ajouter les propriétés spécifiques selon le type
        if item.type == "checkbox" then
            serialized.checked = item.checked or false
            
        elseif item.type == "list" then
            serialized.items = item.items or {}
            serialized.index = item.index or 1
            serialized.selectedItem = item:GetSelectedItem()
            
        elseif item.type == "slider" or item.type == "sliderprogress" or item.type == "progress" then
            serialized.value = item.value or 0
            serialized.max = item.max or 100
            
        elseif item.type == "heritage" then
            serialized.value = item.value or 50
            serialized.min = item.min or 0
            serialized.max = item.max or 100
        end
        
        table.insert(serializedItems, serialized)
    end
    
    return {
        title = menu.title,
        subtitle = menu.subtitle,
        currentItem = menu.currentItem,
        items = serializedItems
    }
end

-- ============================================================================
-- [2] ENVOI À REACT — SendNUIMessage
-- ============================================================================

--- Envoie l'état du menu à React
---@param menu table
local function SendMenuToNUI(menu)
    if not menu then return end
    
    if not menu.visible then
        SendNUIMessage({ type = "HIDE_MENU" })
        return
    end
    
    -- Déterminer le type de menu (création de perso ou générique)
    local state
    if menu.id and menu.id:find("character") then
        state = SerializeCharacterMenu(menu)
    else
        state = SerializeGenericMenu(menu)
    end
    
    if state then
        SendNUIMessage({
            type = "UPDATE_MENU",
            data = state
        })
    end
end

-- ============================================================================
-- [3] OVERRIDE Menu:Draw() — Remplace DrawRect par SendNUIMessage
-- ============================================================================

-- Sauvegarder la fonction Draw originale (au cas où)
local _originalDraw = Menu.Draw

--- Nouvelle fonction Draw qui envoie à React au lieu de dessiner en natif
function Menu:Draw()
    SendMenuToNUI(self)
end

-- Si tu veux un toggle pour activer/désactiver le mode NUI
Menu.useNUI = true  -- false = revenir aux DrawRect natifs

function Menu:Draw()
    if Menu.useNUI then
        SendMenuToNUI(self)
    else
        _originalDraw(self)  -- fallback sur DrawRect
    end
end

-- ============================================================================
-- [4] CALLBACKS REACT → LUA (optionnel, si tu veux gérer clics souris)
-- ============================================================================

--- Callback quand React envoie un événement (ex: clic souris sur un item)
RegisterNUICallback("menuAction", function(data, cb)
    -- data = { action: "selectItem", itemIndex: 3 }
    
    local menu = MenuPool.GetCurrentMenu()
    if not menu then 
        cb({ success = false })
        return 
    end
    
    if data.action == "selectItem" then
        menu:SetCurrentIndex(data.itemIndex)
        menu:Select()
        
    elseif data.action == "goBack" then
        menu:GoBack()
        
    elseif data.action == "closeMenu" then
        menu:Close()
    end
    
    cb({ success = true })
end)

-- ============================================================================
-- [5] HELPER — Focus NUI (pour inputs texte si besoin)
-- ============================================================================

--- Active le focus NUI (clavier capturé par React)
function Menu:EnableNUIFocus()
    SetNuiFocus(true, true)
    self._nuiFocusEnabled = true
end

--- Désactive le focus NUI
function Menu:DisableNUIFocus()
    SetNuiFocus(false, false)
    self._nuiFocusEnabled = false
end

--- Callback pour fermer le focus depuis React
RegisterNUICallback("closeFocus", function(data, cb)
    local menu = MenuPool.GetCurrentMenu()
    if menu then
        menu:DisableNUIFocus()
    end
    cb("ok")
end)

-- ============================================================================
-- [6] DEBUG — Afficher l'état sérialisé dans la console
-- ============================================================================

if Config and Config.Debug then
    RegisterCommand("debugmenu", function()
        local menu = MenuPool.GetCurrentMenu()
        if menu then
            local state = SerializeCharacterMenu(menu) or SerializeGenericMenu(menu)
            print("^2[NUI Bridge] État du menu :^7")
            print(json.encode(state, { indent = true }))
        else
            print("^1[NUI Bridge] Aucun menu actif^7")
        end
    end, false)
end

print("^2[NUI Bridge] Chargé — Les menus utilisent maintenant React NUI^7")
