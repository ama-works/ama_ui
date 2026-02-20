-- items/progress.lua
-- HÃ©rite de BaseItem. Barre de progression avec flÃ¨ches optionnelles.

UIMenuProgressItem = setmetatable({}, { __index = BaseItem })
UIMenuProgressItem.__index = UIMenuProgressItem

---@param text string
---@param progressStart number
---@param progressMax number
---@param description string
---@param style table|nil
---@param enabled boolean|nil
---@param actions table|nil
function UIMenuProgressItem.New(text, progressStart, progressMax, description, style, enabled, actions)
	local self = BaseItem.New(UIMenuProgressItem, "progress", text, description, enabled)

	self.max = tonumber(progressMax) or 100
	if self.max < 0 then self.max = 0 end
	self.min = 0
	self.value = BaseItem.Clamp(tonumber(progressStart) or 0, self.min, self.max)
	self.style = style or {}

	self.OnProgressChanged = Event.New()

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
local _progCfg, _progMenuW, _progItemH

local function ProgressCfg()
	if not _progCfg then
		_progCfg   = Config.Progress or {}
		_progMenuW = Config.Header.size.width
		_progItemH = (Config.Layout and Config.Layout.itemHeight) or 35
	end
	return _progCfg, _progMenuW, _progItemH
end

function UIMenuProgressItem:DrawCustom(x, y, isSelected)
	local cfg, menuWidth, itemHeight = ProgressCfg()
	local bar    = cfg.bar or {}
	local arrows = cfg.arrows or {}

	local width = tonumber(self.style.width) or bar.width or 120
	local barH  = tonumber(self.style.height) or tonumber(bar.height) or 8
	local rectCfg = bar.rectangle
	if rectCfg then
		local bk = rectCfg.black
		if bk and bk.height then barH = tonumber(bk.height) or barH end
	end
	if width < 0 then width = 0 end
	if barH  < 0 then barH  = 0 end

	local arrowsEnabled = (arrows.enabled ~= false)
	local arrowSize = arrows.size or 30
	local arrowGap  = arrows.gap or 4
	local offsetRightX = (arrowsEnabled and (arrows.offsetRightX or bar.offsetRightX)) or bar.offsetRightX or 12
	local offsetY = (bar.offsetY ~= nil) and bar.offsetY or ((itemHeight - barH) * 0.5)

	local barX, leftArrowX, rightArrowX
	if arrowsEnabled then
		local groupRightX = x + menuWidth - offsetRightX
		rightArrowX = groupRightX - arrowSize
		barX = rightArrowX - arrowGap - width
		leftArrowX = barX - arrowGap - arrowSize
	else
		barX = x + menuWidth - offsetRightX - width
	end
	local barY = y + offsetY

	local isEnabled = (self.enabled == nil) and true or self.enabled
	local colors = bar.color or {}

	-- ZERO-ALLOC
	local bgColor   = BaseItem.ResolveColor(colors.background, colors.backgroundSelected, colors.backgroundDisabled, isEnabled, isSelected)
	local fillColor = BaseItem.ResolveColor(colors.fill,       colors.fillSelected,       colors.fillDisabled,       isEnabled, isSelected)

	if bgColor then
		Draw.Rect(barX, barY, width, barH, bgColor)
	end

	-- FlÃ¨ches gauche / droite
	if arrowsEnabled then
		local showArrows = not (arrows.onlyOnSelected == true and not isSelected)
		if showArrows then
			local arrowColor = BaseItem.GetColor(arrows.color, isEnabled, isSelected)
			local ar, ag, ab, aa = arrowColor and arrowColor.r or 255, arrowColor and arrowColor.g or 255, arrowColor and arrowColor.b or 255, arrowColor and arrowColor.a or 255

			local arrowY = (arrows.offsetY ~= nil) and (y + arrows.offsetY) or (barY + (barH - arrowSize) * 0.5)

			local dict = arrows.dict or "commonmenu"
			Draw.Sprite(dict, arrows.left or "arrowleft",  leftArrowX,  arrowY, arrowSize, arrowSize, 0.0, ar, ag, ab, aa)
			Draw.Sprite(dict, arrows.right or "arrowright", rightArrowX, arrowY, arrowSize, arrowSize, 0.0, ar, ag, ab, aa)
		end
	end

	local ratio = (self.max > 0) and (self.value / self.max) or 0
	if ratio < 0 then ratio = 0 elseif ratio > 1 then ratio = 1 end
	local fillW = width * ratio
	if fillW > 0 and fillColor then
		Draw.Rect(barX, barY, fillW, barH, fillColor)
	end
end

-- Alias explicite
DrawProgress = UIMenuProgressItem

return UIMenuProgressItem
