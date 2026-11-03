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
local ParagraphFit=require('src.features.farkle.ui_v2.paragraph_fit')
local Art=require('src.data.art_palette')
local Navigation=require('src.core.navigation')
-- Dialog/reward presenter for the canonical UI v2. This module owns modal hitboxes
-- but never draws the old work surface or implements a fallback HUD.
local V={};local fonts={}
local ink=Art.rgba('text')
local muted=Art.rgba('text_muted')
local gold=Art.rgba('reward')
local green=Art.rgba('forest')
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
-- Multi-line paragraphs use actual wrap metrics and a bounded cell.
-- Unlike txt (also used by FolioView), the whole paragraph must fit
-- vertically before drawing, even when big text is enabled.
local function paragraph(value,x,y,w,h,preferred,minimum,color,align)
 local g=love.graphics
 local content,px=ParagraphFit.fit(value,function(text,n,width)
  local f=face(n)
  local widest,lines=f:getWrap(text,width)
  local spacing=f.getLineHeight and f:getLineHeight() or 1
  return #lines,f:getHeight()*spacing,widest
 end,sized(preferred),sized(minimum),w,h)
 if content=='' then return end
 g.setFont(face(px))
 g.setColor(unpack(color or ink))
 g.printf(content,x,y,w,align or 'left')
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

-- The normal pause menu never exposes balancing/comparison developer tools.
local function pause_button(u,id,label,r,fn,primary)
  local g=love.graphics
  if primary then
    g.setColor(unpack(Art.rgba('surface_alt',.92)))
    g.rectangle('fill',r.x,r.y,r.w,r.h)
  end
  MenuSurface.item(r,{style='editorial',active=pointer_over(r)})
  fitted(label,{x=r.x+14,y=r.y+6,w=r.w-28,h=r.h-12},
    id=='close' and 17 or 25,14,ink,'center')
  u.buttons[id]={x=r.x,y=r.y,w=r.w,h=r.h,enabled=true,fn=fn,label=label}
end
local function draw_pause(u)
  local g=love.graphics
  local saved=u.buttons
  u.modalButtons={}
  u.buttons=u.modalButtons
  g.push('all')
  Res.begin_ui()
  g.setColor(unpack(Art.rgba('ink',.68)))
  g.rectangle('fill',0,0,1920,1080)
  local confirming=u.modal=='run_restart_confirm' or u.modal=='run_exit_confirm'
  local frame=confirming and ModalLayout.pause_confirm_frame
    or ModalLayout.pause_frame
  MenuSurface.panel(frame,{style='editorial',
    high_contrast=RuntimeUI.high_contrast()})
  local closeRect=confirming and ModalLayout.pause_confirm_close
    or ModalLayout.pause_close
  pause_button(u,'close','Chiudi [Esc]',closeRect,
    function() u.modal=confirming and 'run' or nil end)
  if not confirming then
    fitted('PARTITA IN PAUSA',ModalLayout.pause_title,33,22,ink,'left')
    fitted('Scegli come proseguire.',ModalLayout.pause_intro,
      21,15,muted,'left')
    local items=ModalLayout.pause_items
    pause_button(u,'resume','Riprendi la partita',items[1],
      function() u.modal=nil end,true)
    pause_button(u,'settings','Impostazioni',items[2],
      function()
        u.modal=nil
        Navigation.go('settings',{return_to='scriptorium'})
      end)
    pause_button(u,'restart','Ricomincia la partita',items[3],
      function() u.modal='run_restart_confirm' end)
    pause_button(u,'mainmenu','Torna al menu principale',items[4],
      function() u.modal='run_exit_confirm' end)
    paragraph('La partita non dispone ancora di un salvataggio automatico.',
      frame.x+54,frame.y+508,frame.w-108,64,19,14,muted,'center')
  else
    local restarting=u.modal=='run_restart_confirm'
    fitted(restarting and 'RICOMINCIARE?' or 'TORNARE AL MENU?',
      ModalLayout.pause_confirm_title,31,19,ink,'left')
    paragraph(restarting
      and 'I progressi della partita corrente andranno perduti. La modalità di gioco resterà invariata.'
      or 'I progressi non salvati andranno perduti. Potrai iniziare una nuova partita dal menu principale.',
      frame.x+55,frame.y+132,frame.w-110,126,24,16,muted,'left')
    pause_button(u,'cancel','Annulla',ModalLayout.pause_confirm_actions[1],
      function() u.modal='run' end,true)
    if restarting then
      pause_button(u,'confirmrestart','Conferma riavvio',
        ModalLayout.pause_confirm_actions[2],function()
          local mode=(u.duelActive or u.botDuel) and 'control'
            or (u.game and u.game.mode) or 'build'
          u:reset(mode)
        end)
    else
      pause_button(u,'confirmexit','Conferma uscita',
        ModalLayout.pause_confirm_actions[2],function()
          u.modal=nil
          Navigation.go('main_menu')
        end)
    end
  end
  Res.end_ui()
  g.pop()
  u.buttons=saved
