local Navigation = {}

local route_handler = nil

---@param handler? fun(name: string, params: table|nil): boolean|nil
function Navigation.configure(handler)
    assert(handler == nil or type(handler) == "function", "Navigation handler must be a function or nil")
    route_handler = handler
end

---@param name string
---@param params? table
---@return boolean, string?
function Navigation.go(name, params)
    if type(route_handler) ~= "function" then
        return false, "Navigation handler not configured"
    end
    route_handler(name, params)
    return true
end

function Navigation.is_configured()
    return type(route_handler) == "function"
end

return Navigation
