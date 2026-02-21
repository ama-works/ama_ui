-- ============================================================================
-- items/parent_selector.lua
-- Item spécial pour la sélection des parents (Mom/Dad) GTA V
-- ============================================================================

-- ============================================================================
-- items/parent_selector.lua
-- Item spécial pour la sélection des parents (Mom/Dad) GTA V
-- ============================================================================

UIMenuParentSelector = {}  -- ← GLOBAL (pas local)
UIMenuParentSelector.__index = UIMenuParentSelector
setmetatable(UIMenuParentSelector, { __index = BaseItem })

-- ... reste du code ...

-- ❌ NE PAS METTRE
-- return UIMenuParentSelector  

-- Le fichier se termine juste sans return

-- ============================================================================
-- NOMS DES PARENTS GTA V (ordre exact)
-- ============================================================================

-- Index 0-20 : Mères (21 au total)
UIMenuParentSelector.MOM_NAMES = {
    [0]  = "Hannah",
    [1]  = "Audrey",
    [2]  = "Jasmine",
    [3]  = "Gisele",
    [4]  = "Amelia",
    [5]  = "Isabella",
    [6]  = "Zoe",
    [7]  = "Ava",
    [8]  = "Camilla",
    [9]  = "Violet",
    [10] = "Sophia",
    [11] = "Eveline",
    [12] = "Nicole",
    [13] = "Ashley",
    [14] = "Gracie",
    [15] = "Brianna",
    [16] = "Natalie",
    [17] = "Olivia",
    [18] = "Elizabeth",
    [19] = "Charlotte",
    [20] = "Emma",
}

-- Index 0-23 : Pères (24 au total)
UIMenuParentSelector.DAD_NAMES = {
    [0]  = "Benjamin",
    [1]  = "Daniel",
    [2]  = "Joshua",
    [3]  = "Noah",
    [4]  = "Andrew",
    [5]  = "Juan",
    [6]  = "Alex",
    [7]  = "Isaac",
    [8]  = "Evan",
    [9]  = "Ethan",
    [10] = "Vincent",
    [11] = "Angel",
    [12] = "Diego",
    [13] = "Adrian",
    [14] = "Gabriel",
    [15] = "Michael",
    [16] = "Santiago",
    [17] = "Kevin",
    [18] = "Louis",
    [19] = "Samuel",
    [20] = "Anthony",
    [21] = "Claude",   -- GTA III
    [22] = "Niko",     -- GTA IV
    [23] = "John",     -- RDR
}

-- ============================================================================
-- CONSTRUCTEUR
-- ============================================================================

--- Créer un sélecteur de parent (Mom ou Dad)
---@param parentType string "mom" ou "dad"
---@param startIndex number Index de départ (0-20 pour mom, 0-23 pour dad)
---@param description string Description de l'item
---@param actions table Callbacks { onChange = fn }
---@return table UIMenuParentSelector
function UIMenuParentSelector.New(parentType, startIndex, description, actions)
    local self = BaseItem.New(UIMenuParentSelector, "parent_selector", "", description, true)
    
    -- Type de parent
    self.parentType = parentType or "mom"  -- "mom" ou "dad"
    
    -- Liste des noms selon le type
    if self.parentType == "mom" then
        self.names = UIMenuParentSelector.MOM_NAMES
        self.maxIndex = 20
    else
        self.names = UIMenuParentSelector.DAD_NAMES
        self.maxIndex = 23
    end
    
    -- Index actuel (0-based pour correspondre aux natifs GTA)
    self.index = startIndex or 0
    
    -- Clamp l'index
    if self.index < 0 then self.index = 0 end
    if self.index > self.maxIndex then self.index = self.maxIndex end
    
    -- Label dynamique
    self.text = self.parentType == "mom" and "Mère" or "Père"
    
    -- Event
    self.OnParentChanged = Event.New()
    
    -- Actions
    if actions and type(actions.onChange) == "function" then
        self.OnParentChanged.On(function(item)
            actions.onChange(item)
        end)
    end
    
    return self
end

-- ============================================================================
-- MÉTHODES
-- ============================================================================

--- Obtenir le nom du parent actuel
---@return string
function UIMenuParentSelector:GetName()
    return self.names[self.index] or "Unknown"
end

--- Obtenir l'index actuel (0-based)
---@return number
function UIMenuParentSelector:GetIndex()
    return self.index
end

