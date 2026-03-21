-- =============================================================================
-- ama_ui/load.lua
-- Charge tous les fichiers ama_ui dans le contexte Lua du consommateur.
-- Utiliser dans fxmanifest.lua : client_scripts { '@ama_ui/load.lua', ... }
--
-- Avantage : zéro sérialisation MsgPack — alternatives à getSharedObject().
-- Inspiré de ox_lib / sublime_nativeui init.lua.
-- =============================================================================

local _res = 'ama_ui'

local function _load(path)
    local src = LoadResourceFile(_res, path)
    assert(src,       ('[ama_ui/load] Fichier introuvable : %s'):format(path))
    local fn, err = load(src, ('@ama_ui/%s'):format(path), 't', _ENV)
    assert(fn,        ('[ama_ui/load] Erreur parse %s : %s'):format(path, tostring(err)))
    fn()
end

-- Ordre exact de chargement (même ordre que fxmanifest.lua)

-- Config partagée
_load('shared/config.lua')

-- Couleurs
_load('color/items_colour.lua')
_load('color/panel_colour.lua')
_load('color/badge_style.lua')

-- Utils
_load('utils/uuid.lua')
_load('utils/math.lua')
_load('utils/string.lua')
_load('utils/table.lua')

-- Core
_load('core/cache.lua')
_load('core/events.lua')
_load('core/pool.lua')

-- Renderer
_load('renderer/draw.lua')
_load('renderer/text.lua')
_load('renderer/rectangle.lua')
_load('renderer/sprite.lua')
_load('renderer/scaleform.lua')
_load('renderer/glare.lua')
_load('renderer/box.lua')

-- Items
_load('items/base.lua')
_load('items/button.lua')
_load('items/checkbox.lua')
_load('items/list.lua')
_load('items/slider.lua')
_load('items/heritage.lua')
_load('items/progress.lua')
_load('items/separator.lua')
_load('items/separator_jump.lua')
_load('items/dynamic_list.lua')
_load('items/windows.lua')

-- Panels
_load('panels/base.lua')
_load('panels/color_panel.lua')
_load('panels/grid_panel.lua')
_load('panels/grid_panel_h.lua')
_load('panels/grid_panel_v.lua')
_load('panels/percentage_panel.lua')
_load('panels/statistics_panel.lua')

-- Input
_load('input/controller.lua')
_load('input/navigation.lua')
_load('input/mouse.lua')

-- Menu principal + façade
_load('core/menu.lua')
_load('ui/ui.lua')
