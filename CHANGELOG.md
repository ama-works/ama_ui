# ama_ui — Changelog

## 2026-03-24

### Feature — core/menu.lua (rememberIndex)

- Nouvelle option `rememberIndex` (false par défaut) sur chaque menu/submenu
- Quand activée : `Close()` sauvegarde la position courante dans `_savedIndex`, `Open()` la restaure si l'item est toujours navigable
- Usage : `menu.rememberIndex = true` — fonctionne sur menus et submenus via le proxy existant
- Comportement par défaut inchangé (reset au premier item navigable)

### Feature — core/menu.lua (masquage titre avec header custom)

- Quand `dict`/`name` override sont définis sur un menu, le texte du titre n'est plus dessiné dans `_DrawHeader()`
- Comportement identique à NativeUI/RageUI : la bannière image remplace le titre texte

### Feature — ui/ui.lua (CreateSubMenu — syntaxe positionnelle dict/name)

- `CreateSubMenu` accepte maintenant un 5ème paramètre `nameArg` pour la syntaxe positionnelle :
  `ama_ui.CreateSubMenu(parent, "Titre", "Sub", "dict", "name")`
- Syntaxe table déjà supportée reste valide : `{ dict = "...", name = "..." }`

### Feature — ui/ui.lua + core/menu.lua (CreateMenu — dict/name header custom)

- `CreateMenu` supporte deux syntaxes pour le sprite header :
  - Table : `CreateMenu("T", "S", { dict = "commonmenu", name = "interaction_bgd" })`
  - Positionnelle : `CreateMenu("T", "S", "commonmenu", "interaction_bgd")`
- `Menu.New` stocke `_overrideHeaderDict/_overrideHeaderName` avec priorité sur `Config.Header.sprite`

---

## 2026-03-21

### Fix — shared/config.lua (collision Config cross-resource)

- `Config = {}` → `Config = Config or {}` (ligne 20)
- **Cause :** quand `@ama_ui/load.lua` s'exécutait dans le contexte client de `es_extended`, il écrasait le global `Config` ESX (qui contient `Config.Weapons`, `Config.RemoveHudComponents`, etc.) avec le Config ama_ui → erreurs `bad argument #1 to 'for iterator'` et `attempt to get length of a nil value`
- **Fix :** ama_ui étend maintenant le Config existant au lieu de le réinitialiser — compatible standalone ET cross-resource

### Fix — es_extended/fxmanifest.lua (shared_scripts)

- Retiré `@ama_ui/shared/config.lua` des `shared_scripts` d'es_extended
- Inutile : le serveur n'utilise pas ama_ui, et le client charge déjà la config via `@ama_ui/load.lua`

---

## 2026-03-19

### UI — ui.lua (souscription événements cross-resource)

- `proxy.OnClose(cb)` — souscrit au `OnMenuClosed` du vrai menu (cross-resource safe via cfx function reference)
- `proxy.OnItemSelect(cb)` — souscrit au `OnItemSelect`
- `proxy.OnNavChange(cb)` — souscrit au `OnIndexChange`
- Nécessaire car la metatable du proxy est strippée par FiveM lors de la sérialisation MsgPack cross-resource → `menu.OnMenuClosed` était nil depuis un autre VM

---

## 2026-03-18

### Exports — fxmanifest.lua + imports.lua (librairie partagée)

- `fxmanifest.lua` — `client_exports { 'getSharedObject' }` déclaré (requis FiveM pour appels cross-resource)
- `imports.lua` — **nouveau fichier** bootstrap pour les consumers :
  - Remplace les 27–34 lignes `@ama_ui/...` dans les fxmanifest des autres resources par **1 ligne** : `'@ama_ui/imports.lua'`
  - Pose le global `ama_ui = exports['ama_ui']:getSharedObject()`
  - Expose les panels comme globaux : `ColorPanel`, `GridPanel`, `GridPanelH`, `GridPanelV`, `PercentagePanel`, `StatisticsPanel`, `StatisticsPanelAdvanced`

---

## 2026-03-12

### UI — ui.lua (refactor cross-resource proxy)

- `_menuRegistry` — registry interne `id → menu réel` : permet de retrouver le vrai menu même après sérialisation MsgPack (cross-resource)
- `_makeWinProxy(win)` — proxy pour `UIMenuWindowHeritageItem` : expose `SetMum`, `SetDad`, `heritage` comme méthodes directes survivant à MsgPack
- `ama_ui.CreateMenu()` — retourne désormais un **proxy** complet avec bound methods :
  - `proxy.Window`, `Button`, `List`, `Checkbox`, `Slider`, `SliderProgress`, `Heritage`, `Separator`, `Progress`, `SetPanels`, `AddItem`, `Refresh`
  - `proxy.Open`, `Close`, `Toggle` — contrôle visibilité direct
  - `proxy.BindSubmenu` — navigation sous-menus
  - `setmetatable` sur le proxy → accès live aux champs du vrai menu (same-resource)
