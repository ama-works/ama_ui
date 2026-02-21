---@diagnostic disable: missing-parameter
-- core/menu.lua
Menu = {}
Menu.__index = Menu


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

    -- Cache positions header/subtitle (rempli par _Recalculate, jamais recomputed en Draw)
    self._titleX    = nil
    self._titleY    = nil
    self._subtitleX = nil
    self._subtitleY = nil
    self._counterX  = nil
    self._counterY  = nil
    -- Counter text precalcule (mis a jour par _UpdateCounter, pas par frame)
    self._counterText = nil

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
    if not actions or type(actions) ~= "table" then return actions end
    local n = {}

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

    if type(optsOrActions) == "table" and optsOrActions.RightLabel ~= nil then
        rightLabel = optsOrActions.RightLabel
        actions    = extra
        submenu    = nil
    elseif type(extra) == "table" and extra.id ~= nil then
        actions = optsOrActions
        submenu = extra
    end

    local item = self:AddItem(UIMenuButton.New(label, description, true, NormalizeActions(actions)))

    if rightLabel then
        item.rightLabel = rightLabel
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
---@param actions     table|nil   { onChange=fn, onSelect=fn }
function Menu:List(label, items, index, description, actions)
    return self:AddItem(UIMenuList.New(label, items, index, description, NormalizeActions(actions)))
end

--- Case à cocher
--- Note: checked est un booléen indiquant si la case est cochée ou non. Si actions.onChange est défini, il sera appelé lorsque l'utilisateur change l'état de la case à cocher, avec le menu, l'item et la nouvelle valeur (true/false) en paramètre. Si actions.onSelect est défini, il sera appelé lorsque l'item est sélectionné, avec le menu, l'item et la valeur actuelle en paramètre.
-- Exemple d'utilisation: myMenu:Checkbox("Enable Sound", true, "Toggle game sound", { onChange = function(menu, item, newValue) print("Sound enabled: " .. tostring(newValue)) end })
-- Note: pour les cases à cocher, on peut aussi gérer un état "indéterminé" (nil) si on veut représenter une option qui n'est pas simplement binaire. Dans ce cas, checked peut être un booléen ou nil, et le code de l'item Checkbox doit être adapté pour gérer cette possibilité. Cependant, dans la version actuelle, on suppose que checked est un booléen simple.
---@param text        string
---@param checked     boolean|nil
---@param description string|nil
---@param actions     table|nil   { onChange=fn, onSelect=fn }
function Menu:Checkbox(label, checked, description, actions)
    return self:AddItem(UIMenuCheckbox.New(label, checked, description, NormalizeActions(actions)))
end