end

local function reward(u)
 local s=u.game;local g=love.graphics
 Res.begin_ui();g.setColor(unpack(Art.rgba('ink',.78)));g.rectangle('fill',0,0,1920,1080)
 u.buttons={};u.modalButtons={}
 local area=ModalLayout.reward_frame
 panel(area.x,area.y,area.w,area.h)
 txt('COMMISSION DELIVERED',440,245,1040,26,green)
 txt(s.phase=='upgrade' and 'Choose your die' or 'Choose your medal',440,295,1040,43)
 paragraph('Your choice carries into the next commission.',440,359,1040,50,25,17)
 MenuSurface.rule(ModalLayout.reward_rule.x,ModalLayout.reward_rule.y,
  ModalLayout.reward_rule.w,RuntimeUI.high_contrast() and 1 or .85)
 for _,card in ipairs(ModalLayout.reward_cards) do
  MenuSurface.panel(card,{high_contrast=RuntimeUI.high_contrast()})
 end
 if s.phase=='upgrade' then
  fitted('WEIGHTED DIE',{x=450,y=458,w=470,h=38},29,18,ink,'left')
  paragraph('Die 1 favours rolling a 1.\nIts numbered faces stay unchanged.',450,516,470,126,26,17)
  fitted('ENGRAVED DIE',{x=1010,y=458,w=470,h=38},29,18,ink,'left')
  paragraph('Replace the 2 on die 1 with a 1.\nThe new face counts in combinations.',1010,516,470,126,26,17)
  button(u,'weighted','Choose weighted die',440,685,490,85,true,function() R.choose_build(s,'weighted');D.install(s.build);u:sync();u:log('upgrade') end,true)
  button(u,'engraved','Choose engraved die',990,685,490,85,true,function() R.choose_build(s,'engraved');D.install(s.build);u:sync();u:log('upgrade') end,true)
 else
  fitted('CORRECTOR',{x=450,y=458,w=470,h=38},29,18,ink,'left')
  paragraph('One second chance after a Farkle.\nReroll the same dice once per commission.',450,516,470,126,26,17)
  fitted('NO MEDAL',{x=1010,y=458,w=470,h=38},29,18,ink,'left')
  paragraph('Continue with your current dice\nand no additional effect.',1010,516,470,126,26,17)
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
   g.setColor(unpack(s.selected[i] and Art.rgba('ochre_light',1)
     or s.used[i] and Art.rgba('sage_light',.85)
     or Art.rgba('ochre_light',.55)))
   g.setLineWidth(s.selected[i] and 3 or 1)
   g.circle('line',h.x,h.y,(h.r or 25)+4)
  end
 end
 g.setLineWidth(1)
