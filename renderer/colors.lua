-- renderer/colors.lua
Colors = {}

-- Créer une couleur
--- Si aucun paramètre n'est fourni, la couleur sera blanche (255, 255, 255, 255)
---@param r Rouge (0-255)
---@param g Vert (0-255)
---@param b Bleu (0-255)
---@param a Alpha (0-255)
function Colors.New(r, g, b, a)
    return {
        r = r or 255,
        g = g or 255,
        b = b or 255,
        a = a or 255
    }
end

-- Convertir HEX en RGB
--- Accepte les formats "#RRGGBB" ou "RRGGBB"
--- Exemple: Colors.FromHex("#FF5733") ou Colors.FromHex("FF5733")
--- Retourne une table avec les champs r, g, b, a (alpha fixé à 255)
--- Note: Les valeurs r, g, b sont converties de l'hexadécimal en décimal (0-255)
--- Exemple de retour: { r = 255, g = 87, b = 51, a = 255 }
--- Si le format est invalide, la fonction peut retourner une couleur par défaut (blanc) ou nil selon votre choix de gestion des erreurs
--- Vous pouvez ajouter une validation pour vérifier que la chaîne hexadécimale est bien formée avant de procéder à la conversion
---@param hex Chaîne hexadécimale représentant la couleur (ex: "#FF5733" ou "FF5733")
function Colors.FromHex(hex)
    hex = hex:gsub("#", "")
    return {
        r = tonumber("0x" .. hex:sub(1, 2)),
        g = tonumber("0x" .. hex:sub(3, 4)),
        b = tonumber("0x" .. hex:sub(5, 6)),
        a = 255
    }
end

-- Convertir RGBA string en table
--- Accepte les formats "rgb(r, g, b)" ou "rgba(r, g, b, a)"
--- Exemple: Colors.FromRGBA("rgba(255, 87, 51, 0.5)") ou Colors.FromRGBA("rgb(255, 87, 51)")
--- Retourne une table avec les champs r, g, b, a
--- Note: Les valeurs r, g, b sont extraites de la chaîne et converties en nombres (0-255)
--- L'alpha (a) est extrait et converti en nombre, puis multiplié par 255 pour obtenir une valeur entre 0 et 255. Si le format est "rgb", l'alpha est fixé à 255 (opaque).
--- Si le format est invalide, la fonction peut retourner une couleur par défaut (blanc) ou nil selon votre choix de gestion des erreurs
--- Vous pouvez ajouter une validation pour vérifier que la chaîne RGBA est bien formée avant de procéder à l'extraction des valeurs
---@param rgba Chaîne représentant la couleur au format "rgb(r, g, b)" ou "rgba(r, g, b, a)"
function Colors.FromRGBA(rgba)
    local r, g, b, a = rgba:match("rgba?%((%d+),%s*(%d+),%s*(%d+),?%s*([%d%.]*)")
    return {
        r = tonumber(r),
        g = tonumber(g),
        b = tonumber(b),
        a = a and math.floor(tonumber(a) * 255) or 255
    }
end


