package.path = "./?.lua;./?/init.lua;" .. package.path

local FEATURE_DIR = "src/features"

local FEATURE_FILES = {
    FEATURE_DIR .. "/campaign_select/module.lua",
    FEATURE_DIR .. "/main_menu/module.lua",
    FEATURE_DIR .. "/scriptorium/page_layout.lua",
    FEATURE_DIR .. "/settings/module.lua",
    FEATURE_DIR .. "/startup_splash/module.lua",
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

local violations = {}
for _, path in ipairs(FEATURE_FILES) do
    local source = read_file(path)
    if source:find("local function%s+expect_", 1, false) then
        violations[#violations + 1] = path .. " defines local expect_* helper"
    end
    if source:find("local function%s+read_color", 1, false) then
        violations[#violations + 1] = path .. " defines local read_color* helper"
    end
end

if #violations > 0 then
    error("feature schema helper duplication found:\n" .. table.concat(violations, "\n"))
end

print("ok - feature_modules_use_shared_schema_helpers")
