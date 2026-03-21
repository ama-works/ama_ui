fx_version 'cerulean'
game 'gta5'

author 'GastonApache'
description 'Draw Menu v0.1 - Optimized Menu API'
version '0.1.0'
lua54 'yes'

client_exports { 'getSharedObject' }

-- Fichiers accessibles cross-resource (LoadResourceFile depuis d'autres resources)
files {
    'imports.lua',
    'load.lua',
    'shared/*.lua',
    'color/*.lua',
    'utils/*.lua',
    'core/*.lua',
    'renderer/*.lua',
    'items/*.lua',
    'panels/*.lua',
    'input/*.lua',
    'ui/*.lua',
}

-- Configuration
shared_scripts {
    'shared/config.lua'
}

-- Core
client_scripts {
    -- Couleurs (tables de données pures — charger en tout premier)
    'color/items_colour.lua',
    'color/panel_colour.lua',
    'color/badge_style.lua',    -- BadgeStyle (closures sprites pour UIMenuButton)

    -- Utils
    'utils/uuid.lua',
    'utils/math.lua',
    'utils/string.lua',
    'utils/table.lua',

    -- Core
    'core/cache.lua',
    'core/events.lua',
    'core/pool.lua',

    -- Renderer (base minimale)
    'renderer/draw.lua',
    'renderer/text.lua',
    'renderer/rectangle.lua',
    'renderer/sprite.lua',
    'renderer/scaleform.lua',
    'renderer/glare.lua',
    'renderer/box.lua',

    -- Items
    'items/base.lua',
    'items/button.lua',
    'items/checkbox.lua',
    'items/list.lua',
    'items/slider.lua',
    'items/heritage.lua',
    'items/progress.lua',
    'items/separator.lua',
    'items/separator_jump.lua',
    'items/dynamic_list.lua',
    'items/windows.lua',

    -- Panels (fonctions globales style RageUI — appelées via menu:SetPanels(fn))
    'panels/base.lua',
    'panels/color_panel.lua',
    'panels/grid_panel.lua',
    'panels/grid_panel_h.lua',
    'panels/grid_panel_v.lua',
    'panels/percentage_panel.lua',
    'panels/statistics_panel.lua',

    -- Input
    'input/controller.lua',
    'input/navigation.lua',
    'input/mouse.lua',

    -- Menu principal
    'core/menu.lua',

    -- Façade ama_ui (doit être après menu.lua et tous les items)
    'ui/ui.lua',

    -- Point d'entrée
    --'main.lua'
}


