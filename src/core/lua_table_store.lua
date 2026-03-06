local LuaTableStore = {}

local function is_identifier(str)
    return type(str) == "string" and str:match("^[%a_][%w_]*$") ~= nil
end

local function sorted_keys(tbl)
    local keys = {}
    for key in pairs(tbl) do
        keys[#keys + 1] = key
    end
    table.sort(keys, function(a, b)
        if type(a) == type(b) then
            return tostring(a) < tostring(b)
        end
        return type(a) < type(b)
    end)
    return keys
end

local function serialize(value, indent)
    indent = indent or 0
    local pad = string.rep(" ", indent)
    local value_type = type(value)

    if value_type == "number" then
        return tostring(value)
    end
    if value_type == "boolean" then
        return value and "true" or "false"
    end
    if value_type == "string" then
        return string.format("%q", value)
    end
    if value_type == "table" then
        local parts = {"{\n"}
        local keys = sorted_keys(value)
        for _, key in ipairs(keys) do
            local key_repr
            if is_identifier(key) then
                key_repr = key
            else
                key_repr = "[" .. serialize(key, indent + 2) .. "]"
            end
            parts[#parts + 1] = string.rep(" ", indent + 2)
                .. key_repr
                .. " = "
                .. serialize(value[key], indent + 2)
                .. ",\n"
        end
        parts[#parts + 1] = pad .. "}"
        return table.concat(parts)
    end

    return "nil"
end

local function resolve_filesystem(options)
    local opts = options or {}
    if opts.filesystem then
        return opts.filesystem
    end
    if love and love.filesystem then
        return love.filesystem
    end
    return nil
end

---@param path string
---@param options? { filesystem?: table }
---@return table|nil data
---@return string|nil error_message
---@return string|nil status
function LuaTableStore.load(path, options)
    local fs = resolve_filesystem(options)
    if not fs or type(fs.getInfo) ~= "function" or type(fs.load) ~= "function" then
        return nil, nil, "unavailable"
    end

    if not fs.getInfo(path) then
        return nil, nil, "missing"
    end

    local chunk, load_err = fs.load(path)
    if not chunk then
        return nil, tostring(load_err), "load_error"
    end

    local ok, data = pcall(chunk)
    if not ok then
        return nil, tostring(data), "runtime_error"
    end
    if type(data) ~= "table" then
        return nil, "stored chunk did not return a table", "invalid_data"
    end
    return data, nil, nil
end

---@param path string
---@param data table
---@param options? { filesystem?: table }
---@return boolean ok
---@return string|nil error_message
function LuaTableStore.save(path, data, options)
    if type(data) ~= "table" then
        return false, "LuaTableStore.save expects table data"
    end

    local fs = resolve_filesystem(options)
    if not fs or type(fs.write) ~= "function" then
        return false, "filesystem write unavailable"
    end

    local text = "return " .. serialize(data, 0) .. "\n"
    local ok, err = fs.write(path, text)
    return ok, err
end

return LuaTableStore
