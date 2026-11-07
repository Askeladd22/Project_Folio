local Bundle = {}
Bundle.EventBus = (function()
local EventBus = {}
EventBus.__index = EventBus

local function expect_event_name(event_name)
    assert(type(event_name) == "string" and event_name ~= "", "Event name must be a non-empty string")
end

local function expect_handler(handler)
    assert(type(handler) == "function", "Event handler must be a function")
end

---@return table
function EventBus.new()
    return setmetatable({
        listeners = {},
    }, EventBus)
end

---@param event_name string
---@param handler function
---@param opts? {once:boolean}
---@return table
function EventBus:on(event_name, handler, opts)
    expect_event_name(event_name)
    expect_handler(handler)
    local slot = {
        event_name = event_name,
        handler = handler,
        once = (opts and opts.once) and true or false,
    }
    local list = self.listeners[event_name]
    if type(list) ~= "table" then
        list = {}
        self.listeners[event_name] = list
    end
    list[#list + 1] = slot
    return slot
end

---@param event_name string
---@param handler function
---@return table
function EventBus:once(event_name, handler)
    return self:on(event_name, handler, {once = true})
end

local function remove_slot(list, target)
    if type(list) ~= "table" then
        return false
    end
    for i = #list, 1, -1 do
        if list[i] == target then
            table.remove(list, i)
            return true
        end
    end
    return false
end

---@param event_or_slot string|table
---@param handler? function
---@return boolean
function EventBus:off(event_or_slot, handler)
    if type(event_or_slot) == "table" then
        local slot = event_or_slot
        local list = self.listeners[slot.event_name]
        return remove_slot(list, slot)
    end

    expect_event_name(event_or_slot)
    local list = self.listeners[event_or_slot]
    if type(list) ~= "table" or #list == 0 then
        return false
    end

    if handler == nil then
        self.listeners[event_or_slot] = {}
        return true
    end

    expect_handler(handler)
    local removed = false
    for i = #list, 1, -1 do
        if list[i].handler == handler then
            table.remove(list, i)
            removed = true
        end
    end
    return removed
end

---@param event_name string
---@param payload? any
---@return number
function EventBus:emit(event_name, payload)
    expect_event_name(event_name)
    local list = self.listeners[event_name]
    if type(list) ~= "table" or #list == 0 then
        return 0
    end

    local snapshot = {}
    for i = 1, #list do
        snapshot[i] = list[i]
    end

    local called = 0
    for _, slot in ipairs(snapshot) do
        local still_registered = false
        for i = 1, #list do
            if list[i] == slot then
                still_registered = true
                break
            end
        end
        if still_registered then
            called = called + 1
            slot.handler(payload, event_name)
            if slot.once then
                remove_slot(list, slot)
            end
        end
    end
    return called
end

---@param event_name? string
function EventBus:clear(event_name)
    if event_name == nil then
        self.listeners = {}
        return
    end
    expect_event_name(event_name)
    self.listeners[event_name] = {}
end

return EventBus
end)()
Bundle.logger = (function()
local Logger = {}

local enabled = false

function Logger.set_enabled(value)
    enabled = value and true or false
end

function Logger.is_enabled()
    return enabled
end

function Logger.debug(...)
    if not enabled then
        return
    end
    print(...)
end

function Logger.info(...)
    Logger.debug(...)
end

function Logger.warn(...)
    Logger.debug(...)
end

function Logger.error(...)
    Logger.debug(...)
end

return Logger
end)()
Bundle.bridge = (function()
local Parts = {}

-- Logical roll events
Parts.roll_events = (function()
-- A logical roll exists only if the gameplay controller accepts the
-- mechanically settled dice. This module has no LOVE/physics dependencies.
local RollEvents={}
function RollEvents.complete(emit,accept,info)
 assert(type(emit)=='function' and type(info)=='table')
 emit('dice.physical_settled',info)
 local accepted=accept==nil or accept(info.values)==true
 if accepted then
  -- Historical observers still receive the legacy event, but never for a
  -- rejected weighted face or a technical physical reroll.
  emit('dice.roll_settled',info)
  emit('dice.roll_accepted',info)
 end
 return accepted
end
return RollEvents
end)()

-- Engine integration
Parts.bridge = (function()
local EngineBridge = {
    get_dice_tray_rect = nil,
    get_tray_die_hits = nil,
    pick_scriptorium_tray_die = nil,
    to_virtual_ui = nil,
    to_screen_ui = nil,
    event_bus = nil,
}

local HANDLER_KEYS = {
    get_dice_tray_rect = true,
    get_tray_die_hits = true,
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

-- Visible projected centers from the last 3D tray draw, for marquee
-- selection. Return a copy: caller must not mutate the live pick cache.
function EngineBridge.getTrayDieHits()
 local fn=EngineBridge.get_tray_die_hits
 if type(fn)~='function' then return {} end
 local ok,source=pcall(fn)
 if not ok or type(source)~='table' then return {} end
 local out={}
 for _,h in ipairs(source) do
  if type(h)=='table' and type(h.index)=='number' and
    type(h.x)=='number' and type(h.y)=='number' then
   out[#out+1]={index=h.index,x=h.x,y=h.y,r=h.r,depth=h.depth}
  end
 end
 return out
end

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
end)()

Parts.bridge.roll_events = Parts.roll_events
return Parts.bridge
end)()
Bundle.bridge.EventBus = Bundle.EventBus
Bundle.bridge.logger = Bundle.logger
return Bundle.bridge