-- Interpoler entre deux couleurs
--- T doit être un nombre entre 0 et 1, où 0 retourne colorA, 1 retourne colorB, et les valeurs intermédiaires retournent une couleur interpolée entre les deux
--- Exemple: Colors.Lerp({ r = 255, g = 0, b = 0, a = 255 }, { r = 0, g = 0, b = 255, a = 255 }, 0.5) retournera une couleur intermédiaire (environ { r = 127, g = 0, b = 127, a = 255 })
--- Note: La fonction effectue une interpolation linéaire pour chaque composante de couleur (r, g, b, a) et arrondit les résultats à l'entier le plus proche pour obtenir des valeurs valides entre 0 et 255
--- Vous pouvez ajouter une validation pour vérifier que les couleurs d'entrée sont bien formées et que t est dans la plage valide avant de procéder à l'interpolation
--- @param colorA Première couleur (table avec r, g, b, a)
--- @param colorB Deuxième couleur (table avec r, g, b, a)
--- @param t Valeur d'interpolation (0-1)
--- @param out Table de sortie optionnelle (réutilisation pour éviter l'allocation)
local _lerpResult = { r = 0, g = 0, b = 0, a = 255 }

function Colors.Lerp(colorA, colorB, t, out)
    out = out or _lerpResult
    out.r = math.floor(colorA.r + (colorB.r - colorA.r) * t + 0.5)
    out.g = math.floor(colorA.g + (colorB.g - colorA.g) * t + 0.5)
    out.b = math.floor(colorA.b + (colorB.b - colorA.b) * t + 0.5)
    out.a = math.floor(colorA.a + (colorB.a - colorA.a) * t + 0.5)
    return out
end

-- Copier une couleur
--- Crée une nouvelle table de couleur avec les mêmes valeurs que la couleur d'entrée
--- Exemple: Colors.Copy({ r = 255, g = 0, b = 0, a = 255 }) retournera une nouvelle table { r = 255, g = 0, b = 0, a = 255 } qui est une copie de la couleur d'entrée
--- Note: La fonction crée une nouvelle table pour éviter les références partagées, ce qui permet de modifier la copie sans affecter la couleur d'origine
--- Vous pouvez ajouter une validation pour vérifier que la couleur d'entrée est bien formée avant de procéder à la copie
--- @param color Couleur à copier (table avec r, g, b, a)
function Colors.Copy(color)
    return {
        r = color.r,
        g = color.g,
        b = color.b,
        a = color.a
    }
end

-- Assombrir une couleur
--- Le paramètre amount doit être un nombre entre 0 et 1, où 0 ne change pas la couleur, et 1 rend la couleur complètement noire. Les valeurs intermédiaires réduisent les composantes de couleur proportionnellement pour assombrir la couleur
--- Exemple: Colors.Darken({ r = 255, g = 0, b = 0, a = 255 }, 0.5) retournera une couleur plus sombre (environ { r = 127, g = 0, b = 0, a = 255 })
--- Note: La fonction multiplie chaque composante de couleur (r, g, b) par (1 - amount) pour réduire leur intensité, tout en laissant l'alpha inchangé. Les résultats sont arrondis à l'entier le plus proche pour obtenir des valeurs valides entre 0 et 255
--- Vous pouvez ajouter une validation pour vérifier que la couleur d'entrée est bien formée et que amount est dans la plage valide avant de procéder à l'assombrissement
--- @param color Couleur à assombrir (table avec r, g, b, a)
--- @param amount Degré d'assombrissement (0-1)
function Colors.Darken(color, amount)
    amount = amount or 0.2
    return {
        r = math.floor(color.r * (1 - amount)),
        g = math.floor(color.g * (1 - amount)),
        b = math.floor(color.b * (1 - amount)),
        a = color.a
    }
end

-- Éclaircir une couleur
--- Le paramètre amount doit être un nombre entre 0 et 1, où 0 ne change pas la couleur, et 1 rend la couleur complètement blanche. Les valeurs intermédiaires augmentent les composantes de couleur proportionnellement pour éclaircir la couleur
--- Exemple: Colors.Lighten({ r = 255, g = 0, b = 0, a = 255 }, 0.5) retournera une couleur plus claire (environ { r = 255, g = 127, b = 127, a = 255 })
--- Note: La fonction ajoute à chaque composante de couleur (r, g, b) une portion de la distance entre sa valeur actuelle et 255 (blanc), proportionnelle à amount. L'alpha reste inchangé. Les résultats sont arrondis à l'entier le plus proche pour obtenir des valeurs valides entre 0 et 255
--- Vous pouvez ajouter une validation pour vérifier que la couleur d'entrée est bien formée et que amount est dans la plage valide avant de procéder à l'éclaircissement
--- @param color Couleur à éclaircir (table avec r, g, b, a)
--- @param amount Degré d'éclaircissement (0-1)
function Colors.Lighten(color, amount)
    amount = amount or 0.2
    return {
        r = math.floor(color.r + (255 - color.r) * amount),
        g = math.floor(color.g + (255 - color.g) * amount),
        b = math.floor(color.b + (255 - color.b) * amount),
        a = color.a
    }
end

-- Palette de couleurs prédéfinies
Colors.White = { r = 255, g = 255, b = 255, a = 255 }
Colors.Black = { r = 0, g = 0, b = 0, a = 255 }
Colors.Red = { r = 255, g = 0, b = 0, a = 255 }
Colors.Green = { r = 0, g = 255, b = 0, a = 255 }
Colors.Blue = { r = 0, g = 0, b = 255, a = 255 }
Colors.Yellow = { r = 255, g = 255, b = 0, a = 255 }
Colors.Orange = { r = 255, g = 165, b = 0, a = 255 }
Colors.Purple = { r = 128, g = 0, b = 128, a = 255 }
Colors.Transparent = { r = 0, g = 0, b = 0, a = 0 }

-- Couleurs du menu (depuis config)
Colors.HeaderStart = { r = 13, g = 64, b = 140, a = 255 }
Colors.HeaderEnd = { r = 46, g = 110, b = 191, a = 255 }
Colors.SubtitleBg = { r = 0, g = 0, b = 0, a = 204 }
Colors.ItemBg = { r = 0, g = 0, b = 0, a = 120 }
Colors.ItemSelected = { r = 255, g = 255, b = 255, a = 255 }
Colors.TextDefault = { r = 245, g = 242, b = 242, a = 255 }
Colors.TextSelected = { r = 0, g = 0, b = 0, a = 255 }