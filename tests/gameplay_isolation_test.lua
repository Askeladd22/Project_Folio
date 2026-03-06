local DOMAIN_FILES = {
    "src/gameplay/folio/model.lua",
    "src/gameplay/folio/turn.lua",
    "src/gameplay/folio/window_patterns.lua",
    "src/gameplay/run/run.lua",
}

local function read_file(path)
    local file, err = io.open(path, "r")
    if not file then
        error("cannot read file: " .. tostring(path) .. " (" .. tostring(err) .. ")")
    end
    local content = file:read("*a")
    file:close()
    return content
end

local function is_forbidden_dependency(module_name)
    return module_name:match("^src%.core%.")
        or module_name:match("^src%.features%.")
        or module_name:match("^src%.ui%.")
end

local violations = {}
for _, path in ipairs(DOMAIN_FILES) do
    local source = read_file(path)
    for required in source:gmatch("require%s*%(%s*['\"]([^'\"]+)['\"]%s*%)") do
        if is_forbidden_dependency(required) then
            violations[#violations + 1] = string.format("%s -> %s", path, required)
        end
    end
end

if #violations > 0 then
    error("gameplay domain isolation violated:\n" .. table.concat(violations, "\n"))
end

print(string.format("ok - gameplay_domain_modules_are_isolated (%d files)", #DOMAIN_FILES))
