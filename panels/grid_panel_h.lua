-- panels/grid_panel_h.lua
-- GridPanelH conforme à RageUI.GridPanelHorizontal (UIGridPanelHorizontal.lua)
--
-- Signature : GridPanelH(x, leftText, rightText, callback, index)
-- callback(hovered, active, x)  — x dans [0.0, 1.0], Y fixé à 0.5
--
-- Sprite grille : RageUI/horizontal_grid (axe X uniquement)
-- Sprite cercle : mpinventory/in_world_circle
-- Labels : Left(57.75, 130)  Right(373.25, 130)  — PAS de Top/Bottom
--
-- Utilisation typique (dans menu:SetPanels) :
--   local gx = 0.5
--   menu:SetPanels(function()
--       GridPanelH(gx, "Ouverts", "Plissés", function(h, a, nx)
--           gx = nx
--       end, 1)
--   end)

-- ─── Config (Config.GridPanelH) ───────────────────────────────────────────────
local _cfgGPH   = Config.GridPanelH
local _cfgGPHBG = _cfgGPH.background
local _cfgGPHGd = _cfgGPH.grid
local _cfgGPHCr = _cfgGPH.circle
local _cfgGPHTx = _cfgGPH.text

local _GPH_BG  = { Dict = _cfgGPH.sprite.dict,   Tex = _cfgGPH.sprite.name,
                   Y    = _cfgGPHBG.offsetY,      H   = _cfgGPHBG.height }
local _GPH_GRD = { Dict = _cfgGPHGd.sprite.dict,  Tex = _cfgGPHGd.sprite.name,
                   Y    = _cfgGPHGd.offsetY,       W   = _cfgGPHGd.width,  H = _cfgGPHGd.height }
local _GPH_CIR = { Dict = _cfgGPHCr.sprite.dict,  Tex = _cfgGPHCr.sprite.name,
                   W    = _cfgGPHCr.width,         H   = _cfgGPHCr.height }
local _GPH_TXT = {
    Left  = { X = _cfgGPHTx.left.offsetX,  Y = _cfgGPHTx.left.offsetY,  Scale = _cfgGPHTx.left.size  },
    Right = { Y = _cfgGPHTx.right.offsetY, Scale = _cfgGPHTx.right.size, _padRight = _cfgGPHTx.right.padRight },
}
local _GPH_AREA_PAD = _cfgGPH.areaPadding

local _GPH_WHITE = _cfgGPH.color.text
local _GPH_TOTAL = _GPH_BG.H + _GPH_BG.Y

---GridPanelH conforme RageUI.GridPanelHorizontal
---@param X         number     valeur X [0.0, 1.0]
---@param LeftText  string|nil label gauche
---@param RightText string|nil label droite
---@param Callback  function   callback(hovered, active, x)
---@param Index     number|nil
function GridPanelH(X, LeftText, RightText, Callback, Index)
    if not _AmaUIPanelMenu then return end
    if Index ~= nil and _AmaUIPanelMenu.currentItem ~= Index then return end

    local mx    = _AmaUIPanelX
    local my    = _AmaUIPanelY
    local menuW = _AmaUIPanelMenu._menuWidth

    -- Positions dynamiques
    local grdX      = (menuW - _GPH_GRD.W) * 0.5   -- grille centrée
    local txtRightX = menuW - _GPH_TXT.Right._padRight

    if X < 0.0 or X > 1.0 then X = 0.0 end
    local Y = 0.5  -- axe Y fixe au centre

    local _pad  = _GPH_AREA_PAD
    local _pad2 = _pad * 2

    -- Position du cercle
    local CircleX = mx + grdX + _pad + ((_GPH_GRD.W - _pad2) * X) - (_GPH_CIR.W / 2)
    local CircleY = my + _GPH_GRD.Y + _pad + ((_GPH_GRD.H - _pad2) * Y) - (_GPH_CIR.H / 2)

    -- ─── Background sprite ────────────────────────────────────────────────────
    Draw.Sprite(_GPH_BG.Dict,  _GPH_BG.Tex,
        mx, my + _GPH_BG.Y, menuW, _GPH_BG.H, 0, 255, 255, 255, 255)

    -- ─── Sprite grille horizontale ────────────────────────────────────────────
    Draw.Sprite(_GPH_GRD.Dict, _GPH_GRD.Tex,
        mx + grdX, my + _GPH_GRD.Y, _GPH_GRD.W, _GPH_GRD.H, 0, 255, 255, 255, 255)

    -- ─── Interaction souris (axe X uniquement) ────────────────────────────────
    local areaLeft = mx + grdX + _pad
    local areaTop  = my + _GPH_GRD.Y + _pad
    local areaW    = _GPH_GRD.W - _pad2
    local areaH    = _GPH_GRD.H - _pad2

    local mouseX = GetDisabledControlNormal(0, 239) * 1920
    local mouseY = GetDisabledControlNormal(0, 240) * 1080

    local Hovered = mouseX >= areaLeft and mouseX <= (areaLeft + areaW) and
                    mouseY >= areaTop  and mouseY <= (areaTop  + areaH)
    local Selected = false

    if Hovered then
        SetMouseCursorActiveThisFrame()
        if IsDisabledControlPressed(0, 24) then
            Selected = true
            X = math.max(0.0, math.min(1.0, (mouseX - areaLeft) / areaW))
            CircleX = areaLeft + (areaW * X) - (_GPH_CIR.W / 2)
            -- CircleY inchangé (Y fixe à 0.5)
        end
    end

    -- ─── Cercle curseur (position mise à jour si drag) ────────────────────────
    Draw.Sprite(_GPH_CIR.Dict, _GPH_CIR.Tex,
        CircleX, CircleY, _GPH_CIR.W, _GPH_CIR.H, 0, 255, 255, 255, 255)

    -- ─── Labels gauche / droite (PAS de Top/Bottom) ───────────────────────────
    Text.Draw(LeftText  or "", mx + _GPH_TXT.Left.X, my + _GPH_TXT.Left.Y,  0, _GPH_TXT.Left.Scale,  _GPH_WHITE, 1)
    Text.Draw(RightText or "", mx + txtRightX,        my + _GPH_TXT.Right.Y, 0, _GPH_TXT.Right.Scale, _GPH_WHITE, 1)

    -- Avance le curseur Y pour le prochain panel
    _AmaUIPanelY = _AmaUIPanelY + _GPH_TOTAL

    if Callback then
        Callback(Hovered, Selected, X)
    end
end