--- Définir l'index
---@param index number
function UIMenuParentSelector:SetIndex(index)
    if index < 0 then index = 0 end
    if index > self.maxIndex then index = self.maxIndex end
    
    if self.index ~= index then
        self.index = index
        self.OnParentChanged.Emit(self)
        if self.parent then self.parent._dirty = true end
    end
end

--- Passer au parent suivant
function UIMenuParentSelector:Next()
    local newIndex = self.index + 1
    if newIndex > self.maxIndex then newIndex = 0 end
    self:SetIndex(newIndex)
end

--- Passer au parent précédent
function UIMenuParentSelector:Previous()
    local newIndex = self.index - 1
    if newIndex < 0 then newIndex = self.maxIndex end
    self:SetIndex(newIndex)
end

--- Appliquer les natifs GTA (hérédité)
---@param ped number Entity ID du ped
---@param otherParentIndex number Index de l'autre parent
---@param resemblance number Ressemblance (0.0-1.0)
---@param skinMix number Mix de peau (0.0-1.0)
function UIMenuParentSelector:ApplyToGame(ped, otherParentIndex, resemblance, skinMix)
    resemblance = resemblance or 0.5
    skinMix = skinMix or 0.5
    
    local momIdx, dadIdx
    
    if self.parentType == "mom" then
        momIdx = self.index
        dadIdx = otherParentIndex or 0
    else
        momIdx = otherParentIndex or 0
        dadIdx = self.index
    end
    
    -- Native GTA V pour l'hérédité
    SetPedHeadBlendData(
        ped,
        momIdx,      -- Shape First ID (mère)
        dadIdx,      -- Shape Second ID (père)
        0,           -- Shape Third ID (unused)
        momIdx,      -- Skin First ID (mère)
        dadIdx,      -- Skin Second ID (père)
        0,           -- Skin Third ID (unused)
        resemblance, -- Shape Mix (0.0-1.0)
        skinMix,     -- Skin Mix (0.0-1.0)
        0.0,         -- Third Mix (unused)
        false        -- IsParent
    )
end

-- ============================================================================
-- INPUTS (gestion flèches gauche/droite)
-- ============================================================================

function UIMenuParentSelector:HandleInput()
    if not self.parent or not self.enabled then return false end
    
    -- Flèche gauche
    if IsControlJustPressed(0, 174) then  -- INPUT_CURSOR_SCROLL_LEFT
        self:Previous()
        return true
    end
    
    -- Flèche droite
    if IsControlJustPressed(0, 175) then  -- INPUT_CURSOR_SCROLL_RIGHT
        self:Next()
        return true
    end
    
    return false
end

-- ============================================================================
-- RENDU CUSTOM
-- ============================================================================

function UIMenuParentSelector:DrawCustom(x, y, isSelected)
    if not Config.ParentSelector then return end
    
    local cfg = Config.ParentSelector
    local itemWidth = Config.Header.size.width
    local itemHeight = (Config.Layout and Config.Layout.itemHeight) or 35
    
    -- Valeur actuelle (nom du parent)
    local currentName = self:GetName()
    
    -- Position du texte valeur (droite)
    local valueX = x + itemWidth - (cfg.valueOffsetX or 80)
    local valueY = y + (itemHeight / 2)
    
    -- Dessiner les flèches ◄ ►
    local arrowLeftX = x + itemWidth - (cfg.arrowOffsetX or 120)
    local arrowRightX = x + itemWidth - (cfg.arrowOffsetX or 20)
    local arrowY = y + (itemHeight / 2)
    
    -- Flèche gauche ◄
    Text.Draw(
        "<",
        arrowLeftX,
        arrowY,
        cfg.arrowFont or 0,
        cfg.arrowSize or 0.35,
        isSelected and cfg.arrowColorSelected or cfg.arrowColor or { r = 255, g = 255, b = 255, a = 255 }
    )
    
    -- Nom du parent (centré)
    Text.Draw(
        currentName,
        valueX,
        valueY,
        cfg.valueFont or 0,
        cfg.valueSize or 0.26,
        isSelected and cfg.valueColorSelected or cfg.valueColor or { r = 255, g = 255, b = 255, a = 255 }
    )
    
    -- Flèche droite ►
    Text.Draw(
        ">",
        arrowRightX,
        arrowY,
        cfg.arrowFont or 0,
        cfg.arrowSize or 0.35,
        isSelected and cfg.arrowColorSelected or cfg.arrowColor or { r = 255, g = 255, b = 255, a = 255 }
    )
end

return UIMenuParentSelector
