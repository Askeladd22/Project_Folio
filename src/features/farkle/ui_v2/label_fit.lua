-- Pure one-line typography helper for the illuminated Farkle UI.
-- Uses the actual font metrics supplied by the caller; no LÖVE dependency.
-- Never slices a UTF-8 glyph halfway through when shortening a long label.
local M={}

local function characters(text)
 local result={}
 local i=1
 while i<=#text do
  local b=text:byte(i)
  local n=(b and b>=240 and 4)
     or (b and b>=224 and 3)
     or (b and b>=194 and 2) or 1
  result[#result+1]=text:sub(i,i+n-1)
  i=i+n
 end
 return result
end

function M.fit(value,measure,preferred,minimum,max_width,max_height)
 assert(type(measure)=='function','font measure callback required')
 local text=tostring(value or '')
 local high=math.max(8,math.floor(preferred or 18))
 local low=math.max(8,math.min(high,math.floor(minimum or 12)))
 local w=math.max(0,max_width or 0)
 local h=math.max(0,max_height or 0)
 for px=high,low,-1 do
  local tw,th=measure(text,px)
  if tw<=w and th<=h then return text,px,false end
 end
 -- In tight layouts, height remains a hard boundary even if text is long.
 local px=low
 while px>8 do
  local _,th=measure('Hg',px)
  if th<=h then break end
  px=px-1
 end
 local _,height=measure('Hg',px)
 if height>h then return '',px,true end
 if measure(text,px)<=w then return text,px,false end
 local dots='...'
 if measure(dots,px)>w then return '',px,true end
 local glyphs=characters(text)
 local lo,hi=0,#glyphs
 while lo<hi do
  local mid=math.floor((lo+hi+1)*.5)
  local trial=table.concat(glyphs,'',1,mid)..dots
  if measure(trial,px)<=w then lo=mid
  else hi=mid-1 end
 end
 return table.concat(glyphs,'',1,lo)..dots,px,true
end

return M
