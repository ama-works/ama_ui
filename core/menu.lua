
-- core/menu.lua
Menu = {}
Menu.__index = Menu

-- Wrappers locaux vers les fonctions Raw de draw.lua / text.lua.
-- Déclarés comme fonctions (jamais nil) pour satisfaire l'analyse statique.
-- draw.lua et text.lua sont chargés avant menu.lua dans fxmanifest.
local function _fnSpriteRaw(dict, name, nx, ny, nw, nh, heading, r, g, b, a)
    return Draw.SpriteRaw(dict, name, nx, ny, nw, nh, heading, r, g, b, a)
end
local function _fnRectRaw(nx, ny, nw, nh, r, g, b, a)
    Draw.RectRaw(nx, ny, nw, nh, r, g, b, a)
end
local function _fnDrawRaw(text, nx, ny, font, scale, r, g, b, a, alignment, nxWrap)
    Text.DrawRaw(text, nx, ny, font, scale, r, g, b, a, alignment, nxWrap)
end
local function _fnDrawRawShadow(text, nx, ny, font, scale, r, g, b, a, alignment, sDist, sr, sg, sb, sa)
    Text.DrawRawShadow(text, nx, ny, font, scale, r, g, b, a, alignment, sDist, sr, sg, sb, sa)
end


---@param title string
---@param subtitle string
---@param x number
---@param y number
-- CrÃ©er un nouveau menu
function Menu.New(title, subtitle, x, y)
    local self = setmetatable({}, Menu)

    -- ID unique
    self.id = GenerateUUID()
    
    -- Proprieter de base
    self.title = title or "Menu"
    self.subtitle = subtitle or ""
    self.visible = false
    
    -- Position
    -- Note: la position x est la mÃªme pour tous les items (aligne a gauche), la position y du premier item est determine par self.y + header + subtitle, et les items suivants sont espacÃ©s verticalement par itemHeight.
    -- Donc en pratique, self.x et self.y dÃ©terminent la position du menu dans son ensemble, et les items sont positionnÃ©s relativement a cette ancre.
    self.x = x or Config.MenuPosition.x
    self.y = y or Config.MenuPosition.y
    
    -- Items
    -- determiner par self.currentItem et self.maxItemsOnScreen pour le rendu et la navigation
    -- Note: les items sont stockÃ©s dans une table indexÃ©e de 1 Ã  n, oÃ¹ n est le nombre total d'items. L'index de chaque item dans cette table dÃ©termine sa position verticale dans le menu (en fonction de l'index du premier item affichÃ© et de l'espacement).
    -- Exemple: self.items[1] est le premier item, self.items[2] le deuxiÃ¨me, etc. Si self.currentItem = 1 et self.maxItemsOnScreen = 10, alors on affiche self.items[1] a self.items[10]. Si self.currentItem = 5, on peut afficher self.items[1] Ã  self.items[10] ou self.items[2] Ã  self.items[11], etc. en fonction de la logique de centrage.
    self.items = {}
    self.currentItem = 1
    self.minItem = 1
    self.maxItem = 10
    self.maxItemsOnScreen = 10
    
    -- Navigation
    -- Note: self.parentMenu est utilisé pour la navigation en arriere (go back). Si self.parentMenu est nil, le menu se ferme au lieu de revenir en arriere.
    -- self.children peut etre utilisÃ© pour gerer des sous-menus, mais ce n'est pas encore implÃ©mentÃ© dans la logique de navigation. C'est juste une structure de donnes pour l'instant.
    self.parentMenu = nil
    self.children = {}
    
    -- Flags d'optimisation
    -- _dirty: indique que quelque chose a change qui nécessite une mise a jour visuelle (ex: ajouter/supprimer un item, changer le titre, etc.)
    -- _needsRecalculate: indique que les positions des items doivent etre recalcules (ex: ajouter/supprimer un item, changer la taille du menu, etc.)
    -- _cachedPositions: cache des positions x,y de chaque item pour le dessin et la navigation, recalculÃ© uniquement si _needsRecalculate est true
    self._dirty = true
    self._needsRecalculate = true
    self._cachedPositions = {}
    
    -- Events
    -- Note: les events sont des instances de la classe Event, qui gÃ¨re les listeners et l'emission. Les events du menu sont: OnMenuOpened, OnMenuClosed, OnItemSelect (avec l'item et l'index), OnIndexChange (avec le nouvel index).
    -- Les items ont aussi leurs propres events, comme OnActivated, OnListChanged, etc. qui sont Ãmis par l'item lui-meme et peuvent etre Ãcoutons par le menu ou par d'autres scripts.
    -- Exemple d'utilisation des events: myMenu.OnItemSelect:AddListener(function(menu, item, index) print("Selected item: " .. item.text) end)
    self.OnMenuOpened = Event.New()
    self.OnMenuClosed = Event.New()
    self.OnItemSelect = Event.New()
    self.OnIndexChange = Event.New()
    
    -- Composants UI (cree UNE SEULE FOIS)
    -- Note: ces composants sont des structures de données qui contiennent les informations nécessaires pour dessiner chaque partie du menu (header, subtitle, items, description). Ils sont mis a jour lorsque les propriétés du menu changent (ex: changer le titre met a jour self._header), et sont utilisés dans la boucle de dessin pour rendre le menu.
    -- Par exemple, self._header peut contenir le texte, la position, la couleur, etc. du header, et est mis a jour dans la fonction SetTitle ou dans le constructeur. De meme pour self._subtitle et self._items (qui peut etre une table de composants pour chaque item).
    self._header = nil
    self._subtitle = nil
    self._items = {}
    self._description = nil
    
    -- Autres propriétés
    -- Note: ces propriétés sont utilisées pour gérer l'état du menu et optimiser les performances. Par exemple, _justOpened peut etre utilisé pour appliquer des effets d'ouverture uniquement lors de la première frame d'affichage du menu, _lastInputTime et _inputDelay peuvent etre utilisés pour limiter la fréquence de traitement des inputs et éviter les actions rapides involontaires, _descMeasureCache peut etre utilisé pour stocker les mesures de hauteur des descriptions afin d'éviter de recalculer à chaque frame.
    -- exemple d'utilisation de _justOpened: dans la boucle de dessin, si self._justOpened est true, on peut appliquer un effet de fade-in ou de slide-in pour le menu, puis on met self._justOpened à false pour ne pas réappliquer l'effet les frames suivantes.
    self._justOpened = false
    self._lastInputTime = 0
    self._inputDelay = 150

    -- Cache description (auto-size)
    -- Structure: self._descMeasureCache[paramsKey][description] = { lineCount = n, height = px }
    -- paramsKey is a string generated from the parameters that affect description measurement (e.g. menu width, font, font size). This allows us to have different caches for different menu configurations.
    -- Example of paramsKey: "w400_f0_s0.26" for menu width 400, font 0, size 0.26
    -- The description text is often dynamic and can be long, so we want to measure its height to apply auto-sizing and proper background. However, measuring text can be expensive, so we cache the results based on the description content and the relevant parameters that affect its size.
    self._descMeasureCache = {}
    self._descMeasureParamsKey = nil
    self._descMeasureParams = nil

    -- Panels (style RageUI) — stocke la closure passée via menu:SetPanels(fn)
    self._panelsFn = nil

    -- Cache positions header/subtitle (rempli par _Recalculate, jamais recomputed en Draw)
    self._titleX    = nil
    self._titleY    = nil
    self._subtitleX = nil
    self._subtitleY = nil
    self._counterX  = nil
    self._counterY  = nil
    -- Counter text precalcule (mis a jour par _UpdateCounter, pas par frame)
    self._counterText = nil

    -- Cache dimensions (évite 13× lookups Config par frame)
    self._menuWidth      = Config.Header.size.width
    self._headerHeight   = Config.Header.size.height
    self._subtitleHeight = Config.Subtitle.size.height
    self._itemHeight     = (Config.Layout and Config.Layout.itemHeight) or 35

    -- Cache config par type d'item (évite GetItemTypeConfig() par item par frame)
    self._itemTypeCfg = {
        list          = Config.List          or Config.Button,
        checkbox      = Config.Checkbox      or Config.Button,
        sliderprogress= Config.SliderProgress or Config.Button,
        heritage      = Config.Heritage      or Config.SliderProgress or Config.Button,
        progress      = Config.Progress      or Config.Button,
        button        = Config.Button,
        window        = {},
        panel         = {},
        separator     = Config.Separator     or {},
    }

    -- Cache indices/hauteur visibles (mis à jour par _UpdateVisibleRange)
    self._visibleStart       = 1
    self._visibleEnd         = 1
    self._visibleTotalHeight = 0

    return self
