-- renderer/sprite.lua
Sprite = {}
Draw = Draw or {}

-- Créer un sprite
---@param dict string - Le dictionnaire de textures
---@param name string - Le nom de la texture
---@param x number - La position X du sprite
---@param y number - La position Y du sprite
---@param width number - La largeur du sprite
---@param height number - La hauteur du sprite
---@param heading number - L'angle de rotation du sprite
---@param color table - La couleur du sprite (table avec r, g, b, a)
function Sprite.New(dict, name, x, y, width, height, heading, color)
    local self = {
        dict = dict or "",
        name = name or "",
        x = x or 0,
        y = y or 0,
        width = width or 100,
        height = height or 100,
        heading = heading or 0.0,
        color = color or Colors.White,
        visible = true
    }
    
    function self.Draw()
        if not self.visible then return end
        if self.dict == "" or self.name == "" then return end

        Draw.Sprite(
            self.dict,
            self.name,
            self.x,
            self.y,
            self.width,
            self.height,
            self.heading,
            self.color.r,
            self.color.g,
            self.color.b,
            self.color.a
        )
    end
    --- Setters
    --- Position, taille, couleur, angle de rotation, texture
    --- Chaque setter met à jour la propriété correspondante du sprite
    --- Exemple : SetPosition(0.5, 0.5) mettra à jour self.x et self.y
    --- @param x number - La nouvelle position X du sprite
    --- @param y number - La nouvelle position Y du sprite
    function self.SetPosition(x, y)
        self.x = x
        self.y = y
    end

    --- @param width number - La nouvelle largeur du sprite
    --- @param height number - La nouvelle hauteur du sprite
    --- SetSize(0.1, 0.1) mettra à jour self.width et self.height
    function self.SetSize(width, height)
        self.width = width
        self.height = height
    end
    
    --- @param color table - La nouvelle couleur du sprite (table avec r, g, b, a)
    --- SetColor({ r = 255, g = 255, b = 255, a = 255 }) mettra à jour self.color
    --- La couleur doit être une table contenant les valeurs r, g, b et a (alpha)
    ---- Exemple : SetColor({ r = 255, g = 0, b = 0, a = 255 }) rendra le sprite rouge
    function self.SetColor(color)
        self.color = color
    end


    --- @param heading number - Le nouvel angle de rotation du sprite
    --- SetHeading(90) mettra à jour self.heading pour faire pivoter le sprite de 90 degrés
    --- L'angle de rotation est en degrés et est appliqué dans le sens des aiguilles d'une montre
    --- Exemple : SetHeading(180) fera pivoter le sprite à l'envers
    function self.SetHeading(heading)
        self.heading = heading
    end
    
    --- @param dict string - Le nouveau dictionnaire de textures
    --- @param name string - Le nouveau nom de la texture
    --- SetTexture("commonmenu", "arrowleft") mettra à jour self.dict et self.name pour utiliser une nouvelle texture
    --- Le dictionnaire de textures doit être chargé avant d'être utilisé, sinon le sprite ne s'affichera pas
    --- Exemple : SetTexture("shopui_title_ie_modgarage", "shopui_title_ie_modgarage") utilisera la texture du menu de garage
    function self.SetTexture(dict, name)
        self.dict = dict
        self.name = name
    end
    
    function self.IsLoaded()
        return Draw.EnsureTexture(self.dict)
    end
    
    return self
end

-- Libérer une texture
---@param dict string - Le dictionnaire de textures à libérer
--- ReleaseTexture("commonmenu") libérera toutes les textures du dictionnaire "commonmenu" de la mémoire
--- Il est important de libérer les textures qui ne sont plus utilisées pour éviter les fuites de mémoire et améliorer les performances du jeu
--- Exemple : ReleaseTexture("shopui_title_ie_modgarage") libérera les textures utilisées pour le menu de garage
function Sprite.ReleaseTexture(dict)
    Draw.ReleaseTexture(dict)
end

-- Libérer toutes les textures
function Sprite.ReleaseAll()
    Draw.ReleaseAllTextures()
end

-- Sprites prédéfinis (GTA natives)
Sprite.Textures = {
    CommonMenu = "commonmenu",
    MPHud = "mphud",
    Shared = "shared",
    ShopUI = "shopui_title_ie_modgarage"
}

Sprite.Icons = {
    -- CommonMenu
    ArrowLeft = { dict = "commonmenu", name = "arrowleft" },
    ArrowRight = { dict = "commonmenu", name = "arrowright" },
    ShopBoxBlank = { dict = "commonmenu", name = "shop_box_blank" },
    ShopBoxTick = { dict = "commonmenu", name = "shop_box_tick" },
    ShopBoxCross = { dict = "commonmenu", name = "shop_box_cross" },
    GradientBgd = { dict = "commonmenu", name = "gradient_bgd" },
    InteractionBgd = { dict = "commonmenu", name = "interaction_bgd" },
    
    -- MP Hud
    MPCash = { dict = "mphud", name = "mp_cash" },
    MPRP = { dict = "mphud", name = "mp_rp" }
}