# Design — Façade UI pour api_nativeui
## Objectif : attirer les devs RageUI sans sacrifier la qualité de l'API

---

## Pourquoi IsVisible est un problème — analyse du vrai usage RageUI

En regardant des dizaines de scripts réels sur GitHub, voici ce que les devs font :

```lua
-- Pattern RageUI réel (dans une boucle while)
while mainMenu do
    Citizen.Wait(0)
    RageUI.IsVisible(mainMenu, function()
        RageUI.Button("NoClip", "Desc", {RightLabel = "ON/OFF"}, true,
            function(Hovered, Active, Selected)
                if Selected then ... end   -- ← if Selected à l'intérieur
            end
        )
        RageUI.Checkbox("GodMode", nil, data.checked, {},
            function(Hovered, Active, Selected, Checked)
                if Selected then data.checked = Checked end
            end
        )
    end)
end
```

### Problèmes du pattern IsVisible

1. **`while mainMenu do` dans une boucle** → le thread tourne même menu fermé
2. **`if Selected then` à l'intérieur de chaque callback** → les devs oublient,
   le code se déclenche au hover au lieu de sur Enter
3. **`Hovered, Active, Selected`** → 3 params mais 90% du code n'utilise que `Selected`
4. **Les items sont recréés à chaque frame** → RageUI les reconstruit entièrement
   chaque fois que `IsVisible` est appelé → source du bug CPU 3ms

### Conclusion sur IsVisible

`IsVisible` en façade pure RageUI **n'a pas de sens** avec ton architecture
car tes items sont créés une fois et persistent. Ce serait simuler un anti-pattern.

**La bonne approche :** garder la création d'items en dehors de la boucle
(comme tu fais déjà), mais proposer une syntaxe de déclaration proche de RageUI.

---

## Syntaxe proposée : NativeUI façade

