-- Shared frontend illustration resolver.
-- Pure loader: no asset data, no text, no changes to input/layout.
-- A missing/corrupt optional PNG can never make a menu fail to start.
local M = {}
function M.load(preferred, fallback, legacy)
    if not love or not love.filesystem or not love.graphics then
        return nil, nil
    end
    local getInfo = love.filesystem.getInfo
    local newImage = love.graphics.newImage
    if type(getInfo) ~= 'function' or type(newImage) ~= 'function' then
        return nil, nil
    end
    local seen = {}
    for _,path in ipairs({preferred, fallback, legacy}) do
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
-- Keep the authored illustration's blank left margin visible when
-- covering non-widescreen windows. Legacy backgrounds stay centered.
function M.cover_rect(image,w,h,keep_left)
    if not image or w<=0 or h<=0 then return nil end
    local bw,bh=image:getWidth(),image:getHeight()
    if bw<=0 or bh<=0 then return nil end
    local scale=math.max(w/bw,h/bh)
    local dw,dh=bw*scale,bh*scale
    local x=(w-dw)*.5
    if keep_left and dw>w then x=0 end
    return x,(h-dh)*.5,scale
end

-- Reserve the leftmost ~32.5% of the illustrated print shop as quiet
-- space for the parchment navigation. Keep press, workers and typecases
-- visible without disturbing the layout or mouse hitboxes.
function M.left_panel_limit(image,w,h,left)
    if not image then return nil end
    local x,_,scale=M.cover_rect(image,w,h,true)
    if not x then return nil end
    local safe_right=x+image:getWidth()*.325*scale
    local gap=math.max(10,h*.016)
    return math.max(0,math.floor(safe_right-left-gap))
end

return M
