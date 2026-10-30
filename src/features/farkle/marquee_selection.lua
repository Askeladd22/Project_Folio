-- Rectangle selection in screen coordinates. Separate from Farkle score selection.
-- Only hits whose centers lie inside the actual dragged rectangle are selected.
local M={}
local function finite(v)
 return type(v)=='number' and v==v and v~=math.huge and v~=-math.huge
end
local THRESHOLD=9
function M.begin(x,y)
 if not(finite(x) and finite(y)) then return nil end
 return {x0=x,y0=y,x=x,y=y}
end
function M.move(d,x,y)
 if not d or not(finite(x) and finite(y)) then return false end
 d.x,d.y=x,y
 return true
end
function M.rectangle(d)
 if not d then return nil end
 return {x=math.min(d.x0,d.x),y=math.min(d.y0,d.y),
   w=math.abs(d.x-d.x0),h=math.abs(d.y-d.y0)}
end
function M.dragged(d)
 local r=M.rectangle(d)
 return r and (r.w*r.w+r.h*r.h >= THRESHOLD*THRESHOLD) or false
end
function M.choose(d,hits,allowed)
 local r=M.rectangle(d)
 local selected={}
 if not r or not M.dragged(d) then return selected end
 for _,hit in ipairs(hits or {}) do
  local index=hit.index or hit.roll_index
  if type(index)=='number' and index%1==0 and index>=1 and
    finite(hit.x) and finite(hit.y) and
    hit.x>=r.x and hit.x<=r.x+r.w and
    hit.y>=r.y and hit.y<=r.y+r.h and
    (not allowed or allowed(index)) then
   selected[index]=true
  end
 end
 return selected
end
function M.count(indices)
 local n=0
 for _,value in pairs(indices or {}) do if value then n=n+1 end end
 return n
end
return M
