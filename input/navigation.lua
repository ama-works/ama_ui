--input/navigation.lua
MenuNavigation = MenuNavigation or {}
MenuController = MenuController or {}

-- Natives localisées
local GetGameTimer                 = GetGameTimer
local IsDisabledControlJustPressed = IsDisabledControlJustPressed
local IsControlJustPressed         = IsControlJustPressed

-- Cache lazy-init : résout Config.Controls + IDs natifs une seule fois
local _navResolved = false
local _navUp, _navDown, _navLeft, _navRight, _navSelect, _navBack
local _navGroup, _navJP

local function _navResolve()
	if _navResolved then return end
	local cc = (Config and Config.Controls) or {}
	local mc = MenuController.Controls or {}
	_navUp     = cc.Up     or mc.Up     or 172
	_navDown   = cc.Down   or mc.Down   or 173
	_navLeft   = cc.Left   or mc.Left   or 174
	_navRight  = cc.Right  or mc.Right  or 175
	_navSelect = cc.Select or mc.Select or 201
	_navBack   = cc.Back   or mc.Back   or 177
	_navGroup  = cc.Group  or MenuController.Group or 0
	local useDisabled = (cc.UseDisabled ~= nil) and cc.UseDisabled or MenuController.UseDisabled
	_navJP = useDisabled and IsDisabledControlJustPressed or IsControlJustPressed
	_navResolved = true
end

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
	local now = GetGameTimer()
	if now - (menu._lastInputTime or 0) < (menu._inputDelay or 150) then
		return
	end

	-- Résolution unique des IDs
	_navResolve()
	local jp    = _navJP
	local group = _navGroup

	if jp(group, _navUp) then
		menu:GoUp()
		menu._lastInputTime = now
		return
	end

	if jp(group, _navDown) then
		menu:GoDown()
		menu._lastInputTime = now
		return
	end

	if jp(group, _navLeft) then
		local item = menu:GetCurrentItem()
		-- Mouse-only: progress se change via flèches souris.
		if item and item.type ~= "progress" and item.Prev then
			item:Prev()
			menu._dirty = true
		end
		menu._lastInputTime = now
		return
	end

	if jp(group, _navRight) then
		local item = menu:GetCurrentItem()
		if item and item.type ~= "progress" and item.Next then
			item:Next()
			menu._dirty = true
		end
		menu._lastInputTime = now
		return
	end

	if jp(group, _navSelect) then
		menu:Select()
		menu._lastInputTime = now
		return
	end

	if jp(group, _navBack) then
		menu:GoBack()
		menu._lastInputTime = now
		return
	end
end
