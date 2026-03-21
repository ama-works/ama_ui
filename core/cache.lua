

-- core/cache.lua
Cache = {
    resolution = nil,
    aspectRatio = nil,
    safeZone = nil,
    texts = {},
    sprites = {},
    calculations = {}
}

function Cache.Init()
    Cache.aspectRatio = GetAspectRatio(false)
    Cache.safeZone = GetSafeZoneSize()
    Cache.resolution = {
        width = Config.BaseResolution.height * Cache.aspectRatio,
        height = Config.BaseResolution.height
    }
    if Text and Text.SetResolution then
        Text.SetResolution(Cache.resolution.width, Cache.resolution.height)
    end
end

function Cache.Update()
    -- ⚡ FIX : Vérifier si le cache est initialisé
    if not Cache.resolution then
        Cache.Init()
        return
    end
    
    local newAspectRatio = GetAspectRatio(false)
    if newAspectRatio ~= Cache.aspectRatio then
        Cache.aspectRatio = newAspectRatio
        Cache.resolution.width = Config.BaseResolution.height * Cache.aspectRatio
        if Text and Text.SetResolution then
            Text.SetResolution(Cache.resolution.width, Cache.resolution.height)
        end
        Cache.InvalidateAll()
    end
end

function Cache.InvalidateAll()
    Cache.texts = {}
    Cache.calculations = {}
end

function Cache.GetResolution()
    -- ⚡ FIX : Auto-init si pas encore fait
    if not Cache.resolution then
        Cache.Init()
    end
    return Cache.resolution
end