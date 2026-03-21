-- panels/color_panel.lua
-- ColorPanel conforme à RageUI.ColourPanel (UIColourPanel.lua)
--
-- Signature : ColorPanel(title, colors, minIdx, curIdx, callback, index)
-- callback(hovered, active, newMinIdx, newCurIdx)
--
-- colors : table de {r, g, b} ou {r, g, b, a}  (format PanelColour.HairCut)
-- minIdx : premier index visible dans la fenêtre glissante (1-based)
-- curIdx : index sélectionné (1-based)
-- index  : numéro de l'item associé (currentItem doit être == index pour afficher)
--
-- Utilisation typique (dans menu:SetPanels) :
--   local minIdx, curIdx = 1, 1
--   menu:SetPanels(function()
--       ColorPanel("Couleur", RageUI.PanelColour.HairCut, minIdx, curIdx, function(h, a, newMin, newCur)
--           minIdx = newMin
--           curIdx = newCur
--       end, 5)
--   end)

-- ─── Config (Config.ColorPanel) ───────────────────────────────────────────────
local _cfgCP = Config.ColorPanel

local _CP_BG  = { Dict = _cfgCP.sprite.dict, Tex = _cfgCP.sprite.name,
                  Y    = _cfgCP.background.offsetY, H = _cfgCP.background.height }
local _CP_LA  = { Dict = "commonmenu", Tex = "arrowleft",
                  X    = _cfgCP.arrowLeft.offsetX,  Y = _cfgCP.arrowLeft.offsetY,
                  W    = _cfgCP.arrowLeft.width,    H = _cfgCP.arrowLeft.height }
local _CP_RA  = { Dict = "commonmenu", Tex = "arrowright",
                  Y    = _cfgCP.arrowRight.offsetY, W = _cfgCP.arrowRight.width,
                  H    = _cfgCP.arrowRight.height,  _padRight = _cfgCP.arrowRight.padRight }
local _CP_HDR = { Y = _cfgCP.header.offsetY, Scale = _cfgCP.header.size }
local _CP_BOX = { X = _cfgCP.box.offsetX,       Y = _cfgCP.box.offsetY,
                  W = _cfgCP.box.width,          H = _cfgCP.box.height }
local _CP_SEL = { X = _cfgCP.selection.offsetX,  Y = _cfgCP.selection.offsetY,
                  W = _cfgCP.selection.width,    H = _cfgCP.selection.height }

local _CP_WHITE = _cfgCP.color.text
local _CP_TOTAL = _CP_BG.H + _CP_BG.Y

-- Table couleur réutilisable — évite 9 allocs GC par frame dans la boucle des carrés
local _cp_color = { r = 0, g = 0, b = 0, a = 255 }
-- Cache titre — évite string concat à chaque frame
local _cp_lastTitle, _cp_lastCurIdx, _cp_lastTotal, _cp_cachedTitle

