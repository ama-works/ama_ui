-- main.lua

-- Initialisation au démarrage
CreateThread(function()
    print("^2[Draw Menu] Initialisation...^7")
    print("^2[Draw Menu] Prêt !^7")
end)

-- Cleanup à l'arrêt
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        print("^3[Draw Menu] Arrêt...^7")
    end
end)

