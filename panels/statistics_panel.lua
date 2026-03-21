-- panels/statistics_panel.lua
-- StatisticsPanel et StatisticsPanelAdvanced conformes à RageUI (UIStatisticsPanel.lua)
-- Optimisé: buffer/flush (1 DrawRect fond pour N stats) + normInto sans allocation GC

-- ─── Config depuis Config.StatisticsPanel (shared/config.lua) ────────────────
-- barW calculé dynamiquement dans FlushStatBuffer : mw - _SP_BAR.X - _SP_BAR._padRight
local _c   = Config.StatisticsPanel or {}
local _cbg = _c.background or {}
local _clb = _c.label      or {}
local _cbar= _c.bar        or {}

local _SP_BG  = { Y = _cbg.offsetY   or 4,  H = _cbg.rowHeight or 40 }
local _SP_TXT = { X = _clb.offsetX   or 10, Y = _clb.offsetY   or 10, Scale = _clb.size or 0.26 }
local _SP_BAR = { X = _cbar.offsetX  or 190, Y = _cbar.offsetY or 18,
                  H = _cbar.height   or 6,  _padRight = _cbar.padRight or 11,
                  divCount = _cbar.divCount or 4 }

local _SP_BG_CLR  = _cbg.color    or { r = 0,   g = 0,   b = 0,   a = 170 }
local _SP_BAR_BG  = _cbar.colorBg or { r = 87,  g = 87,  b = 87,  a = 255 }
local _SP_BAR_FG  = _cbar.colorFill or { r = 255, g = 255, b = 255, a = 255 }
local _SP_TXT_CLR = _clb.color    or { r = 245, g = 245, b = 245, a = 255 }
local _SP_DIV_CLR = _cbar.colorDiv or { r = 0,   g = 0,   b = 0,   a = 255 }

-- Table temporaire réutilisée pour dessiner les couleurs custom sans allocation GC
local _fillColor = { r = 255, g = 255, b = 255, a = 255 }

-- ─── Buffer/flush ─────────────────────────────────────────────────────────────
-- Les slots sont pré-alloués et réutilisés entre les frames (zéro GC par frame).
local _MAX_SLOTS = 16
local _statSlots = {}
for i = 1, _MAX_SLOTS do
    _statSlots[i] = {
        label    = "",
        percent  = 0.0,
        advanced = false,
        -- couleur barre principale (StatisticsPanelAdvanced)
        c1r = 255, c1g = 255, c1b = 255, c1a = 255,
        -- portion secondaire
        percent2 = 0.0,
        c2r = 0,   c2g = 153, c2b = 204, c2a = 255,
        c3r = 185, c3g = 0,   c3b = 0,   c3a = 255,
    }
end

local _statCount = 0
local _statBufX  = 0
local _statBufY  = 0
local _statBufMW = 431

local function FlushStatBuffer()
    if _statCount == 0 then return end

    local x   = _statBufX
    local y   = _statBufY
    local mw  = _statBufMW
    local n   = _statCount

    -- Barre dynamique : s'adapte à la largeur du menu
    local barX    = _SP_BAR.X
    local barW    = mw - barX - _SP_BAR._padRight
    local divN    = _SP_BAR.divCount              -- nombre de diviseurs
    local divStep = barW / (divN + 1)             -- espacement entre diviseurs

    -- ⚡ 1 seul DrawRect fond pour toutes les lignes empilées
    Draw.Rect(x, y + _SP_BG.Y, mw, n * _SP_BG.H, _SP_BG_CLR)

    for i = 1, n do
        local s  = _statSlots[i]
        local oy = (i - 1) * _SP_BG.H

        -- Label
        Text.Draw(s.label, x + _SP_TXT.X, y + _SP_TXT.Y + oy, 0, _SP_TXT.Scale, _SP_TXT_CLR, 0)

        -- Barre fond (gris)
        Draw.Rect(x + barX, y + _SP_BAR.Y + oy, barW, _SP_BAR.H, _SP_BAR_BG)

        -- Barre fill principale
        local fillW1 = s.percent * barW
        if fillW1 > 0 then
            if s.advanced then
                _fillColor.r = s.c1r
                _fillColor.g = s.c1g
                _fillColor.b = s.c1b
                _fillColor.a = s.c1a
                Draw.Rect(x + barX, y + _SP_BAR.Y + oy, fillW1, _SP_BAR.H, _fillColor)
            else
                Draw.Rect(x + barX, y + _SP_BAR.Y + oy, fillW1, _SP_BAR.H, _SP_BAR_FG)
            end
        end

        -- Portion secondaire (StatisticsPanelAdvanced uniquement)
        if s.advanced and s.percent2 ~= 0 then
            local fillW2 = s.percent2 * barW
            local startX = x + barX + fillW1
            if fillW2 > 0 then
                _fillColor.r = s.c2r; _fillColor.g = s.c2g
                _fillColor.b = s.c2b; _fillColor.a = s.c2a
                Draw.Rect(startX, y + _SP_BAR.Y + oy, fillW2, _SP_BAR.H, _fillColor)
            elseif fillW2 < 0 then
                _fillColor.r = s.c3r; _fillColor.g = s.c3g
                _fillColor.b = s.c3b; _fillColor.a = s.c3a
                Draw.Rect(startX + fillW2, y + _SP_BAR.Y + oy, -fillW2, _SP_BAR.H, _fillColor)
            end
        end

        -- Diviseurs proportionnels (divN sections égales)
        for d = 1, divN do
            Draw.Rect(x + barX + d * divStep, y + _SP_BAR.Y + oy, 2, _SP_BAR.H, _SP_DIV_CLR)
        end
    end

    _statCount = 0
