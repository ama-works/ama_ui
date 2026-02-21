-- items/slider.lua
-- HÃ©rite de BaseItem. Barre de progression contrÃ´lÃ©e avec Left/Right.

UIMenuSliderProgress = setmetatable({}, { __index = BaseItem })
UIMenuSliderProgress.__index = UIMenuSliderProgress

---@param text string
---@param progressStart number
---@param progressMax number
---@param description string
---@param style table|nil
---@param enabled boolean|nil
---@param actions table|nil
function UIMenuSliderProgress.New(text, progressStart, progressMax, description, style, enabled, actions)
	local self = BaseItem.New(UIMenuSliderProgress, "sliderprogress", text, description, enabled)

	self.max = tonumber(progressMax) or 100
	if self.max < 0 then self.max = 0 end
	self.min = 0
	self.value = BaseItem.Clamp(tonumber(progressStart) or 0, self.min, self.max)
	self.style = style or {}

	self.OnProgressChanged = Event.New()

	-- Callbacks optionnels (style RageUI)
	if actions then
		if type(actions.onSelected) == "function" then
			self.OnActivated.On(function()
				actions.onSelected(self, self.value, self.max)
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

-- SetEnabled, SetMax, SetValue, GetStep, Next, Prev â†’ tous hÃ©ritÃ©s de BaseItem

-- Upvalues: Ã©vite les lookups Config rÃ©pÃ©tÃ©s par frame
local _sliderCfg    -- cache Config.SliderProgress
local _sliderMenuW  -- cache Config.Header.size.width
local _sliderItemH  -- cache itemHeight

local function SliderCfg()
	if not _sliderCfg then
		_sliderCfg  = Config.SliderProgress or {}
		_sliderMenuW = Config.Header.size.width
		_sliderItemH = (Config.Layout and Config.Layout.itemHeight) or 35
	end
	return _sliderCfg, _sliderMenuW, _sliderItemH
end

function UIMenuSliderProgress:DrawCustom(x, y, isSelected)
	local cfg, menuWidth, itemHeight = SliderCfg()
	local bar = cfg.bar or {}

	local width   = tonumber(self.style.width) or bar.width or 120
	local barH    = tonumber(self.style.height) or tonumber(bar.height) or 8
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

	local isEnabled = (self.enabled == nil) and true or self.enabled
	local colors = bar.color or {}

	-- ZERO-ALLOC: pas de table temporaire
	local bgColor   = BaseItem.ResolveColor(colors.background,   colors.backgroundSelected,   colors.backgroundDisabled,   isEnabled, isSelected)
	local fillColor = BaseItem.ResolveColor(colors.fill,         colors.fillSelected,         colors.fillDisabled,         isEnabled, isSelected)

	-- Background bar
	if bgColor then
		Draw.Rect(barX, barY, width, barH, bgColor)
	end

	-- Fill
	local ratio = (self.max > 0) and (self.value / self.max) or 0
	if ratio < 0 then ratio = 0 elseif ratio > 1 then ratio = 1 end
	local fillW = width * ratio
	if fillW > 0 and fillColor then
		Draw.Rect(barX, barY, fillW, barH, fillColor)
	end

	-- Optionnel: value text Ã  droite
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
