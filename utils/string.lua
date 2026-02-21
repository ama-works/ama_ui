-- utils/string.lua
StringUtils = {}

-- Mesurer la largeur d'un texte
--- Measures the width of a given text using specified font and scale.
--- @param text The text to measure.
--- @param font The font to use for measurement (default is 0).
--- @param scale The scale to use for measurement (default is 0.35).
function StringUtils.MeasureWidth(text, font, scale)
    SetTextFont(font or 0)
    SetTextScale(scale or 0.35, scale or 0.35)
    BeginTextCommandWidth("CELL_EMAIL_BCON")
    AddTextComponentSubstringPlayerName(text)
    return EndTextCommandGetWidth(true) * Config.BaseResolution.width
end

-- Wrap text
--- Wraps a given text into multiple lines based on a specified maximum width, font, and scale.
--- @param text The text to wrap.
--- @param maxWidth The maximum width for each line.
--- @param font The font to use for measurement (default is 0).
--- @param scale The scale to use for measurement (default is 0.35).
function StringUtils.Wrap(text, maxWidth, font, scale)
    local lines = {}
    local words = {}
    for word in text:gmatch("%S+") do
        table.insert(words, word)
    end
    
    local currentLine = ""
    for _, word in ipairs(words) do
        local testLine = currentLine == "" and word or (currentLine .. " " .. word)
        local width = StringUtils.MeasureWidth(testLine, font, scale)
        
        if width > maxWidth then
            table.insert(lines, currentLine)
            currentLine = word
        else
            currentLine = testLine
        end
    end
    
    if currentLine ~= "" then
        table.insert(lines, currentLine)
    end
    
    return lines
end