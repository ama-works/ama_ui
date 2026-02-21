---@diagnostic disable: undefined-global

-- input/mouse.lua
-- Navigation souris minimale:
-- - Hover sur une ligne => sÃ©lectionne l'item
-- - Clic sur flÃ¨che gauche/droite (Progress uniquement) => Prev/Next

MenuMouse = MenuMouse or {}

-- Natives
local DisableControlAction = DisableControlAction
local IsDisabledControlJustPressed = IsDisabledControlJustPressed
local GetDisabledControlNormal = GetDisabledControlNormal
local GetControlNormal = GetControlNormal
local SetMouseCursorActiveThisFrame = SetMouseCursorActiveThisFrame

-- Controls
local INPUT_CURSOR_X = 239
local INPUT_CURSOR_Y = 240
local INPUT_ATTACK = 24 -- Left click
local INPUT_AIM = 25

local function GetMousePixels()
	local res = Draw and Draw.GetResolution and Draw.GetResolution()
	if not res then
		return nil, nil
	end

	-- Prefer disabled normals (souvent utilisÃ©s quand on disable des contrÃ´les)
	local nx = 0.0
	local ny = 0.0
	if GetDisabledControlNormal then
		nx = GetDisabledControlNormal(0, INPUT_CURSOR_X)
		ny = GetDisabledControlNormal(0, INPUT_CURSOR_Y)
	elseif GetControlNormal then
		nx = GetControlNormal(0, INPUT_CURSOR_X)
		ny = GetControlNormal(0, INPUT_CURSOR_Y)
	end

	return nx * res.width, ny * res.height
end
---@returns boolean
---@params px number, py number, x number, y number, w number, h number
--- Checks if point (px, py) is within the rectangle defined by (x, y, w, h)
--- (x, y) is the top-left corner of the rectangle, w is width and h is height
--- Returns true if the point is inside the rectangle, false otherwise
--- Example usage: PointInRect(150, 150, 100, 100, 200, 200) => true
local function PointInRect(px, py, x, y, w, h)
	return px >= x and px <= (x + w) and py >= y and py <= (y + h)
end

--- Given the menu and its current state, calculates the range of item indices that are currently visible on screen
--- This is used to determine which items are being rendered and interacted with, especially for pagination and scrolling
---- The function takes into account the current selected item, the maximum number of items that can be displayed on screen, and the total number of items in the menu
--- It ensures that the selected item is centered in the visible range when possible, and adjusts the start and end indices accordingly to fit within the total number of items
--- @param menu table - The menu object containing the current state of the menu, including items, currentItem, and maxItemsOnScreen
local function GetVisibleRange(menu)
	local startIndex = math.max(1, menu.currentItem - math.floor(menu.maxItemsOnScreen / 2))
	local endIndex = math.min(#menu.items, startIndex + menu.maxItemsOnScreen - 1)
	if endIndex - startIndex < menu.maxItemsOnScreen - 1 then
		startIndex = math.max(1, endIndex - menu.maxItemsOnScreen + 1)
	end
	return startIndex, endIndex
end

--- Resolves the heights for the progress bar's background (black) and fill (white) based on the item's style and the configuration
--- This function checks the item's style for a specified height, then falls back to the bar configuration, and finally to a default value
--- It ensures that both the background and fill heights are the same, as per the specification, and that they are not negative
--- @param item table - The menu item being processed, which may contain style information
--- @param bar table - The configuration for the progress bar, which may contain default height values
local function ResolveProgressHeights(item, bar)
	local style = (item and item.style) or {}
	local baseHeight = tonumber(style.height) or tonumber(bar.height) or 8
	local rect = bar.rectangle or {}
	local blackH = (rect.black and tonumber(rect.black.height)) or baseHeight
	-- Spec: background + fill must be the same height
	local whiteH = blackH
	if blackH < 0 then blackH = 0 end
	if whiteH < 0 then whiteH = 0 end
	return blackH, whiteH
end

-- Run each frame from Menu:Process()
--- Handles mouse input for menu navigation, specifically for progress items with clickable arrows
--- This function checks if the menu is visible and has items, then processes mouse input to allow interaction with progress bars
--- It enables the mouse cursor for the current frame, disables shooting controls to prevent interference, and checks for mouse clicks on the left and right arrows of progress items
--- If a click is detected on the arrows, it calls the appropriate Prev or Next function on the item and marks the menu as dirty to trigger a redraw
--- @param menu table - The menu object being processed, which contains information about visibility, items, current selection, and configuration for rendering
function MenuMouse.Process(menu)
	if not menu or not menu.visible then return end
	if not menu.items or #menu.items == 0 then return end

	-- make cursor usable this frame (si le serveur veut le masquer, Ã§a ne forcera pas l'affichage Ã  100%)
	if SetMouseCursorActiveThisFrame then
		SetMouseCursorActiveThisFrame()
	end

	-- prevent shooting while clicking
	if DisableControlAction then
		DisableControlAction(0, INPUT_ATTACK, true)
		DisableControlAction(0, INPUT_AIM, true)
	end

	local mx, my = GetMousePixels()
	if not mx or not my then return end

	-- Click on progress arrows (Progress uniquement)
	local clicked = IsDisabledControlJustPressed and IsDisabledControlJustPressed(0, INPUT_ATTACK)
	if not clicked then return end

	local item = menu:GetCurrentItem()
	if not item or item.type ~= "progress" then return end

	local cfg = Config.Progress or {}
	local bar = cfg.bar or {}
	local arrows = cfg.arrows or {}
	if arrows.enabled == false then return end

	local itemHeight = (Config.Layout and Config.Layout.itemHeight) or 35
	local menuWidth = Config.Header.size.width
	local yStart = menu.y + Config.Header.size.height + Config.Subtitle.size.height
	local startIndex = GetVisibleRange(menu)

	local width = tonumber(item.style and item.style.width) or bar.width or 120
	local blackH = ResolveProgressHeights(item, bar)
	local arrowSize = arrows.size or 30
	local arrowGap = arrows.gap or 4
	local offsetRightX = arrows.offsetRightX or bar.offsetRightX or 12

	local currentPos = menu._cachedPositions and menu._cachedPositions[menu.currentItem]
	local itemY = (currentPos and currentPos.y) or (yStart + (menu.currentItem - startIndex) * itemHeight)
	local offsetY = (bar.offsetY ~= nil) and bar.offsetY or ((itemHeight - blackH) * 0.5)
	local barY = itemY + offsetY

	local groupRightX = menu.x + menuWidth - offsetRightX
	local rightArrowX = groupRightX - arrowSize
	local barX = rightArrowX - arrowGap - width
	local leftArrowX = barX - arrowGap - arrowSize

	local arrowY
	if arrows.offsetY ~= nil then
		arrowY = itemY + arrows.offsetY
	else
		arrowY = barY + (blackH * 0.5) - (arrowSize * 0.5)
	end

	if PointInRect(mx, my, leftArrowX, arrowY, arrowSize, arrowSize) then
		if item.Prev then
			item:Prev()
			menu._dirty = true
		end
		return
	end

	if PointInRect(mx, my, rightArrowX, arrowY, arrowSize, arrowSize) then
		if item.Next then
			item:Next()
			menu._dirty = true
		end
		return
	end
end

