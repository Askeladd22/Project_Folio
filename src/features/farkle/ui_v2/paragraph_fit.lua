-- Pure bounded paragraph typography for the shipping Folio modal UI.
-- Never changes game state, buttons or the real LÖVE font metrics.
local M={}

local function glyphs(text)
 local result={}
 local i=1
 while i<=#text do
  local byte=text:byte(i)
  local count=(byte>=240 and 4) or (byte>=224 and 3)
    or (byte>=194 and 2) or 1
  result[#result+1]=text:sub(i,i+count-1)
  i=i+count
 end
 return result
end

local function fits(value,measure,px,width,height)
 local count,lineHeight,longest=measure(value,px,width)
 count=math.max(1,count or 1)
 lineHeight=math.max(0,lineHeight or 0)
 return count*lineHeight<=height and (longest or 0)<=width,
  count
end

-- measure(text,px,width) returns line count, line step and widest line;
-- callers use actual Font:getWrap / getHeight / getLineHeight.
-- Returns printable text, font pixels, line count and a clipped flag.
function M.fit(value,measure,preferred,minimum,width,height)
 assert(type(measure)=='function','paragraph measure callback required')
 local text=tostring(value or '')
 local w=math.max(0,width or 0)
 local h=math.max(0,height or 0)
 local hi=math.max(8,math.floor(preferred or 22))
 local low=math.max(8,math.min(hi,math.floor(minimum or 12)))
 if text=='' or w<=0 or h<=0 then return '',low,0,text~='' end
 for px=hi,low,-1 do
  local ok,count=fits(text,measure,px,w,h)
  if ok then return text,px,count,false end
 end
 -- Very small viewports or unusually verbose experimental descriptions:
 -- trim by whole UTF-8 glyph, never leak words into the next UI control.
 local px=low
 while px>8 do
  local _,step=measure('Hg',px,w)
  if step and step<=h then break end
  px=px-1
 end
 local dots='...'
 local ok,lines=fits(dots,measure,px,w,h)
 if not ok then return '',px,0,true end
 local chars=glyphs(text)
 local left,right=0,#chars
 while left<right do
  local mid=math.floor((left+right+1)/2)
  local candidate=table.concat(chars,'',1,mid)..dots
  if fits(candidate,measure,px,w,h) then left=mid
  else right=mid-1 end
 end
 local result=table.concat(chars,'',1,left)..dots
 local _,count=fits(result,measure,px,w,h)
 return result,px,count,true
end

return M
