-- renderer/rectangle.lua
Rectangle = {}

---@param x number
---@param y number
---@param width number
---@param height number
---@param color number
-- Créer un rectangle
function Rectangle.New(x, y, width, height, color)
    local self = {
        x = x or 0,
        y = y or 0,
        width = width or 100,
        height = height or 100,
        color = color or Colors.White,
        visible = true,
        border = nil  -- { width = 2, color = Colors.Black }
    }
    
    function self.Draw()
        if not self.visible then return end
        
        if self.border then
            Draw.RectBorder(
                self.x,
                self.y,
                self.width,
                self.height,
                self.color,
                self.border.width,
                self.border.color
            )
        else
            Draw.Rect(self.x, self.y, self.width, self.height, self.color)
        end
    end
    ---- Setters
    ---- Permet de changer la position du rectangle
 ---@param x number
 ---@param y number
    function self.SetPosition(x, y)
        self.x = x
        self.y = y
    end
    --- Permet de changer la taille du rectangle
    ---@param width number
    ---@param height number
    function self.SetSize(width, height)
        self.width = width
        self.height = height
    end
    
    --- Permet de changer la couleur du rectangle
    ---@param color number
    function self.SetColor(color)
        self.color = color
    end
    
    --- Permet d'ajouter une bordure au rectangle
    ---@param width number
    ---@param color number
    function self.SetBorder(width, color)
        self.border = {
            width = width,
            color = color
        }
    end
    
    function self.RemoveBorder()
        self.border = nil
    end
    --- Permet de vérifier si un point est à l'intérieur du rectangle
    ---@param pointX number
    ---@param pointY number
    function self.Contains(pointX, pointY)
        return pointX >= self.x and pointX <= self.x + self.width and
               pointY >= self.y and pointY <= self.y + self.height
    end
    
    return self
end


-- Rectangle avec gradient
---@param x number
---@param y number
---@param width number
---@param height number
---@param colorStart number
---@param colorEnd number
---@param horizontal boolean
--- Créer un rectangle avec un gradient
function Rectangle.NewGradient(x, y, width, height, colorStart, colorEnd, horizontal)
    local self = {
        x = x or 0,
        y = y or 0,
        width = width or 100,
        height = height or 100,
        colorStart = colorStart or Colors.White,
        colorEnd = colorEnd or Colors.Black,
        horizontal = horizontal == nil and true or horizontal,
        visible = true,
        steps = Config.Performance.gradientSteps or 20
    }
    
    function self.Draw()
        if not self.visible then return end
        
        if self.horizontal then
            Draw.GradientH(
                self.x,
                self.y,
                self.width,
                self.height,
                self.colorStart,
                self.colorEnd,
                self.steps
            )
        else
            Draw.GradientV(
                self.x,
                self.y,
                self.width,
                self.height,
                self.colorStart,
                self.colorEnd,
                self.steps
            )
        end
    end
    --- Setters
    --- Permet de changer la position du rectangle
    ---@param x number
    ---@param y number
    function self.SetPosition(x, y)
        self.x = x
        self.y = y
    end
    --- Permet de changer la taille du rectangle
    ---@param width number
    ---@param height number
    function self.SetSize(width, height)
        self.width = width
        self.height = height
    end

    --- Permet de changer les couleurs du gradient
    ---@param colorStart number
    ---@param colorEnd number   
    function self.SetColors(colorStart, colorEnd)
        self.colorStart = colorStart
        self.colorEnd = colorEnd
    end
    
    return self
end