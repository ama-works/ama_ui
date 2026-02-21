
MenuNavigation = MenuNavigation or {}
MenuController = MenuController or {}

-- Localiser les natives pour réduire les lookups globales
local GetGameTimer = GetGameTimer

-- Traite la navigation d'un menu.
-- Note: dépend des champs menu._justOpened, menu._lastInputTime, menu._inputDelay
-- et des méthodes menu:GoUp/GoDown/Select/GoBack, + Prev/Next pour les lists.
---@param menu table
function MenuNavigation.Process(menu)
	if not menu or not menu.visible then return end

	-- Skip le premier frame après ouverture
	if menu._justOpened then
		menu._justOpened = false
		return
	end

	-- Throttling des inputs
	local now = GetGameTimer and GetGameTimer() or 0
	local delay = menu._inputDelay or 150
	local last = menu._lastInputTime or 0
	if now - last < delay then
		return
	end

	-- Navigation
	local controller = MenuController
	if controller ~= nil and controller.JustPressed and controller.JustPressed("Up") then
		menu:GoUp()
		menu._lastInputTime = now
		return
	end

	if controller ~= nil and controller.JustPressed and controller.JustPressed("Down") then
		menu:GoDown()
		menu._lastInputTime = now
		return
	end

	if controller ~= nil and controller.JustPressed and controller.JustPressed("Left") then
		local item = menu:GetCurrentItem()
		-- Mouse-only: progress se change via flèches souris.
		if item and item.type ~= "progress" and item.Prev then
			item:Prev()
			menu._dirty = true
		end
		menu._lastInputTime = now
		return
	end

	if controller ~= nil and controller.JustPressed and controller.JustPressed("Right") then
		local item = menu:GetCurrentItem()
		if item and item.type ~= "progress" and item.Next then
			item:Next()
			menu._dirty = true
		end
		menu._lastInputTime = now
		return
	end

	if controller ~= nil and controller.JustPressed and controller.JustPressed("Select") then
		menu:Select()
		menu._lastInputTime = now
		return
	end

	if controller ~= nil and controller.JustPressed and controller.JustPressed("Back") then
		menu:GoBack()
		menu._lastInputTime = now
		return
	end
end