---ColorPanel conforme RageUI.ColourPanel
---@param Title      string
---@param Colours    table     table de {r,g,b} ou {r,g,b,a}
---@param MinIdx     number    premier index visible (1-based)
---@param CurIdx     number    index sélectionné (1-based)
---@param Callback   function  callback(hovered, active, newMinIdx, newCurIdx)
---@param Index      number|nil  index de l'item associé (nil = toujours visible)
---@param MouseOnly  boolean|nil  true = navigation souris uniquement (désactive clavier ←→)
function ColorPanel(Title, Colours, MinIdx, CurIdx, Callback, Index, MouseOnly)
    if not _AmaUIPanelMenu then return end
    if Index ~= nil and _AmaUIPanelMenu.currentItem ~= Index then return end

    local x     = _AmaUIPanelX
    local y     = _AmaUIPanelY
    local menuW = _AmaUIPanelMenu._menuWidth
    local total = #Colours
    -- Nombre de cases visibles dynamique (chaque case = 37.5px, marge gauche 42, droite 37.5)
    local Max   = math.min(total, math.max(1, math.floor((menuW - 79.5) / _CP_BOX.W)))
    local raX   = menuW - _CP_RA._padRight      -- flèche droite
    local hdrX  = menuW * 0.5                   -- titre centré

    -- ─── Background sprite ────────────────────────────────────────────────────
    Draw.Sprite(_CP_BG.Dict, _CP_BG.Tex,
        x, y + _CP_BG.Y, menuW, _CP_BG.H, 0, 255, 255, 255, 255)

    -- ─── Flèches gauche / droite ──────────────────────────────────────────────
    Draw.Sprite(_CP_LA.Dict, _CP_LA.Tex,
        x + _CP_LA.X, y + _CP_LA.Y, _CP_LA.W, _CP_LA.H, 0, 255, 255, 255, 255)
    Draw.Sprite(_CP_RA.Dict, _CP_RA.Tex,
        x + raX, y + _CP_RA.Y, _CP_RA.W, _CP_RA.H, 0, 255, 255, 255, 255)

    -- ─── Barre blanche de sélection (sous le carré actif) ────────────────────
    Draw.Rect(
        x + _CP_SEL.X + (_CP_BOX.W * (CurIdx - MinIdx)),
        y + _CP_SEL.Y,
        _CP_SEL.W, _CP_SEL.H, _CP_WHITE)

    -- ─── Carrés de couleur (max 9 visibles, fenêtre glissante) ───────────────
    for i = 1, Max do
        local c = Colours[MinIdx + i - 1]
        if c then
            _cp_color.r = c[1]
            _cp_color.g = c[2]
            _cp_color.b = c[3]
            _cp_color.a = c[4] or 255
            Draw.Rect(
                x + _CP_BOX.X + (_CP_BOX.W * (i - 1)),
                y + _CP_BOX.Y,
                _CP_BOX.W, _CP_BOX.H, _cp_color)
        end
    end

    -- ─── Titre centré : "Label (curIdx of total)" ────────────────────────────
    local t = Title or ""
    if t ~= _cp_lastTitle or CurIdx ~= _cp_lastCurIdx or total ~= _cp_lastTotal then
        _cp_lastTitle  = t
        _cp_lastCurIdx = CurIdx
        _cp_lastTotal  = total
        _cp_cachedTitle = t .. " (" .. CurIdx .. " of " .. total .. ")"
    end
    Text.Draw(_cp_cachedTitle, x + hdrX, y + _CP_HDR.Y, 0, _CP_HDR.Scale, _CP_WHITE, 1)

    -- ─── Navigation gauche / droite ───────────────────────────────────────────
    local Hovered = false
    local Active  = false

    if not MouseOnly and (Index == nil or _AmaUIPanelMenu.currentItem == Index) then
        if IsControlJustPressed(0, 174) then        -- LEFT
            CurIdx = CurIdx - 1
            if CurIdx < 1 then
                CurIdx = total
                MinIdx = total - Max + 1
            elseif CurIdx < MinIdx then
                MinIdx = MinIdx - 1
            end
            Active = true
        elseif IsControlJustPressed(0, 175) then    -- RIGHT
            CurIdx = CurIdx + 1
            if CurIdx > total then
                CurIdx = 1
                MinIdx = 1
            elseif CurIdx > MinIdx + Max - 1 then
                MinIdx = MinIdx + 1
            end
            Active = true
        end
    end

    -- ─── Interaction souris sur les flèches ───────────────────────────────────
    local mouseX = GetDisabledControlNormal(0, 239) * 1920
    local mouseY = GetDisabledControlNormal(0, 240) * 1080

    local laTop = y + _CP_LA.Y
    local raTop = y + _CP_RA.Y
    local overLeft  = mouseX >= (x + _CP_LA.X) and mouseX <= (x + _CP_LA.X + _CP_LA.W)
                      and mouseY >= laTop and mouseY <= (laTop + _CP_LA.H)
    local overRight = mouseX >= (x + raX) and mouseX <= (x + raX + _CP_RA.W)
                      and mouseY >= raTop and mouseY <= (raTop + _CP_RA.H)

    if overLeft or overRight then
        SetMouseCursorActiveThisFrame()
        Hovered = true
        if IsDisabledControlJustPressed(0, 24) then
            if overLeft then
                CurIdx = CurIdx - 1
                if CurIdx < 1 then CurIdx = total; MinIdx = total - Max + 1
                elseif CurIdx < MinIdx then MinIdx = MinIdx - 1 end
            else
                CurIdx = CurIdx + 1
                if CurIdx > total then CurIdx = 1; MinIdx = 1
                elseif CurIdx > MinIdx + Max - 1 then MinIdx = MinIdx + 1 end
            end
            Active = true
        end
    end

    -- Avance le curseur Y pour le prochain panel
    _AmaUIPanelY = _AmaUIPanelY + _CP_TOTAL

    if Callback then
        Callback(Hovered, Active, MinIdx, CurIdx)
    end
end
