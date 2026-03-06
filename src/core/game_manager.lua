local EventBus = require("src.core.event_bus")

local GameManager = {}
GameManager.__index = GameManager

local function call_module(module, method_name, ...)
    if type(module) ~= "table" then
        return nil
    end
    local fn = module[method_name]
    if type(fn) ~= "function" then
        return nil
    end
    return fn(module, ...)
end

local ORDERED_PHASES = {
    pre_update = true,
    post_update = true,
    pre_draw = true,
    post_draw = true,
}

local function sort_hooks(hooks)
    table.sort(hooks, function(a, b)
        if a.order == b.order then
            return a.name < b.name
        end
        return a.order < b.order
    end)
end

---@param opts? table
---@return table
function GameManager.new(opts)
    local injected_event_bus = opts and opts.event_bus
    if injected_event_bus ~= nil then
        assert(type(injected_event_bus) == "table", "opts.event_bus must be a table")
        assert(type(injected_event_bus.emit) == "function", "opts.event_bus.emit must be a function")
        assert(type(injected_event_bus.on) == "function", "opts.event_bus.on must be a function")
        assert(type(injected_event_bus.off) == "function", "opts.event_bus.off must be a function")
    end
    local event_bus = injected_event_bus or EventBus.new()

    local self = setmetatable({
        modules = {},
        current = nil,
        current_name = nil,
        event_bus = event_bus,
        hooks = {
            pre_update = {},
            post_update = {},
            pre_draw = {},
            post_draw = {},
        },
    }, GameManager)

    self.context = {
        navigate = function(name, params)
            return self:switch(name, params)
        end,
        get_active_module = function()
            return self.current_name, self.current
        end,
        events = event_bus,
        emit_event = function(event_name, payload)
            return event_bus:emit(event_name, payload)
        end,
        on_event = function(event_name, handler, hook_opts)
            return event_bus:on(event_name, handler, hook_opts)
        end,
        once_event = function(event_name, handler)
            return event_bus:once(event_name, handler)
        end,
        off_event = function(event_or_slot, handler)
            return event_bus:off(event_or_slot, handler)
        end,
        metadata = (opts and opts.metadata) or {},
    }

    return self
end

function GameManager:get_context()
    return self.context
end

function GameManager:get_event_bus()
    return self.event_bus
end

function GameManager:emit(event_name, payload)
    return self.event_bus:emit(event_name, payload)
end

function GameManager:on(event_name, handler, opts)
    return self.event_bus:on(event_name, handler, opts)
end

function GameManager:once(event_name, handler)
    return self.event_bus:once(event_name, handler)
end

function GameManager:off(event_or_slot, handler)
    return self.event_bus:off(event_or_slot, handler)
end

---@param phase "pre_update"|"post_update"|"pre_draw"|"post_draw"
---@param name string
---@param fn function
---@param order? number
function GameManager:register_hook(phase, name, fn, order)
    assert(ORDERED_PHASES[phase], "Unknown phase: " .. tostring(phase))
    assert(type(name) == "string" and name ~= "", "Hook name must be a non-empty string")
    assert(type(fn) == "function", "Hook callback must be a function")
    local hooks = self.hooks[phase]
    for i = #hooks, 1, -1 do
        if hooks[i].name == name then
            table.remove(hooks, i)
        end
    end
    hooks[#hooks + 1] = {
        name = name,
        callback = fn,
        order = tonumber(order) or 1000,
    }
    sort_hooks(hooks)
end

---@param phase "pre_update"|"post_update"|"pre_draw"|"post_draw"
function GameManager:run_phase(phase, ...)
    local hooks = self.hooks[phase]
    if type(hooks) ~= "table" then
        return
    end
    for _, hook in ipairs(hooks) do
        hook.callback(...)
    end
end

---@param name string
---@param module table
function GameManager:register(name, module)
    assert(type(name) == "string" and name ~= "", "Module name must be a non-empty string")
    assert(type(module) == "table", "Module must be a table for: " .. tostring(name))
    self.modules[name] = module
end

---@param name string
---@param params? table
function GameManager:switch(name, params)
    local next_module = self.modules[name]
    assert(next_module, "Module not found: " .. tostring(name))

    local previous_name = self.current_name
    if self.current then
        self:emit("module.will_exit", {
            from = previous_name,
            to = name,
            params = params,
        })
        call_module(self.current, "exit", self.context)
    end

    self.current = next_module
    self.current_name = name
    self:emit("module.will_enter", {
        from = previous_name,
        to = name,
        params = params,
    })
    call_module(self.current, "enter", params, self.context)
    self:emit("module.did_enter", {
        from = previous_name,
        to = name,
        params = params,
    })
    return true
end

function GameManager:update(dt)
    self:emit("frame.pre_update", {
        dt = dt,
        module = self.current_name,
    })
    self:run_phase("pre_update", dt, self.context)
    call_module(self.current, "update", dt, self.context)
    self:run_phase("post_update", dt, self.context)
    self:emit("frame.post_update", {
        dt = dt,
        module = self.current_name,
    })
end

function GameManager:draw()
    self:emit("frame.pre_draw", {
        module = self.current_name,
    })
    self:run_phase("pre_draw", self.context)
    call_module(self.current, "draw", self.context)
    self:run_phase("post_draw", self.context)
    self:emit("frame.post_draw", {
        module = self.current_name,
    })
end

function GameManager:keypressed(key, scancode, isrepeat)
    call_module(self.current, "keypressed", key, scancode, isrepeat, self.context)
end

function GameManager:mousepressed(x, y, button)
    call_module(self.current, "mousepressed", x, y, button, self.context)
end

function GameManager:mousereleased(x, y, button)
    call_module(self.current, "mousereleased", x, y, button, self.context)
end

function GameManager:mousemoved(x, y, dx, dy, istouch)
    call_module(self.current, "mousemoved", x, y, dx, dy, istouch, self.context)
end

function GameManager:wheelmoved(x, y)
    call_module(self.current, "wheelmoved", x, y, self.context)
end

return GameManager
