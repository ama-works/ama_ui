-- renderer/box.lua
-- UIaMa.DrawBox / UIaMa.DrawDebugBox — wrappers des natives 3D world-space.
-- USAGE : debug de zones, hitboxes, triggers — PAS pour l'interface 2D.
-- Paramètres : x1,y1,z1 (coin 1) → x2,y2,z2 (coin opposé) en coordonnées monde.

UIaMa = UIaMa or {}

--- Dessine une boîte filaire dans l'espace monde GTA V.
---@param x1 number  Coordonnée X du premier coin
---@param y1 number  Coordonnée Y du premier coin
---@param z1 number  Coordonnée Z du premier coin
---@param x2 number  Coordonnée X du coin opposé
---@param y2 number  Coordonnée Y du coin opposé
---@param z2 number  Coordonnée Z du coin opposé
---@param r  number  Canal rouge   (0–255)
---@param g  number  Canal vert    (0–255)
---@param b  number  Canal bleu    (0–255)
---@param a  number  Canal alpha   (0–255)
function UIaMa.DrawBox(x1, y1, z1, x2, y2, z2, r, g, b, a)
    DrawBox(x1, y1, z1, x2, y2, z2, r, g, b, a)
end

--- Dessine une boîte de débogage dans l'espace monde GTA V.
--- Note : cette native peut être absente dans la version retail du jeu.
---@param x1 number  Coordonnée X du premier coin
---@param y1 number  Coordonnée Y du premier coin
---@param z1 number  Coordonnée Z du premier coin
---@param x2 number  Coordonnée X du coin opposé
---@param y2 number  Coordonnée Y du coin opposé
---@param z2 number  Coordonnée Z du coin opposé
---@param r  number  Canal rouge   (0–255)
---@param g  number  Canal vert    (0–255)
---@param b  number  Canal bleu    (0–255)
---@param a  number  Canal alpha   (0–255)
function UIaMa.DrawDebugBox(x1, y1, z1, x2, y2, z2, r, g, b, a)
    DrawDebugBox(x1, y1, z1, x2, y2, z2, r, g, b, a)
end