end

---@param item UIMenuItem
-- Ajouter un item
-- Note: cette fonction ajoute un item à la fin de la liste des items du menu. L'index de l'item est déterminé par sa position dans la table self.items. Après avoir ajouté l'item, on marque le menu comme dirty et nécessitant un recalcul pour que les positions soient mises à jour et que le menu soit redessiné avec le nouvel item.
-- Exemple d'utilisation: local item1 = UIMenuButton.New("Option 1", "Description 1"); myMenu:AddItem(item1)

function Menu:AddItem(item)
    if not item then return end

    table.insert(self.items, item)
    item.parent = self
    item.index = #self.items

    self._dirty = true
    self._needsRecalculate = true
    self:_UpdateCounter()

    return item
end

---@param items table
-- Note: cette fonction prend une table d'items et les ajoute un par un en utilisant la fonction AddItem. Cela permet d'ajouter plusieurs items en une seule opération, ce qui peut être plus pratique et plus performant que d'appeler AddItem plusieurs fois depuis l'extérieur.
-- Exemple d'utilisation: local items = { UIMenuButton.New("Option 1", "Description 1"), UIMenuButton.New("Option 2", "Description 2") }; myMenu:AddItems(items)
-- Note: la table d'items doit être une table indexée de 1 à n, où chaque élément est un item valide (ex: UIMenuButton, UIMenuList, etc.). La fonction AddItems ne vérifie pas la validité de chaque item, elle se contente de les ajouter à la liste du menu.
-- Ajouter plusieurs items
function Menu:AddItems(items)
    if not items then return end
    
    for _, item in ipairs(items) do
        self:AddItem(item)
    end
end

-- ============================================================================
-- Normalisation des callbacks ama_ui → API interne
-- onSelected      → onSelect
-- onListChange    → onChange
-- onSliderChange  → onChange
-- onChecked / onUnChecked → onChange (Checkbox)
-- ============================================================================
local function NormalizeActions(actions)
    if not actions or type(actions) ~= "table" then return nil end
    -- ⚡ Early-return si aucune clé pertinente (évite de créer une table vide)
    if not (actions.onSelected or actions.onSelect or actions.onListChange
        or actions.onSliderChange or actions.onChange
        or actions.onChecked or actions.onUnChecked or actions.step) then
        return nil
    end
    local n = {}
    if actions.step then n.step = tonumber(actions.step) end

    if type(actions.onSelected) == "function" then
        n.onSelect = actions.onSelected
    elseif type(actions.onSelect) == "function" then
        n.onSelect = actions.onSelect
    end

    if type(actions.onListChange) == "function" then
        n.onChange = actions.onListChange
    elseif type(actions.onSliderChange) == "function" then
        n.onChange = actions.onSliderChange
    elseif type(actions.onChange) == "function" then
        n.onChange = actions.onChange
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

-- ===== Raccourcis syntaxiques =====

--- Bouton simple, avec RightLabel ou avec sous-menu.
-- Signatures supportées :
--   menu:Button("label", "desc", { onSelected = fn })
--   menu:Button("label", "desc", { RightLabel = "ON/OFF" }, { onSelected = fn })
--   menu:Button("label", "desc", {}, sousMenu)
---@param label        string
---@param description  string|nil
---@param optsOrActions table|nil  { onSelected=fn } ou { RightLabel="..." }
---@param extra         table|nil  actions ou sous-menu
function Menu:Button(label, description, optsOrActions, extra)
    local actions    = optsOrActions
    local submenu    = extra
    local rightLabel = nil

    if type(optsOrActions) == "table" and
       (optsOrActions.RightLabel ~= nil or optsOrActions.RightBadge ~= nil or optsOrActions.LeftBadge ~= nil) then
        rightLabel = optsOrActions.RightLabel
        actions    = extra
        submenu    = nil
    elseif type(extra) == "table" and extra.id ~= nil then
        actions = optsOrActions
        submenu = extra
    end

    local item = self:AddItem(UIMenuButton.New(label, description, true, NormalizeActions(actions)))

    if rightLabel then item.rightLabel = rightLabel end
    if type(optsOrActions) == "table" then
        if optsOrActions.RightBadge ~= nil then item.rightBadge = optsOrActions.RightBadge; self._needsRecalculate = true end
        if optsOrActions.LeftBadge  ~= nil then item.leftBadge  = optsOrActions.LeftBadge;  self._needsRecalculate = true end
    end

    if submenu and submenu.id then
        self:BindSubmenu(item, submenu)
    end

    return item
end


--- Liste de valeurs avec flèches ← →
-- Note: items est une table indexée de 1 à n contenant les différentes options de la liste. index est l'index de l'option actuellement sélectionnée (commençant à 1). Si actions.onChange est défini, il sera appelé lorsque l'utilisateur change l'option sélectionnée, avec le menu, l'item et le nouvel index en paramètre. Si actions.onSelect est défini, il sera appelé lorsque l'item est sélectionné, avec le menu, l'item et l'index actuel en paramètre.
-- Exemple d'utilisation: myMenu:List("Difficulty", {"Easy", "Medium", "Hard"}, 2, "Select difficulty level", { onChange = function(menu, item, newIndex) print("New difficulty: " .. item.items[newIndex]) end })
-- note: pour les listes, on peut aussi gérer des sous-tables d'options pour chaque item, par exemple si on veut que certaines options soient disponibles uniquement pour certains items. Dans ce cas, la table items peut être une table de tables, et le code de l'item List doit être adapté pour gérer cette structure. Cependant, dans la version actuelle, on suppose que items est une table simple d'options.
---@param text        string
---@param items       table
---@param index       number|nil
---@param description string|nil
---@param enabled     boolean|nil
---@param actions     table|nil   { onChange=fn, onSelect=fn }
function Menu:List(label, items, index, description, enabled, actions)
    return self:AddItem(UIMenuList.New(label, items, index, description, enabled, NormalizeActions(actions)))
end

---@param text        string
---@param checked     boolean|nil
---@param description string|nil
---@param enabled     boolean|nil
---@param actions     table|nil   { onChange=fn, onSelect=fn }
function Menu:Checkbox(label, checked, description, enabled, actions)
    return self:AddItem(UIMenuCheckbox.New(label, checked, description, enabled, NormalizeActions(actions)))
end

---@param label        string
---@param progressStart number
---@param progressMax   number
---@param description   string|nil
---@param enabled       boolean|nil
---@param actions       table|nil   { step=number, onChange=fn, onSelect=fn }
function Menu:SliderProgress(label, progressStart, progressMax, description, enabled, actions)
    return self:AddItem(UIMenuSliderProgress.New(label, progressStart, progressMax, description, enabled, NormalizeActions(actions)))
end

---@param label        string
---@param value        number
---@param max          number
---@param description  string|nil
---@param enabled      boolean|nil
---@param actions      table|nil  { step=number, onChange=fn, onSelect=fn }
function Menu:Slider(label, value, max, description, enabled, actions)
    return self:SliderProgress(label, value, max, description, enabled, actions)
end

---@param text          string
---@param progressStart number
---@param progressMax   number
---@param description   string|nil
---@param enabled       boolean|nil
---@param actions       table|nil
function Menu:Progress(text, progressStart, progressMax, description, enabled, actions)
    return self:AddItem(UIMenuProgressItem.New(text, progressStart, progressMax, description, enabled, actions))
end