- `ama_ui.CreateSubMenu()` — résolution du parent via `_menuRegistry` (cross-resource safe)
- `ama_ui.Visible()` / `IsVisible()` — acceptent maintenant un proxy cross-resource (lookup via `id`)
- `ama_ui.DynDesc(item, fn)` — nouveau helper façade → `item:SetDynDesc(fn)` (chainable)
- **Panels exposés dans `ama_ui.*`** — accessibles via `getSharedObject` depuis d'autres ressources :
  - `ama_ui.StatisticsPanel`, `ama_ui.StatisticsPanelAdvanced`
  - `ama_ui.ColorPanel`, `ama_ui.GridPanel`, `ama_ui.GridPanelH`, `ama_ui.GridPanelV`
  - `ama_ui.PercentagePanel`

---

## 2026-03-11

### Config — config.lua (nouveau style visuel)

- `Config.NewStyle` — style alternatif activé par défaut (`enabled = true`) :
  - `itemRow` — rows gris inset (`offsetX = 15`) avec gap visuel entre items (`gapPx = 3`) au lieu du white highlight NativeUI classique
  - `arrow` — flèche de sélection orange (sprite `icon/arrow_right_36dp`, `color = {241, 101, 34}`) sur l'item courant
  - `label.offsetX/Y` — override de la position du label gauche pour tous les items en mode NewStyle
  - `selectedColor` — couleur texte cyan `{0, 255, 255}` sur l'item sélectionné (remplace les `.color.selected` individuels)
- Commentaires explicatifs enrichis dans la section sync-largeurs (guide `_W` → éléments dérivés)

### Core — menu.lua (rendu NewStyle)

- `_DrawItems()` — rendu bifurqué selon `Config.NewStyle.enabled` :
  - **NewStyle ON** : grey rect inset (gap), flèche orange sprite, couleur texte override cyan
  - **NewStyle OFF** : comportement NativeUI classique (white highlight)
  - Toutes les valeurs NewStyle pré-normalisées dans `_Recalculate` → **zéro calcul en frame**
- `_Recalculate()` — pré-calcul des upvalues NewStyle (`_itemRowNX`, `_itemRowNW`, `_itemRowGapH`, `_arNX`, `_arNW`, `_arNH`, `_arNYOff`, `_nsSelColR/G/B/A`, etc.)

---

## 2026-03-10

### Items — base.lua (refactor majeur — classe mère unifiée)

Centralisation de toute la logique commune dans `BaseItem` — supprime les ~15 blocs dupliqués dans chaque item :

- `BaseItem.GetColor(colorTable, isEnabled, isSelected)` — helper statique 3-way (disabled → selected → default)
- `BaseItem.ResolveColor(default, selected, disabled, isEnabled, isSelected)` — version **zero-alloc** (pas de table wrapper temporaire par frame)
- `BaseItem.Clamp(v, min, max)` — helper statique (remplace les inline min/max partout)
- `BaseItem:SetText(text)` — marque `_dirty = true` + `_needsRecalculate = true` sur le parent
- `BaseItem:SetDescription(desc)` — annule `_descFn` dynamique existante
- `BaseItem:SetDynDesc(fn)` — description dynamique : `fn(item)` appelée chaque frame, `nil` pour retirer
- `BaseItem:SetEnabled(enabled)` — marque `_dirty = true` sur le parent
- `BaseItem:SetValue(value)` — clamp + émet `OnProgressChanged` (centralisé depuis slider/progress/heritage)
- `BaseItem:SetMax(max)` — change le max + re-clamp la valeur
- `BaseItem:GetStep()` — lit `self._step` en priorité, puis `self.style.step` (compat legacy)
- `BaseItem:Next()` / `Prev()` — incrémente/décrémente d'un step (noop si pas de `value`)
- `BaseItem:Destroy()` — nettoyage unifié : clear tous les events (`OnActivated`, `OnProgressChanged`, `OnCheckboxChange`, `OnListChanged`) + `setmetatable(self, nil)`

### Items — progress.lua (héritage BaseItem + DrawCustom optimisé)

- `UIMenuProgressItem` hérite désormais de `BaseItem` via `setmetatable({}, {__index = BaseItem})`
- `actions.onChange` — nouveau callback : `function(item, value, max)` (en plus de `onSelect`)
- `DrawCustom` — chemin optimisé : utilise les valeurs pré-normalisées `_barNX`, `_barNW`, `_barNH`, `_barNYOff`, `_barBgR/G/B/A`, `_barFiR/G/B/A` (remplis par `_Recalculate`) — zéro lookup config en frame
- `DrawProgress` — alias global ajouté (`DrawProgress = UIMenuProgressItem`)
- `BaseItem.Clamp` et `BaseItem.ResolveColor` utilisés en interne (supprime les duplications)