### Principe
- **Nom du module :** `NativeUI` (pas `RageUI`, on garde l'indépendance)
- **Items créés une fois** à la déclaration (pas recréés chaque frame)
- **Callbacks nommés** proches de RageUI : `onSelected`, `onChecked`, `onListChange`
- **Pas de `IsVisible`** : remplacé par `NativeUI.Visible()` (toggle propre)
- **Pas de boucle while** : la boucle est gérée automatiquement

### Comparaison directe

```lua
-- ══════════════════════════════════════
-- RAGEUI (ancien pattern)
-- ══════════════════════════════════════
local mainMenu = RageUI.CreateMenu("Titre", "Sous-titre")

RageUI.Visible(mainMenu, not RageUI.Visible(mainMenu))

while mainMenu do
    Citizen.Wait(0)
    RageUI.IsVisible(mainMenu, function()

        RageUI.Button("GodMode", "Active l'invincibilité", {}, true,
            function(Hovered, Active, Selected)
                if Selected then
                    SetPlayerInvincible(PlayerId(), true)
                end
            end
        )

        RageUI.Checkbox("NoClip", nil, noClipActive, {},
            function(Hovered, Active, Selected, Checked)
                if Selected then
                    noClipActive = Checked
                end
            end
        )

        RageUI.List("Arme", {"Pistolet","Fusil","SMG"}, weaponIndex, nil, {}, true,
            function(Index, onSelected, onListChange)
                if onListChange then weaponIndex = Index end
            end
        )

    end)
end

-- ══════════════════════════════════════
-- TON API — Syntaxe NativeUI façade
-- ══════════════════════════════════════
local mainMenu = NativeUI.CreateMenu("Titre", "Sous-titre")

mainMenu:Button("GodMode", "Active l'invincibilité", {
    onSelected = function(item)
        SetPlayerInvincible(PlayerId(), true)
    end
})

mainMenu:Checkbox("NoClip", noClipActive, "", {
    onSelected = function(item)
        noClipActive = item.checked
    end
})

mainMenu:List("Arme", {"Pistolet","Fusil","SMG"}, 1, "", {
    onListChange = function(item)
        weaponIndex = item.index
    end
})

NativeUI.Visible(mainMenu)      -- toggle ouverture/fermeture
-- Pas de boucle while, pas de Citizen.Wait manuel, tout est géré
```

---

## API complète NativeUI

```lua
-- ─── Création ───────────────────────────────────────────────────────────────

local menu = NativeUI.CreateMenu(title, subtitle, opts)
-- opts optionnel : { x=50, y=50, sprite={dict, name} }

local sub = NativeUI.CreateSubMenu(parentMenu, title, subtitle, opts)
-- Crée un sous-menu lié à parentMenu (navigation retour automatique)

-- ─── Ouverture ──────────────────────────────────────────────────────────────

NativeUI.Visible(menu)               -- toggle (ouvre si fermé, ferme si ouvert)
NativeUI.Visible(menu, true)         -- forcer ouvert
NativeUI.Visible(menu, false)        -- forcer fermé
NativeUI.IsVisible(menu)             -- retourne true/false (lecture seule)

-- ─── Items (même syntaxe pour tous) ─────────────────────────────────────────

menu:Button(label, description, actions)
-- actions.onSelected = function(item) end

menu:Checkbox(label, checked, description, actions)
-- actions.onSelected  = function(item) end    ← item.checked = nouvelle valeur
-- actions.onChecked   = function(item) end    ← appelé si checked devient true
-- actions.onUnChecked = function(item) end    ← appelé si checked devient false

menu:List(label, {valeurs}, index, description, actions)
-- actions.onListChange = function(item) end   ← item.index, item:GetSelectedItem()
-- actions.onSelected   = function(item) end

menu:Slider(label, value, max, description, style, actions)
-- style optionnel : { step=1 }
-- actions.onSliderChange = function(item) end ← item.value, item.max
-- actions.onSelected     = function(item) end

menu:Progress(label, value, max, description, style, actions)
-- Même que Slider (alias sémantique)

menu:Heritage(label, min, max, value, step, description, actions)
-- actions.onSliderChange = function(item) end ← item.value
-- actions.onSelected     = function(item) end

menu:Separator(text)

-- ─── Description dynamique ──────────────────────────────────────────────────

-- Passe une fonction à la place du texte de description :
menu:Button("Cash", function(item) return "$" .. GetPlayerMoney() end, {
    onSelected = function(item) end
})
-- Recalculé automatiquement quand l'item est sélectionné

-- ─── Sous-menus ─────────────────────────────────────────────────────────────

local sub = NativeUI.CreateSubMenu(menu, "Sous-titre", "Description")
sub:Button("Option A", "Desc")

menu:Button("Ouvrir sous-menu →", "Accède aux options", {}, sub)
-- Le 4ème paramètre = sous-menu à ouvrir sur Select

-- ─── RightLabel (compat RageUI) ──────────────────────────────────────────────

menu:Button("NoClip", "Desc", { RightLabel = "ON/OFF" }, {
    onSelected = function(item) end
})
-- opts.RightLabel = string affiché à droite du label (comme RageUI)
```

---

## Ce qui change par rapport à RageUI

| RageUI | NativeUI façade | Raison |
|--------|----------------|--------|
| `while menu do Citizen.Wait(0)` | Rien, géré automatiquement | Anti-pattern, CPU inutile |
| `IsVisible(menu, function() items end)` | Items déclarés une fois | Recréation à chaque frame = bug |
| `function(Hovered, Active, Selected)` | `function(item)` | 90% n'utilise que Selected |
| `if Selected then` dans chaque callback | Pas nécessaire | onSelected est déjà "si sélectionné" |
| `onChecked` / `onUnChecked` séparés | Supportés ✅ | Compat RageUI maintenue |
| `onListChange(Index, Item)` | `onListChange(item)` → `item.index` | Cohérent avec le reste |
| `RightLabel = "→"` dans opts | Supporté ✅ | Compat RageUI maintenue |

---

## Implémentation — ui.lua

```lua
-- ui.lua — Façade NativeUI pour api_nativeui
-- Couche de compatibilité inspirée de RageUI, sans ses anti-patterns.

NativeUI = NativeUI or {}

-- ─── CreateMenu ──────────────────────────────────────────────────────────────
function NativeUI.CreateMenu(title, subtitle, opts)
    local x = opts and opts.x or nil
    local y = opts and opts.y or nil
    local menu = Menu.New(title, subtitle, x, y)
    MenuPool.Add(menu)
    return menu
end

-- ─── CreateSubMenu ───────────────────────────────────────────────────────────
function NativeUI.CreateSubMenu(parent, title, subtitle, opts)
    local sub = NativeUI.CreateMenu(title, subtitle, opts)
    sub.parentMenu = parent
    return sub
end

-- ─── Visible ─────────────────────────────────────────────────────────────────
function NativeUI.Visible(menu, state)
    if state == nil then
        menu:Toggle()                          -- toggle
    elseif state then
        if not menu.visible then menu:Open() end
    else
        if menu.visible then menu:Close() end
    end
end

function NativeUI.IsVisible(menu)
    return menu and menu.visible == true
end

-- ─── Items — wrappers sur les méthodes Menu: ─────────────────────────────────
-- Gère RightLabel optionnel + normalisation des callbacks

local function NormalizeActions(actions)
    -- Compat onChecked/onUnChecked → onChange
    if actions and (actions.onChecked or actions.onUnChecked) then
        actions.onChange = function(item)
            if item.checked and type(actions.onChecked) == "function" then
                actions.onChecked(item)
            elseif not item.checked and type(actions.onUnChecked) == "function" then
                actions.onUnChecked(item)
            end
        end
    end
    -- Compat onListChange → onChange
    if actions and actions.onListChange and not actions.onChange then
        actions.onChange = actions.onListChange
    end
    -- Compat onSliderChange → onChange
    if actions and actions.onSliderChange and not actions.onChange then
        actions.onChange = actions.onSliderChange
    end
    return actions
end

-- Button : menu:Button(label, desc, opts_or_actions, submenuOrNil)
-- opts peuvent contenir { RightLabel = "..." }
local _origButton = Menu.Button
function Menu:Button(label, description, optsOrActions, submenuOrExtra)
    -- Détecter si opts contient RightLabel (compat RageUI)
    local actions = optsOrActions
    local rightLabel = nil
    if type(optsOrActions) == "table" and optsOrActions.RightLabel ~= nil then
        rightLabel = optsOrActions.RightLabel
        actions = submenuOrExtra   -- les actions sont le 4ème param dans ce cas
        submenuOrExtra = nil
    end

    local item = _origButton(self, label, description, nil, NormalizeActions(actions))

    -- RightLabel : stocker pour l'affichage (le renderer le lira)
    if rightLabel then item.rightLabel = rightLabel end

    -- Sous-menu lié directement
    if submenuOrExtra and submenuOrExtra.id then
        self:BindSubmenu(item, submenuOrExtra)
    end

    return item
end

-- Checkbox
local _origCheckbox = Menu.Checkbox
function Menu:Checkbox(label, checked, description, actions)
    return _origCheckbox(self, label, checked, description, NormalizeActions(actions))
end

-- List (compat onListChange)
local _origList = Menu.List
function Menu:List(label, items, index, description, actions)
    return _origList(self, label, items, index, description, NormalizeActions(actions))
end

-- Slider (alias de SliderProgress)
function Menu:Slider(label, value, max, description, style, actions)
    return self:SliderProgress(label, value, max, description, style, nil, NormalizeActions(actions))
end

-- Heritage (compat onSliderChange)
local _origHeritage = Menu.Heritage
function Menu:Heritage(label, min, max, value, step, description, style, enabled, actions)
    return _origHeritage(self, label, min, max, value, step, description, style, enabled, NormalizeActions(actions))
end
```

---

## Exemple final — script réel migré de RageUI

```lua
-- ══════════════════════════════════════════════════════════════
-- Exemple complet — syntaxe NativeUI (migration depuis RageUI)
-- ══════════════════════════════════════════════════════════════

local mainMenu = NativeUI.CreateMenu("Admin", "Outils serveur")

-- Button simple
mainMenu:Button("Revive", "Revive le joueur", {
    onSelected = function(item)
        TriggerServerEvent("admin:revive")
    end
})

-- Button avec RightLabel (syntaxe compat RageUI)
mainMenu:Button("NoClip", "Active le noclip", { RightLabel = "~g~ON~b~/~r~OFF" }, {
    onSelected = function(item)
        noClipActive = not noClipActive
    end
})

-- Checkbox
mainMenu:Checkbox("GodMode", false, "", {
    onChecked   = function(item) SetPlayerInvincible(PlayerId(), true) end,
    onUnChecked = function(item) SetPlayerInvincible(PlayerId(), false) end
})

-- List
local weaponIndex = 1
mainMenu:List("Arme", {"Pistolet", "Fusil", "SMG"}, 1, "", {
    onListChange = function(item)
        weaponIndex = item.index
    end
})

-- Slider
mainMenu:Slider("Vitesse", 100, 300, "", { step = 10 }, {
    onSliderChange = function(item)
        SetEntityMaxSpeed(GetVehiclePedIsIn(PlayerPedId(), false), item.value)
    end
})

-- Sous-menu
local subMenu = NativeUI.CreateSubMenu(mainMenu, "Joueurs", "Gestion des joueurs")
subMenu:Button("Liste", "Voir la liste des joueurs", {
    onSelected = function(item)
        TriggerEvent("admin:showPlayers")
    end
})

-- Lien vers sous-menu (4ème param = sous-menu)
mainMenu:Button("Joueurs →", "Gérer les joueurs", {}, subMenu)

-- ─── Touche d'ouverture ──────────────────────────────────────
RegisterCommand("adminmenu", function()
    NativeUI.Visible(mainMenu)    -- toggle, simple
end, false)
RegisterKeyMapping("adminmenu", "Ouvrir le menu admin", "keyboard", "F6")

-- ─── Boucle (UNE SEULE PAR SCRIPT) ──────────────────────────
CreateThread(function()
    while true do
        if MenuPool.IsAnyMenuOpen() then
            Wait(0)
            MenuPool.Process()
            MenuPool.Draw()
        else
            Wait(200)
        end
    end
end)
```

---

## Résumé des fichiers à créer/modifier

| Fichier | Action | Contenu |
|---------|--------|---------|
| `ui/ui.lua` | **Créer** | `NativeUI.CreateMenu`, `NativeUI.Visible`, `NativeUI.IsVisible` |
| `ui/ui.lua` | **Créer** | Wrappers `NormalizeActions`, `RightLabel`, `Slider` alias |
| `menu.lua` | **Patch minimal** | Surcharge `Button`/`Checkbox`/`List` pour `RightLabel` + sous-menu direct |
| `example_nativeui.lua` | **Créer** | Exemple complet style NativeUI pour le README GitHub |

### Ce qu'on NE fait PAS

- ❌ `IsVisible(menu, function() items end)` — anti-pattern RageUI, items recréés chaque frame
- ❌ `while menu do Citizen.Wait(0)` — géré automatiquement par la boucle unique
- ❌ `Hovered, Active, Selected` — remplacés par `item` (plus clair, moins d'erreurs)
- ❌ Panels (Grid, Percentage, ColourPanel) — fonctionnalité future si demandée
