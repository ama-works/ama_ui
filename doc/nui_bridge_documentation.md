# Documentation nui_bridge.lua
## Bridge Lua ↔ React pour api_nativeui

---

## Vue d'ensemble

`nui_bridge.lua` est le **pont de communication** entre ton API Lua (logique métier) et l'interface React (rendu visuel). Il sérialise l'état du menu Lua en JSON et l'envoie à React via `SendNUIMessage`.

**Principe :** Lua gère tout (inputs, calculs, events), React affiche uniquement.

---

## Emplacement

```
api_nativeui/
├─ client/
│  ├─ core/
│  ├─ items/
│  └─ nui_bridge.lua    ← ICI
```

**Déclaré dans `fxmanifest.lua` :**
```lua
client_scripts {
    'client/core/*.lua',
    'client/items/*.lua',
    'client/nui_bridge.lua'
}
```

---

## Fonctionnement

### 1. Menu Lua (état source)

```lua
local menu = NativeUI.CreateMenu("Character", "Creator")
menu:List("Mom", {"elizabeth", "hannah"}, 1)
menu:SliderProgress("Ressemblance 1", 50, 100)
```

### 2. Bridge sérialise l'état

```lua
-- nui_bridge.lua
local function SerializeCharacterMenu(menu)
    return {
        mom = menu.items[1]:GetSelectedItem(),  -- "elizabeth"
        resemblance1 = menu.items[2].value,     -- 50
        -- ... autres données
    }
end
```

### 3. Envoi à React

```lua
SendNUIMessage({
    type = "UPDATE_MENU",
    data = {
        mom = "elizabeth",
        resemblance1 = 50,
        -- ...
    }
})
```

### 4. React reçoit et affiche

```jsx
// App.jsx
useEffect(() => {
    window.addEventListener('message', (event) => {
        if (event.data.type === 'UPDATE_MENU') {
            setState(event.data.data)  // { mom: "elizabeth", ... }
        }
    })
}, [])
```

---

## Structure de données sérialisées

### Pour un menu de création de personnage

```lua
{
    -- Selectors
    mom = "elizabeth",           -- string
    dad = "benjamin",            -- string
    
    -- Sliders
    resemblance1 = 50,           -- number 0-100
    resemblance2 = 80,           -- number 0-100
    
    -- Color picker
    skinTone = 1,                -- number
    
    -- Text input
    name = "Jhon Dhoe",          -- string
    
    -- Progress bar
    nose = 50,                   -- number 0-100
    
    -- Catégorie active
    category = "face",           -- "face" | "hair" | "makeup" | "beard" | "skin" | "clothes"
    
    -- Grille d'items
    items = {
        { label = "Cheeks 1", value = 0 },
        { label = "Cheeks 2", value = 0 },
        { label = "Hair 1", value = 0 },
        -- ...
    },
    
    -- Stats (panneau droit)
    stats = {
        sex = "F / M",
        id = 1,
        job = "unemployed",
        money = 10,
        maxMoney = 100,
        date = "12/04/1978",
        gender = "Male"
    },
    
    -- Graphique circulaire
    momPercent = 28,
    dadPercent = 89
}
```

### Pour un menu générique

```lua
{
    title = "Mon Menu",
    subtitle = "Sous-titre",
    currentItem = 2,           -- index de l'item sélectionné
    
    items = {
        {
            type = "button",
            text = "Option 1",
            description = "Description",
            enabled = true,
            selected = false
        },
        {
            type = "checkbox",
            text = "God Mode",
            checked = true,
            selected = true
        },
        {
            type = "list",
            text = "Arme",
            items = {"Pistolet", "Fusil"},
            index = 1,
            selectedItem = "Pistolet",
            selected = false
        },
        {
            type = "slider",
            text = "Vitesse",
            value = 50,
            max = 100,
            selected = false
        }
    }
}
```

---

## Fonctions principales

### SerializeCharacterMenu(menu)

**Sérialise un menu de création de personnage.**

