local EngineBridge = {
    get_dice_tray_rect = nil,
    pick_scriptorium_tray_die = nil,
    to_virtual_ui = nil,
    to_screen_ui = nil,
    event_bus = nil,
}

local HANDLER_KEYS = {
    get_dice_tray_rect = true,
    pick_scriptorium_tray_die = true,
    to_virtual_ui = true,
    to_screen_ui = true,
}

---@param handlers table
function EngineBridge.configure(handlers)
    if type(handlers) ~= "table" then
        return
    end
    for key, fn in pairs(handlers) do
        if key == "event_bus" and type(fn) == "table" then
            EngineBridge.set_event_bus(fn)
        elseif HANDLER_KEYS[key] and type(fn) == "function" then
            EngineBridge[key] = fn
        end
    end
end

---@param event_bus table|nil
function EngineBridge.set_event_bus(event_bus)
    if event_bus == nil then
        EngineBridge.event_bus = nil
        return
    end
    if type(event_bus) ~= "table" then
        return
    end
    if type(event_bus.emit) ~= "function" then
        return
    end
    if type(event_bus.on) ~= "function" then
        return
    end
    if type(event_bus.off) ~= "function" then
        return
    end
    EngineBridge.event_bus = event_bus
end

---@param event_name string
---@param payload any
---@return number
function EngineBridge.emit(event_name, payload)
    local bus = EngineBridge.event_bus
    if type(bus) ~= "table" then
        return 0
    end
    local fn = bus.emit
    if type(fn) ~= "function" then
        return 0
    end
    local ok, called = pcall(fn, bus, event_name, payload)
    if ok and type(called) == "number" then
        return called
    end
    return 0
end

---@param event_name string
---@param handler function
---@param opts? table
---@return table|nil
function EngineBridge.on(event_name, handler, opts)
    local bus = EngineBridge.event_bus
    if type(bus) ~= "table" then
        return nil
    end
    local fn = bus.on
    if type(fn) ~= "function" then
        return nil
    end
    local ok, slot = pcall(fn, bus, event_name, handler, opts)
    if ok then
        return slot
    end
    return nil
end

---@param event_or_slot string|table
---@param handler? function
---@return boolean
function EngineBridge.off(event_or_slot, handler)
    local bus = EngineBridge.event_bus
    if type(bus) ~= "table" then
        return false
    end
    local fn = bus.off
    if type(fn) ~= "function" then
        return false
    end
    local ok, removed = pcall(fn, bus, event_or_slot, handler)
    if ok and removed then
        return true
    end
    return false
end

---@return table|nil
function EngineBridge.getDiceTrayRect()
    local fn = EngineBridge.get_dice_tray_rect
    if type(fn) ~= "function" then
        return nil
    end
    local ok, rect = pcall(fn)
    if ok and type(rect) == "table" then
        return rect
    end
    return nil
end

---@param x number
---@param y number
---@return number|nil
function EngineBridge.pickTrayDie(x, y)
    local fn = EngineBridge.pick_scriptorium_tray_die
    if type(fn) ~= "function" then
        return nil
    end
    local ok, roll_index = pcall(fn, x, y)
    if ok then
        return roll_index
    end
    return nil
end

---@param x number
---@param y number
---@return number, number
function EngineBridge.toVirtual(x, y)
    local fn = EngineBridge.to_virtual_ui
    if type(fn) == "function" then
        local ok, out_x, out_y = pcall(fn, x, y)
        if ok then
            return out_x, out_y
        end
    end
    return x, y
end

---@param x number
---@param y number
---@return number, number
function EngineBridge.toScreen(x, y)
    local fn = EngineBridge.to_screen_ui
    if type(fn) == "function" then
        local ok, out_x, out_y = pcall(fn, x, y)
        if ok then
            return out_x, out_y
        end
    end
    return x, y
end

return EngineBridge
