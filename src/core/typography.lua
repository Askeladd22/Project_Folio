-- Project Folio typography: facsimile Aldine Aetna + readable Roman fallback.
-- Load both as TTF fonts: LÖVE's setFallbacks substitutes individual glyphs,
-- rather than replacing a whole label when one character is missing.
local M={}
M.primary='resources/font/AldineAetna-Regular.ttf'
M.support='resources/font/Cardo-Regular.ttf'
local linked=setmetatable({},{__mode='k'})

function M.load(path,size)
 assert(type(path)=='string' and path~='','font path required')
 assert(type(size)=='number' and size>0,'positive font size required')
 local font=love.graphics.newFont(path,size)
 if path==M.primary then
  local secondary=love.graphics.newFont(M.support,size)
  -- Test graphics stubs may not implement this native LÖVE method.
  -- The production Font always does (LÖVE >= 0.10).
  if font.setFallbacks then font:setFallbacks(secondary) end
  linked[font]=secondary
 end
 return font
end
return M
