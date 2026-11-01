local R=require('src.gameplay.farkle.rules')
local Medals=require('src.gameplay.farkle.medals')
local MedalPanel=require('src.features.farkle.medal_panel')
local D=require('src.features.farkle.dice')
local H=require('src.features.farkle.hud_model')
local Res=require('src.core.resolution_manager')
local Presentation=require('src.features.farkle.presentation')
local FolioView=require('src.features.farkle.folio_view')
local MenuSurface=require('src.features.ui_v2.menu_surface')
local RuntimeUI=require('src.core.runtime_ui')
local ModalLayout=require('src.features.farkle.ui_v2.modal_layout')
local LabelFit=require('src.features.farkle.ui_v2.label_fit')
-- Dialog/reward presenter for the canonical UI v2. This module owns modal hitboxes
-- but never draws the old work surface or implements a fallback HUD.
local V={};local fonts={}
local ink={.24,.15,.09,1}
local muted={.47,.33,.22,1}
local gold={.57,.37,.13,1}
local green={.18,.30,.23,1}
local function sized(n)
 return math.max(8,math.floor(n*math.min(1.35,RuntimeUI.scale())*
  (RuntimeUI.big_text() and 1.16 or 1)+.5))
end
local function face(px)
 fonts[px]=fonts[px] or
  love.graphics.newFont('resources/font/IMFeENsc28P.ttf',px)
 return fonts[px]
end
-- Body paragraphs must preserve their existing wraps and deliberate line
-- breaks. Action labels instead use the measured single-line fitter below.
local function txt(s,x,y,w,size,c,align)
 local g=love.graphics
 g.setFont(face(size))
 g.setColor(unpack(c or ink))
 g.printf(tostring(s),x,y,w,align or 'left')
end
local function fitted(s,r,preferred,minimum,color,align)
 local g=love.graphics
 local label,px=LabelFit.fit(s,function(text,n)
  local f=face(n)
  return f:getWidth(text),f:getHeight()
 end,sized(preferred),sized(minimum),r.w,r.h)
 if label=='' then return end
 local f=face(px)
 g.setFont(f)
 g.setColor(unpack(color or ink))
 g.printf(label,r.x,r.y+math.max(0,(r.h-f:getHeight())*.5),
  r.w,align or 'center')
end
local function panel(x,y,w,h)
 MenuSurface.panel({x=x,y=y,w=w,h=h},
  {high_contrast=RuntimeUI.high_contrast()})
end
local function pointer_over(rect)
 if not love.mouse or not love.mouse.getPosition then return false end
 local mx,my=love.mouse.getPosition()
 if type(mx)~='number' or type(my)~='number' then return false end
 local vx,vy=Res.to_virtual(mx,my)
 return MenuSurface.contains(rect,vx,vy)
end
local function button(u,id,label,x,y,w,h,on,fn,primary)
 local rect={x=x,y=y,w=w,h=h}
 -- Same authoritative hitboxes/callbacks as the previous UI V2.
 -- Hover can never activate a disabled option.
 MenuSurface.item(rect,{active=on and (primary or pointer_over(rect)),
  primary=primary,disabled=not on})
 fitted(label,{x=x+14,y=y+6,w=w-28,h=h-12},
  w<215 and 22 or 24,13,on and ink or muted,'center')
 u.buttons[id]={x=x,y=y,w=w,h=h,enabled=on,fn=fn,label=label}
end
local function reward(u)
 local s=u.game;local g=love.graphics
 Res.begin_ui();g.setColor(.06,.035,.015,.78);g.rectangle('fill',0,0,1920,1080)
 u.buttons={};u.modalButtons={}
 local area=ModalLayout.reward_frame
 panel(area.x,area.y,area.w,area.h)
 txt('COMMISSION DELIVERED',440,245,1040,26,green)
 txt(s.phase=='upgrade' and 'Choose your die' or 'Choose your medal',440,295,1040,43)
 txt('Your choice carries into the next commission.',440,365,1040,25)
 MenuSurface.rule(ModalLayout.reward_rule.x,ModalLayout.reward_rule.y,
  ModalLayout.reward_rule.w,RuntimeUI.high_contrast() and 1 or .85)
 for _,card in ipairs(ModalLayout.reward_cards) do
  MenuSurface.panel(card,{high_contrast=RuntimeUI.high_contrast()})
 end
 if s.phase=='upgrade' then
  txt('WEIGHTED DIE',450,465,470,29)
  txt('Die 1 favours rolling a 1.\nIts numbered faces stay unchanged.',450,520,470,26)
  txt('ENGRAVED DIE',1010,465,470,29)
  txt('Replace the 2 on die 1 with a 1.\nThe new face counts in combinations.',1010,520,470,26)
  button(u,'weighted','Choose weighted die',440,685,490,85,true,function() R.choose_build(s,'weighted');D.install(s.build);u:sync();u:log('upgrade') end,true)
  button(u,'engraved','Choose engraved die',990,685,490,85,true,function() R.choose_build(s,'engraved');D.install(s.build);u:sync();u:log('upgrade') end,true)
 else
  txt('CORRECTOR',450,465,470,29)
  txt('One second chance after a Farkle.\nReroll the same dice once per commission.',450,520,470,26)
  txt('NO MEDAL',1010,465,470,29)
  txt('Continue with your current dice\nand no additional effect.',1010,520,470,26)
  button(u,'medal','Equip the Corrector',440,685,490,85,true,function() R.choose_medal(s,'retry');u:sync();u:log('medal') end,true)
  button(u,'none','Continue without a medal',990,685,490,85,true,function() R.choose_medal(s,'none');u:sync();u:log('no_medal') end)
 end
 Res.end_ui()
