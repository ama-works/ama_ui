-- items/slider.lua
-- Herite de BaseItem. Barre de progression controlee avec Left/Right.

UIMenuSliderProgress = setmetatable({}, { __index = BaseItem })
UIMenuSliderProgress.__index = UIMenuSliderProgress

---@param text string
---@param progressStart number
---@param progressMax number
---@param description string
---@param enabled boolean|nil
---@param actions table|nil   { onSelect=fn, onChange=fn, step=number }
function UIMenuSliderProgress.New(text, progressStart, progressMax, description, enabled, actions)
	local self = BaseItem.New(UIMenuSliderProgress, "sliderprogress", text, description, enabled)

	self.max = tonumber(progressMax) or 100
	if self.max < 0 then self.max = 0 end
	self.min = 0
	self.value = BaseItem.Clamp(tonumber(progressStart) or 0, self.min, self.max)
	self._step = (actions and tonumber(actions.step)) or 1

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
local _sliderCfg, _sliderMenuW, _sliderItemH

local function SliderCfg()
	if not _sliderCfg then
		_sliderCfg   = Config.SliderProgress or {}
		_sliderMenuW = Config.Header.size.width
		_sliderItemH = (Config.Layout and Config.Layout.itemHeight) or 35
	end
	return _sliderCfg, _sliderMenuW, _sliderItemH
end

---@param x          number
---@param y          number
---@param isSelected boolean
---@param invW       number|nil  1/resW pre-calcule
---@param invH       number|nil  1/resH pre-calcule
function UIMenuSliderProgress:DrawCustom(x, y, isSelected, invW, invH)
	if not invW or not invH then
		invW, invH = Draw.GetInvScale()
	end

	local isEnabled = (self.enabled == nil) and true or self.enabled

	-- Chemin optimise : valeurs pre-calculees dans _Recalculate
	if self._barNX then
		local barNY = y * invH + self._barNYOff
		local ratio = (self.max > 0) and (self.value / self.max) or 0
		if ratio < 0 then ratio = 0 elseif ratio > 1 then ratio = 1 end

		local bgR, bgG, bgB, bgA, fiR, fiG, fiB, fiA
		if not isEnabled then
			bgR, bgG, bgB, bgA = self._barBgDR, self._barBgDG, self._barBgDB, self._barBgDA
			fiR, fiG, fiB, fiA = self._barFiDR, self._barFiDG, self._barFiDB, self._barFiDA
		elseif isSelected then
			bgR, bgG, bgB, bgA = self._barBgSR, self._barBgSG, self._barBgSB, self._barBgSA
			fiR, fiG, fiB, fiA = self._barFiSR, self._barFiSG, self._barFiSB, self._barFiSA
		else
			bgR, bgG, bgB, bgA = self._barBgR, self._barBgG, self._barBgB, self._barBgA
			fiR, fiG, fiB, fiA = self._barFiR, self._barFiG, self._barFiB, self._barFiA
		end

		-- Fond
		Draw.RectRaw(self._barNX, barNY, self._barNW, self._barNH, bgR, bgG, bgB, bgA)

		-- Fill (aligne a gauche du fond)
		local fillNW = self._barNW * ratio
		if fillNW > 0 then
			local fillNX = self._barNX - self._barNW * 0.5 + fillNW * 0.5
			Draw.RectRaw(fillNX, barNY, fillNW, self._barNH, fiR, fiG, fiB, fiA)
		end
		return
	end

	-- Fallback non-optimise (avant premier _Recalculate)
	local cfg, menuWidth, itemHeight = SliderCfg()
	local bar = cfg.bar or {}

	local width   = bar.width or 120
	local barH    = tonumber(bar.height) or 8
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
	local bgColor   = BaseItem.ResolveColor(colors.background,   colors.backgroundSelected,   colors.backgroundDisabled,   isEnabled, isSelected)
	local fillColor = BaseItem.ResolveColor(colors.fill,         colors.fillSelected,         colors.fillDisabled,         isEnabled, isSelected)

	if bgColor then Draw.Rect(barX, barY, width, barH, bgColor) end

	local ratio = (self.max > 0) and (self.value / self.max) or 0
	if ratio < 0 then ratio = 0 elseif ratio > 1 then ratio = 1 end
	local fillW = width * ratio
	if fillW > 0 and fillColor then Draw.Rect(barX, barY, fillW, barH, fillColor) end

	if bar.showValue == true then
		local valueText = string.format("%d/%d", math.floor(self.value), math.floor(self.max))
		local valueCfg = cfg.value or {}
		local tx = x + menuWidth - (valueCfg.offsetRightX or offsetRightX)
		local ty = y + (valueCfg.offsetY or 7)
		local color = BaseItem.GetColor(valueCfg.color, isEnabled, isSelected)
		Text.Draw(valueText, tx, ty, valueCfg.font or 0, valueCfg.size or 0.26, color, Text.Align.Right)
	end
end

-- Alias explicite
DrawSliderProgress = UIMenuSliderProgress

return UIMenuSliderProgress
