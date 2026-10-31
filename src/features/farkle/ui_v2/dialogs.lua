local R=require('src.gameplay.farkle.rules')
local Medals=require('src.gameplay.farkle.medals')
local MedalPanel=require('src.features.farkle.medal_panel')
local D=require('src.features.farkle.dice')
local H=require('src.features.farkle.hud_model')
local Res=require('src.core.resolution_manager')
local Presentation=require('src.features.farkle.presentation')
local FolioView=require('src.features.farkle.folio_view')
-- Dialog/reward presenter for the canonical UI v2. This module owns modal hitboxes
-- but never draws the old work surface or implements a fallback HUD.
local V={};local fonts={}
local ink={.12,.075,.035,1};local cream={.96,.90,.76,1};local green={.18,.30,.23,1};local red={.56,.13,.10,1}
local function txt(s,x,y,w,size,c,align)
 local g=love.graphics;fonts[size]=fonts[size] or g.newFont(size);g.setFont(fonts[size]);g.setColor(unpack(c or ink));g.printf(tostring(s),x,y,w,align or 'left')
end
local function panel(x,y,w,h)
 local g=love.graphics;g.setColor(.08,.04,.02,.35);g.rectangle('fill',x+5,y+7,w,h,5)
 g.setColor(.96,.89,.74,1);g.rectangle('fill',x,y,w,h,3)
 g.setColor(.40,.26,.13,1);g.setLineWidth(2);g.rectangle('line',x,y,w,h,3)
 g.setLineWidth(1)
end
local function button(u,id,label,x,y,w,h,on,fn,primary)
 local g=love.graphics;local c=not on and {.73,.69,.60,1} or primary and green or {.96,.89,.73,1}
 local dieIndicator=id:match('^die%d$')
 if not dieIndicator or primary then
  g.setColor(unpack(c));g.rectangle('fill',x,y,w,h,4);g.setColor(.37,.24,.12);g.rectangle('line',x,y,w,h,4)
 elseif id~='die1' then
  g.setColor(.55,.39,.22);g.line(x-5,y+12,x-5,y+h-12)
 end
 local size=w<215 and 22 or 24
 fonts[size]=fonts[size] or g.newFont(size)
 local _,lines=fonts[size]:getWrap(label,w-28)
 txt(label,x+14,y+(h-#lines*fonts[size]:getHeight())/2,w-28,size,primary and on and cream or ink)
 if on and primary then g.setColor(.84,.66,.31,1);g.setLineWidth(2);g.rectangle('line',x+3,y+3,w-6,h-6,3);g.setLineWidth(1) end
 if not on and not dieIndicator then g.setColor(.32,.29,.23,1);g.line(x+8,y+8,x+8,y+h-8) end
 u.buttons[id]={x=x,y=y,w=w,h=h,enabled=on,fn=fn,label=label}
end
local function reward(u)
 local s=u.game;local g=love.graphics
 Res.begin_ui();g.setColor(.06,.035,.015,.78);g.rectangle('fill',0,0,1920,1080)
 u.buttons={};u.modalButtons={}
 panel(390,210,1140,650)
 txt('COMMISSION DELIVERED',440,245,1040,26,green)
 txt(s.phase=='upgrade' and 'Choose your die' or 'Choose your medal',440,295,1040,43)
 txt('Your choice carries into the next commission.',440,365,1040,25)
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
 panel(390,145,1140,800);u.modalButtons={}
 local saved=u.buttons;u.buttons=u.modalButtons
 button(u,'close','Close [Esc]',1295,175,205,56,true,function() u.modal=nil end)
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
