-- Pure paragraph fitter regression: real run uses LOVE font:getWrap,
-- but this test intentionally has no drawing or gameplay dependencies.
local F=require('src.features.farkle.ui_v2.paragraph_fit')
local function measure(text,px,width)
 local count,longest=0,0
 for line in (text..'\n'):gmatch('([^\n]*)\n') do
  local tw=#line*px*.53
  local n=math.max(1,math.ceil(tw/math.max(1,width)))
  count=count+n
  longest=math.max(longest,math.min(tw,width))
 end
 return count,px*1.15,longest
end
local example='Long descriptions should remain on the manuscript page, even with big text enabled.'
local text,px,rows,cut=F.fit(example,measure,36,14,420,132)
assert(text==example and px<36 and px>=14 and rows>=2 and not cut,
 'ordinary long paragraphs should shrink before cutting words')
local repeated='First line\nSecond line'
local plain,_,lines,clipped=F.fit(repeated,measure,26,12,470,128)
assert(plain==repeated and lines>=2 and not clipped,
 'explicit newlines in reward card descriptions must survive fitting')
local narrow='Un testo con lettere accentate: '..string.rep('è',80)
local shortened,_,_,didCut=F.fit(narrow,measure,30,18,110,45)
assert(didCut and shortened:sub(-3)=='...')
-- Ending cannot contain a leading byte of a multi-byte character without
-- its continuation. This is stricter than merely checking printed length.
local prefix=shortened:sub(1,-4)
local function valid_utf8(value)
 local pos=1
 while pos<=#value do
  local b=value:byte(pos)
  local n=b>=240 and 4 or b>=224 and 3 or b>=194 and 2 or 1
  if pos+n-1>#value then return false end
  for k=2,n do
   local v=value:byte(pos+k-1)
   if not v or v<128 or v>=192 then return false end
  end
  pos=pos+n
 end
 return true
end
assert(valid_utf8(prefix),'paragraph abbreviation split an accented glyph')
local empty=F.fit('content',measure,20,12,0,100)
assert(empty=='','zero-width region must paint no text')
local lower=F.fit('content',measure,20,12,100,0)
assert(lower=='','zero-height region must paint no text')
local huge='Very long status: '..string.rep('long text. ',120)
local shrink,sp,sl,sCut=F.fit(huge,measure,28,12,200,50)
assert(sCut and #shrink<#huge and sp<=12 and sl*sp*1.15<=50,
 'overflow must be bounded and visibly abbreviated')
print('PASS UI V2 bounded paragraph fitting: wraps, explicit newlines, big fonts, UTF-8 shortening and hard geometry limits')
