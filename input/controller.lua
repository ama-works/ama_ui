-- input/controller.lua
-- Centralise les touches (controls) et helpers input.

MenuController = MenuController or {}

-- Groupe de controls (0 = player)
MenuController.Group = 0

-- Par défaut on utilise les contrôles "disabled" (ça marche bien quand tu disables des controls ailleurs)
MenuController.UseDisabled = true

-- Mapping GTA/FiveM (par défaut)
MenuController.Controls = {
	Up = 172,
	Down = 173,
	Left = 174,
	Right = 175,
	Select = 201,
	Back = 177
}

local IsDisabledControlJustPressed = IsDisabledControlJustPressed
local IsControlJustPressed = IsControlJustPressed

-- Cache lazy-init : résout Config.Controls une seule fois
local _ctrlResolved = false
local _ctrlMap      = {}
local _ctrlGroup, _ctrlUseDisabled

local function _resolveOnce()
	if _ctrlResolved then return end
	local cc = (Config and Config.Controls) or {}
	local mc = MenuController.Controls
	_ctrlMap.Up      = cc.Up     or mc.Up
	_ctrlMap.Down    = cc.Down   or mc.Down
	_ctrlMap.Left    = cc.Left   or mc.Left
	_ctrlMap.Right   = cc.Right  or mc.Right
	_ctrlMap.Select  = cc.Select or mc.Select
	_ctrlMap.Back    = cc.Back   or mc.Back
	_ctrlGroup       = cc.Group  or MenuController.Group
	_ctrlUseDisabled = (cc.UseDisabled ~= nil) and cc.UseDisabled or MenuController.UseDisabled
	_ctrlResolved    = true
end

-- Retourne l'id d'un control (permet override via Config.Controls)
---@param controlName string|number
function MenuController.Get(controlName)
	if type(controlName) == "number" then return controlName end
	_resolveOnce()
	return _ctrlMap[controlName]
end

--- Vérifie si un control a été pressé (permet override via Config.Controls et Config.Controls.UseDisabled)
---@param controlNameOrId string|number
function MenuController.JustPressed(controlNameOrId)
	_resolveOnce()
	local control = (type(controlNameOrId) == "number") and controlNameOrId or _ctrlMap[controlNameOrId]
	if not control then return false end
	if _ctrlUseDisabled then
		return IsDisabledControlJustPressed(_ctrlGroup, control)
	end
	return IsControlJustPressed(_ctrlGroup, control)
end

return MenuController
