-- panels/base.lua
-- Classe de base pour tous les panels ama_ui.
-- Un panel est un item non-navigable dessiné via DrawCustom (pas de label, pas de highlight).
-- Hériter : MonPanel = setmetatable({}, { __index = PanelBase }) puis surcharger DrawCustom et GetHeight.

PanelBase = {}
PanelBase.__index = PanelBase

---@param panelClass table
---@param height number|nil  hauteur en pixels (défaut 100)
function PanelBase.New(panelClass, height)
    local self = setmetatable({}, panelClass)
    self.id      = GenerateUUID()   -- même pattern que BaseItem
    self.type    = "panel"          -- reconnu par menu.lua comme non-navigable
    self.parent  = nil              -- défini par Menu:AddItem
    self._height = height or 100
    return self
end

--- Retourne la hauteur du panel en pixels.
--- Surcharger dans les sous-classes si la hauteur est dynamique.
function PanelBase:GetHeight()
    return self._height
end

--- Dessin du panel. Appelé par menu.lua via DrawCustom(x, y).
--- x, y : coin top-left du panel (pixels normalisés GTA).
--- Surcharger dans chaque sous-classe.
function PanelBase:DrawCustom(x, y)
end

--- Nettoyage mémoire.
function PanelBase:Destroy()
    self.parent = nil
    setmetatable(self, nil)
end

return PanelBase