end
function V.overlay(u,hits)
 u.hits=hits
 local g=love.graphics;local s=u.game
 local eligible=H.eligible(s)
 -- Only unobtrusive outlines on the 3D dice; all text stays outside the tray.
 for _,h in ipairs(hits or {}) do local i=h.index or h.roll_index
  if i and (s.selected[i] or s.used[i] or eligible[i]) then
   g.setColor(unpack(s.selected[i] and {1,.79,.30,1} or s.used[i] and {.65,.8,.63,.85} or {.95,.84,.56,.48}));g.setLineWidth(s.selected[i] and 3 or 1)
   g.circle('line',h.x,h.y,(h.r or 25)+4)
  end
 end
 g.setLineWidth(1)
if H.reward_active(s) then reward(u);return end
 if not u.modal then return end
 Res.begin_ui();g.setColor(.05,.025,.01,.82);g.rectangle('fill',0,0,1920,1080)
 local area=ModalLayout.frame
 panel(area.x,area.y,area.w,area.h);u.modalButtons={}
 local saved=u.buttons;u.buttons=u.modalButtons
 local close=ModalLayout.close
 button(u,'close','Close [Esc]',close.x,close.y,close.w,close.h,
  true,function() u.modal=nil end)
 MenuSurface.rule(ModalLayout.header_rule.x,ModalLayout.header_rule.y,
  ModalLayout.header_rule.w,RuntimeUI.high_contrast() and 1 or .8)
 if u.modal=='run' then
  txt('RUN MENU',425,180,800,30)
  txt('Starting a new run abandons the current one.',440,285,1040,26)
  button(u,'restart','New run with modifiers',440,390,1040,70,true,function() u:reset('build') end)
  button(u,'control','Without modifiers: new comparison run',440,490,1040,70,true,function() u:reset('control') end)
  button(u,'medals','Medal laboratory',440,590,1040,70,not u.physicalFailure,function() u.modal='medals';u.medalPage=1;u.medalPreview=nil end)
  txt('Close to return to the game without making changes.',440,710,1040,24)
 elseif u.modal=='medals' or u.modal=='medaluse' then
  MedalPanel.draw(u,txt,button)
 elseif u.modal=='folio' then
    txt('THE MANUSCRIPT',425,180,750,30)
    -- Same folio renderer used by the in-game side panel; the previous
    -- unbound manuscript(...) call crashed every time this modal opened.
    FolioView.draw(s,u.presentation,665,245,510,625,txt,R.contracts[s.stage].target)
    txt(R.contracts[s.stage].condition,435,892,1050,24)
 elseif u.modal=='choices' then
  txt('CURRENT ROLL OPTIONS',425,180,800,30)
  local choices=R.options(s);local pages=math.max(1,math.ceil(#choices/7))
  u.choicePage=math.max(1,math.min(u.choicePage or 1,pages))
  txt('Choose dice, then Set aside or Bank. You can also click dice directly.',440,245,1040,23)
  for row=1,7 do local o=choices[(u.choicePage-1)*7+row];if o then
   button(u,'option'..row,H.option_text(o),440,290+(row-1)*72,1040,66,true,function() if u:select_option(o.mask) then u.modal=nil end end)
  end end
  button(u,'prev','Previous',440,830,240,60,u.choicePage>1,function() u.choicePage=u.choicePage-1 end)
  txt('Page '..u.choicePage..' / '..pages,745,845,250,25)
  button(u,'nextpage','Next',1190,830,290,60,u.choicePage<pages,function() u.choicePage=u.choicePage+1 end) else
  txt('FARKLE RULES',425,180,800,30)
  local sections=H.help_sections(s);u.helpTab=math.max(1,math.min(3,u.helpTab or 1))
  for i,section in ipairs(sections) do
   button(u,'helpTab'..i,section.title,425+(i-1)*360,250,350,60,true,function() u.helpTab=i end,u.helpTab==i)
  end
  local section=sections[u.helpTab]
  if section.rows then
   txt(section.lines[1],445,337,1030,27)
   local headers={'Face','Three of a kind','Four of a kind','Five of a kind','Six of a kind'}
   for j,label in ipairs(headers) do txt(label,445+(j-1)*210,392,200,25) end
   for i,row in ipairs(section.rows) do
    g.setColor(i%2==0 and .88 or .94,.82,.66,1);g.rectangle('fill',435,432+(i-1)*47,1060,47)
    for j,value in ipairs(row) do txt(value,445+(j-1)*210,439+(i-1)*47,200,26) end
   end
   txt(section.lines[2],445,745,1030,26);txt(section.lines[3],445,800,1030,26)
  else
   for i,line in ipairs(section.lines) do txt(line,445,342+(i-1)*76,1030,26) end
  end
  txt('Left/right arrows: change tab · Esc: close',445,900,1030,22)

 end
 u.buttons=saved;Res.end_ui()
end
return V
