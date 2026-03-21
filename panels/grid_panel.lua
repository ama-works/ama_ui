-- panels/grid_panel.lua
-- GridPanel conforme à RageUI.GridPanel (UIGridPanel.lua)
--
-- Signature : GridPanel(x, y, topText, bottomText, leftText, rightText, callback, index)
-- callback(hovered, active, x, y)  — x, y dans [0.0, 1.0]
--
-- Sprite grille : pause_menu_pages_char_mom_dad/nose_grid
-- Sprite cercle : mpinventory/in_world_circle
--
-- Utilisation typique (dans menu:SetPanels) :
--   local gx, gy = 0.5, 0.5
--   menu:SetPanels(function()
--       GridPanel(gx, gy, "Haut", "Bas", "Int", "Ext", function(h, a, nx, ny)
--           gx, gy = nx, ny
--       end, 2)
--   end)

-- ─── Config (Config.GridPanel) ────────────────────────────────────────────────
local _cfgGP   = Config.GridPanel
local _cfgGPBG = _cfgGP.background
local _cfgGPGd = _cfgGP.grid
local _cfgGPCr = _cfgGP.circle
local _cfgGPTx = _cfgGP.text

local _GP_BG  = { Dict = _cfgGP.sprite.dict,   Tex = _cfgGP.sprite.name,
                  Y    = _cfgGPBG.offsetY,      H   = _cfgGPBG.height }
local _GP_GRD = { Dict = _cfgGPGd.sprite.dict,  Tex = _cfgGPGd.sprite.name,
                  Y    = _cfgGPGd.offsetY,       W   = _cfgGPGd.width,  H = _cfgGPGd.height }
local _GP_CIR = { Dict = _cfgGPCr.sprite.dict,  Tex = _cfgGPCr.sprite.name,
                  W    = _cfgGPCr.width,         H   = _cfgGPCr.height }
local _GP_TXT = {
    Top    = { Y = _cfgGPTx.top.offsetY,     Scale = _cfgGPTx.top.size    },
    Bottom = { Y = _cfgGPTx.bottom.offsetY,  Scale = _cfgGPTx.bottom.size },
    Left   = { X = _cfgGPTx.left.offsetX,   Y = _cfgGPTx.left.offsetY,   Scale = _cfgGPTx.left.size  },
    Right  = { Y = _cfgGPTx.right.offsetY,  Scale = _cfgGPTx.right.size,  _padRight = _cfgGPTx.right.padRight },
}
local _GP_AREA_PAD = _cfgGP.areaPadding

local _GP_WHITE = _cfgGP.color.text
local _GP_TOTAL = _GP_BG.H + _GP_BG.Y

---GridPanel conforme RageUI.GridPanel
---@param X          number     valeur X [0.0, 1.0]
---@param Y          number     valeur Y [0.0, 1.0]
---@param TopText    string|nil
---@param BottomText string|nil
---@param LeftText   string|nil
---@param RightText  string|nil
---@param Callback   function   callback(hovered, active, x, y)
---@param Index      number|nil
function GridPanel(X, Y, TopText, BottomText, LeftText, RightText, Callback, Index)
    if not _AmaUIPanelMenu then return end
    if Index ~= nil and _AmaUIPanelMenu.currentItem ~= Index then return end

    local mx    = _AmaUIPanelX
    local my    = _AmaUIPanelY
    local menuW = _AmaUIPanelMenu._menuWidth

    -- Positions dynamiques (dépendent de la largeur du menu)
    local grdX       = (menuW - _GP_GRD.W) * 0.5   -- grille centrée
    local txtCenterX = menuW * 0.5                   -- labels Haut/Bas centrés
    local txtRightX  = menuW - _GP_TXT.Right._padRight

    -- Clamp X, Y dans [0.0, 1.0]
    if X < 0.0 or X > 1.0 then X = 0.0 end
    if Y < 0.0 or Y > 1.0 then Y = 0.0 end

    local _pad  = _GP_AREA_PAD
    local _pad2 = _pad * 2

    -- Position du cercle
    local CircleX = mx + grdX + _pad + ((_GP_GRD.W - _pad2) * X) - (_GP_CIR.W / 2)
    local CircleY = my + _GP_GRD.Y + _pad + ((_GP_GRD.H - _pad2) * Y) - (_GP_CIR.H / 2)

    -- ─── Background + grille ─────────────────────────────────────────────────
    Draw.Sprite(_GP_BG.Dict,  _GP_BG.Tex,
        mx, my + _GP_BG.Y, menuW, _GP_BG.H, 0, 255, 255, 255, 255)
    Draw.Sprite(_GP_GRD.Dict, _GP_GRD.Tex,
        mx + grdX, my + _GP_GRD.Y, _GP_GRD.W, _GP_GRD.H, 0, 255, 255, 255, 255)

    -- ─── Interaction souris (style RageUI) ────────────────────────────────────
    local areaLeft = mx + grdX + _pad
    local areaTop  = my + _GP_GRD.Y + _pad
    local areaW    = _GP_GRD.W - _pad2
    local areaH    = _GP_GRD.H - _pad2

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
            Y = math.max(0.0, math.min(1.0, (mouseY - areaTop)  / areaH))
            CircleX = areaLeft + (areaW * X) - (_GP_CIR.W / 2)
            CircleY = areaTop  + (areaH * Y) - (_GP_CIR.H / 2)
        end
    end

    -- ─── Cercle curseur (position initiale ou mise à jour par la souris) ──────
    Draw.Sprite(_GP_CIR.Dict, _GP_CIR.Tex,
        CircleX, CircleY, _GP_CIR.W, _GP_CIR.H, 0, 255, 255, 255, 255)

    -- ─── Labels directionnels ─────────────────────────────────────────────────
    Text.Draw(TopText    or "", mx + txtCenterX,        my + _GP_TXT.Top.Y,    0, _GP_TXT.Top.Scale,    _GP_WHITE, 1)
    Text.Draw(BottomText or "", mx + txtCenterX,        my + _GP_TXT.Bottom.Y, 0, _GP_TXT.Bottom.Scale, _GP_WHITE, 1)
    Text.Draw(LeftText   or "", mx + _GP_TXT.Left.X,   my + _GP_TXT.Left.Y,   0, _GP_TXT.Left.Scale,   _GP_WHITE, 1)
    Text.Draw(RightText  or "", mx + txtRightX,         my + _GP_TXT.Right.Y,  0, _GP_TXT.Right.Scale,  _GP_WHITE, 1)

    -- Avance le curseur Y pour le prochain panel
    _AmaUIPanelY = _AmaUIPanelY + _GP_TOTAL

    if Callback then
        Callback(Hovered, Selected, X, Y)
    end
end
