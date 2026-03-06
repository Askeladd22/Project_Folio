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