end

-- Exposer FlushStatBuffer comme _AmaUIPanelFlush (appelé depuis menu.lua:_DrawPanels)
_AmaUIPanelFlush = FlushStatBuffer

-- ─── StatisticsPanel ─────────────────────────────────────────────────────────
---@param Percent number   [0.0, 1.0]
---@param Label   string
---@param Index   number|nil
function StatisticsPanel(Percent, Label, Index)
    if not _AmaUIPanelMenu then return end
    if Index ~= nil and _AmaUIPanelMenu.currentItem ~= Index then return end

    if _statCount == 0 then
        _statBufX  = _AmaUIPanelX
        _statBufY  = _AmaUIPanelY
        _statBufMW = _AmaUIPanelMenu._menuWidth or 431
    end

    _statCount = _statCount + 1
    if _statCount <= _MAX_SLOTS then
        local s = _statSlots[_statCount]
        s.label    = Label or ""
        s.percent  = Percent or 0
        s.advanced = false
        s.percent2 = 0
    end

    _AmaUIPanelStatCount = _AmaUIPanelStatCount + 1
end

-- ─── StatisticsPanelAdvanced ─────────────────────────────────────────────────
---@param Label    string
---@param Percent  number          [0.0, 1.0]
---@param RGBA1    table|nil       couleur principale {r,g,b,a} ou positional
---@param Percent2 number|nil      portion secondaire (peut être négatif)
---@param RGBA2    table|nil       couleur portion positive
---@param RGBA3    table|nil       couleur portion négative
---@param Index    number|nil
function StatisticsPanelAdvanced(Label, Percent, RGBA1, Percent2, RGBA2, RGBA3, Index)
    if not _AmaUIPanelMenu then return end
    if Index ~= nil and _AmaUIPanelMenu.currentItem ~= Index then return end

    if _statCount == 0 then
        _statBufX  = _AmaUIPanelX
        _statBufY  = _AmaUIPanelY
        _statBufMW = _AmaUIPanelMenu._menuWidth or 431
    end

    -- Valeurs par défaut (sans création de table)
    local r1, g1, b1, a1 = 255, 255, 255, 255
    local r2, g2, b2, a2 = 0,   153, 204, 255
    local r3, g3, b3, a3 = 185, 0,   0,   255

    if RGBA1 then
        r1 = RGBA1.r or RGBA1[1] or 255
        g1 = RGBA1.g or RGBA1[2] or 255
        b1 = RGBA1.b or RGBA1[3] or 255
        a1 = RGBA1.a or RGBA1[4] or 255
    end
    if RGBA2 then
        r2 = RGBA2.r or RGBA2[1] or 0
        g2 = RGBA2.g or RGBA2[2] or 153
        b2 = RGBA2.b or RGBA2[3] or 204
        a2 = RGBA2.a or RGBA2[4] or 255
    end
    if RGBA3 then
        r3 = RGBA3.r or RGBA3[1] or 185
        g3 = RGBA3.g or RGBA3[2] or 0
        b3 = RGBA3.b or RGBA3[3] or 0
        a3 = RGBA3.a or RGBA3[4] or 255
    end

    _statCount = _statCount + 1
    if _statCount <= _MAX_SLOTS then
        local s = _statSlots[_statCount]
        s.label    = Label or ""
        s.percent  = Percent or 0
        s.advanced = true
        s.percent2 = Percent2 or 0
        s.c1r = r1; s.c1g = g1; s.c1b = b1; s.c1a = a1
        s.c2r = r2; s.c2g = g2; s.c2b = b2; s.c2a = a2
        s.c3r = r3; s.c3g = g3; s.c3b = b3; s.c3a = a3
    end

    _AmaUIPanelStatCount = _AmaUIPanelStatCount + 1
end
