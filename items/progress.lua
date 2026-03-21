-- items/progress.lua
-- Herite de BaseItem. Barre de statut passive (sante, stamina, faim, etc.) — sans fleches.

UIMenuProgressItem = setmetatable({}, { __index = BaseItem })
UIMenuProgressItem.__index = UIMenuProgressItem

---@param text string
---@param progressStart number
---@param progressMax number
---@param description string
---@param enabled boolean|nil
---@param actions table|nil   { onSelect=fn, onChange=fn }
function UIMenuProgressItem.New(text, progressStart, progressMax, description, enabled, actions)
	local self = BaseItem.New(UIMenuProgressItem, "progress", text, description, enabled)

	self.max = tonumber(progressMax) or 100
	if self.max < 0 then self.max = 0 end
	self.min = 0
	self.value = BaseItem.Clamp(tonumber(progressStart) or 0, self.min, self.max)

	self.OnProgressChanged = Event.New()

	if actions then
		if type(actions.onSelect) == "function" then
			self.OnActivated.On(function()
				actions.onSelect(self, self.value, self.max)
			end)
		end
		if type(actions.onChange) == "function" then
			self.OnProgressChanged.On(function(_, value, max)
				actions.onChange(self, value, max)
			end)
		end
	end

	return self
end

-- SetEnabled, SetMax, SetValue, GetStep, Next, Prev → tous hérités de BaseItem

-- Upvalues: fallback si DrawCustom appelé sans pré-calcul
local _progCfg, _progMenuW, _progItemH

local function ProgressCfg()
	if not _progCfg then
		_progCfg   = Config.Progress or {}
		_progMenuW = Config.Header.size.width
		_progItemH = (Config.Layout and Config.Layout.itemHeight) or 35
	end
	return _progCfg, _progMenuW, _progItemH
end

---@param x          number
---@param y          number
---@param isSelected boolean
---@param invW       number|nil  1/resW pre-calcule
---@param invH       number|nil  1/resH pre-calcule
function UIMenuProgressItem:DrawCustom(x, y, isSelected, invW, invH)
	if not invW or not invH then
		invW, invH = Draw.GetInvScale()
	end

	local isEnabled = (self.enabled == nil) and true or self.enabled

	-- Chemin optimise : valeurs pre-calculees dans _Recalculate
	if self._barNX then
		local barNY  = y * invH + self._barNYOff
		local ratio  = (self.max > 0) and (self.value / self.max) or 0
		if ratio < 0 then ratio = 0 elseif ratio > 1 then ratio = 1 end

		-- progress n'a pas de variantes selected/disabled dans le plan — on utilise les valeurs de base
		Draw.RectRaw(self._barNX, barNY, self._barNW, self._barNH,
			self._barBgR, self._barBgG, self._barBgB, self._barBgA)

		local fillNW = self._barNW * ratio
		if fillNW > 0 then
			local fillNX = self._barNX - self._barNW * 0.5 + fillNW * 0.5
			Draw.RectRaw(fillNX, barNY, fillNW, self._barNH,
				self._barFiR, self._barFiG, self._barFiB, self._barFiA)
		end
		return
	end

	-- Fallback non-optimise (avant premier _Recalculate)
	local cfg, menuWidth, itemHeight = ProgressCfg()
	local bar = cfg.bar or {}

	local width = (self.style and tonumber(self.style.width)) or bar.width or 120
	local barH  = (self.style and tonumber(self.style.height)) or tonumber(bar.height) or 8
	local rectCfg = bar.rectangle
	if rectCfg then
		local bk = rectCfg.black
		if bk and bk.height then barH = tonumber(bk.height) or barH end
	end
	if width < 0 then width = 0 end
	if barH  < 0 then barH  = 0 end

	local offsetRightX = bar.offsetRightX or 12
	local offsetY = (bar.offsetY ~= nil) and bar.offsetY or ((itemHeight - barH) * 0.5)

	local barX = x + menuWidth - offsetRightX - width
	local barY = y + offsetY

	local colors = bar.color or {}
	local bgColor   = BaseItem.ResolveColor(colors.background, colors.backgroundSelected, colors.backgroundDisabled, isEnabled, isSelected)
	local fillColor = BaseItem.ResolveColor(colors.fill,       colors.fillSelected,       colors.fillDisabled,       isEnabled, isSelected)

	if bgColor then Draw.Rect(barX, barY, width, barH, bgColor) end

	local ratio = (self.max > 0) and (self.value / self.max) or 0
	if ratio < 0 then ratio = 0 elseif ratio > 1 then ratio = 1 end
	local fillW = width * ratio
	if fillW > 0 and fillColor then Draw.Rect(barX, barY, fillW, barH, fillColor) end
end

-- Alias explicite
DrawProgress = UIMenuProgressItem

return UIMenuProgressItem
