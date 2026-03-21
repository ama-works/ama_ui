-- panels/percentage_panel.lua
-- PercentagePanel conforme à RageUI.PercentagePanel (UIPercentagePanel.lua)
--
-- Signature : PercentagePanel(percent, headerText, minText, maxText, callback, index)
-- callback(hovered, active, percent)
--
-- percent  : [0.0, 1.0]
-- Barre fond : DrawRect RGB(87,87,87), W=413px
-- Barre fill : DrawRect RGB(245,245,245), W=percent*413
--
-- Utilisation typique (dans menu:SetPanels) :
--   local pct = 0.5
--   menu:SetPanels(function()
--       PercentagePanel(pct, "Opacity", "0%", "100%", function(h, a, newPct)
--           pct = newPct
--       end, 7)
--   end)

-- ─── Config (Config.PercentagePanel) ──────────────────────────────────────────
local _cfgPP = Config.PercentagePanel

local _PP_BG  = { Dict = _cfgPP.sprite.dict, Tex = _cfgPP.sprite.name,
                  Y    = _cfgPP.background.offsetY, H = _cfgPP.background.height }
local _PP_BAR = { X = _cfgPP.bar.offsetX, Y = _cfgPP.bar.offsetY,
                  H = _cfgPP.bar.height,  _padRight = _cfgPP.bar.padRight }
local _PP_TXT = {
    Left   = { X = _cfgPP.text.left.offsetX, Y = _cfgPP.text.left.offsetY,   Scale = _cfgPP.text.left.size   },
    Middle = {                                Y = _cfgPP.text.middle.offsetY,  Scale = _cfgPP.text.middle.size },
    Right  = {                                Y = _cfgPP.text.right.offsetY,   Scale = _cfgPP.text.right.size,
               _padRight = _cfgPP.text.right.padRight },
}

local _PP_WHITE  = _cfgPP.color.text
local _PP_BAR_BG = _cfgPP.color.barBg
local _PP_BAR_FG = _cfgPP.color.barFill
local _PP_TOTAL  = _PP_BG.H + _PP_BG.Y

---PercentagePanel conforme RageUI.PercentagePanel
---@param Percent    number     [0.0, 1.0]
---@param HeaderText string|nil label centré (ex: "Opacity")
---@param MinText    string|nil label gauche (ex: "0%", nil → "0%")
---@param MaxText    string|nil label droite (ex: "100%", nil → "100%")
---@param Callback   function   callback(hovered, active, percent)
---@param Index      number|nil
---@param MouseOnly  boolean|nil  true = navigation souris uniquement (désactive clavier ←→)
function PercentagePanel(Percent, HeaderText, MinText, MaxText, Callback, Index, MouseOnly)
    if not _AmaUIPanelMenu then return end
    if Index ~= nil and _AmaUIPanelMenu.currentItem ~= Index then return end

    local x     = _AmaUIPanelX
    local y     = _AmaUIPanelY
    local menuW = _AmaUIPanelMenu._menuWidth

    -- Positions dynamiques (dépendent de la largeur du menu)
    local barW     = menuW - _PP_BAR.X - _PP_BAR._padRight
    local txtMidX  = menuW * 0.5
    local txtRightX = menuW - _PP_TXT.Right._padRight

    -- Clamp dans [0.0, 1.0]
    if Percent < 0.0 then Percent = 0.0 elseif Percent > 1.0 then Percent = 1.0 end

    -- ─── Background sprite ────────────────────────────────────────────────────
    Draw.Sprite(_PP_BG.Dict, _PP_BG.Tex,
        x, y + _PP_BG.Y, menuW, _PP_BG.H, 0, 255, 255, 255, 255)

    -- ─── Barre fond (gris) ────────────────────────────────────────────────────
    Draw.Rect(x + _PP_BAR.X, y + _PP_BAR.Y, barW, _PP_BAR.H, _PP_BAR_BG)

    -- ─── Barre fill (blanc, proportionnelle) ──────────────────────────────────
    local fillW = Percent * barW
    if fillW > 0 then
        Draw.Rect(x + _PP_BAR.X, y + _PP_BAR.Y, fillW, _PP_BAR.H, _PP_BAR_FG)
    end

    -- ─── Labels ───────────────────────────────────────────────────────────────
    Text.Draw(HeaderText or "Opacity", x + txtMidX,           y + _PP_TXT.Middle.Y, 0, _PP_TXT.Middle.Scale, _PP_WHITE, 1)
    Text.Draw(MinText    or "0%",      x + _PP_TXT.Left.X,    y + _PP_TXT.Left.Y,   0, _PP_TXT.Left.Scale,   _PP_WHITE, 1)
    Text.Draw(MaxText    or "100%",    x + txtRightX,          y + _PP_TXT.Right.Y,  0, _PP_TXT.Right.Scale,  _PP_WHITE, 1)

    -- ─── Navigation clavier ← → (style ColorPanel : IsControlJustPressed) ──────
    -- IsControlJustPressed (non-disabled) évite le conflit avec navigation.lua
    -- qui utilise IsDisabledControlJustPressed sur les mêmes controls 174/175.
    local Hovered = false
    local Active  = false

    if not MouseOnly then
        if IsControlJustPressed(0, 174) then       -- LEFT
            Percent = math.max(0.0, Percent - 0.05)
            Active  = true
        elseif IsControlJustPressed(0, 175) then   -- RIGHT
            Percent = math.min(1.0, Percent + 0.05)
            Active  = true
        end
    end

    -- ─── Interaction souris sur la barre (drag) ───────────────────────────────
    local mouseX = GetDisabledControlNormal(0, 239) * 1920
    local mouseY = GetDisabledControlNormal(0, 240) * 1080

    local barLeft = x + _PP_BAR.X
    local barTop  = y + _PP_BAR.Y
    local overBar = mouseX >= barLeft and mouseX <= (barLeft + barW)
                    and mouseY >= (barTop - 5) and mouseY <= (barTop + _PP_BAR.H + 5)

    if overBar then
        SetMouseCursorActiveThisFrame()
        Hovered = true
        if IsDisabledControlPressed(0, 24) then
            Percent = math.max(0.0, math.min(1.0, (mouseX - barLeft) / barW))
            Active  = true
        end
    end

    -- Avance le curseur Y pour le prochain panel
    _AmaUIPanelY = _AmaUIPanelY + _PP_TOTAL

    if Callback then
        Callback(Hovered, Active, Percent)
    end
end