```lua
local function SerializeCharacterMenu(menu)
    -- Retourne la structure de données pour React
    return {
        mom = ...,
        dad = ...,
        -- ... (voir structure ci-dessus)
    }
end
```

**Usage interne** — Appelée automatiquement par `Menu:Draw()`

---

### SerializeGenericMenu(menu)

**Sérialise n'importe quel menu (button, list, checkbox, etc.).**

```lua
local function SerializeGenericMenu(menu)
    -- Parcourt tous les items et les sérialise selon leur type
    return {
        title = menu.title,
        items = { ... }
    }
end
```

**Usage interne** — Appelée automatiquement par `Menu:Draw()`

---

### Menu:Draw() (override)

**Remplace la fonction Draw() originale.**

**Avant (natifs Lua) :**
```lua
function Menu:Draw()
    Draw.Rect(...)
    Draw.Sprite(...)
    Text.Draw(...)
end
```

**Après (NUI React) :**
```lua
function Menu:Draw()
    if Menu.useNUI then
        SendMenuToNUI(self)  -- Envoie à React
    else
        _originalDraw(self)  -- Fallback DrawRect
    end
end
```

---

### Menu.useNUI (toggle)

**Active/désactive le mode NUI.**

```lua
Menu.useNUI = true   -- Utilise React (défaut)
Menu.useNUI = false  -- Revient aux DrawRect natifs
```

**Usage :**
```lua
-- Désactiver temporairement React
Menu.useNUI = false
menu:Draw()  -- Utilise DrawRect

-- Réactiver React
Menu.useNUI = true
menu:Draw()  -- Utilise React
```

---

### Callbacks React → Lua (optionnel)

**Gère les événements envoyés depuis React.**

```lua
RegisterNUICallback("menuAction", function(data, cb)
    -- data = { action: "selectItem", itemIndex: 3 }
    
    local menu = MenuPool.GetCurrentMenu()
    if data.action == "selectItem" then
        menu:SetCurrentIndex(data.itemIndex)
        menu:Select()
    end
    
    cb({ success = true })
end)
```

**Usage côté React :**
```js
// Envoyer un événement à Lua
fetch(`https://${GetParentResourceName()}/menuAction`, {
    method: 'POST',
    body: JSON.stringify({ action: 'selectItem', itemIndex: 3 })
})
```

**Note :** Les callbacks ne sont pas obligatoires si tu gères tout au clavier en Lua.

---

## Commandes debug

### /debugmenu

**Affiche l'état JSON du menu actif dans la console F8.**

```
/debugmenu
```

**Output :**
```json
{
  "mom": "elizabeth",
  "dad": "benjamin",
  "resemblance1": 50,
  "resemblance2": 80,
  ...
}
```

**Disponible uniquement si `Config.Debug = true`.**

---

## Personnalisation

### Ajouter des données custom

**Exemple : Ajouter le niveau du joueur**

```lua
local function SerializeCharacterMenu(menu)
    return {
        -- Données standard
        mom = ...,
        dad = ...,
        
        -- ▼ AJOUT CUSTOM
        playerLevel = GetPlayerLevel(),
        playerXP = GetPlayerXP(),
        
        stats = {
            -- ... stats existantes
            level = GetPlayerLevel()  -- Ajouter dans stats aussi
        }
    }
end
```

**Côté React :**
```jsx
<span>Level : {state.playerLevel}</span>
<span>XP : {state.playerXP}</span>
```

---

### Gérer plusieurs types de menus

**Détection automatique du type :**

```lua
function SendMenuToNUI(menu)
    local state
    
    if menu.id and menu.id:find("character") then
        state = SerializeCharacterMenu(menu)
        
    elseif menu.id and menu.id:find("bank") then
        state = SerializeBankMenu(menu)
        
    elseif menu.id and menu.id:find("inventory") then
        state = SerializeInventoryMenu(menu)
        
    else
        state = SerializeGenericMenu(menu)
    end
    
    SendNUIMessage({ type = "UPDATE_MENU", data = state })
