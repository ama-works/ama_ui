-- utils/uuid.lua
-- UUID v4 optimisé: lookup table hex + évite string.gsub + closure par appel

local _hexChars = "0123456789abcdef"

local _hex = {}
for i = 0, 15 do
    _hex[i] = _hexChars:sub(i + 1, i + 1)
end

function GenerateUUID()
    local r = math.random
    local h = _hex

    local s1 = h[r(0,15)]..h[r(0,15)]..h[r(0,15)]..h[r(0,15)]
             ..h[r(0,15)]..h[r(0,15)]..h[r(0,15)]..h[r(0,15)]
    local s2 = h[r(0,15)]..h[r(0,15)]..h[r(0,15)]..h[r(0,15)]
    local s3 = "4"..h[r(0,15)]..h[r(0,15)]..h[r(0,15)]
    local s4 = h[r(8,11)]..h[r(0,15)]..h[r(0,15)]..h[r(0,15)]
    local s5 = h[r(0,15)]..h[r(0,15)]..h[r(0,15)]..h[r(0,15)]
             ..h[r(0,15)]..h[r(0,15)]..h[r(0,15)]..h[r(0,15)]
             ..h[r(0,15)]..h[r(0,15)]..h[r(0,15)]..h[r(0,15)]

    return s1.."-"..s2.."-"..s3.."-"..s4.."-"..s5
end
