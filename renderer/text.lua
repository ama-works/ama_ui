-- renderer/text.lua
Text = {}

-- Alignements
Text.Align = {
    Left = 0,
    Center = 1,
    Right = 2
}

-- Fonts GTA V
Text.Font = {
    ChaletLondon = 0,
    HouseScript = 1,
    Monospace = 2,
    ChaletComprimeCologne = 4,
    Pricedown = 7
}

-- Cache des mesures de texte
local textWidthCache = {}
local textWidthCacheCount = 0

-- Upvalues: check une seule fois au boot, pas à chaque frame
local _cacheEnabled
local _maxCachedTexts
local _hasSetTextProportional = (type(SetTextProportional) == "function")

local function EnsureCacheConfig()
    if _cacheEnabled == nil then
        _cacheEnabled = Config and Config.Performance and Config.Performance.enableCache == true
        _maxCachedTexts = (Config and Config.Performance and Config.Performance.maxCachedTexts) or 200
    end
end

---@param str any
local function AddText(str)
    local value <const> = tostring(str)
    local charCount <const> = #value

    if charCount < 100 then
        AddTextComponentSubstringPlayerName(value)
        return
    end

    -- Split en chunks de 99 chars (limite GTA)
    local strCount <const> = math.ceil(charCount / 99)
    for i = 1, strCount do
        local start <const> = (i - 1) * 99 + 1
        local finish <const> = math.min(i * 99, charCount)
        AddTextComponentSubstringPlayerName(value:sub(start, finish))
    end
end

-- Upvalue: détecte le bon nom de native une seule fois
local _shadowNative
local function ApplyShadow(distance, r, g, b, a)
    if not _shadowNative then
        if type(SetTextDropshadow) == "function" then
            _shadowNative = SetTextDropshadow
        elseif type(SetTextDropShadow) == "function" then
            _shadowNative = SetTextDropShadow
        else
            _shadowNative = false
        end
    end
    if _shadowNative then _shadowNative(distance, r, g, b, a) end
end

local function Clamp01(v)
    if v < 0.0 then return 0.0 end
    if v > 1.0 then return 1.0 end
    return v
end

-- ============================================================================
-- Text.Draw — version optimisée
-- ============================================================================
-- Gains vs ancienne version:
--   • type(SetTextProportional) checké 1x au boot, pas par appel
--   • ClearShadow() skippé quand shadow == nil (99% des cas)
--   • Draw.GetResolution() → local res une seule fois
--   • Moins de branches inutiles
function Text.Draw(text, x, y, font, scale, color, alignment, shadow, outline, wrap, wrapWidth)
    if not text or text == "" then return end

    font = tonumber(font) or 0
    scale = tonumber(scale) or 0.35
    alignment = alignment or 0  -- Text.Align.Left

    SetTextFont(font)
    SetTextScale(1.0, scale)
    SetTextColour(
        color and color.r or 255,
        color and color.g or 255,
        color and color.b or 255,
        color and color.a or 255
    )
    if _hasSetTextProportional then
        SetTextProportional(true)
    end

    local isCenter = alignment == 1
    local isRight  = alignment == 2
    SetTextCentre(isCenter)
    SetTextRightJustify(isRight)

    -- Ombre: seulement si demandé (skip le reset coûteux sinon)
    if shadow and shadow.enabled ~= false then
        ApplyShadow(
            shadow.distance or 2,
            shadow.color and shadow.color.r or 0,
            shadow.color and shadow.color.g or 0,
            shadow.color and shadow.color.b or 0,
            shadow.color and shadow.color.a or 150
        )
    end

    -- Contour
    if outline then
        SetTextOutline()
    end

    local res = Draw.GetResolution()
    local nx = x / res.width
    local ny = y / res.height

    -- Wrap/align
    if wrap and wrapWidth and wrapWidth ~= 0 then
        local nWrap = wrapWidth / res.width
        if isCenter then
            SetTextWrap(Clamp01(nx - nWrap * 0.5), Clamp01(nx + nWrap * 0.5))
        elseif isRight then
            SetTextWrap(0.0, Clamp01(nx))
        else
            SetTextWrap(Clamp01(nx), Clamp01(nx + nWrap))
        end
    elseif isRight then
        SetTextWrap(0.0, Clamp01(nx))
    end

    BeginTextCommandDisplayText("CELL_EMAIL_BCON")
    AddText(text)
    EndTextCommandDisplayText(nx, ny)