end
```

---

## Performance

### Optimisations incluses

✅ **Pas de recalcul inutile** — Sérialise uniquement si `menu.visible == true`  
✅ **Pas de deep copy** — Référence directe aux valeurs  
✅ **JSON léger** — Seulement les données affichables  

### Mesure de performance

```lua
local startTime = GetGameTimer()
SendMenuToNUI(menu)
local elapsed = GetGameTimer() - startTime
print("Bridge took " .. elapsed .. "ms")
```

**Attendu :** < 1ms pour un menu de 20 items.

---

## Messages NUI

### Types de messages envoyés

| Type | Data | Description |
|------|------|-------------|
| `UPDATE_MENU` | `{ ...state }` | Met à jour l'affichage React |
| `HIDE_MENU` | `null` | Cache l'interface React |

### Réception côté React

```jsx
window.addEventListener('message', (event) => {
    const { type, data } = event.data
    
    switch (type) {
        case 'UPDATE_MENU':
            setState(data)      // Affiche le menu
            break
            
        case 'HIDE_MENU':
            setState(null)      // Cache le menu
            break
    }
})
```

---

## Troubleshooting

### Le menu ne s'affiche pas

**Vérifications :**
```lua
-- 1. Bridge activé ?
print(Menu.useNUI)  -- doit être true

-- 2. Menu visible ?
print(menu.visible)  -- doit être true

-- 3. Build React existe ?
-- Vérifie que nui/dist/ contient index.html
```

### L'interface ne se met pas à jour

**Solution :**
```lua
-- Force un dirty flag
menu._dirty = true
menu:Draw()
```

### Erreur "attempt to index nil value"

**Cause :** Item inexistant dans la sérialisation.

**Solution :**
```lua
-- Toujours vérifier l'existence
resemblance1 = items[3] and items[3].value or 50
--             ^^^^^^^^^^^^^ vérification
```

---

## Checklist d'intégration

- [ ] `nui_bridge.lua` dans `client/`
- [ ] Déclaré dans `fxmanifest.lua`
- [ ] `Menu.useNUI = true` (ou toggle selon besoin)
- [ ] React écoute `window.addEventListener('message')`
- [ ] Build React existe dans `nui/dist/`
- [ ] `ui_page 'nui/dist/index.html'` dans manifest
- [ ] Test avec `/debugmenu` pour voir le JSON

---

## Exemple complet

### Lua (création du menu)

```lua
local menu = NativeUI.CreateMenu("Character", "Creator")
menu.id = "character_creator"  -- Important pour la détection

menu:List("Mom", {"elizabeth", "hannah"}, 1)
menu:List("Dad", {"benjamin", "daniel"}, 1)
menu:SliderProgress("Ressemblance 1", 50, 100, "", { step = 1 })

RegisterCommand("char", function()
    menu:Toggle()
end)
```

### Bridge (automatique)

```lua
-- nui_bridge.lua fait le travail
-- Appel automatique de SerializeCharacterMenu()
-- Envoi automatique via SendNUIMessage()
```

### React (affichage)

```jsx
// App.jsx reçoit automatiquement
{state && <CharacterCreator state={state} />}
```

**Tout est automatique une fois configuré !**

---

## Notes importantes

⚠️ **Le bridge ne gère PAS la logique métier**  
→ Inputs, calculs, events restent en Lua

⚠️ **React ne peut pas modifier l'état Lua directement**  
→ Passe par des callbacks RegisterNUICallback si besoin

⚠️ **Un seul menu actif à la fois**  
→ Si plusieurs menus ouverts, seul le dernier est sérialisé

✅ **Compatible avec ton API actuelle**  
→ Aucune modification de ton code menu existant

---

## Références

- [Brief React complet](../react/brief_claude_code.md)
- [Plan d'intégration](../react/plan_integration_react.md)
- [Architecture globale](../references/architecture.md)
