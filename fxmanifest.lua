fx_version 'cerulean'
game 'gta5'

author 'GastonApache'
description 'Draw Menu v0.1 - Optimized Menu API'
version '0.1.0'
lua54 'yes'


-- Configuration
shared_scripts {
    'shared/config.lua'
}

-- Core
client_scripts {
    -- Utils (charger en premier)
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
    
    
    
    -- Panels
    'panels/base.lua',
    'panels/color_panel.lua',
    'panels/grid_panel.lua',
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

-- Examples (optionnel)
--client_scripts {
--    'example.lua'
--}