local R=require('src.gameplay.farkle.rules')
local Medals=require('src.gameplay.farkle.medals')
local MedalPanel=require('src.features.farkle.medal_panel')
local D=require('src.features.farkle.dice')
local H=require('src.features.farkle.hud_model')
local Res=require('src.core.resolution_manager')
local Desk=require('src.features.scriptorium.desk_view')
local PresentationView=require('src.features.farkle.presentation_view')
local Presentation=require('src.features.farkle.presentation')
local V={};local fonts={}
local ink={.12,.075,.035,1};local cream={.96,.90,.76,1};local green={.18,.30,.23,1};local red={.56,.13,.10,1}
local function txt(s,x,y,w,size,c)
 local g=love.graphics;fonts[size]=fonts[size] or g.newFont(size);g.setFont(fonts[size]);g.setColor(unpack(c or ink));g.printf(tostring(s),x,y,w,'left')
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
local boardWood
local function workboard()
 local g=love.graphics
 -- One continuous wooden object beneath tray, folio and edge controls.
 boardWood=boardWood or g.newImage('resources/textures/wood.png')
 g.setColor(.035,.02,.01,.65);g.rectangle('fill',24,30,1880,1050,24)
 g.setColor(.23,.13,.065);g.rectangle('fill',16,12,1888,1054,18)
 g.setColor(.56,.40,.25);g.draw(boardWood,28,24,0,1864/boardWood:getWidth(),1026/boardWood:getHeight())
 g.setColor(.10,.055,.025,.42);g.rectangle('fill',28,24,1864,1026)
 g.setColor(.54,.37,.20);g.setLineWidth(2);g.rectangle('line',27,23,1866,1028,10)
 -- Light rubbed wood on the two working edges, joined by the outer frame.
 g.setColor(.72,.57,.36);g.rectangle('fill',36,28,1848,110,6)
 g.setColor(.10,.055,.025,.65);g.line(36,141,1884,141)
 g.setColor(.72,.57,.36);g.rectangle('fill',40,870,1320,180,6)
 g.setColor(.10,.055,.025,.65);g.line(40,867,1360,867)
 -- The folio rests on the same board, with a narrow retaining lip.
 g.setColor(.08,.045,.02,.35);g.rectangle('fill',1422,187,470,590,5)
 g.setColor(.32,.19,.095);g.rectangle('fill',1420,803,450,12,3)
 g.setColor(.57,.39,.21);g.line(1424,803,1866,803)
 g.setLineWidth(1)
