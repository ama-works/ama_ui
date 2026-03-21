-- items/base.lua
-- Classe mère de TOUS les items du menu NativeUI.
-- Chaque item (button, checkbox, list, slider, progress, heritage, separator)
-- hérite de BaseItem via setmetatable({}, {__index = BaseItem}).
--
-- Usage dans un item enfant:
--   local self = BaseItem.New(UIMenuCheckbox, "checkbox", text, description, true)

BaseItem = {}
BaseItem.__index = BaseItem

-- ============================================================================
-- 2.1 — Constructeur commun
-- ============================================================================

---@param itemClass table  La classe enfant (ex: UIMenuCheckbox)
---@param itemType string  Le type d'item ("button", "checkbox", "list", etc.)
---@param text string|nil  Label affiché
---@param description string|nil  Description affichée en bas du menu
---@param enabled boolean|nil  true par défaut
---@return table  instance avec metatable = itemClass
function BaseItem.New(itemClass, itemType, text, description, enabled)
	local self = setmetatable({}, itemClass)

	self.id = GenerateUUID()
	self.type = itemType or "button"
	self.text = text or "Item"
	self.description = description or ""
	self.enabled = (enabled == nil) and true or enabled
	self.parent = nil -- sera set par Menu:AddItem()

	self.OnActivated = Event.New()

	return self
end

-- ============================================================================
-- 2.2 — Méthodes partagées (centralisées, plus jamais dupliquées)
-- ============================================================================

--- Change le label de l'item et marque le menu comme dirty (auto-refresh).
function BaseItem:SetText(text)
	self.text = text or self.text
	if self.parent then
		self.parent._dirty = true
		self.parent._needsRecalculate = true
	end
end

--- Change la description et marque le menu comme dirty.
function BaseItem:SetDescription(desc)
	self.description = desc or ""
	self._descFn = nil   -- annule toute description dynamique existante
	if self.parent then self.parent._dirty = true end
end

--- Attache une description dynamique — fn(item) est appelée chaque frame.
---   btn:SetDynDesc(function(item) return "Valeur : " .. myValue end)
--- Passer nil pour retirer la description dynamique.
function BaseItem:SetDynDesc(fn)
	self._descFn = fn
	if fn then
		self.description = fn(self)   -- calcul immédiat pour la valeur initiale
	end
end

--- Active/désactive l'item et marque le menu comme dirty.
function BaseItem:SetEnabled(enabled)
	self.enabled = (enabled == nil) and true or enabled
	if self.parent then self.parent._dirty = true end
end

--- Nettoie l'item pour éviter les fuites mémoire.
--- Appeler quand un menu est fermé/recyclé.
function BaseItem:Destroy()
	if self.OnActivated then self.OnActivated.Clear() end
	if self.OnProgressChanged then self.OnProgressChanged.Clear() end
	-- OnSliderChanged removed (heritage now uses OnProgressChanged)
	if self.OnCheckboxChange then self.OnCheckboxChange.Clear() end
	if self.OnListChanged then self.OnListChanged.Clear() end
	self.parent = nil
	setmetatable(self, nil)
end

-- ============================================================================
-- 2.3 — Helper statique: résolution couleur 3-way (disabled → selected → default)
-- ============================================================================
-- Remplace les ~15 blocs if/elseif/else identiques dans tous les items.
-- Usage: local c = BaseItem.GetColor(colors, isEnabled, isSelected)

---@param colorTable table|nil  Table avec clés: default, selected, disabled
---@param isEnabled boolean
---@param isSelected boolean
---@return table|nil  La couleur {r,g,b,a} correspondant à l'état
function BaseItem.GetColor(colorTable, isEnabled, isSelected)
	if not colorTable then return nil end
	if not isEnabled then
		return colorTable.disabled or colorTable.default
	elseif isSelected then
		return colorTable.selected or colorTable.default
	else
		return colorTable.default
	end
end

--- Version ZERO-ALLOC de GetColor: prend 3 couleurs directes (pas de table wrapper).
--- Élimine la création de table temporaire {default=…, selected=…, disabled=…} par frame.
---@param default table|nil
---@param selected table|nil
---@param disabled table|nil
---@param isEnabled boolean
---@param isSelected boolean
---@return table|nil
function BaseItem.ResolveColor(default, selected, disabled, isEnabled, isSelected)
	if not isEnabled then return disabled or default end
	if isSelected then return selected or default end
	return default
end

-- ============================================================================
-- 2.4 — Méthodes valeur/barre (pour slider, progress, heritage)
-- ============================================================================
-- Les items sans barre (button, checkbox, list, separator) ignorent ces méthodes.
-- Elles ne sont appelées que par la navigation sur les items qui les supportent.

--- Clamp une valeur entre min et max. Helper statique.
---@param v number
---@param min number
---@param max number
---@return number
function BaseItem.Clamp(v, min, max)
	if v < min then return min end
	if v > max then return max end
	return v
end

--- Change la valeur, clamp, et émet l'event approprié.
function BaseItem:SetValue(value)
	local clamped = BaseItem.Clamp(tonumber(value) or 0, self.min, self.max)
	if clamped ~= self.value then
		self.value = clamped
		if self.OnProgressChanged then self.OnProgressChanged.Emit(self, self.value, self.max) end
	end
end

--- Change le maximum, re-clamp la valeur.
function BaseItem:SetMax(max)
	self.max = tonumber(max) or self.max
	if self.max < 0 then self.max = 0 end
	self.value = BaseItem.Clamp(self.value, self.min, self.max)
end

--- Retourne le step (incrémentation par pression gauche/droite).
---@return number
function BaseItem:GetStep()
	local step = self._step or (self.style and tonumber(self.style.step))
	if not step or step <= 0 then step = 1 end
	return step
end

--- Incrémente la valeur d'un step (ignoré si l'item n'a pas de valeur).
function BaseItem:Next()
	if self.value == nil then return end
	self:SetValue(self.value + self:GetStep())
end

--- Décrémente la valeur d'un step (ignoré si l'item n'a pas de valeur).
function BaseItem:Prev()
	if self.value == nil then return end
	self:SetValue(self.value - self:GetStep())
end

return BaseItem
