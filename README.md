# ama_ui

Librairie de menus 2D pour FiveM, basée sur le rendu natif GTA V (DrawRect / DrawSprite / Text).
Compatible **ESX Legacy** — conçue pour être utilisée avec **ama_module** et **es_extended**.

---

## Utilisation dans une resource

```lua
-- fxmanifest.lua
dependency 'ama_ui'

client_scripts {
    '@ama_ui/load.lua',  -- charge tout ama_ui dans ce contexte Lua
    'client/*.lua',
}
```

```lua
-- client/main.lua
local menu = Menu.New("Titre", "Sous-titre")
menu:Button("Mon bouton", "description", { onSelected = function() end })
menu:Open()
```

> `@ama_ui/load.lua` charge tous les fichiers ama_ui directement dans le contexte Lua du consommateur — sans sérialisation MsgPack.

---

## Structure

```
ama_ui/
├── shared/config.lua       Config centrale (tailles, couleurs, polices)
├── color/                  Palettes GTA V (ItemsColour, HairCut, BadgeStyle)
├── core/
│   ├── cache.lua           Résolution / aspect ratio / safe zone
│   ├── events.lua          Event.New() — pub/sub interne
│   ├── pool.lua            MenuPool
│   └── menu.lua            Menu principal
├── renderer/
│   ├── draw.lua            Draw.Rect / Sprite / Scaleform (coords pixels → normalisé)
│   ├── text.lua            Text.Draw / DrawRaw / GetWidth (avec cache)
│   ├── rectangle.lua       Rectangle OOP
│   ├── sprite.lua          Sprite OOP
│   ├── scaleform.lua       Scaleform OOP
│   ├── glare.lua           Effet glare header
│   └── box.lua             UIaMa.DrawBox
├── items/                  Button, Checkbox, List, Slider, Progress, Heritage, Window, Separator
├── panels/                 ColorPanel, GridPanel, PercentagePanel, StatisticsPanel
├── input/                  Navigation clavier/manette/souris
├── ui/ui.lua               Façade publique
├── load.lua                Chargeur cross-resource (pattern @ama_ui/load.lua)
└── imports.lua             Export getSharedObject (rétrocompatibilité)
```

---

## API publique

```lua
-- Menus
local menu = Menu.New("Titre", "Sous-titre", x, y)
local pool = MenuPool  -- singleton

-- Items
menu:Button("Label", "desc", { onSelected = fn })
menu:Checkbox("Label", false, "desc", { onChecked = fn })
menu:List("Label", { "A","B","C" }, 1, "desc", { onListChange = fn })
menu:Slider("Label", 0, 100, "desc", { step = 5 }, { onSliderChange = fn })
menu:Progress("Label", 50, 100, "desc")
menu:Heritage("Label", 0, 100, 50, 1, "desc", { onSliderChange = fn })
menu:Window(mumIndex, dadIndex)
menu:Separator("Texte")
menu:SetPanels(function() StatisticsPanel(0.8, "Vitesse", itemIndex) end)

-- Visibilité
menu:Open()
menu:Close()
menu:Toggle()
```

---

## Dépendances

Aucune — fonctionne en standalone sur tout serveur FiveM GTA V.

---

## Projet

Développé pour le serveur **AMA Works** (ESX Legacy).
Resources associées : `ama_module`, `es_extended`.
