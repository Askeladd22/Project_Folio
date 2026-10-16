local GameManager = require("src.core.game_manager")

-- Legacy compatibility wrapper.
-- Keep old ModuleManager entrypoints routed to the newer GameManager core.
local ModuleManager = {
    current = nil,
    current_name = nil,
    modules = {},
}

local manager = GameManager.new()
ModuleManager.modules = manager.modules

local function sync_state()
    ModuleManager.current = manager.current
    ModuleManager.current_name = manager.current_name
    ModuleManager.modules = manager.modules
end

function ModuleManager.register(name, module)
    manager:register(name, module)
    sync_state()
end

function ModuleManager.switch(name, ...)
    manager:switch(name, ...)
    sync_state()
end

function ModuleManager.update(dt)
    manager:update(dt)
    sync_state()
end

function ModuleManager.draw()
    manager:draw()
    sync_state()
end

function ModuleManager.register_hook(phase, name, fn, order)
    manager:register_hook(phase, name, fn, order)
    sync_state()
end

function ModuleManager.get_context()
    return manager:get_context()
end

function ModuleManager.get_event_bus()
    return manager:get_event_bus()
end

function ModuleManager.emit(event_name, payload)
    return manager:emit(event_name, payload)
end

function ModuleManager.on(event_name, handler, opts)
    return manager:on(event_name, handler, opts)
end

function ModuleManager.once(event_name, handler)
    return manager:once(event_name, handler)
end

function ModuleManager.off(event_or_slot, handler)
    return manager:off(event_or_slot, handler)
end

function ModuleManager.keypressed(key, scancode, isrepeat)
    manager:keypressed(key, scancode, isrepeat)
    sync_state()
end

function ModuleManager.mousepressed(x, y, button)
    manager:mousepressed(x, y, button)
    sync_state()
end

function ModuleManager.mousereleased(x, y, button)
    manager:mousereleased(x, y, button)
    sync_state()
end

function ModuleManager.mousemoved(x, y, dx, dy, istouch)
    manager:mousemoved(x, y, dx, dy, istouch)
    sync_state()
end

function ModuleManager.wheelmoved(x, y)
    manager:wheelmoved(x, y)
    sync_state()
end

return ModuleManager