---@param label       string
---@param min         number
---@param max         number
---@param value       number
---@param description string|nil
---@param enabled     boolean|nil
---@param actions     table|nil  { step=number, onChange=fn, onSelect=fn }
function Menu:Heritage(label, min, max, value, description, enabled, actions)
    return self:AddItem(UIMenuSliderHeritageItem.New(label, min, max, value, description, enabled, NormalizeActions(actions)))
end

--- Panneau portrait héritage (mère/père) — non navigable, hauteur propre
---@param mumIndex number|nil  0-20
---@param dadIndex number|nil  0-23
function Menu:Window(mumIndex, dadIndex)
    return self:AddItem(UIMenuWindowHeritageItem.New(mumIndex, dadIndex))
end

-- Separateur simple (non cliquable)
-- Note: ce type d'item est utilisé pour séparer visuellement les sections du menu. Il n'est pas sélectionnable et ne déclenche aucun événement. Le paramètre text peut être utilisé pour afficher un label au-dessus du séparateur, ou il peut être laissé vide pour un simple trait de séparation.
-- Exemple d'utilisation: myMenu:Separator("Settings") pour ajouter un séparateur avec le label "Settings", ou myMenu:Separator("") pour un simple trait de séparation sans label.
--- @param text string
-- myMenu:Separator("label") â†’ sÃ©parateur qui saute (navigation skip)
function Menu:Separator(text)
    return self:AddItem(UIMenuSeparatorJump.New(text))
end

-- Note : remove item
-- Cette fonction prend un item en paramètre et le retire de la liste des items du menu. Elle parcourt la table self.items pour trouver l'item correspondant, et si elle le trouve, elle le supprime de la table. Après avoir retiré l'item, on marque le menu comme dirty et nécessitant un recalcul pour que les positions soient mises à jour et que le menu soit redessiné sans l'item retiré.
-- Exemple d'utilisation: myMenu:RemoveItem(item1) pour retirer l'item1 du menu. La fonction retourne true si l'item a été trouvé et retiré, ou false si l'item n'était pas dans la liste.
---@param text string
-- Retirer un item
function Menu:RemoveItem(item)
    for i, itm in ipairs(self.items) do
        if itm == item then
            table.remove(self.items, i)
            self._dirty = true
            self._needsRecalculate = true
            return true
        end
    end
    return false
end


-- Note : remove item by index
-- example: myMenu:RemoveItemAt(2) pour retirer le 2e item du menu
-- Attention: l'index doit être valide (entre 1 et le nombre d'items), sinon la fonction retourne false et ne fait rien. Après avoir retiré l'item, on marque le menu comme dirty et nécessitant un recalcul pour que les positions soient mises à jour et que le menu soit redessiné sans l'item retiré.
---@param index number
-- Retirer un item par index
function Menu:RemoveItemAt(index)
    if index < 1 or index > #self.items then return false end
    
    table.remove(self.items, index)
    self._dirty = true
    self._needsRecalculate = true
    return true
end

-- Nettoyer tous les items
-- Note : cette fonction supprime tous les items du menu en vidant la table self.items. Après avoir nettoyé les items, on réinitialise l'index actuel à 1, et on marque le menu comme dirty et nécessitant un recalcul pour que les positions soient mises à jour et que le menu soit redessiné sans aucun item.
-- exemple d'utilisation: myMenu:Clear() pour retirer tous les items du menu et repartir avec une liste vide.
function Menu:Clear()
    self.items = {}
    self.currentItem = 1
    self._dirty = true
    self._needsRecalculate = true
end

-- Ouvrir le menu
-- Note : cette fonction rend le menu visible en mettant self.visible à true, et émet l'événement OnMenuOpened pour notifier les listeners que le menu a été ouvert. Elle peut aussi être utilisée pour appliquer des effets d'ouverture ou initialiser certains états lors de l'ouverture du menu.
-- exemple d'utilisation: myMenu:Open() pour afficher le menu à l'écran. Si le menu est déjà ouvert, cette fonction n'a pas d'effet.
function Menu:Open()
    self.visible = true
    self._justOpened = true
    self._dirty = true

    -- Démarrer le chargement du scaleform glare dès l'ouverture (non-bloquant)
    if Config.Header.glare and Config.Header.glare.enabled then
        Glare.Init()
    end

    -- Si currentItem pointe sur un item non-navigable (window/separator), corriger
    local cur = self.items[self.currentItem]
    if cur and (cur.isSeparator or cur.type == "window") then
        self.currentItem = self:_FirstNavigableIndex()
    end

    MenuPool.NotifyMenuOpened(self)
    self.OnMenuOpened.Emit(self)
end

-- Fermer le menu
function Menu:Close()
    if not self.visible then return end  -- guard anti-double-close
    self.visible = false
    self.currentItem = self:_FirstNavigableIndex()

    -- Libère le scaleform glare si activé (économise le handle GPU)
    if self._glareEnabled then
        Glare.Cleanup()
    end

    MenuPool.NotifyMenuClosed(self)
    self.OnMenuClosed.Emit(self)
end

-- Toggle visibilité
-- Note : cette fonction bascule la visibilité du menu. Si le menu est actuellement visible, elle le ferme, sinon elle l'ouvre. C'est un raccourci pratique pour gérer l'affichage du menu sans avoir à vérifier son état actuel.
-- Exemple d'utilisation: myMenu:Toggle() pour basculer l'affichage du menu. Si le menu est fermé, il s'ouvrira, et si le menu est ouvert, il se fermera.
function Menu:Toggle()
    if self.visible then
        self:Close()
    else
        self:Open()
    end
end

-- Obtenir l'item actuel
-- Note : cette fonction retourne l'item actuellement sélectionné dans le menu, en utilisant l'index self.currentItem pour accéder à la table self.items. Si la liste des items est vide, elle retourne nil. Cette fonction est souvent utilisée dans la logique de sélection pour déterminer quel item a été activé par l'utilisateur.
-- Example : local currentItem = myMenu:GetCurrentItem() pour obtenir l'item actuellement sélectionné dans le menu. Si currentItem est nil, cela signifie qu'il n'y a aucun item dans le menu.
function Menu:GetCurrentItem()
    if #self.items == 0 then return nil end
    return self.items[self.currentItem]
end

