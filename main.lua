-- main.lua

-- Initialisation au démarrage
CreateThread(function()
    print("^2[Draw Menu] Initialisation...^7")
    
    -- Init cache
    Cache.Init()
    
    -- Init draw system
    Draw.Init()
    
    print("^2[Draw Menu] Prêt !^7")
end)

-- Loop principale (UN SEUL THREAD)
CreateThread(function()
    while true do
        Wait(0)
        
        -- Process tous les menus
        MenuPool.Process()
        
        -- Dessiner tous les menus visibles
        MenuPool.Draw()
    end
end)

-- Cleanup à l'arrêt
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        print("^3[Draw Menu] Arrêt et nettoyage...^7")
        MenuPool.Cleanup()
        Sprite.ReleaseAll()
        Text.ClearCache()
    end
end)

