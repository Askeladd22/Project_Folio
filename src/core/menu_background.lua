-- Shared frontend illustration resolver.
-- Pure loader: no asset data, no text, no changes to input/layout.
-- A missing/corrupt optional PNG can never make a menu fail to start.
local M = {}
function M.load(preferred, fallback)
    if not love or not love.filesystem or not love.graphics then
        return nil, nil
    end
    local getInfo = love.filesystem.getInfo
    local newImage = love.graphics.newImage
    if type(getInfo) ~= 'function' or type(newImage) ~= 'function' then
        return nil, nil
    end
    local seen = {}
    for _,path in ipairs({preferred, fallback}) do
        if type(path) == 'string' and path ~= '' and not seen[path] then
            seen[path] = true
            local exists, info = pcall(getInfo, path)
            if exists and info then
                local ok, image = pcall(newImage, path)
                if ok and image then return image, path end
            end
        end
    end
    return nil, nil
end
return M
