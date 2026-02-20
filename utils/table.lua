-- utils/table.lua
TableUtils = {}

--- Deep copy a table
--- @param orig table The original table to copy
function TableUtils.DeepCopy(orig)
    local copy
    if type(orig) == 'table' then
        copy = {}
        for k, v in pairs(orig) do
            copy[TableUtils.DeepCopy(k)] = TableUtils.DeepCopy(v)
        end
    else
        copy = orig
    end
    return copy
end

--- Find the index of a value in a table
--- @param tbl table The table to search
--- @param value any The value to find
function TableUtils.FindIndex(tbl, value)
    for i, v in ipairs(tbl) do
        if v == value then
            return i
        end
    end
    return -1
end

--- Check if a table contains a value
--- @param tbl table The table to search
--- @param value any The value to check for
function TableUtils.Contains(tbl, value)
    return TableUtils.FindIndex(tbl, value) ~= -1
end