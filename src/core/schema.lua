local Schema = {}

local function fail(path, expected, actual)
    error(string.format("Invalid schema at %s: expected %s, got %s", path, expected, actual))
end

---@param value any
---@param path string
---@return table
function Schema.expect_table(value, path)
    if type(value) ~= "table" then
        fail(path, "table", type(value))
    end
    return value
end

---@param value any
---@param path string
---@return table
function Schema.expect_non_empty_list(value, path)
    local list = Schema.expect_table(value, path)
    if #list <= 0 then
        fail(path, "non-empty list", "empty list")
    end
    return list
end

---@param value any
---@param path string
---@return string
function Schema.expect_string(value, path)
    if type(value) ~= "string" or value == "" then
        fail(path, "non-empty string", type(value))
    end
    return value
end

---@param value any
---@param path string
---@return number
function Schema.expect_number(value, path)
    local number_value = tonumber(value)
    if not number_value then
        fail(path, "number", type(value))
    end
    return number_value
end

---@param value any
---@param path string
---@return boolean
function Schema.expect_boolean(value, path)
    if type(value) ~= "boolean" then
        fail(path, "boolean", type(value))
    end
    return value
end

---@param value any
---@param path string
---@return table
function Schema.expect_entry(value, path)
    local entry = Schema.expect_table(value, path)
    if type(entry.key) ~= "string" or entry.key == "" then
        fail(path .. ".key", "non-empty string", type(entry.key))
    end
    return entry
end

---@param value any
---@param path string
---@return number[]
function Schema.expect_color3(value, path)
    local color = Schema.expect_table(value, path)
    local r = tonumber(color[1])
    local g = tonumber(color[2])
    local b = tonumber(color[3])
    if (not r) or (not g) or (not b) then
        fail(path, "color3 table", "invalid components")
    end
    return {r, g, b}
end

---@param value any
---@param path string
---@param default_alpha? number
---@return number[]
function Schema.expect_color4(value, path, default_alpha)
    local color = Schema.expect_table(value, path)
    local r = tonumber(color[1])
    local g = tonumber(color[2])
    local b = tonumber(color[3])
    if (not r) or (not g) or (not b) then
        fail(path, "color4 table", "invalid components")
    end
    local a = tonumber(color[4])
    if not a then
        a = tonumber(default_alpha) or 1
    end
    return {r, g, b, a}
end

---@param value any
---@param path string
---@return string[]
function Schema.expect_string_list(value, path)
    local list = Schema.expect_non_empty_list(value, path)
    local out = {}
    for i, item in ipairs(list) do
        if type(item) ~= "string" or item == "" then
            fail(path .. "[" .. tostring(i) .. "]", "non-empty string", type(item))
        end
        out[#out + 1] = item
    end
    return out
end

return Schema
