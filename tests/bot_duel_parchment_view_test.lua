-- Visual-only Monk duel UI V2: both live ledger and finished modal.
-- The miniature is stubbed: no physical D6, renderer, RNG or rules involved.
local Geometry=require('src.features.farkle.ui_v2.monk_layout')
local Layout=require('src.features.farkle.ui_v2.layout_candidates')
local Model=require('src.features.farkle.bot_duel_presentation')
local Res=require('src.core.resolution_manager')
local UI=require('src.core.runtime_ui')
local ok,reason=Geometry.validate()
assert(ok,reason)
local base=Layout.build('single_folio')
assert(Layout.overlap(Geometry.status_panel,base.tray)==0)
assert(Layout.overlap(Geometry.status_panel,base.context)==0)
assert(Geometry.status_panel.y+Geometry.status_panel.h<=320,
 'Monk status must not cover the short folio in duels')
assert(Geometry.retry.x==780 and Geometry.retry.y==540
  and Geometry.retry.w==350 and Geometry.retry.h==45,
 'restart click region must match controller exactly')

local viewSource=assert(io.open('src/features/farkle/bot_duel_view.lua','rb'))
local src=viewSource:read('*a');viewSource:close()
assert(src:find('MenuSurface.panel',1,true))
assert(src:find('MenuSurface.item',1,true))
assert(src:find('LabelFit.fit',1,true))
assert(src:find('monk:return_to_page',1,true))
assert(not src:find('src.engine3d.render',1,true))
local ctlFile=assert(io.open('src/features/farkle/controller.lua','rb'))
local ctl=ctlFile:read('*a');ctlFile:close()
assert(ctl:find('vx>=780 and vx<=1130 and vy>=540 and vy<=585',1,true))
assert(ctl:find("if k=='r' then self:reset('control')",1,true))

local originalLove=love
local oldMiniature=package.loaded['src.features.scriptorium.miniature_2d']
local originalScale=UI.scale
local originalBig=UI.big_text
local originalContrast=UI.high_contrast
local originalReduce=UI.reduced_animations
local bigText=false
local highContrast=false
UI.scale=function()return 1 end
UI.big_text=function()return bigText end
UI.high_contrast=function()return highContrast end
UI.reduced_animations=function()return true end

local figureCount,returnCount=0,0
package.loaded['src.features.scriptorium.miniature_2d']={
 new=function(canvas,opts)
  figureCount=figureCount+1
  assert(opts.frameWidth==72 and opts.frameHeight==120)
  return {
   draw=function()end,
   update=function()end,
   move_to=function()end,
   return_to_page=function()
    returnCount=returnCount+1
   end,
  }
 end
}
local width,height=1920,1080
local presses,pops=0,0
local lastFont=nil
local calls={}
local mouseX,mouseY=nil,nil
local function f(size)
 size=type(size)=='number' and size or 18
 return {
  getWidth=function(_,str)return #tostring(str)*size*.52 end,
  getHeight=function()return size*1.14 end,
  getWrap=function(_,str)return #tostring(str)*size*.52,{tostring(str)}end
 }
end
local graphics=setmetatable({
 getWidth=function()return width end,
 getHeight=function()return height end,
 getDimensions=function()return width,height end,
 newFont=function(a,b)return f(b or a)end,
 getFont=function()return f(18)end,
 setFont=function(face)lastFont=face end,
 newCanvas=function()return {}end,
 push=function()presses=presses+1 end,
 pop=function()pops=pops+1 end,
 rectangle=function(mode,x,y,w,h)
  calls[#calls+1]={kind='rect',mode=mode,x=x,y=y,w=w,h=h}
 end,
 printf=function(value,x,y,w)
  local txt=tostring(value)
  calls[#calls+1]={kind='text',text=txt,x=x,y=y,
   w=w,h=lastFont and lastFont:getHeight() or 0,
   width=lastFont and lastFont:getWidth(txt) or 0}
 end,
},{__index=function()return function()end end})
love={graphics=graphics,mouse={getPosition=function()return mouseX,mouseY end}}
local View=require('src.features.farkle.bot_duel_view')
local function same_rect(r)
 for _,v in ipairs(calls) do
  if v.kind=='rect' and v.mode=='fill' and
   v.x==r.x and v.y==r.y and v.w==r.w and v.h==r.h then
   return true
  end
 end
 return false
end
local function text_inside(r,label)
 for _,v in ipairs(calls) do
  if v.kind=='text' and v.text:find(label,1,true) and
   v.x>=r.x and v.x+v.w<=r.x+r.w+1 and
   v.y>=r.y and v.y+v.h<=r.y+r.h+1 and
   v.width<=v.w+1 then return true end
 end
 return false
end
for _,screen in ipairs{{1280,720},{1920,1080},{2560,1440}} do
 width,height=screen[1],screen[2]
 Res.init(1920,1080)
 Res.refresh(width,height)
 for _,access in ipairs{{false,false},{true,true}} do
  bigText,highContrast=access[1],access[2]
  View.reset()
  calls={}
  local before=figureCount
  View.draw(true)
  assert(figureCount==before+1,'Monk miniature not initialized')
  assert(presses==pops,'LÖVE draw state leaked')
  assert(same_rect(Geometry.status_panel),
   'Monk ledger must be drawn on shared parchment')
  assert(not same_rect(Geometry.result_panel),
   'result modal must not cover play while duel is active')
  assert(text_inside(Geometry.title,'SFIDA AL MONACO'))
  assert(text_inside(Geometry.score,'TU:'))
  assert(text_inside(Geometry.round,'MANO'))
  assert(text_inside(Geometry.last_roll,'Ultimo tiro:'))
  assert(text_inside(Geometry.status,'Il monaco'))

  -- Use the real event presentation path; the view may only observe it.
  local evt={
   report={turn=1,rolls=1,banked=35,loss=false,
    faces={{1,2,3,4,5,6}}},
   player=80,bot=35,finished=true,winner='player',
  }
  assert(View.on_turn(evt))
  assert(returnCount>0,'winning must still send miniature into folio')
  calls={}
  mouseX,mouseY=Res.to_screen(Geometry.retry.x+175,
    Geometry.retry.y+22)
  View.draw(true)
  assert(presses==pops)
  assert(same_rect(Geometry.status_panel))
  assert(same_rect(Geometry.result_panel))
  assert(same_rect(Geometry.retry),'original restart zone must be painted')
  assert(text_inside(Geometry.result_title,'HAI VINTO!'))
  assert(text_inside(Geometry.result_help,'R: nuova sfida'))
  assert(text_inside(Geometry.retry_label,'RIPROVA'))
  assert(text_inside(Geometry.score,'TU: 80'))
  assert(text_inside(Geometry.status,'Sconfitto:'))
 end
end
-- Bot win and tie share the exact same modal, but not the title.
for _,c in ipairs{{'bot','IL MONACO HA VINTO'},{'tie','PARITA'}} do
 View.reset()
 calls={}
 assert(View.on_turn({report={turn=1,rolls=1,loss=false,banked=625,
  faces={{1,1,1,1,1,1}}},player=10,bot=625,finished=true,
  winner=c[1]}))
 View.draw(true)
 assert(text_inside(Geometry.result_title,c[2]))
end
View.reset()
UI.scale=originalScale
UI.big_text=originalBig
UI.high_contrast=originalContrast
UI.reduced_animations=originalReduce
love=originalLove
package.loaded['src.features.scriptorium.miniature_2d']=oldMiniature
print('PASS Monk parchment ledger/result, restart hitbox, optional figure, big text/high contrast and 720p/1080p/1440p')
