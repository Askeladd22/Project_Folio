-- A production HUD must depict committed stakes, not imagined dice outcomes.
-- Graphics are mocked; this checks the real HUD renderer and colors/widths.
local R=require('src.farkle.rules')
local P=require('src.farkle.presentation')
local UI=require('src.farkle.ui')
local Art=require('src.data.frontend_schema').palette
local Res=require('src.core.navigation').resolution
local Layout=UI.layout
local rect=Layout.build().stakes_track
assert(Layout.validate(Layout.build()))
local savedLove=love
local calls,color={},{}
local function fakeFont(px)
 px=type(px)=='number' and px or 18
 return {getWidth=function(_,s)return #tostring(s)*px*.50 end,
  getHeight=function()return px end,
  getWrap=function(_,s)return 100,{tostring(s)} end}
end
love={graphics=setmetatable({
 getDimensions=function()return 1920,1080 end,
 getWidth=function()return 1920 end,
 getHeight=function()return 1080 end,
 newFont=function(a,b)return fakeFont(b or a) end,
 getFont=function()return fakeFont(18) end,
 newImage=function()return {getWidth=function()return 944 end,
  getHeight=function()return 229 end}end,
 setColor=function(...)color={...}end,
 rectangle=function(mode,x,y,w,h)
  if mode=='fill' and y==rect.y and h==rect.h then
   calls[#calls+1]={x=x,y=y,w=w,h=h,color=color}
  end
 end,
},{__index=function()return function()end end}),
 mouse={getPosition=function()return 0,0 end}}
Res.init(1920,1080);Res.refresh(1920,1080)
local function sameRgb(a,b)
 for i=1,3 do if math.abs(a[i]-b[i])>0.0001 then return false end end
 return true
end
local function run(bank,pot)
 local s=R.new()
 s.bank,s.pot=bank,pot
 local u={game=s,presentation=P.new(s)}
 calls={}
 UI.hud.draw(u)
 assert(s.bank==bank and s.pot==pot,
  'the wager-track renderer must not mutate Farkle points')
 local safe,risky={},{}
 for _,c in ipairs(calls) do
  if sameRgb(c.color,Art.rgba('sage')) then safe[#safe+1]=c end
  if sameRgb(c.color,Art.rgba('clay')) then risky[#risky+1]=c end
  assert(c.x>=rect.x and c.x+c.w<=rect.x+rect.w+1e-6,
   'the progress track paints past its visual bounds')
 end
 return safe,risky
end
local function approx(a,b)
 return math.abs(a-b)<.01
end
local safe,risky=run(0,0)
assert(#safe==0 and #risky==0,
 'an untouched roll must show no earned or risky stake')
safe,risky=run(25,35)
assert(#safe==1 and #risky==1 and
 approx(safe[1].w,rect.w*.25) and
 approx(risky[1].w,rect.w*.35) and
 approx(risky[1].x,safe[1].x+safe[1].w),
 'secured and risky stakes must have separate proportional adjacent spans')
safe,risky=run(90,60)
assert(#safe==1 and #risky==1 and
 approx(safe[1].w,rect.w*.90) and
 approx(risky[1].w,rect.w*.10),
 'a risky stake must be clipped at the target, not overflow the HUD')
safe,risky=run(130,20)
assert(#safe==1 and #risky==0 and approx(safe[1].w,rect.w),
 'a secured total beyond target must fill but never exceed the track')

local selected=R.new()
assert(R.start(selected))
assert(R.settle(selected,{1,5,2,3,4,6}))
assert(R.toggle(selected,1))
calls={}
UI.hud.draw({game=selected,presentation=P.new(selected)})
for _,c in ipairs(calls) do
 assert(not sameRgb(c.color,Art.rgba('clay')),
  'a selection preview must not masquerade as committed pot points')
end
assert(selected.pot==0,'drawing a pending selection cannot take dice')
love=savedLove
print('PASS wager track: secured vs risky, clipping, untouched selection and read-only HUD')
