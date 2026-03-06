local ExecutionOrderPlan = require("src.data.execution_order_plan")
local ExecutionOrder = {}

local PHASE_ORDER = {
    "pre_update",
    "post_update",
    "pre_draw",
    "post_draw",
}

local function copy_value(value)
    if type(value) ~= "table" then
        return value
    end
    local out = {}
    for k, v in pairs(value) do
        out[k] = copy_value(v)
    end
    return out
end

function ExecutionOrder.get_plan()
    return copy_value(ExecutionOrderPlan)
end

---@param game_manager table
---@param handlers table<string, function>
function ExecutionOrder.register(game_manager, handlers)
    assert(type(game_manager) == "table", "Game manager is required")
    assert(type(handlers) == "table", "Hook handlers table is required")

    local plan = ExecutionOrder.get_plan()
    for _, phase in ipairs(PHASE_ORDER) do
        local entries = plan[phase] or {}
        for _, entry in ipairs(entries) do
            local callback = handlers[entry.name]
            assert(type(callback) == "function", "Missing hook handler: " .. tostring(entry.name))
            game_manager:register_hook(phase, entry.name, callback, entry.order)
        end
    end
end

return ExecutionOrder