---

## 2026-03-09

### Items — Standardisation signatures `.New()` (breaking internal, façade inchangée)

Alignement complet des constructeurs sur le pattern `(données…, description, enabled, actions)` :

- `items/checkbox.lua` — `UIMenuCheckbox.New(text, checked, description, enabled, actions)`
  - Ajout `enabled` avant `actions` (était absent)
- `items/list.lua` — `UIMenuList.New(text, items, index, description, enabled, actions)`
  - Ajout `enabled` avant `actions` (était absent)
- `items/slider.lua` — `UIMenuSliderProgress.New(text, start, max, description, enabled, actions)`
  - Suppression param `style` (step → `actions.step`)
  - `onSelected` → `onSelect` dans le binding actions
- `items/progress.lua` — `UIMenuProgressItem.New(text, start, max, description, enabled, actions)`
  - Idem slider : suppression `style`, `onSelected` → `onSelect`
- `items/heritage.lua` — `UIMenuSliderHeritageItem.New(text, min, max, value, description, enabled, actions)`
  - Suppression params positionnels `step` et `style` (→ `actions.step`)
  - `OnSliderChanged` renommé `OnProgressChanged` (unification avec slider/progress)
  - `onSelected` → `onSelect` dans le binding actions

### Base — base.lua (unification)

- `GetStep()` : lit `self._step` en priorité, puis `self.style.step` (compat legacy)
- `SetValue()` : n'émet plus que `OnProgressChanged` (suppression `OnSliderChanged.Emit`)
- `Destroy()` : nettoyage adapté (plus de ref à `OnSliderChanged`)

### Core — menu.lua (wrappers façade)

- `NormalizeActions()` : passe désormais `step` à travers (upvalue `n.step = tonumber(actions.step)`)
- `Menu:List(label, items, index, description, enabled, actions)` — `enabled` ajouté
- `Menu:Checkbox(label, checked, description, enabled, actions)` — `enabled` ajouté
- `Menu:SliderProgress(label, start, max, description, enabled, actions)` — `style` supprimé
- `Menu:Slider(label, value, max, description, enabled, actions)` — signature simplifiée
- `Menu:Progress(label, value, max, description, enabled, actions)` — `style` supprimé
- `Menu:Heritage(label, min, max, value, description, enabled, actions)` — `step`/`style` supprimés

> La façade publique (`onSelected`, `onSliderChange`, `onChecked`…) reste rétrocompatible via `NormalizeActions`.

---

## 2026-03-07

### Panels — GridPanel, GridPanelH, GridPanelV (nouveaux)
- `panels/grid_panel.lua` — `GridPanel(x, y, topText, bottomText, leftText, rightText, callback, index?)`
  - Grille 2D (sprite `pause_menu_pages_char_mom_dad/nose_grid`) + cercle curseur (`mpinventory/in_world_circle`)
  - Interaction souris drag-and-drop : `IsDisabledControlPressed(0, 24)` → met à jour X, Y dans [0..1]
  - Callback : `function(hovered, active, x, y)`
- `panels/grid_panel_h.lua` — `GridPanelH(x, leftText, rightText, callback, index?)` — axe X uniquement, Y fixé à 0.5
- `panels/grid_panel_v.lua` — `GridPanelV(y, topText, bottomText, callback, index?)` — axe Y uniquement, X fixé à 0.5

### Panels — ColorPanel (nouveau)
- `panels/color_panel.lua` — `ColorPanel(title, colors, minIdx, curIdx, callback, index?, mouseOnly?)`
  - Fenêtre glissante de carrés couleur (scroll automatique autour de `curIdx`)
  - Navigation souris (hover/clic) + clavier ← → sauf si `mouseOnly = true`
  - Cache titre (évite `string.format` à chaque frame) — table `_cp_color` réutilisée (zéro GC)
  - Callback : `function(hovered, active, newMinIdx, newCurIdx)`

### Panels — StatisticsPanel (fix diviseurs)
- `panels/statistics_panel.lua` — Diviseurs proportionnels : `divStep = barW / (divN + 1)`
  - Corrige le bug où la dernière barre était plus petite que les autres (copie des 5 valeurs absolues de RageUI)
  - Valeur par défaut `divCount = 4` dans `Config.StatisticsPanel.bar`

### Items — Button (syntaxe unifiée)
- `items/button.lua` — `UIMenuButton.New(text, description, enabled, actions)`
  - Nouveau pattern : `actions = { onSelect = function(item) ... end }`
  - Rétrocompat : ancien pattern `actions` = function directe encore supporté

