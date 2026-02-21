-- utils/math.lua
MathUtils = {}

--- Clamps a value between a minimum and maximum range.
--- @param value The value to clamp.
--- @param min The minimum value.
--- @param max The maximum value.
--- @return The clamped value.
function MathUtils.Clamp(value, min, max)
    return math.max(min, math.min(max, value))
end

--- Linearly interpolates between two values based on a given factor.
--- @param a The starting value.
--- @param b The ending value.
--- @param t The interpolation factor (0.0 to 1.0).
function MathUtils.Lerp(a, b, t)
    return a + (b - a) * t
end

--- Rounds a value to a specified number of decimal places.
--- @param value The value to round.
--- @param decimals The number of decimal places to round to (default is 0).
function MathUtils.Round(value, decimals)
    local mult = 10 ^ (decimals or 0)
    return math.floor(value * mult + 0.5) / mult
end

--- Maps a value from one range to another.
--- @param value The value to map.
--- @param inMin The minimum of the input range.
--- @param inMax The maximum of the input range.
--- @param outMin The minimum of the output range.
--- @param outMax The maximum of the output range.
function MathUtils.Map(value, inMin, inMax, outMin, outMax)
    return (value - inMin) * (outMax - outMin) / (inMax - inMin) + outMin
end