-- slider de progression (ex: barre de santé, d'armure, etc.)
-- Note: progressStart est la valeur actuelle de la progression, progressMax est la valeur maximale. Si actions.onChange est défini, il sera appelé lorsque l'utilisateur change la valeur du slider, avec le menu, l'item et la nouvelle valeur en paramètre. Si actions.onSelect est défini, il sera appelé lorsque l'item est sélectionné, avec le menu, l'item et la valeur actuelle en paramètre.
-- exemple d'utilisation: myMenu:SliderProgress("Health", 75, 100, "Current health", { onChange = function(menu, item, newValue) print("New health: " .. newValue) end })
--- @param text string
--- @param progressStart number
--- @param progressMax number
--- @param description string
--- @param style table (optionnel, pour config spécifique a ce slider)
--- @param enabled boolean (optionnel, dÃ©faut true)
--- @param actions table (optionnel, pour override les actions par defaut de ce slider)
-- myMenu:SliderProgress("label", 10, 100, "desc", style, enabled, actions)
function Menu:SliderProgress(label, progressStart, progressMax, description, style, enabled, actions)
    return self:AddItem(UIMenuSliderProgress.New(label, progressStart, progressMax, description, style, enabled, NormalizeActions(actions)))
end

--- Alias simplifié de SliderProgress.
-- menu:Slider("label", 50, 100, "desc", { step=5 }, { onSliderChange = fn })
---@param label        string
---@param value        number
---@param max          number
---@param description  string|nil
---@param style        table|nil
---@param actions      table|nil  { onSliderChange=fn, onSelected=fn }
function Menu:Slider(label, value, max, description, style, actions)
    return self:SliderProgress(label, value, max, description, style, true, actions)
end


--TODO MODIFIER CETTE ITEM DE PROGRESS RETIRER Fléches gauche / droite et avoir un vrai progress pour la stamina health ped native fivem
-- progress 
-- Note
---@param text string
---@param progressStart number
---@param progressMax number
---@param description string
---@param style table (optionnel, pour config spécifique ce progress)
---@param enabled boolean (optionnel, dÃ©faut true)
---@param actions table (optionnel, pour override les actions par défaut de ce progress)
-- myMenu:Progress("label", 10, 100, "desc", style, enabled, actions)
function Menu:Progress(text, progressStart, progressMax, description, style, enabled, actions)
    return self:AddItem(UIMenuProgressItem.New(text, progressStart, progressMax, description, style, enabled, actions))
end

-- heritage cretor menu
-- Note: ce type d'item est similaire au slider de progression, mais il est spécifiquement conçu pour les menus de création de personnage (heritage). Il peut inclure des fonctionnalités supplémentaires comme la sélection de parents, la génération aléatoire, etc. Les paramètres sont similaires à ceux du slider de progression, mais le style et les actions peuvent être adaptés pour ce contexte spécifique.
-- Exemple d'utilisation: myMenu:Heritage("Face Shape", 0, 100, 50, 1, "Adjust the face shape", style, true, { onChange = function(menu, item, newValue) print("New face shape value: " .. newValue) end })
-- Note: pour les items de type heritage, on peut aussi gérer des sous-options spécifiques à la création de personnage, comme la sélection de parents (father/mother), la génération aléatoire, etc. Dans ce cas, le style peut inclure des configurations pour ces fonctionnalités, et les actions peuvent inclure des callbacks spécifiques pour gérer ces interactions. Cependant, dans la version actuelle, on suppose que l'item Heritage est un simple slider avec des paramètres similaires au slider de progression.
--- @param text string
--- @param min number
--- @param max number
--- @param value number
--- @param step number
--- @param description string
--- @param style table (optionnel, pour config spÃ©cifique Ã  ce heritage)
--- @param enabled boolean (optionnel, dÃ©faut true)
--- @param actions table (optionnel, pour override les actions par dÃ©faut de ce heritage)
-- myMenu:Heritage("label", 0, 100, 50, 1, "desc", style, enabled, actions)
--- menu:Heritage("label", 0, 100, 50, 1, "desc", { onSliderChange=fn })
---@param label       string
---@param min         number
---@param max         number
---@param value       number
---@param step        number
---@param description string|nil
---@param actions     table|nil  { onSliderChange=fn, onSelected=fn }
function Menu:Heritage(label, min, max, value, step, description, actions)
    return self:AddItem(UIMenuSliderHeritageItem.New(label, min, max, value, step, description, nil, true, NormalizeActions(actions)))
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

    -- Si currentItem pointe sur un item non-navigable (window/separator), corriger
    local cur = self.items[self.currentItem]
    if cur and (cur.isSeparator or cur.type == "window") then
        self.currentItem = self:_FirstNavigableIndex()
    end

    MenuPool.NotifyMenuOpened(self)
    self.OnMenuOpened.Emit(self)
end

-- Fermer le menu
-- Note : cette fonction rend le menu invisible en mettant self.visible à false, réinitialise l'index actuel à 1, et émet l'événement OnMenuClosed pour notifier les listeners que le menu a été fermé. Elle peut aussi être utilisée pour appliquer des effets de fermeture ou nettoyer certains états lors de la fermeture du menu.
-- Example : myMenu:Close() pour fermer le menu. Si le menu est déjà fermé, cette fonction n'a pas d'effet.
function Menu:Close()
    self.visible = false
    self.currentItem = self:_FirstNavigableIndex()

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
    end
end

--- Retourne l'index du premier item navigable (non-separator, non-window).
---@return number
function Menu:_FirstNavigableIndex()
    for i = 1, #self.items do
        local item = self.items[i]
        if item and not item.isSeparator and item.type ~= "window" then
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
        if not item or (not item.isSeparator and item.type ~= "window") then break end
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
        if not item or (not item.isSeparator and item.type ~= "window") then break end
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

--- Cache le counter text — appelé depuis SetCurrentIndex() et _Recalculate(), jamais depuis Draw()
function Menu:_UpdateCounter()
    local navPos, navTotal = 0, 0
    for i = 1, #self.items do
        local it = self.items[i]
        if it and not it.isSeparator and it.type ~= "window" then
            navTotal = navTotal + 1
            if i <= self.currentItem then navPos = navTotal end
        end
    end
    self._counterText = navTotal > 0 and string.format("%d / %d", navPos, navTotal) or nil
end

-- Recalculer les positions (seulement si dirty)
function Menu:_Recalculate()
    if not self._needsRecalculate then return end

    local itemHeight = (Config.Layout and Config.Layout.itemHeight) or 35
    local yOffset = self.y + Config.Header.size.height + Config.Subtitle.size.height

    for i, item in ipairs(self.items) do
        self._cachedPositions[i] = { x = self.x, y = yOffset }
        -- Les items window ont une hauteur propre (GetHeight), les autres utilisent itemHeight
        local h = (item.GetHeight and item:GetHeight()) or itemHeight
        yOffset = yOffset + h
    end

    -- Cache positions statiques header + subtitle (jamais recomputees en Draw)
    local hCfg  = Config.Header
    local sCfg  = Config.Subtitle
    local menuW = hCfg.size.width
    local yPos  = self.y + hCfg.size.height

    local titleCfg = hCfg.title
    self._titleX = (titleCfg and titleCfg.alignment == 1)
        and (self.x + menuW * 0.5)
        or  (titleCfg and titleCfg.offsetX ~= nil and self.x + titleCfg.offsetX or self.x)
    self._titleY = self.y + (titleCfg and titleCfg.offsetY or 0)

    local tCfg = sCfg.text
    self._subtitleX = self.x + (tCfg and tCfg.offsetX or 0)
    self._subtitleY = yPos   + (tCfg and tCfg.offsetY or 0)

    local cCfg = sCfg.counter
    local padR = (cCfg and cCfg.offsetX ~= nil) and cCfg.offsetX
        or (menuW - ((sCfg.padding and sCfg.padding.right) or 8))
    self._counterX = self.x + padR
    self._counterY = yPos + (cCfg and cCfg.offsetY or 0)

    self:_UpdateCounter()

    self._needsRecalculate = false
end

-- Dessiner le menu
function Menu:Draw()
    if not self.visible then return end
    
    if self._dirty or self._needsRecalculate then
        self:_Recalculate()
        self._dirty = false
    end
    
    self:_DrawHeader()
    self:_DrawSubtitle()
    self:_DrawItemsBackground()
    self:_DrawItems()
    
    local currentItem = self:GetCurrentItem()
    if currentItem and currentItem.description and currentItem.description ~= "" then
        self:_DrawDescription(currentItem.description)
    end
end

-- Dessiner le header
function Menu:_DrawHeader()
    local cfg = Config.Header
    if cfg.sprite and cfg.sprite.use then
        local tint = cfg.sprite.color or cfg.sprite.tint
        Draw.Sprite(cfg.sprite.dict, cfg.sprite.name,
            self.x, self.y, cfg.size.width, cfg.size.height,
            cfg.sprite.heading or 0.0,
            tint and tint.r or 255,
            tint and tint.g or 255,
            tint and tint.b or 255,
            cfg.sprite.alpha or (tint and tint.a or 255))
    end
    local tc = cfg.title
    Text.Draw(self.title, self._titleX, self._titleY,
        tc.font, tc.size, tc.color, tc.alignment,
        tc.shadow and tc.shadow.enabled and tc.shadow or nil)
end

-- Dessiner le subtitle
function Menu:_DrawSubtitle()
    local cfg  = Config.Subtitle
    local hCfg = Config.Header
    Draw.Rect(self.x, self.y + hCfg.size.height, hCfg.size.width, cfg.size.height, cfg.background)
    local tc = cfg.text
    Text.Draw(self.subtitle, self._subtitleX, self._subtitleY,
        tc.font, tc.size, tc.color, Text.Align.Left)
    if self._counterText then
        local cc = cfg.counter
        Text.Draw(self._counterText, self._counterX, self._counterY,
            cc.font, cc.size, cc.color, Text.Align.Right)
    end
end

--- Obtenir la config spÃ©cifique Ã  un type d'item (list, checkbox, sliderprogress, heritage, progress)
--- Si la config spÃ©cifique n'existe pas, fallback sur Button (pour Ã©viter d'avoir Ã  gÃ©rer nil partout)
---@param itemType string
local function GetItemTypeConfig(itemType)
    if itemType == "list" then
        return Config.List
    end
    if itemType == "checkbox" then
        return Config.Checkbox or Config.Button
    end
    if itemType == "sliderprogress" then
        return Config.SliderProgress or Config.Button
    end
    if itemType == "heritage" then
        return Config.Heritage or Config.SliderProgress or Config.Button
    end
    if itemType == "progress" then
        return Config.Progress or Config.Button
    end
    return Config.Button