if H.reward_active(s) then reward(u);return end
 if not u.modal then return end
 if u.modal=='run' or u.modal=='run_restart_confirm'
  or u.modal=='run_exit_confirm' then
  draw_pause(u)
  return
 end
 Res.begin_ui();g.setColor(unpack(Art.rgba('ink',.82)));g.rectangle('fill',0,0,1920,1080)
 local area=ModalLayout.frame
 panel(area.x,area.y,area.w,area.h);u.modalButtons={}
 local saved=u.buttons;u.buttons=u.modalButtons
 local close=ModalLayout.close
 button(u,'close','Close [Esc]',close.x,close.y,close.w,close.h,
  true,function() u.modal=nil end)
 MenuSurface.rule(ModalLayout.header_rule.x,ModalLayout.header_rule.y,
  ModalLayout.header_rule.w,RuntimeUI.high_contrast() and 1 or .8)
 if u.modal=='medals' or u.modal=='medaluse' then
  MedalPanel.draw(u,txt,button,paragraph)
 elseif u.modal=='folio' then
    txt('THE MANUSCRIPT',425,180,750,30)
    -- Same folio renderer used by the in-game side panel; the previous
    -- unbound manuscript(...) call crashed every time this modal opened.
    FolioView.draw(s,u.presentation,665,245,510,625,txt,R.contracts[s.stage].target)
    paragraph(R.contracts[s.stage].condition,435,882,1050,49,24,15)
 elseif u.modal=='choices' then
  txt('CURRENT ROLL OPTIONS',425,180,800,30)
  local choices=R.options(s);local pages=math.max(1,math.ceil(#choices/7))
  u.choicePage=math.max(1,math.min(u.choicePage or 1,pages))
  paragraph('Choose dice, then Set aside or Bank. You can also click dice directly.',440,240,1040,49,23,16)
  for row=1,7 do local o=choices[(u.choicePage-1)*7+row];if o then
   button(u,'option'..row,H.option_text(o),440,290+(row-1)*72,1040,66,true,function() if u:select_option(o.mask) then u.modal=nil end end)
  end end
  button(u,'prev','Previous',440,830,240,60,u.choicePage>1,function() u.choicePage=u.choicePage-1 end)
  fitted('Page '..u.choicePage..' / '..pages,{x=745,y=836,w=250,h=46},25,16,ink,'center')
  button(u,'nextpage','Next',1190,830,290,60,u.choicePage<pages,function() u.choicePage=u.choicePage+1 end) else
  txt('FARKLE RULES',425,180,800,30)
  local sections=H.help_sections(s);u.helpTab=math.max(1,math.min(3,u.helpTab or 1))
  for i,section in ipairs(sections) do
   button(u,'helpTab'..i,section.title,425+(i-1)*360,250,350,60,true,function() u.helpTab=i end,u.helpTab==i)
  end
  local section=sections[u.helpTab]
  if section.rows then
   paragraph(section.lines[1],445,329,1030,56,27,17)
   local headers={'Face','Three of a kind','Four of a kind','Five of a kind','Six of a kind'}
   for j,label in ipairs(headers) do
    fitted(label,{x=445+(j-1)*210,y=388,w=200,h=39},
     25,13,gold,'left')
   end
   for i,row in ipairs(section.rows) do
    g.setColor(unpack(Art.rgba(i%2==0 and 'surface_alt' or 'surface')))
    g.rectangle('fill',435,432+(i-1)*47,1060,47)
    for j,value in ipairs(row) do
     fitted(value,{x=445+(j-1)*210,y=436+(i-1)*47,w=200,h=39},
      26,14,ink,'left')
    end
   end
   paragraph(section.lines[2],445,735,1030,55,26,16)
   paragraph(section.lines[3],445,794,1030,55,26,16)
  else
   for i,line in ipairs(section.lines) do
    paragraph(line,445,333+(i-1)*76,1030,66,26,17)
   end
  end
  paragraph('Left/right arrows: change tab · Esc: close',445,887,1030,45,22,14,muted)

 end
 u.buttons=saved;Res.end_ui()
end
return V