--- Obtenir l'index actuel
-- Note : cette fonction retourne l'index de l'item actuellement sélectionné dans le menu, qui est stocké dans self.currentItem. Si la liste des items est vide, elle retourne nil. Cette fonction peut être utilisée pour des opérations qui nécessitent l'index plutôt que l'item lui-même, comme l'affichage du compteur ou la gestion de la navigation.
-- Example : local currentIndex = myMenu:GetCurrentIndex() pour obtenir l'index de l'item actuellement sélectionné. Si currentIndex est nil, cela signifie qu'il n'y a aucun item dans le menu.
---@param idenx number
-- DÃ©finir l'index actuel
function Menu:SetCurrentIndex(index)
    if #self.items == 0 then return end
    
    index = math.max(1, math.min(index, #self.items))
    
    if self.currentItem ~= index then
        self.currentItem = index
        self._dirty = true
        self.OnIndexChange.Emit(self, index)
        self:_UpdateCounter()
        self:_UpdateVisibleRange()
    end
end

--- Retourne l'index du premier item navigable (non-separator, non-window).
---@return number
function Menu:_FirstNavigableIndex()
    for i = 1, #self.items do
        local item = self.items[i]
        if item and not item.isSeparator and item.type ~= "window" and item.type ~= "panel" then
            return i
        end
    end
    return 1
end

-- Naviguer vers le haut
-- Note / !\ : cette fonction gère la navigation vers le haut dans le menu. Elle décrémente l'index actuel pour sélectionner l'item précédent. Si l'index devient inférieur à 1, il boucle pour revenir au dernier item de la liste. De plus, cette fonction inclut une logique pour sauter les items de type separator (non sélectionnables) lors de la navigation. Si le nouvel index pointe vers un separator, la fonction continue à décrémenter jusqu'à trouver un item sélectionnable ou revenir au début de la liste.
-- Example : myMenu:GoUp() pour naviguer vers le haut dans le menu. Si le menu est vide, cette fonction n'a aucun effet.
function Menu:GoUp()
    if #self.items == 0 then return end
    
    local newIndex = self.currentItem - 1
    if newIndex < 1 then
        newIndex = #self.items
    end

    -- Skip les separators et les window (non navigables)
    local attempts = 0
    while attempts < #self.items do
        local item = self.items[newIndex]
        if not item or (not item.isSeparator and item.type ~= "window" and item.type ~= "panel") then break end
        newIndex = newIndex - 1
        if newIndex < 1 then newIndex = #self.items end
        attempts = attempts + 1
    end

    self:SetCurrentIndex(newIndex)
end

-- Naviguer vers le bas
-- Note : cette fonction gère la navigation vers le bas dans le menu. Elle incrémente l'index actuel pour sélectionner l'item suivant. Si l'index devient supérieur au nombre d'items, il boucle pour revenir au premier item de la liste. De plus, cette fonction inclut une logique pour sauter les items de type separator (non sélectionnables) lors de la navigation. Si le nouvel index pointe vers un separator, la fonction continue à incrémenter jusqu'à trouver un item sélectionnable ou revenir au début de la liste.
-- Example : myMenu:GoDown() pour naviguer vers le bas dans le menu. Si le menu est vide, cette fonction n'a aucun effet.
function Menu:GoDown()
    if #self.items == 0 then return end
    
    local newIndex = self.currentItem + 1
    if newIndex > #self.items then
        newIndex = 1
    end

    -- Skip les separators et les window (non navigables)
    local attempts = 0
    while attempts < #self.items do
        local item = self.items[newIndex]
        if not item or (not item.isSeparator and item.type ~= "window" and item.type ~= "panel") then break end
        newIndex = newIndex + 1
        if newIndex > #self.items then newIndex = 1 end
        attempts = attempts + 1
    end

    self:SetCurrentIndex(newIndex)
end

-- Sélectionner l'item actuel
-- Note : cette fonction est appelée lorsque l'utilisateur confirme la sélection de l'item actuel (par exemple, en appuyant sur la touche "Enter"). Elle récupère l'item actuellement sélectionné et émet l'événement OnItemSelect avec le menu, l'item et son index. Ensuite, si l'item a une fonction OnActivated, elle l'appelle pour déclencher les actions spécifiques à cet item.
-- Example : myMenu:Select() pour sélectionner l'item actuellement mis en surbrillance. Si le menu est vide ou si aucun item n'est sélectionné, cette fonction n'a aucun effet.
function Menu:Select()
    local item = self:GetCurrentItem()
    if not item then return end
    
    self.OnItemSelect.Emit(self, item, self.currentItem)
    
    if item.OnActivated then
        item.OnActivated.Emit(item)
    end
end

-- Retour en arriÃ¨re
function Menu:GoBack()
    if self.parentMenu then
        self:Close()
        self.parentMenu:Open()
    else
        self:Close()
    end
end

-- Process (inputs et logique)
function Menu:Process()
	if MenuMouse and MenuMouse.Process then
		MenuMouse.Process(self)
	end

    if MenuNavigation and MenuNavigation.Process then
        return MenuNavigation.Process(self)
    end

    -- Fallback minimal si le script input n'est pas chargÃ©
    if not self.visible then return end
end

--- Cache les indices visibles et la hauteur totale — appelé depuis SetCurrentIndex() et _Recalculate().
function Menu:_UpdateVisibleRange()
    local itemHeight = self._itemHeight or 35
    local items = self.items
    local n = #items

    -- Compter les items window en tête (non scrollables, toujours visibles)
    local winCount = 0
    for i = 1, n do
        if items[i] and items[i].type == "window" then winCount = winCount + 1 else break end
    end
    self._winCount = winCount

    local half = math.floor(self.maxItemsOnScreen * 0.5)
    local s = math.max(1, self.currentItem - half)
    local e = math.min(n, s + self.maxItemsOnScreen - 1)
    if e - s < self.maxItemsOnScreen - 1 then
        s = math.max(1, e - self.maxItemsOnScreen + 1)
    end
    local h = 0
    for i = s, e do
        local it = items[i]
        h = h + ((it and it.GetHeight and it:GetHeight()) or itemHeight)
    end
    -- Si les windows sont au-dessus de la plage scrollable, leur hauteur s'ajoute au fond
    if winCount > 0 and s > winCount then
        for i = 1, winCount do
            local it = items[i]
            h = h + ((it and it.GetHeight and it:GetHeight()) or itemHeight)
        end
    end
    self._visibleStart       = s
    self._visibleEnd         = e
    self._visibleTotalHeight = h
end

--- Cache le counter text — appelé depuis SetCurrentIndex() et _Recalculate(), jamais depuis Draw()
function Menu:_UpdateCounter()
    local navPos, navTotal = 0, 0
    for i = 1, #self.items do
        local it = self.items[i]
        if it and not it.isSeparator and it.type ~= "window" and it.type ~= "panel" then
            navTotal = navTotal + 1
            if i <= self.currentItem then navPos = navTotal end
        end
    end
    self._counterText = navTotal > 0 and string.format("%d / %d", navPos, navTotal) or nil
end

-- Recalculer les positions (seulement si dirty)
function Menu:_Recalculate()
    if not self._needsRecalculate then return end

    local menuW = Config.Header.size.width
    self._menuWidth = menuW
    self._headerHeight = Config.Header.size.height
    self._subtitleHeight = Config.Subtitle.size.height
    self._itemHeight = (Config.Layout and Config.Layout.itemHeight) or 35

    -- 1. CACHE HEADER
    local hCfg = Config.Header
    self._hSpriteUse = hCfg.sprite and hCfg.sprite.use
    self._hSpriteDict = hCfg.sprite and hCfg.sprite.dict or "commonmenu"
    self._hSpriteName = hCfg.sprite and hCfg.sprite.name or "interaction_bgd"
    local hTint = hCfg.sprite and (hCfg.sprite.color or hCfg.sprite.tint) or {r=255,g=255,b=255,a=255}
    self._hSpriteR, self._hSpriteG, self._hSpriteB, self._hSpriteA = hTint.r, hTint.g, hTint.b, hCfg.sprite and hCfg.sprite.alpha or hTint.a
    
    local tc = hCfg.title or {}
    self._tFont, self._tScale, self._tAlign = tc.font or 1, tc.size or 0.95, tc.alignment or 1
    self._tColor = tc.color or {r=255,g=255,b=255,a=255}
    self._tShadow = tc.shadow and tc.shadow.enabled and tc.shadow or nil
    self._titleX = (self._tAlign == 1) and (self.x + menuW * 0.5) or (tc.offsetX and self.x + tc.offsetX or self.x)
    -- offsetY scale proportionnellement avec headerHeight via tc.refHeight (calibration)
    local _tRefH = tc.refHeight or self._headerHeight
    self._titleY = self.y + (tc.offsetY or 0) * (self._headerHeight / _tRefH)

    -- 2. CACHE SUBTITLE
    local sCfg = Config.Subtitle
    self._subBg = sCfg.background or {r=0,g=0,b=0,a=255}
    
    local st = sCfg.text or {}
    self._stFont, self._stScale = st.font or 0, st.size or 0.28
    self._stColor = st.color or {r=245,g=245,b=245,a=255}
    self._subtitleX = self.x + (st.offsetX or 0)
    self._subtitleY = self.y + self._headerHeight + (st.offsetY or 0)

    local sc = sCfg.counter or {}
    self._scFont, self._scScale = sc.font or 0, sc.size or 0.28
    self._scColor = sc.color or {r=245,g=245,b=245,a=255}
    self._counterX = self.x + (sc.offsetX or (menuW - ((sCfg.padding and sCfg.padding.right) or 8)))
    self._counterY = self.y + self._headerHeight + (sc.offsetY or 0)

    -- 2b. PRE-NORMALISATION header + subtitle (élimine toutes les mul/div dans Draw* par frame)
    -- Les coordonnées normalisées (0..1) sont stables tant que la résolution et la position
    -- du menu ne changent pas. Draw.GetInvScale() initialise cachedInvW/H si nécessaire.
    -- Appel direct (pas via upvalue) : _fnGetInvScale est nil à la déclaration et le linter
    -- ne peut pas prouver statiquement qu'_InitUpvalues l'a rempli avant cette ligne.
    local invW, invH = Draw.GetInvScale()

    -- Header sprite : centre normalisé + taille normalisée
    local hNW = menuW * invW
    local hNH = self._headerHeight * invH
    self._hSpriteNX = self.x * invW + hNW * 0.5
    self._hSpriteNY = self.y * invH + hNH * 0.5
    self._hSpriteNW = hNW
    self._hSpriteNH = hNH

    -- Titre header : position normalisée
    self._titleNX = self._titleX * invW
    self._titleNY = self._titleY * invH

    -- Shadow : valeurs aplaties (évite shadow.color.r/g/b/a par frame dans Text.Draw)
    if self._tShadow then
        local shColor = self._tShadow.color or {}
        self._tShadowDist = self._tShadow.distance or 2
        self._tShadowR = shColor.r or 0
        self._tShadowG = shColor.g or 0
        self._tShadowB = shColor.b or 0
        self._tShadowA = shColor.a or 150
    end

    -- Subtitle rect : centre normalisé + taille normalisée
    local stNW = menuW * invW
    local stNH = self._subtitleHeight * invH
    local stRawY = self.y + self._headerHeight
    self._subRectNX = self.x * invW + stNW * 0.5
    self._subRectNY = stRawY * invH + stNH * 0.5
    self._subRectNW = stNW
    self._subRectNH = stNH

    -- Couleurs subtitle rect aplaties (évite "color and color.r or 255" par frame)
    local bg = self._subBg
    self._subBgR, self._subBgG, self._subBgB, self._subBgA = bg.r, bg.g, bg.b, bg.a

    -- Subtitle texte : position normalisée
    self._subtitleNX = self._subtitleX * invW
    self._subtitleNY = self._subtitleY * invH

    -- Counter texte : position normalisée + nxWrap pré-calculé pour SetTextWrap (align=2)
    self._counterNX   = self._counterX * invW
    self._counterNY   = self._counterY * invH
    -- Pour alignment==2, Text.DrawRaw passe nxWrap à SetTextWrap(0.0, nxWrap)
    -- c'est la même valeur que _counterNX
    self._counterNXWrap = self._counterNX

    -- 2c. GLARE (scaleform header) — flag + dimensions pré-calculées
    self._glareEnabled = Config.Header.glare and Config.Header.glare.enabled == true
    if self._glareEnabled then
        local gCfg = Config.Header.glare
        self._glareW = menuW              * (gCfg.widthScale  or 1.0)
        self._glareH = self._headerHeight * (gCfg.heightScale or 1.0)
        -- Auto-centrage sur le header : le scaleform (potentiellement large) est toujours
        -- centré sur la zone header. offsetX/Y = fine-tuning en pixels (0 = centré).
        self._glareX = self.x - (self._glareW - menuW) * 0.5 + (gCfg.offsetX or 0)
        self._glareY = self.y - (self._glareH - self._headerHeight) * 0.5 + (gCfg.offsetY or 0)
    end

    -- 3. CACHE ITEMS BACKGROUND
    local ibCfg = Config.ItemsBackground or {}
    self._ibSpriteUse = ibCfg.sprite and ibCfg.sprite.use
    self._ibSpriteDict = ibCfg.sprite and ibCfg.sprite.dict or "commonmenu"
    self._ibSpriteName = ibCfg.sprite and ibCfg.sprite.name or "gradient_bgd"
    local ibTint = ibCfg.sprite and (ibCfg.sprite.color or ibCfg.sprite.tint) or {r=255,g=255,b=255,a=255}
    self._ibSpriteR, self._ibSpriteG, self._ibSpriteB, self._ibSpriteA = ibTint.r, ibTint.g, ibTint.b, ibCfg.sprite and ibCfg.sprite.alpha or ibTint.a
    self._ibSpriteHeading = ibCfg.sprite and ibCfg.sprite.heading or 0.0
    local ibCol = ibCfg.color or {r=0,g=0,b=0,a=120}
    self._ibColorR, self._ibColorG, self._ibColorB, self._ibColorA = ibCol.r or 0, ibCol.g or 0, ibCol.b or 0, ibCol.a or 120
    -- NX/NW stables (centre normalisé) ; NY/NH dynamiques car _visibleTotalHeight change
    local ibNW = menuW * invW
    self._ibSpriteNX = self.x * invW + ibNW * 0.5
    self._ibSpriteNW = ibNW

    -- 4. CACHE NAVIGATION HIGHLIGHT
    local navCfg = Config.Navigation or {}
    self._navH = navCfg.size and navCfg.size.height or self._itemHeight
    self._navOffsetY = navCfg.offsetY or 0

    -- Pré-normalisation nav : NX et NW stables tant que x/menuW ne changent pas
    local navNW = menuW * invW
    self._navNX = self.x * invW + navNW * 0.5
    self._navNW = navNW

    -- 4b. CACHE NEW STYLE (grey rows + arrow)
    local _ns = Config.NewStyle or {}
    self._newStyleEnabled = (_ns.enabled == true)

    if self._newStyleEnabled then
        local irCfg  = _ns.itemRow or {}
        local irCol  = irCfg.color or {r=36,g=36,b=36,a=255}
        local irOffX = irCfg.offsetX or 15
        self._itemRowR    = irCol.r or 36
        self._itemRowG    = irCol.g or 36
        self._itemRowB    = irCol.b or 36
        self._itemRowA    = irCol.a or 255
        self._itemRowGapH = (irCfg.gapPx or 3) * invH
        local irNW        = (menuW - irOffX * 2) * invW
        self._itemRowNX   = (self.x + irOffX) * invW + irNW * 0.5
        self._itemRowNW   = irNW

        local arCfg   = _ns.arrow or {}
        local arCol   = arCfg.color or {r=241,g=101,b=34,a=255}
        self._arDict  = arCfg.dict   or "icon"
        self._arName  = arCfg.name   or "arrow_right_36dp"
        self._arNW    = (arCfg.width  or 50) * invW
        self._arNH    = (arCfg.height or 30) * invH
        self._arNX    = (self.x + (arCfg.offsetX or 1)) * invW + self._arNW * 0.5
        self._arNYOff = (arCfg.offsetY or 2) * invH + self._arNH * 0.5
        self._arR     = arCol.r or 241
        self._arG     = arCol.g or 101
        self._arB     = arCol.b or 34
        self._arA     = arCol.a or 255

        -- Cache label NewStyle (override position label gauche de tous les items)
        local lbCfg = _ns.label or {}
        self._nsLabelNX    = (self.x + (lbCfg.offsetX or 30)) * invW
        self._nsLabelNYOff = (lbCfg.offsetY or 5) * invH
        local nsSel = _ns.selectedColor or {}
        self._nsSelColR = nsSel.r or 0
        self._nsSelColG = nsSel.g or 255
        self._nsSelColB = nsSel.b or 255
        self._nsSelColA = nsSel.a or 255
    end

    -- 5. CACHE ITEMS (La plus grosse optimisation CPU)
    local yOffset = self.y + self._headerHeight + self._subtitleHeight
    for i, item in ipairs(self.items) do
        self._cachedPositions[i] = { x = self.x, y = yOffset }
        -- Les items window ont une hauteur propre (GetHeight), les autres utilisent itemHeight
        local h = (item.GetHeight and item:GetHeight()) or self._itemHeight
        item._h = h
        yOffset = yOffset + h

        if item.type ~= "window" and item.type ~= "panel" then
            local typeCfg = self._itemTypeCfg[item.type] or Config.Button
            local labelCfg = (typeCfg and typeCfg.label) or (Config.Button and Config.Button.label) or {}
            
            item._bgCfg = (typeCfg and typeCfg.background) or (Config.Button and Config.Button.background) or {}
            item._font = labelCfg.font or 0
            item._scale = labelCfg.size or 0.26
            item._textX = self.x + (labelCfg.offsetX or 0)
            item._textYOffset = labelCfg.offsetY or 0

            -- Cache des couleurs pour éviter les lookups
            item._defCol = labelCfg.color and labelCfg.color.default or {r=255,g=255,b=255,a=255}
            item._selCol = labelCfg.color and labelCfg.color.selected or {r=0,g=0,b=0,a=255}
            item._disCol = labelCfg.color and labelCfg.color.disabled or {r=163,g=159,b=148,a=255}

            -- Calcul de la largeur max pour l'ellipsize (FAIT 1 SEULE FOIS)
            local maxLabelWidth = nil
            if item.type == "list" then
                local lCfg = Config.List or {}
                local uiCfg = lCfg.ui or {}
                local valueCfg = lCfg.value or {}
                local left, right = uiCfg.left or "←", uiCfg.right or "→"
                local baselineW = math.floor(menuW * 0.33)
                local arrowsW = Text.GetWidth(left .. "  " .. right, valueCfg.font or 0, valueCfg.size or 0.26)
                
                item._listRawMaxWidthWithArrows = math.max(0, baselineW - arrowsW)
                item._listRawMaxWidthNoArrows = baselineW
                item._listMaxLabelWidth = math.max(0, (self.x + menuW - (valueCfg.offsetRightX or valueCfg.offsetX or 0)) - item._textX - ((lCfg.labelValueGap ~= nil) and lCfg.labelValueGap or 10) - baselineW)
                maxLabelWidth = item._listMaxLabelWidth
                -- Pré-normalise X du texte valeur droite (élimine 1 mul/div par frame dans DrawCustom list)
                item._listValueRightNX = (self.x + menuW - (valueCfg.offsetRightX or valueCfg.offsetX or 0)) * invW

            elseif item.type == "checkbox" and Config.Checkbox and Config.Checkbox.sprite then
                maxLabelWidth = (self.x + menuW - (Config.Checkbox.sprite.offsetRightX or 12) - (Config.Checkbox.sprite.size or 32)) - item._textX - ((Config.Checkbox.labelSpriteGap ~= nil) and Config.Checkbox.labelSpriteGap or 10)

            elseif item.type == "sliderprogress" and Config.SliderProgress and Config.SliderProgress.bar then
                maxLabelWidth = (self.x + menuW - (Config.SliderProgress.bar.offsetRightX or 12) - (Config.SliderProgress.bar.width or 120)) - item._textX - ((Config.SliderProgress.labelBarGap ~= nil) and Config.SliderProgress.labelBarGap or 10)

            elseif item.type == "heritage" then
                local hCfg = Config.Heritage or {}
                local style = item.style or {}
                local groupW = (math.max(0, tonumber(style.iconSize) or tonumber((hCfg.icons or {}).size) or 40) * 2) + (math.max(0, tonumber(style.gap) or tonumber((hCfg.icons or {}).gap) or 6) * 2) + math.max(0, tonumber(style.barWidth) or tonumber((hCfg.bar or {}).width) or 120)
                maxLabelWidth = (self.x + menuW - (tonumber(style.offsetRightX) or tonumber(hCfg.offsetRightX) or 12) - groupW) - item._textX - ((hCfg.labelBarGap ~= nil) and hCfg.labelBarGap or 10)

            elseif item.type == "progress" and Config.Progress and Config.Progress.bar then
                maxLabelWidth = (self.x + menuW - (Config.Progress.bar.offsetRightX or 12) - (Config.Progress.bar.width or 120)) - item._textX - ((Config.Progress.labelBarGap ~= nil) and Config.Progress.labelBarGap or 10)
            end

            -- Badge button (RightBadge / LeftBadge / RightLabel)
            if item.type == "button" then
                local bdgCfg  = (Config.Button and Config.Button.badge) or {}
                local bdgSize = bdgCfg.size or 28
                local bdgOffY = bdgCfg.offsetY
                -- Centre Y du badge dans l'item (centré automatiquement si offsetY nil)
                local bdgNYOff = bdgOffY
                    and (bdgOffY + bdgSize * 0.5) * invH
                    or  ((self._itemHeight - bdgSize) * 0.5 + bdgSize * 0.5) * invH
                item._badgeNW    = bdgSize * invW
                item._badgeNH    = bdgSize * invH
                item._badgeNYOff = bdgNYOff

                if item.rightBadge then
                    local offR = bdgCfg.offsetRightX or 6
                    item._badgeRightNX = (self.x + menuW - offR - bdgSize * 0.5) * invW
                    -- Réduire maxLabelWidth pour ne pas chevaucher le badge
                    maxLabelWidth = math.min(
                        maxLabelWidth or (menuW - (item._textX - self.x) - (labelCfg.rightPadding or 20)),
                        (self.x + menuW - offR - bdgSize) - item._textX - 6
                    )
                end
                if item.leftBadge then
                    local offL = bdgCfg.offsetLeftX or 6
                    item._badgeLeftNX = (self.x + offL + bdgSize * 0.5) * invW
                    -- Décaler le texte à droite du badge (offL + badge + 6px de gap)
                    item._textX = self.x + offL + bdgSize + 6
                end
                if item.rightLabel then
                    local lCfg = (Config.Button and Config.Button.label) or {}
                    item._rlNX = (self.x + menuW - (lCfg.rightPadding or 20)) * invW
                end
            end

            if not maxLabelWidth then
                maxLabelWidth = menuW - (item._textX - self.x) - (labelCfg.rightPadding or 20)
            end

            -- Ellipsize pré-calculé !
            item._ellipsizedText = Text.Ellipsize(item.text or "Item", maxLabelWidth, item._font, item._scale)

            -- Pré-normalisation label (élimine 2 divisions par item par frame dans _DrawItems)
            item._textNX    = item._textX * invW
            item._textNYOff = item._textYOffset * invH

            -- NewStyle : override position label gauche
            if self._newStyleEnabled then
                item._textNX    = self._nsLabelNX
                item._textNYOff = self._nsLabelNYOff
            end

            -- Pré-aplatir couleur sélectionnée background (élimine accès table dans _DrawNavigationHighlight)
            local selBg = item._bgCfg and item._bgCfg.selected
            if selBg then
                item._selBgR = selBg.r or 255
                item._selBgG = selBg.g or 255
                item._selBgB = selBg.b or 255
                item._selBgA = selBg.a or 255
            else
                item._selBgR, item._selBgG, item._selBgB, item._selBgA = 255, 255, 255, 255
            end
        end
    end

    -- 6. CACHE DESCRIPTION (élimine ~15 lookups Config + GetTextScaleHeight par frame)
    local dCfg  = Config.Description or {}
    local dPad  = dCfg.padding or {}
    local dText = dCfg.text or {}
    local dPadLeft   = dPad.left   or dText.offsetX or 0
    local dPadRight  = dPad.right  or dPadLeft
    local dPadTop    = dPad.top    or dText.offsetY or 0
    local dPadBottom = dPad.bottom or dPadTop
    self._descSpacing    = dCfg.spacing or 0
    self._descPadTop     = dPadTop
    self._descPadBottom  = dPadBottom
    self._descTextX      = self.x + (dText.offsetX or dPadLeft)
    self._descTextYOff   = dText.offsetY or dPadTop
    self._descWrapWidth  = dText.maxWidth or (menuW - dPadLeft - dPadRight)
    self._descFont       = tonumber(dText.font) or 0
    self._descSize       = tonumber(dText.size) or 0.35
    self._descBackground = dCfg.background
    self._descTextColor  = dText.color
    local dCfgLineH = dText.lineHeight or 19
    -- Native line height : appelée 1x ici, jamais dans _DrawDescription
    local dNativeLineH = 0
    local dRes = Draw.GetResolution()
    local dResH = dRes and dRes.height or 1080
    if type(GetTextScaleHeight) == "function" then
        dNativeLineH = GetTextScaleHeight(self._descSize, self._descFont) * dResH
    elseif type(GetRenderedCharacterHeight) == "function" then
        dNativeLineH = GetRenderedCharacterHeight(self._descSize, self._descFont) * dResH
    end
    self._descLineHeight = math.max(dCfgLineH, math.ceil(dNativeLineH) + 2)
    -- Clé de mesure pré-construite (élimine table.concat à chaque frame)
    self._descMeasureParamsKey = table.concat({
        tostring(self._descFont), tostring(self._descSize),
        tostring(self._descWrapWidth), tostring(self._descLineHeight),
        tostring(dPadTop), tostring(dPadBottom)
    }, "|")
    if not self._descCacheSize then self._descCacheSize = {} end

    self:_UpdateCounter()
    self:_UpdateVisibleRange()
    self._needsRecalculate = false
end

-- Dessiner le menu
function Menu:Draw()
    --[[if not self.visible then return end

    if self._dirty or self._needsRecalculate then
        self:_Recalculate()
        self._dirty = false
    end

    self:_DrawHeader()
    self:_DrawSubtitle()
    self:_DrawItemsBackground()
    self:_DrawItems()]]

        if not self.visible then return end

    if self._dirty or self._needsRecalculate then
        self:_Recalculate()
        self._dirty = false
    end

    -- ✅ Un seul appel pour toutes les sous-fonctions
    local invW, invH = Draw.GetInvScale()

    self:_DrawHeader()
    self:_DrawSubtitle()
    self:_DrawItemsBackground(invH)   -- reçoit invH, ne rappelle pas GetInvScale
    self:_DrawItems(invW, invH)   

    -- Y de départ pour les panels (sous les items)
    local panelStartY = self.y + self._headerHeight + self._subtitleHeight + self._visibleTotalHeight

    local currentItem = self:GetCurrentItem()
    local desc = currentItem and (
        (currentItem._descFn and currentItem._descFn(currentItem))
        or currentItem.description
    ) or nil
    if desc and desc ~= "" then
        panelStartY = self:_DrawDescription(desc)
    end

    -- Panels style RageUI : appelle la closure stockée par menu:SetPanels(fn)
    if self._panelsFn then
        _AmaUIPanelMenu      = self
        _AmaUIPanelX         = self.x
        _AmaUIPanelY         = panelStartY
        _AmaUIPanelStatCount = 0
        self._panelsFn()
        -- ⚡ Flush le buffer de statistiques (1 DrawRect fond pour N stats empilées)
        if _AmaUIPanelFlush then _AmaUIPanelFlush() end
        _AmaUIPanelMenu = nil
    end
end

-- Dessiner le header
-- Toutes les coordonnées sont pré-normalisées dans _Recalculate : zéro mul/div/accès-table ici.
function Menu:_DrawHeader()
    if self._hSpriteUse then
        -- SpriteRaw : coordonnées déjà normalisées, EnsureTexture + DrawSprite direct.
        _fnSpriteRaw(self._hSpriteDict, self._hSpriteName,
            self._hSpriteNX, self._hSpriteNY, self._hSpriteNW, self._hSpriteNH,
            0.0, self._hSpriteR, self._hSpriteG, self._hSpriteB, self._hSpriteA)
    end
    -- Glare : superposé sur le sprite, derrière le titre (dimensions depuis _Recalculate)
    if self._glareEnabled then
        Glare.Draw(self._glareX, self._glareY, self._glareW, self._glareH)
    end
    if self._tShadow then
        -- DrawRawShadow : positions normalisées + valeurs shadow aplaties, SetTextProportional inclus.
        _fnDrawRawShadow(self.title,
            self._titleNX, self._titleNY,
            self._tFont, self._tScale,
            self._tColor.r, self._tColor.g, self._tColor.b, self._tColor.a,
            self._tAlign,
            self._tShadowDist, self._tShadowR, self._tShadowG, self._tShadowB, self._tShadowA)
    else
        -- DrawRaw : positions normalisées + reset alignement état GTA.
        _fnDrawRaw(self.title,
            self._titleNX, self._titleNY,
            self._tFont, self._tScale,
            self._tColor.r, self._tColor.g, self._tColor.b, self._tColor.a,
            self._tAlign)
    end
end

-- Dessiner le subtitle
-- Toutes les coordonnées sont pré-normalisées dans _Recalculate : zéro mul/div/accès-table ici.
function Menu:_DrawSubtitle()
    -- RectRaw : centre normalisé + taille normalisée + composantes couleur aplaties.
    _fnRectRaw(self._subRectNX, self._subRectNY, self._subRectNW, self._subRectNH,
        self._subBgR, self._subBgG, self._subBgB, self._subBgA)

    -- Subtitle texte : alignment==0, pas de SetTextCentre/RightJustify dans DrawRaw.
    _fnDrawRaw(self.subtitle,
        self._subtitleNX, self._subtitleNY,
        self._stFont, self._stScale,
        self._stColor.r, self._stColor.g, self._stColor.b, self._stColor.a,
        0)

    if self._counterText then
        -- Counter : alignment==2 (droite), nxWrap pré-calculé = _counterNX.
        _fnDrawRaw(self._counterText,
            self._counterNX, self._counterNY,
            self._scFont, self._scScale,
            self._scColor.r, self._scColor.g, self._scColor.b, self._scColor.a,
            2, self._counterNXWrap)
    end
end


--- Dessiner le highlight de navigation (rectangle blanc derriÃ¨re l'item sÃ©lectionnÃ©)
--- Highlight de navigation. invH/item passes depuis _DrawItems, zero mul/div en frame.
---@param bgCfg table (config background spÃ©cifique Ã  ce type d'item, ou fallback Button)
--[[function Menu:_DrawNavigationHighlight(itemY, itemHeight, bgCfg, invH, item)
    local typeH = bgCfg and bgCfg.height
    if typeH == 0 then typeH = nil end

    local navH = typeH or self._navH or itemHeight
    if navH > itemHeight then navH = itemHeight end
    if navH < 0 then navH = 0 end

    local extraOffsetY = (bgCfg and bgCfg.offsetY) or 0
    local navY = itemY + (itemHeight - navH) * 0.5 + self._navOffsetY + extraOffsetY

    -- RectRaw : coordonnees normalisees, couleurs pre-aplaties depuis _Recalculate
    local navNH = navH * invH
    local navNY = navY * invH + navNH * 0.5
    _fnRectRaw(self._navNX, navNY, self._navNW, navNH,
        item._selBgR, item._selBgG, item._selBgB, item._selBgA)
end]]

-- ✅ FIX : normalisation inline directe, variable intermédiaire supprimée
function Menu:_DrawNavigationHighlight(itemY, itemHeight, bgCfg, invH, item)
    local typeH = bgCfg and bgCfg.height
    if typeH == 0 then typeH = nil end

    local navH = typeH or self._navH or itemHeight
    if navH > itemHeight then navH = itemHeight end
    if navH < 0 then navH = 0 end

    local extraOffsetY = (bgCfg and bgCfg.offsetY) or 0
    local navY = itemY + (itemHeight - navH) * 0.5 + self._navOffsetY + extraOffsetY

    -- ✅ fusion en 3 opérations au lieu de 4 (navNH réutilisé directement)
    local navNH = navH * invH
    _fnRectRaw(self._navNX, navY * invH + navNH * 0.5, self._navNW, navNH,
        item._selBgR, item._selBgG, item._selBgB, item._selBgA)
end
-- Dessiner le fond des items (gradient_bgd) — tous les champs Config pré-cachés
function Menu:_DrawItemsBackground()
    if #self.items == 0 then return end

    local yStart      = self.y + self._headerHeight + self._subtitleHeight
    local totalHeight = self._visibleTotalHeight
    local _, invH     = Draw.GetInvScale()
   -- local nh          = totalHeight * invH
    local nh = totalHeight * invH
    local ny          = yStart * invH + nh * 0.5

    if self._ibSpriteUse then
        local ok = Draw.SpriteRaw(
            self._ibSpriteDict, self._ibSpriteName,
            self._ibSpriteNX, ny, self._ibSpriteNW, nh,
            self._ibSpriteHeading,
            self._ibSpriteR, self._ibSpriteG, self._ibSpriteB, self._ibSpriteA
        )
        if not ok then
            Draw.RectRaw(self._ibSpriteNX, ny, self._ibSpriteNW, nh,
                self._ibColorR, self._ibColorG, self._ibColorB, self._ibColorA)
        end
    else
        Draw.RectRaw(self._ibSpriteNX, ny, self._ibSpriteNW, nh,
            self._ibColorR, self._ibColorG, self._ibColorB, self._ibColorA)
    end
end

-- Dessiner les items
-- invW, invH : passés depuis Draw() — zéro appel GetInvScale() redondant
function Menu:_DrawItems(invW, invH)
    if #self.items == 0 then return end

    local itemHeight = self._itemHeight
    local yStart = self.y + self._headerHeight + self._subtitleHeight
    local _itemNH     = itemHeight * invH

    -- Toggle new style
    local _newStyle = self._newStyleEnabled
    local _irNX, _irNW, _irGapH, _irR, _irG, _irB, _irA
    local _arDict, _arName, _arNX, _arNW, _arNH, _arNYOff, _arR, _arG, _arB, _arA
    local _nsSelColR, _nsSelColG, _nsSelColB, _nsSelColA

    if _newStyle then
        _irNX, _irNW     = self._itemRowNX, self._itemRowNW
        _irGapH          = self._itemRowGapH or 0
        _irR, _irG, _irB, _irA = self._itemRowR, self._itemRowG, self._itemRowB, self._itemRowA
        _arDict, _arName = self._arDict, self._arName
        _arNX, _arNW, _arNH = self._arNX, self._arNW, self._arNH
        _arNYOff         = self._arNYOff
        _arR, _arG, _arB, _arA = self._arR, self._arG, self._arB, self._arA
        _nsSelColR = self._nsSelColR
        _nsSelColG = self._nsSelColG
        _nsSelColB = self._nsSelColB
        _nsSelColA = self._nsSelColA
    end

    local startIndex = self._visibleStart
    local endIndex   = self._visibleEnd
    local winCount   = self._winCount or 0

    local runY = yStart
    if winCount > 0 and startIndex > winCount then
        for i = 1, winCount do
            local item = self.items[i]
            if item then
                local itemH = item._h or itemHeight
                if item.DrawCustom then item:DrawCustom(self.x, runY, false, invW, invH) end
                runY = runY + itemH
            end
        end
    end

    for i = startIndex, endIndex do
        local item = self.items[i]
        local itemH = item._h or itemHeight
        local itemY = runY
        runY = runY + itemH

        local isSelected = (i == self.currentItem)

        if item.type == "window" or item.type == "panel" then
            if item.DrawCustom then item:DrawCustom(self.x, itemY, false, invW, invH) end
            goto continue
        end

        if not item.isSeparator then
            local itemNYBase = itemY * invH
            local itemNH = (itemH == itemHeight) and _itemNH or (itemH * invH)

            if _newStyle then
                -- 1. Grey rect (inset, gap)
                local rowNH = itemNH - _irGapH
                _fnRectRaw(_irNX, itemNYBase + _irGapH * 0.5 + rowNH * 0.5, _irNW, rowNH,
                    _irR, _irG, _irB, _irA)
            else
                -- 1. Classic white highlight
                if isSelected then
                    self:_DrawNavigationHighlight(itemY, itemH, item._bgCfg, invH, item)
                end
            end

            -- 2. Label
            local isEnabled = item.enabled ~= false
            local tR, tG, tB, tA
            if isSelected then
                if _newStyle then
                    tR, tG, tB, tA = _nsSelColR, _nsSelColG, _nsSelColB, _nsSelColA
                else
                    local c = item._selCol
                    tR, tG, tB, tA = c.r, c.g, c.b, c.a
                end
            elseif isEnabled then
                local c = item._defCol
                tR, tG, tB, tA = c.r, c.g, c.b, c.a
            else
                local c = item._disCol
                tR, tG, tB, tA = c.r, c.g, c.b, c.a
            end
            Text.DrawRaw(
                item._ellipsizedText, item._textNX,
                itemNYBase + item._textNYOff,
                item._font, item._scale,
                tR, tG, tB, tA,
                0
            )

            -- 3. DrawCustom (checkbox, list, slider...)
            if item.DrawCustom then
                item:DrawCustom(self.x, itemY, isSelected, invW, invH)
            end

            -- 4. Arrow orange (new style, selectionne uniquement)
            if _newStyle and isSelected then
                _fnSpriteRaw(_arDict, _arName,
                    _arNX, itemNYBase + _arNYOff,
                    _arNW, _arNH, 0.0,
                    _arR, _arG, _arB, _arA)
            end
        else
            if item.DrawCustom then
                item:DrawCustom(self.x, itemY, false, invW, invH)
            end
        end
        ::continue::
    end
end

---@param description string
-- Dessiner la description
function Menu:_DrawDescription(description)
    local yPos      = self.y + self._headerHeight + self._subtitleHeight + self._visibleTotalHeight + self._descSpacing
    local textX     = self._descTextX
    local textY     = yPos + self._descTextYOff
    local paramsKey = self._descMeasureParamsKey
    local padTop    = self._descPadTop
    local padBottom = self._descPadBottom
    local lineHeight = self._descLineHeight
    local font      = self._descFont
    local size      = self._descSize
    local wrapWidth = self._descWrapWidth

    local byParams = self._descMeasureCache[paramsKey]
    if not byParams then
        byParams = {}
        self._descMeasureCache[paramsKey] = byParams
        self._descCacheSize[paramsKey] = 0
    end

    local cached = byParams[description]
    local dynamicHeight
    if cached then
        dynamicHeight = cached.height
    else
        local lineCount = Text.GetLineCount(description, textX, textY, font, size, wrapWidth, Text.Align.Left)
        lineCount = math.max(1, lineCount)
        dynamicHeight = padTop + padBottom + (lineCount * lineHeight)
        local n = (self._descCacheSize[paramsKey] or 0) + 1
        if n >= 50 then
            byParams = {}
            self._descMeasureCache[paramsKey] = byParams
            n = 0
        end
        self._descCacheSize[paramsKey] = n
        byParams[description] = { lineCount = lineCount, height = dynamicHeight }
    end

    Draw.Rect(self.x, yPos, self._menuWidth, dynamicHeight, self._descBackground)
    Text.Draw(description, textX, textY, font, size, self._descTextColor, Text.Align.Left, nil, nil, true, wrapWidth)
    return yPos + dynamicHeight
end


---@param item UIMenuItem
---@param submenu subMenu
-- Bind un sous-menu
function Menu:BindSubmenu(item, submenu)
    if not item or not submenu then return end
    
    submenu.parentMenu = self
    self.children[item.id] = submenu
    
    -- Event pour ouvrir le sous-menu
    item.OnActivated.On(function()
        self:Close()
        submenu:Open()
    end)
end

-- DÃ©truire le menu (cleanup)
function Menu:Destroy()
    self:Close()
    
    -- Clear events
    self.OnMenuOpened.Clear()
    self.OnMenuClosed.Clear()
    self.OnItemSelect.Clear()
    self.OnIndexChange.Clear()
    
    -- Clear items
    self.items = {}
    self.children = {}
end

-- Refresh (forcer un recalcul)
function Menu:Refresh()
    self._dirty = true
    self._needsRecalculate = true
end

--- Enregistre la closure des panels (style RageUI).
-- Appelé une fois après la création du menu.
-- La closure est appelée à chaque frame dans Menu:Draw, APRÈS les items et la description.
-- À l'intérieur, utilisez les fonctions globales ColorPanel, GridPanel, PercentagePanel,
-- StatisticsPanel, GridPanelH, GridPanelV avec un paramètre d'index (1-based).
--
-- Exemple :
--   menu:SetPanels(function()
--       GridPanel(0.5, 0.5, "Haut", "Bas", "Int", "Ext", fn, 2)
--       ColorPanel("Couleur", colors, minIdx, curIdx, fn, 5)
--   end)
---@param fn function
function Menu:SetPanels(fn)
    self._panelsFn = type(fn) == "function" and fn or nil
end

-- Debug
function Menu:Debug()
    print("^2=== Menu Debug ===^7")
    print("ID: " .. self.id)
    print("Title: " .. self.title)
    print("Visible: " .. tostring(self.visible))
    print("Items: " .. #self.items)
    print("Current Item: " .. self.currentItem)
    print("^2==================^7")
end

return Menu