end

--- Dessiner le highlight de navigation (rectangle blanc derriÃ¨re l'item sÃ©lectionnÃ©)
---@param itemY number
---@param itemHeight number
---@param bgCfg table (config background spÃ©cifique Ã  ce type d'item, ou fallback Button)
function Menu:_DrawNavigationHighlight(itemY, itemHeight, bgCfg)
    local navCfg = Config.Navigation or {}
    local typeH = bgCfg and bgCfg.height
    if typeH == 0 then typeH = nil end

    local navH = typeH or (navCfg.size and navCfg.size.height) or itemHeight
    navH = math.max(0, math.min(navH, itemHeight))

    local extraOffsetY = (bgCfg and bgCfg.offsetY) or 0
    local navY = itemY + ((itemHeight - navH) * 0.5) + (navCfg.offsetY or 0) + extraOffsetY
    Draw.Rect(self.x, navY, Config.Header.size.width, navH, bgCfg.selected)
end

-- Dessiner le fond des items (gradient_bgd)
function Menu:_DrawItemsBackground()
    if #self.items == 0 then return end

    local cfg = Config.ItemsBackground
    local yStart = self.y + Config.Header.size.height + Config.Subtitle.size.height
    local itemHeight = (Config.Layout and Config.Layout.itemHeight) or 35

    -- Calculer les indices visibles (même logique que _DrawItems)
    local startIndex = math.max(1, self.currentItem - math.floor(self.maxItemsOnScreen / 2))
    local endIndex   = math.min(#self.items, startIndex + self.maxItemsOnScreen - 1)
    if endIndex - startIndex < self.maxItemsOnScreen - 1 then
        startIndex = math.max(1, endIndex - self.maxItemsOnScreen + 1)
    end

    -- Sommer les hauteurs réelles (window = 155px, autres = itemHeight)
    local totalHeight = 0
    for i = startIndex, endIndex do
        local item = self.items[i]
        totalHeight = totalHeight + ((item and item.GetHeight and item:GetHeight()) or itemHeight)
    end
    
    if cfg.sprite and cfg.sprite.use then
        local tint = cfg.sprite.color or cfg.sprite.tint
        local ok = Draw.Sprite(
            cfg.sprite.dict,
            cfg.sprite.name,
            self.x,
            yStart,
            Config.Header.size.width,
            totalHeight,
            (cfg.sprite.heading ~= nil) and cfg.sprite.heading or 0.0,
            tint and tint.r or 0,
            tint and tint.g or 0,
            tint and tint.b or 0,
            (cfg.sprite.alpha ~= nil) and cfg.sprite.alpha or (tint and tint.a or 255)
        )

        if not ok then
           Draw.Rect(self.x, yStart, Config.Header.size.width, totalHeight, cfg.color)
        end
    else
        Draw.Rect(self.x, yStart, Config.Header.size.width, totalHeight, cfg.color)
    end
end

-- Dessiner les items
function Menu:_DrawItems()
    -- 
    if #self.items == 0 then return end
    -- Note: on dessine les items dans la boucle Draw pour pouvoir appliquer des effets de survol (highlight) et de texte dynamique (ellipsize en fonction du type d'item)
    -- On pourrait optimiser en dessinant les items statiques (non sÃ©lectionnÃ©s) dans une boucle et les items dynamiques (sÃ©lectionnÃ©s) dans une autre boucle, mais pour l'instant on garde tout dans la mÃªme boucle pour la simplicitÃ©.
    -- Calculer la plage d'items a dessiner en fonction de currentItem et maxItemsOnScreen
    -- Exemple: maxItemsOnScreen = 10, currentItem = 1 => afficher items 1-10
    local itemHeight = (Config.Layout and Config.Layout.itemHeight) or 35
    local yStart = self.y + Config.Header.size.height + Config.Subtitle.size.height
    
    -- Calculer les items visibles
    local startIndex = math.max(1, self.currentItem - math.floor(self.maxItemsOnScreen / 2))
    local endIndex = math.min(#self.items, startIndex + self.maxItemsOnScreen - 1)
    
    -- Ajuster si on est a la fin de la liste pour toujours afficher maxItemsOnScreen
    -- Sauf si le nombre total d'items est inferieur a maxItemsOnScreen, alors on affiche tout sans forcer le nombre
    -- Exemple: 12 items, maxItemsOnScreen = 10, currentItem = 12 => on veut afficher les items 3-12 (10 items), pas 4-12 (9 items)
    -- Exemple: 8 items, maxItemsOnScreen = 10, currentItem = 8 => on veut afficher les items 1-8 (tous les items), pas 1-10 (impossible)
    -- Donc on ajuste startIndex pour compenser si endIndex est trop proche de la fin
    -- Note: on ajuste seulement startIndex pour éviter de faire des calculs complexes sur endIndex qui est déjà limité par le nombre total d'items
    -- Seule condition pour ajuster: si le nombre d'items affichés est inférieur à maxItemsOnScreen - 1 (car currentItem doit être inclus), alors on recule startIndex
    -- Exemple: 12 items, maxItemsOnScreen = 10, currentItem = 12 => startIndex initial = 8, endIndex initial = 12, nombre affiché = 5 < 9 => startIndex ajusté à 3
    --
    if endIndex - startIndex < self.maxItemsOnScreen - 1 then
        startIndex = math.max(1, endIndex - self.maxItemsOnScreen + 1)
    end
    
    -- Dessiner les items visibles (Y cumulatif pour supporter les hauteurs variables)
    local runY = yStart
    for i = startIndex, endIndex do
        local item = self.items[i]
        local itemH = (item.GetHeight and item:GetHeight()) or itemHeight
        local itemY = runY
        runY = runY + itemH

        local isSelected = (i == self.currentItem)

        -- Les items window gèrent tout via DrawCustom (pas de label, pas de highlight)
        if item.type == "window" then
            if item.DrawCustom then item:DrawCustom(self.x, itemY) end
            goto continue
        end

        local typeCfg = GetItemTypeConfig(item.type)
        local labelCfg = (typeCfg and typeCfg.label) or (Config.Button and Config.Button.label) or {}
        local bgCfg    = (typeCfg and typeCfg.background) or (Config.Button and Config.Button.background) or {}
        
        -- âš¡ SEULEMENT si sÃ©lectionnÃ© (et pas un separator), dessiner le rectangle blanc
        if isSelected and not item.isSeparator then
            self:_DrawNavigationHighlight(itemY, itemH, bgCfg)
        end
        -- âš¡ Si pas sÃ©lectionnÃ©, le gradient_bgd est dÃ©jÃ  dessinÃ© en fond
        
        -- Texte
        local isEnabled = (item.enabled == nil) and true or item.enabled
        local textColor
        if not isEnabled then
            textColor = labelCfg.color and labelCfg.color.disabled
        elseif isSelected then
            textColor = labelCfg.color and labelCfg.color.selected
        else
            textColor = labelCfg.color and labelCfg.color.default
        end

        local textX = self.x + (labelCfg.offsetX or 0)
        local textY = itemY + (labelCfg.offsetY or 0)
        local maxLabelWidth = nil
        local labelText = item.text or "Item"
        local labelAlreadyEllipsized = false

        if item.type == "list" and Config.List and Config.List.value then
            local menuWidth = Config.Header.size.width
            local cfg = Config.List or {}
            local valueCfg = cfg.value or {}
            local uiCfg = cfg.ui or {}

            local valueRightX = self.x + menuWidth - (valueCfg.offsetRightX or valueCfg.offsetX or 0)

            local labelGap = (cfg.labelValueGap ~= nil) and cfg.labelValueGap or 10

            -- Flexible value column width (no config change):
            -- 1) Ensure a baseline value width (~33% menu)
            -- 2) Ellipsize label to leave that baseline
            -- 3) Measure the *actual drawn* label and give the value all remaining space
            local baselineValueWidth = math.floor(menuWidth * 0.33)
            local labelFont = labelCfg.font or 0
            local labelSize = labelCfg.size or 0.26
            local labelMaxForBaseline = math.max(0, valueRightX - textX - labelGap - baselineValueWidth)
            labelText = Text.Ellipsize(labelText, labelMaxForBaseline, labelFont, labelSize)
            labelAlreadyEllipsized = true

            local drawnLabelWidth = Text.GetWidth(labelText, labelFont, labelSize)
            local remainingAfterLabel = valueRightX - (textX + drawnLabelWidth + labelGap)
            local valueColumnWidth = math.max(0, math.floor(math.max(baselineValueWidth, remainingAfterLabel)))
            maxLabelWidth = math.max(0, valueRightX - textX - labelGap - valueColumnWidth)

            -- Compute max raw widths for the list value, accounting for arrows.
            -- Stable reservation for LABEL: we reserve the same column regardless of selection.
            -- For the VALUE itself: keep two budgets so non-selected items (no arrows) can show more.
            local font = valueCfg.font or 0
            local size = valueCfg.size or 0.26
            local left = uiCfg.left or ""
            local right = uiCfg.right or ""
            local arrowsWidth = Text.GetWidth(left .. "  " .. right, font, size)

            item._listRawMaxWidthWithArrows = math.max(0, valueColumnWidth - arrowsWidth)
            item._listRawMaxWidthNoArrows = valueColumnWidth
            item._listValueColumnWidth = valueColumnWidth
        elseif item.type == "checkbox" and Config.Checkbox and Config.Checkbox.sprite then
            local menuWidth = Config.Header.size.width
            local spriteCfg = Config.Checkbox.sprite
            local size = spriteCfg.size or 32
            local offsetRightX = spriteCfg.offsetRightX or 12
            local spriteRightX = self.x + menuWidth - offsetRightX
            local spriteLeftX = spriteRightX - size
            local labelGap = (Config.Checkbox.labelSpriteGap ~= nil) and Config.Checkbox.labelSpriteGap or 10
            maxLabelWidth = spriteLeftX - textX - labelGap

        elseif item.type == "sliderprogress" and Config.SliderProgress and Config.SliderProgress.bar then
            local menuWidth = Config.Header.size.width
            local barCfg = Config.SliderProgress.bar
            local width = barCfg.width or 120
            local offsetRightX = barCfg.offsetRightX or 12
            local barRightX = self.x + menuWidth - offsetRightX
            local barLeftX = barRightX - width
            local labelGap = (Config.SliderProgress.labelBarGap ~= nil) and Config.SliderProgress.labelBarGap or 10
            maxLabelWidth = barLeftX - textX - labelGap

        elseif item.type == "heritage" then
            local menuWidth = Config.Header.size.width
            local hCfg = Config.Heritage or {}
            local iconsCfg = hCfg.icons or {}
            local barCfg = hCfg.bar or {}

            -- Mirror the layout logic inside items/heritage.lua so label never overlaps.
            local style = item.style or {}
            local iconSize = tonumber(style.iconSize) or tonumber(iconsCfg.size) or 40
            local gap = tonumber(style.gap) or tonumber(iconsCfg.gap) or 6
            local barWidth = tonumber(style.barWidth) or tonumber(barCfg.width) or 120
            local offsetRightX = tonumber(style.offsetRightX) or tonumber(hCfg.offsetRightX) or 12
            if iconSize < 0 then iconSize = 0 end
            if gap < 0 then gap = 0 end
            if barWidth < 0 then barWidth = 0 end

            local groupW = (iconSize * 2) + (gap * 2) + barWidth
            local groupRightX = self.x + menuWidth - offsetRightX
            local groupLeftX = groupRightX - groupW
            local labelGap = (hCfg.labelBarGap ~= nil) and hCfg.labelBarGap
                or ((Config.SliderProgress and Config.SliderProgress.labelBarGap ~= nil) and Config.SliderProgress.labelBarGap or 10)
            maxLabelWidth = groupLeftX - textX - labelGap

        elseif item.type == "progress" and Config.Progress and Config.Progress.bar then
            local menuWidth = Config.Header.size.width
            local barCfg = Config.Progress.bar
            local width = barCfg.width or 120
            local arrowsCfg = Config.Progress.arrows
            local reservedWidth = width
            local offsetRightX = barCfg.offsetRightX or 12
            if arrowsCfg and arrowsCfg.enabled ~= false then
                local arrowSize = arrowsCfg.size or 30
                local arrowGap = arrowsCfg.gap or 4
                reservedWidth = reservedWidth + (arrowSize * 2) + (arrowGap * 2)
                offsetRightX = arrowsCfg.offsetRightX or offsetRightX
            end
            local groupRightX = self.x + menuWidth - offsetRightX
            local groupLeftX = groupRightX - reservedWidth
            local labelGap = (Config.Progress.labelBarGap ~= nil) and Config.Progress.labelBarGap or 10
            maxLabelWidth = groupLeftX - textX - labelGap
        end

        if not maxLabelWidth then
            local rightPadding = labelCfg.rightPadding or 20
            maxLabelWidth = Config.Header.size.width - (textX - self.x) - rightPadding
        end

        if not labelAlreadyEllipsized then
            labelText = Text.Ellipsize(labelText, maxLabelWidth, labelCfg.font or 0, labelCfg.size or 0.26)
        end

        -- Ne pas dessiner le label par dÃ©faut pour les separators (gÃ©rÃ© dans DrawCustom)
        if not item.isSeparator then
            Text.Draw(
                labelText,
                textX,
                textY,
                labelCfg.font or 0,
                labelCfg.size or 0.26,
                textColor
            )
        end
        
        -- Appeler le draw spÃ©cifique de l'item (pour checkbox, list, etc.)
        if item.DrawCustom then
            item:DrawCustom(self.x, itemY, isSelected)
        end
        ::continue::
    end
end

---@param description string
-- Dessiner la description
function Menu:_DrawDescription(description)
    local cfg = Config.Description
    local spacing = cfg.spacing or 0
    local itemHeight = (Config.Layout and Config.Layout.itemHeight) or 35

    -- Même calcul d'indices que _DrawItems / _DrawItemsBackground
    local startIndex = math.max(1, self.currentItem - math.floor(self.maxItemsOnScreen / 2))
    local endIndex   = math.min(#self.items, startIndex + self.maxItemsOnScreen - 1)
    if endIndex - startIndex < self.maxItemsOnScreen - 1 then
        startIndex = math.max(1, endIndex - self.maxItemsOnScreen + 1)
    end

    -- Sommer les hauteurs réelles (window = 155px, items normaux = itemHeight)
    local realHeight = 0
    for i = startIndex, endIndex do
        local item = self.items[i]
        realHeight = realHeight + ((item and item.GetHeight and item:GetHeight()) or itemHeight)
    end

    local yPos = self.y + Config.Header.size.height + Config.Subtitle.size.height + realHeight + spacing

    local menuWidth = Config.Header.size.width

    local padding = cfg.padding or {}
    local padLeft = padding.left or (cfg.text and cfg.text.offsetX) or 0
    local padRight = padding.right or padLeft
    local padTop = padding.top or (cfg.text and cfg.text.offsetY) or 0
    local padBottom = padding.bottom or padTop

    local textX = self.x + ((cfg.text and cfg.text.offsetX) or padLeft)
    local textY = yPos + ((cfg.text and cfg.text.offsetY) or padTop)

    -- Wrap width: si cfg.text.maxWidth n'est pas dÃ©fini, on prend la largeur du menu - padding
    local wrapWidth = (cfg.text and cfg.text.maxWidth) or (menuWidth - padLeft - padRight)

    -- Auto-size: hauteur en fonction des lignes wrap
    local cfgLineHeight = (cfg.text and cfg.text.lineHeight) or 19

    local font = tonumber(cfg.text.font) or 0
    local size = tonumber(cfg.text.size) or 0.35

    -- Use native text height to avoid clipping/overflow when cfgLineHeight is too small.
    -- Keep config as minimum baseline; add a small leading for safety.
    local res = Draw.GetResolution()
    local nativeLineHeight = 0
    if type(GetTextScaleHeight) == "function" then
        nativeLineHeight = GetTextScaleHeight(size, font) * res.height
    elseif type(GetRenderedCharacterHeight) == "function" then
        nativeLineHeight = GetRenderedCharacterHeight(size, font) * res.height
    end
    local lineHeight = math.max(cfgLineHeight, math.ceil(nativeLineHeight) + 2)

    -- ParamÃ¨tres de mesure (rarement modifiÃ©s) â†’ on Ã©vite de reconstruire une clÃ© Ã  chaque frame.
    local p = self._descMeasureParams
    if not p
        or p.font ~= font
        or p.size ~= size
        or p.wrapWidth ~= wrapWidth
        or p.lineHeight ~= lineHeight
        or p.padTop ~= padTop
        or p.padBottom ~= padBottom
    then
        p = {
            font = font,
            size = size,
            wrapWidth = wrapWidth,
            lineHeight = lineHeight,
            padTop = padTop,
            padBottom = padBottom
        }
        self._descMeasureParams = p
        self._descMeasureParamsKey = table.concat({ tostring(font), tostring(size), tostring(wrapWidth), tostring(lineHeight), tostring(padTop), tostring(padBottom) }, "|")
    end

    local paramsKey = self._descMeasureParamsKey
    local byParams = self._descMeasureCache[paramsKey]
    if not byParams then
        byParams = {}
        self._descMeasureCache[paramsKey] = byParams
    end

    local cached = byParams[description]
    local lineCount
    local dynamicHeight
    if cached then
        lineCount = cached.lineCount
        dynamicHeight = cached.height
    else
        lineCount = Text.GetLineCount(description, textX, textY, font, size, wrapWidth, Text.Align.Left)
        lineCount = math.max(1, lineCount)
        dynamicHeight = padTop + padBottom + (lineCount * lineHeight)
        byParams[description] = { lineCount = lineCount, height = dynamicHeight }
    end

    -- Fond (hauteur dynamique)
    Draw.Rect(
        self.x,
        yPos,
        menuWidth,
        dynamicHeight,
        cfg.background
    )

    -- Texte (wrap)
    Text.Draw(
        description,
        textX,
        textY,
        cfg.text.font,
        cfg.text.size,
        cfg.text.color,
        Text.Align.Left,
        nil,
        nil,
        true,
        wrapWidth
    )
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