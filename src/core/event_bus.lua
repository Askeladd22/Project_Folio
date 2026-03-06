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