### Renderer — text.lua
- `renderer/text.lua` — Mise à jour (cache texte, DrawRaw sans division)

### Config — config.lua
- `shared/config.lua` — Ajout des sections `Config.GridPanel`, `Config.GridPanelH`, `Config.GridPanelV`, `Config.ColorPanel`
  - Sync largeur : toutes les largeurs dérivées de `Config.Header.size.width` recalculées en bas de fichier

### Couleurs — badge_style.lua (nouveau)
- `color/badge_style.lua` — Styles de badges (4 variantes : aucun, Rockstar, couronne, alerte)

### fxmanifest.lua
- Ajout des panels `grid_panel.lua`, `grid_panel_h.lua`, `grid_panel_v.lua`, `color_panel.lua`
- Ajout de `color/badge_style.lua`

---

## 2026-03-06

### Core — pool.lua
- `core/pool.lua` — MenuPool : compteurs atomiques pour détection changements (évite itérations complètes)

---

## 2026-03-04

### Items — Windows, SeparatorJump, List
- `items/windows.lua` — `UIMenuWindowHeritageItem` : portraits mère/père pour le créateur de personnage (indices mère 0–20, père 0–23)
- `items/separator_jump.lua` — `SeparatorJump` : séparateur que la navigation clavier saute automatiquement
- `items/list.lua` — `UIMenuList` : sélecteur ← valeur → avec boucle infinie

### Input — navigation.lua, controller.lua
- `input/navigation.lua` — Gestion complète clavier/souris (Up/Down/Select/Back + détection souris active)
- `input/controller.lua` — Support manette (IsDisabledControlJustPressed pour chaque action)

### API — ui/imports.lua
- `ui/imports.lua` — Imports publics mis à jour (`ama_ui.CreateMenu`, `ama_ui.Visible`, `MenuPool.Process`)

### Core — main.lua
- `main.lua` — Point d'entrée : initialisation dans l'ordre correct (cache → renderer → items → panels → input)

---

## 2026-02-27

### Renderer — Glare (non-bloquant)
- `renderer/glare.lua` — `Glare.Init()` / `Glare.Draw(x, y, w, h)` / `Glare.Cleanup()`
  - Pattern non-bloquant : zéro `Wait()`, chargement vérifié par `HasScaleformMovieLoaded` chaque frame
  - `Config.Header.glare.enabled = true` requis pour l'afficher
- `renderer/colors.lua` — Palette de couleurs HUD natives GTA V (96 couleurs)

---

## 2026-02-25

### Items — Checkbox, Slider, Progress, Heritage
- `items/checkbox.lua` — `UIMenuCheckbox` : toggle On/Off avec sprite GTA (`commonmenu/common_medal`)
- `items/slider.lua` — `UIMenuSliderProgress` : barre horizontale contrôlée ← →
- `items/progress.lua` — `UIMenuProgressItem` : barre passive (santé, stamina, etc.)
- `items/heritage.lua` — `UIMenuSliderHeritageItem` : slider fill-from-center (ADN mère/père)

### Renderer — draw.lua, box.lua, scaleform.lua
- `renderer/draw.lua` — `Draw.Rect`, `Draw.RectRaw`, `Draw.Sprite`, `Draw.SpriteRaw`, `Draw.Scaleform`
  - Normalisation inline avec cache `(1/W, 1/H)` — évite divisions répétées
- `renderer/box.lua` — `Box.Draw` : rect avec bordures configurables
- `renderer/scaleform.lua` — `Draw.Scaleform` : dessin scaleform avec normalisation pixels → [0..1]

---

## 2026-02-23

### Core — events.lua, cache.lua
- `core/events.lua` — `Event.New()` / `event.On(cb)` / `event.Emit(data)` — pattern pub/sub léger sans allocation
- `core/cache.lua` — `Cache.Resolution` (1920×1080 fallback) + `Cache.AspectRatio` — mis à jour à chaque `_Recalculate`

### Couleurs — items_colour.lua, panel_colour.lua
- `color/items_colour.lua` — Couleurs des items (texte, fond, highlight, disabled)
- `color/panel_colour.lua` — Palettes prédéfinies pour ColorPanel (`PanelColour.HairCut`, `PanelColour.Vehicle`, etc.)

---

## Notes importantes

- `Config.Header.glare.enabled` doit être `true` pour activer le glare
- `Glare.Init()` est non-bloquant — ne pas mettre dans une boucle avec `Wait()`
- Diviseurs StatisticsPanel : `divStep = barW / (divCount + 1)` — 4 diviseurs par défaut
- `Index` dans les panels : si fourni, le panel n'est dessiné que si `menu.currentItem == Index`
- Tous les panels utilisent des coordonnées pixels 1080p — la normalisation est faite dans les primitives `Draw.*`
