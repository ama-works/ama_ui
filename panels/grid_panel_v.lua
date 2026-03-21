-- panels/grid_panel_v.lua
-- GridPanelV conforme à RageUI.GridPanelVertical (UIGridPanelVertical.lua)
--
-- Signature : GridPanelV(y, topText, bottomText, callback, index)
-- callback(hovered, active, y)  — y dans [0.0, 1.0], X fixé à 0.5
--
-- Sprite grille : RageUI/vertical_grid (axe Y uniquement)
-- Sprite cercle : mpinventory/in_world_circle
-- Labels : Top(215.5, 15)  Bottom(215.5, 250)  — PAS de Left/Right
--
-- Utilisation typique (dans menu:SetPanels) :
--   local gy = 0.5
--   menu:SetPanels(function()
--       GridPanelV(gy, "Haut", "Bas", function(h, a, ny)
--           gy = ny
--       end, 4)
--   end)

-- ─── Config (Config.GridPanelV) ───────────────────────────────────────────────
local _cfgGPV   = Config.GridPanelV
local _cfgGPVBG = _cfgGPV.background
local _cfgGPVGd = _cfgGPV.grid
local _cfgGPVCr = _cfgGPV.circle
local _cfgGPVTx = _cfgGPV.text

local _GPV_BG  = { Dict = _cfgGPV.sprite.dict,   Tex = _cfgGPV.sprite.name,
                   Y    = _cfgGPVBG.offsetY,      H   = _cfgGPVBG.height }
local _GPV_GRD = { Dict = _cfgGPVGd.sprite.dict,  Tex = _cfgGPVGd.sprite.name,
                   Y    = _cfgGPVGd.offsetY,       W   = _cfgGPVGd.width,  H = _cfgGPVGd.height }
local _GPV_CIR = { Dict = _cfgGPVCr.sprite.dict,  Tex = _cfgGPVCr.sprite.name,
                   W    = _cfgGPVCr.width,         H   = _cfgGPVCr.height }
local _GPV_TXT = {
    Top    = { Y = _cfgGPVTx.top.offsetY,    Scale = _cfgGPVTx.top.size    },
    Bottom = { Y = _cfgGPVTx.bottom.offsetY, Scale = _cfgGPVTx.bottom.size },
}
local _GPV_AREA_PAD = _cfgGPV.areaPadding

local _GPV_WHITE = _cfgGPV.color.text
local _GPV_TOTAL = _GPV_BG.H + _GPV_BG.Y

---GridPanelV conforme RageUI.GridPanelVertical
---@param Y          number     valeur Y [0.0, 1.0]
---@param TopText    string|nil label haut
---@param BottomText string|nil label bas
---@param Callback   function   callback(hovered, active, y)
---@param Index      number|nil
function GridPanelV(Y, TopText, BottomText, Callback, Index)
    if not _AmaUIPanelMenu then return end
    if Index ~= nil and _AmaUIPanelMenu.currentItem ~= Index then return end

    local mx    = _AmaUIPanelX
    local my    = _AmaUIPanelY
    local menuW = _AmaUIPanelMenu._menuWidth

    -- Positions dynamiques
    local grdX       = (menuW - _GPV_GRD.W) * 0.5   -- grille centrée
    local txtCenterX = menuW * 0.5                    -- labels Haut/Bas centrés

    if Y < 0.0 or Y > 1.0 then Y = 0.0 end
    local X = 0.5  -- axe X fixe au centre

    local _pad  = _GPV_AREA_PAD
    local _pad2 = _pad * 2

    -- Position du cercle
    local CircleX = mx + grdX + _pad + ((_GPV_GRD.W - _pad2) * X) - (_GPV_CIR.W / 2)
    local CircleY = my + _GPV_GRD.Y + _pad + ((_GPV_GRD.H - _pad2) * Y) - (_GPV_CIR.H / 2)

    -- ─── Background sprite ────────────────────────────────────────────────────
    Draw.Sprite(_GPV_BG.Dict,  _GPV_BG.Tex,
        mx, my + _GPV_BG.Y, menuW, _GPV_BG.H, 0, 255, 255, 255, 255)

    -- ─── Sprite grille verticale ──────────────────────────────────────────────
    Draw.Sprite(_GPV_GRD.Dict, _GPV_GRD.Tex,
        mx + grdX, my + _GPV_GRD.Y, _GPV_GRD.W, _GPV_GRD.H, 0, 255, 255, 255, 255)

    -- ─── Interaction souris (axe Y uniquement) ────────────────────────────────
    local areaLeft = mx + grdX + _pad
    local areaTop  = my + _GPV_GRD.Y + _pad
    local areaW    = _GPV_GRD.W - _pad2
    local areaH    = _GPV_GRD.H - _pad2

    local mouseX = GetDisabledControlNormal(0, 239) * 1920
    local mouseY = GetDisabledControlNormal(0, 240) * 1080

    local Hovered = mouseX >= areaLeft and mouseX <= (areaLeft + areaW) and
                    mouseY >= areaTop  and mouseY <= (areaTop  + areaH)
    local Selected = false

    if Hovered then
        SetMouseCursorActiveThisFrame()
        if IsDisabledControlPressed(0, 24) then
            Selected = true
            Y = math.max(0.0, math.min(1.0, (mouseY - areaTop) / areaH))
            CircleY = areaTop + (areaH * Y) - (_GPV_CIR.H / 2)
            -- CircleX inchangé (X fixe à 0.5)
        end
    end

    -- ─── Cercle curseur (position mise à jour si drag) ────────────────────────
    Draw.Sprite(_GPV_CIR.Dict, _GPV_CIR.Tex,
        CircleX, CircleY, _GPV_CIR.W, _GPV_CIR.H, 0, 255, 255, 255, 255)

    -- ─── Labels haut / bas (PAS de Left/Right) ────────────────────────────────
    Text.Draw(TopText    or "", mx + txtCenterX, my + _GPV_TXT.Top.Y,    0, _GPV_TXT.Top.Scale,    _GPV_WHITE, 1)
    Text.Draw(BottomText or "", mx + txtCenterX, my + _GPV_TXT.Bottom.Y, 0, _GPV_TXT.Bottom.Scale, _GPV_WHITE, 1)

    -- Avance le curseur Y pour le prochain panel
    _AmaUIPanelY = _AmaUIPanelY + _GPV_TOTAL

    if Callback then
        Callback(Hovered, Selected, Y)
    end
end
