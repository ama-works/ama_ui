-- utils/uuid.lua
---Generates a UUID (Universally Unique Identifier) string in the format of 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.
---The '4' in the third segment indicates that this is a version 4 UUID, which is randomly generated. The 'y' in the fourth segment is replaced with a random value from 8 to b (inclusive) to ensure that the UUID conforms to the version 4 specification.
---@return string A UUID string.

function GenerateUUID()
    local template = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    return string.gsub(template, '[xy]', function(c)
        local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb)
        return string.format('%x', v)
    end)
end