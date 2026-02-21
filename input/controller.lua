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

-- Retourne l'id d'un control (permet override via Config.Controls)
---@param controlName string|number
function MenuController.Get(controlName)
	if type(controlName) == "number" then
		return controlName
	end

	if Config and Config.Controls and Config.Controls[controlName] ~= nil then
		return Config.Controls[controlName]
	end

	return MenuController.Controls[controlName]
end

--- Vérifie si un control a été pressé (permet override via Config.Controls et Config.Controls.UseDisabled)
----- @param controlNameOrId string|number
function MenuController.JustPressed(controlNameOrId)
	local control = MenuController.Get(controlNameOrId)
	if not control then return false end

	local group = (Config and Config.Controls and Config.Controls.Group) or MenuController.Group
	local useDisabled = (Config and Config.Controls and Config.Controls.UseDisabled) or MenuController.UseDisabled

	if useDisabled then
		return IsDisabledControlJustPressed(group, control)
	end

	return IsControlJustPressed(group, control)
end

return MenuController