end

-- ============================================================================
-- Text.GetWidth — version optimisée
-- ============================================================================
-- Gains:
--   • Cache key via table lookup au lieu de string concat (text.."_"..font.."_"..scale)
--   • IsCacheEnabled() → upvalue, pas re-évalué à chaque appel
--   • Cache count suivi par compteur, pas itération pairs()
function Text.GetWidth(text, font, scale)
    if not text or text == "" then return 0 end

    font  = font  or 0
    scale = scale or 0.35
    EnsureCacheConfig()

    -- Cache lookup: table[font][scale][text] → plus rapide que concat string
    if _cacheEnabled then
        local byFont = textWidthCache[font]
        if byFont then
            local byScale = byFont[scale]
            if byScale then
                local cached = byScale[text]
                if cached then return cached end
            end
        end
    end

    -- Mesurer (retour en pixels dans l'espace de référence)
    SetTextFont(font)
    SetTextScale(1.0, scale)
    BeginTextCommandGetWidth("CELL_EMAIL_BCON")
    AddTextComponentSubstringPlayerName(text)
    local width = EndTextCommandGetWidth(true)

    local res = Draw.GetResolution()
    local pixelWidth = width * res.width

    -- Mettre en cache (structure imbriquée)
    if _cacheEnabled then
        if textWidthCacheCount > _maxCachedTexts then
            textWidthCache = {}
            textWidthCacheCount = 0
        end
        local byFont = textWidthCache[font]
        if not byFont then byFont = {}; textWidthCache[font] = byFont end
        local byScale = byFont[scale]
        if not byScale then byScale = {}; byFont[scale] = byScale end
        if not byScale[text] then
            textWidthCacheCount = textWidthCacheCount + 1
        end
        byScale[text] = pixelWidth
    end

    return pixelWidth
end

-- ============================================================================
-- Text.GetLineCount
-- ============================================================================
function Text.GetLineCount(text, x, y, font, scale, wrapWidth, alignment)
    if not text or text == "" then return 0 end

    if type(BeginTextCommandLineCount) ~= "function" or type(EndTextCommandLineCount) ~= "function" then
        local _, n = tostring(text):gsub("\n", "")
        return n + 1
    end

    font  = tonumber(font) or 0
    scale = tonumber(scale) or 0.35
    alignment = alignment or 0

    SetTextFont(font)
    SetTextScale(1.0, scale)

    local res = Draw.GetResolution()
    local nx = x / res.width
    local ny = y / res.height

    if wrapWidth and wrapWidth ~= 0 then
        local nWrap = wrapWidth / res.width
        if alignment == 1 then
            SetTextWrap(Clamp01(nx - nWrap * 0.5), Clamp01(nx + nWrap * 0.5))
        elseif alignment == 2 then
            SetTextWrap(0.0, Clamp01(nx))
        else
            SetTextWrap(Clamp01(nx), Clamp01(nx + nWrap))
        end
    elseif alignment == 2 then
        SetTextWrap(0.0, Clamp01(nx))
    else
        SetTextWrap(0.0, 1.0)
    end

    BeginTextCommandLineCount("CELL_EMAIL_BCON")
    AddText(text)
    local count = EndTextCommandLineCount(nx, ny)
    return (count and count >= 1) and count or 1
end

-- ============================================================================
-- Text.Ellipsize
-- ============================================================================
function Text.Ellipsize(text, maxWidth, font, scale, suffix)
    if not text or text == "" then return text end
    if not maxWidth or maxWidth <= 0 then return text end

    suffix = suffix or "..."
    font  = font  or 0
    scale = scale or 0.35

    local fullWidth = Text.GetWidth(text, font, scale)
    if fullWidth <= maxWidth then
        return text
    end

    local suffixWidth = Text.GetWidth(suffix, font, scale)
    if suffixWidth >= maxWidth then
        return suffix
    end

    local left  = 1
    local right = #text
    local best  = ""

    while left <= right do
        local mid = math.floor((left + right) * 0.5)
        local candidate = string.sub(text, 1, mid)
        local width = Text.GetWidth(candidate, font, scale)

        if width + suffixWidth <= maxWidth then
            best = candidate
            left = mid + 1
        else
            right = mid - 1
        end
    end

    return best .. suffix
end