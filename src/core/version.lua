-- Single canonical Project Folio version from the repository's version.txt.
-- This is a pure module; normal LÖVE uses the mounted game filesystem.
local M={}
local current
function M.parse(value)
 if type(value)~='string' then return nil end
 local candidate=value:match('^%s*(.-)%s*$')
 local major,minor,patch,rest=candidate:match('^(%d+)%.(%d+)%.(%d+)(.*)$')
 if not major then return nil end
 if rest~='' and not rest:match('^%-[%w%.%-]+$') then return nil end
 if major:match('^0%d') or minor:match('^0%d') or patch:match('^0%d') then return nil end
 return candidate
end
function M.current()
 if current then return current end
 local content
 if love and love.filesystem and love.filesystem.read then
  content=love.filesystem.read('version.txt')
 else
  local file=assert(io.open('version.txt','rb'),'Missing Project Folio version.txt')
  content=file:read('*a')
  file:close()
 end
 current=assert(M.parse(content),'Invalid/missing Project Folio version.txt')
 return current
end
return M