end
local function manuscript(s,x,y,w,h,presentation)
 require('src.features.farkle.folio_view').draw(s,presentation,x,y,w,h,txt,R.contracts[s.stage].target)
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
function V.draw(u)
 local s=u.game;if not s then return end
 local c=R.contracts[s.stage];local g=love.graphics;local rewardActive=H.reward_active(s)
 u.buttons={};Res.begin_ui()
 g.clear(.19,.12,.07,1)
 Desk.draw_layer('background',{x=0,y=0,w=1920,h=1080},function() end)
 Desk.draw_layer('desk',{x=0,y=0,w=1920,h=1080},function() end)
 g.setColor(.07,.035,.015,.28);g.rectangle('fill',0,0,1920,1080)
 workboard()
 txt('COMMISSION '..s.stage..' / 3',54,36,620,20)
 txt(c.name,54,64,620,30)
 txt(c.condition,54,104,680,19)
 txt('BANKED / TARGET',780,38,330,21)
 txt(s.bank..' / '..c.target,780,72,330,36,green)
 txt('TURNS LEFT',1145,38,220,21)
 txt(math.max(0,c.limit-s.turn+((s.phase=='ended' or H.commission_closed(s)) and 0 or 1)),1145,72,220,36)
 txt('AT RISK',1400,38,180,21)
 txt(s.pot,1400,72,180,36,red)
 button(u,'help','Rules [?]',1645,48,205,57,s.phase~='rolling',function() u.modal='help' end)
 -- The open folio is the second visual anchor, with no enclosing HUD column.
 manuscript(s,1410,175,470,590,u.presentation)
 txt('Dark ink: banked · faint: at risk',1435,778,420,21,cream)
 button(u,'folio','Inspect folio [F]',1435,820,420,60,s.phase~='rolling',function() u.modal='folio' end)
 local d=Medals.get(s.medal)
 if s.medal~='none' then
  local label=(d and d.label or 'Corrector')..' · '..Medals.remaining(s)..' uses left'
  button(u,'medaluse',label,1435,902,420,60,d~=nil and s.phase~='rolling' and not H.commission_closed(s),function() u.medalDice={};u.modal='medaluse' end)
 end
 if s.build~='normal' then txt(s.build=='engraved' and 'D1: 2 replaced by 1' or 'D1: weighted towards 1',1435,148,420,21,cream) end
 button(u,'runmenu','Run menu',1645,1024,205,46,s.phase~='rolling',function() u.modal='run' end)
 if rewardActive then u.buttons={};Res.end_ui();return end
 local eligible=H.eligible(s);local slots=H.slots
 PresentationView.rail()
 for i=1,6 do
  local x=slots.x+(i-1)*slots.step
  local value=s.phase=='rolling' and not s.used[i] and '...' or s.hand[i] or '-'
  local state=s.used[i] and 'held' or s.selected[i] and 'selected' or eligible[i] and 'scoring' or 'free'
  button(u,'die'..i,'',x,slots.y,slots.w,slots.h,s.phase=='ready' and not s.used[i],function() u:toggle(i) end,s.selected[i])
  local color=cream
  txt('['..i..'] '..value,x+8,slots.y+14,80,22,color)
  txt(state,x+94,slots.y+16,104,20,color)
 end
 local counting=PresentationView.contributions(u,txt)
 if not counting then
  local message=H.state_text(u)
  if s.phase=='ended' and u.presentation and u.presentation.conclusion and not u.physicalFailure then message=u.lastLoss~=nil and 'FARKLE · Turn over' or 'BANKED · Turn over' end
  txt(message,64,882,1272,24,(s.phase=='lost' or u.lastLoss~=nil and s.phase=='ended') and red or ink)
  if not u.physicalFailure then PresentationView.feedback(u,txt) end
 end
 if u.physicalFailure then
  button(u,'retryphysical','Retry physical roll',64,975,620,59,true,function() u:retry_physical() end,true)
 elseif s.phase=='rescue' then
  button(u,'rescue','Use medal [M]',64,975,620,59,true,function() u:request(true) end,true)
  button(u,'fail','Accept Farkle',714,975,620,59,true,function() u:act('accept_bust',function() return R.fail(s) end) end)
 elseif H.commission_closed(s) then
  if s.phase=='advance' then button(u,'next','Next commission [N]',64,975,1270,59,true,function() u:act('next',function() return R.advance(s) end) end,true) end
 elseif s.phase=='ended' then
  button(u,'next','Next turn [N]',64,975,1270,59,true,function() u:act('next',function() return R.next_turn(s) end) end,true)
 else
  local pts=R.selection(s);local canBank,total=R.bank_status(s)
  if s.phase=='ready' and next(s.selected) then
   local n=H.selected_count(s)
   button(u,'take',pts and ('Set aside '..n..(n==1 and ' die' or ' dice')..' · +'..pts..' [A]') or 'Set aside [A]',64,975,620,59,pts~=nil,function() u:act('take',function() return R.take(s) end) end,true)
  else
   button(u,'roll',s.hot and 'Hot dice [Space]' or s.phase=='fresh' and 'Roll [Space]' or 'Reroll [Space]',64,975,620,59,R.can_roll(s),function() u:request() end,true)
  end
  button(u,'bank','Bank '..total..' [Enter]',714,975,620,59,canBank,function() u:act('bank',function() return R.bank_turn(s) end) end)
 end
 if s.phase=='ready' then
  local choices=R.options(s)
  button(u,'choices','Scoring options ('..#choices..')',1435,s.medal~='none' and 967 or 902,420,50,#choices>0,function() u.choicePage=1;u.modal='choices' end)
 end
 local hint=s.phase=='ready' and R.can_roll(s) and string.format('Farkle risk %.1f%% · theoretical, excludes medals',100*D.risk(s.build,H.reroll_indices(s))) or '1–6: select · Tab: finish count · ?: rules'
 txt(hint,64,1054,1290,20,cream)
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
 if u.hud_variant~='minimal' then
  PresentationView.held(u,txt)
  require('src.features.farkle.tray_workshop').caption(txt)
 end
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
    txt('THE MANUSCRIPT',425,180,750,30);manuscript(s,665,245,510,625,u.presentation)
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
