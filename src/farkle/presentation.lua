local Bundle = {}
Bundle.core = (function()
-- Read-only projection of gameplay state. No bodies, RNG or rule mutations.
local P={transfer_duration=.52,feedback_duration=.45,score_duration=.7}
local closed={ended=true,lost=true,won=true,upgrade=true,medal=true,advance=true}
function P.new(s)
 return {game=s,stage=s.stage,turn=s.turn,bank=s.bank,pot=s.pot,phase=s.phase,shelf={},origins={},serial=0,ledger={},bonus=0,hot=s.hot,
  folio={bank=s.bank,pot=s.pot,fromBank=s.bank,fromPot=s.pot,age=P.score_duration}}
end
function P.folio_values(p,s)
 local folio=p and p.folio
 if not folio then return s.bank,s.pot end
 local progress=math.min(1,folio.age/P.score_duration)
 progress=1-(1-progress)^3
 return folio.fromBank+(folio.bank-folio.fromBank)*progress,
  folio.fromPot+(folio.pot-folio.fromPot)*progress
end
-- Snapshot the authoritative partition BEFORE take/bank clears selection.
function P.prepare(p,s)
 local o=require('src.farkle.rules').selection_option(s)
 local groups={}
 for _,g in ipairs(o and o.groups or {}) do
  local ids={};for _,id in ipairs(g.ids) do ids[#ids+1]=id end
  local rolls={};for _,id in ipairs(ids) do rolls[id]=p.origins[id] or 0 end
  groups[#groups+1]={label=g.label,points=g.points,ids=ids,rolls=rolls}
 end
 return {groups=groups,pot=s.pot,bank=s.bank}
end
function P.commit(p,s,before,kind,reduced)
 for _,g in ipairs(before.groups) do p.ledger[#p.ledger+1]=g end
 local banked=s.bank>before.bank
 local base=0;for _,g in ipairs(p.ledger) do base=base+g.points end
 p.bonus=banked and math.max(0,s.bank-before.bank-base) or 0
 local medal=p.bonus>0 and require('src.farkle.rules').medals.get(s.medal)
 p.bonusLabel=medal and medal.label or 'Medal'
 local channel=banked and 'bank' or 'pot'
 local from=banked and before.bank or P.display(p,'pot',before.pot)
 p.score={channel=channel,from=from,to=s[channel],base=base,bonus=p.bonus,
  age=reduced and P.score_duration or 0,groups=banked and p.ledger or before.groups,kind=kind}
end
-- Match physical identity AND accepted throw: hot dice reuse the same IDs.
function P.contributing_dice(p)
 local marked={};local e=p and p.score
 if not e or e.age>=P.score_duration then return marked end
 for _,group in ipairs(e.groups) do
  for _,id in ipairs(group.ids) do
   local held=p.shelf[id]
   if held and group.rolls and group.rolls[id]==held.roll then marked[id]=true end
  end
 end
 return marked
end
function P.display(p,channel,actual)
 local e=p and p.score
 if not e or e.channel~=channel then return actual end
 local t=math.min(1,e.age/P.score_duration);t=1-(1-t)^3
 return math.floor(e.from+(e.to-e.from)*t+.5)
end
function P.accepted(p,indices)
 p.serial=p.serial+1
 for _,i in ipairs(indices or {}) do p.origins[i]=p.serial end
end
function P.observe(p,s,hits,reduced)
 if p.game~=s or p.stage~=s.stage or p.turn~=s.turn then
  local serial=p.game==s and p.serial or 0
  local fresh=P.new(s);for k in pairs(p) do p[k]=nil end;for k,v in pairs(fresh) do p[k]=v end;p.serial=serial
 end
 local moved=false
 if p.folio.bank~=s.bank or p.folio.pot~=s.pot then
  local bank,pot=P.folio_values(p,s)
  p.folio={bank=s.bank,pot=s.pot,fromBank=bank,fromPot=pot,age=reduced and P.score_duration or 0}
 end
 for i=1,6 do
  if s.used[i] then
   if not p.shelf[i] then
    local origin
    for _,h in ipairs(hits or {}) do if h.index==i then origin={x=h.x,y=h.y};break end end
    p.shelf[i]={id=i,value=s.hand[i],roll=p.origins[i] or 0,stage=s.stage,turn=s.turn,
     age=reduced and P.transfer_duration or 0,origin=origin};moved=true
   end
  else p.shelf[i]=nil end
 end
 local event
 if closed[s.phase] and (not closed[p.phase] or s.bank>p.bank) then
  local gained=s.bank-p.bank
  p.conclusion={kind=gained>0 and 'bank' or 'loss',points=gained>0 and gained or p.pot,
   bank=s.bank,stage=s.stage,turn=s.turn,remaining=math.max(0,require('src.farkle.rules').contracts[s.stage].limit-s.turn),
   age=reduced and P.feedback_duration or 0}
  event=p.conclusion.kind
  if event=='loss' then p.score=nil;p.bonus=0 end
 end
 local hot=s.hot and not p.hot
 p.bank=s.bank;p.pot=s.pot;p.phase=s.phase;p.hot=s.hot
 return event or (hot and 'hot' or moved and 'take' or nil)
end
function P.update(p,dt,reduced)
 if p.folio then p.folio.age=reduced and P.score_duration or math.min(P.score_duration,p.folio.age+math.max(0,dt)) end
 for _,e in pairs(p.shelf) do e.age=reduced and P.transfer_duration or math.min(P.transfer_duration,e.age+dt) end
 if p.conclusion then p.conclusion.age=reduced and P.feedback_duration or math.min(P.feedback_duration,p.conclusion.age+dt) end
 if p.score then p.score.age=reduced and P.score_duration or math.min(P.score_duration,p.score.age+math.max(0,dt)) end
end
function P.finish(p)
 P.update(p,math.max(P.transfer_duration,P.feedback_duration,P.score_duration),true)
end
return P
end)()
Bundle.hud_model = (function()
local R=require('src.farkle.rules')
-- Pure Farkle presentation semantics only. Layout lives in ui_v2/.
local H={}
function H.reward_active(s) return s.phase=='upgrade' or s.phase=='medal' end
function H.help_sections(s)
 local p=R.points;local c=R.contracts[s.stage];local rows={}
 for v=1,6 do rows[v]={v,p.kind[3][v],p.kind[4][v],p.kind[5][v],p.kind[6][v]} end
 return {
  {title='How to play',lines={
   '1. Press Space to roll all six dice.',
   '2. Select a combination: click the dice or press 1–6.',
   '3. Press Set aside [A]. Selected dice leave the tray.',
   '4. Reroll the remaining dice or Bank [Enter].',
   'You can also bank a valid selection without setting it aside first.',
   'Banked points are safe. Turn points remain at risk.',
   'Reach the target within the turns shown above.'}},
  {title='Combinations & scores',rows=rows,lines={
   'Singles: 1 = '..p.single[1]..' points   ·   5 = '..p.single[5]..' points',
   'Straight 1–5 or 2–6: '..p.small..'   ·   Straight 1–6: '..p.straight,
   'Three pairs: '..p.pairs..'   ·   Full house (4+2): '..p.full..'   ·   Two triplets: '..p.triples}},
  {title='Special rules',lines={
   'Farkle: no scoring combination. You lose your unbanked turn points.',
   'Previously banked points always remain safe.',
   'Hot dice: after setting aside every die, reroll all six or bank.',
   'First bank: at least '..(c.entry_min or 0)..' points. Later banks: at least '..(c.bank_min or 0)..'.',
   'Each combination uses dice from one roll. No die counts twice.',
   'You may set aside only some of the scoring dice.',
   'Medal exceptions are explained in the medal panel.'}}
 }
end
function H.commission_closed(s)
 return s.phase=='lost' or s.phase=='won' or s.phase=='upgrade' or s.phase=='medal' or s.phase=='advance'
end
function H.state_text(u)
 local s=u.game
 if u.physicalFailure then return u.physicalFailure end
 if u.physicalNotice then return u.physicalNotice end
 if s.phase=='lost' then return 'Commission failed: no turns left. The run ends here.' end
 if s.phase=='won' then return 'Three commissions delivered: mini-run complete.' end
 if s.phase=='advance' then return 'Commission delivered. Continue with Next.' end
 if s.phase=='upgrade' or s.phase=='medal' then return 'Commission delivered. Choose your reward on the right.' end
 if s.phase=='rolling' then return u.retry and 'Rerolling the weighted die…' or 'The dice are rolling…' end
 if s.phase=='fresh' then return 'Roll all six dice to begin your turn.' end
 if s.phase=='ended' then
  if u.lastLoss~=nil then return u.lastLoss>0 and ('FARKLE · '..u.lastLoss..' unbanked points lost.') or 'FARKLE · Turn over, no points accumulated.' end
  return 'Banked '..(u.lastBank or 0)..' points. Continue to the next turn.'
 end
 if s.phase=='rescue' then return 'FARKLE · Use the Corrector to save your turn.' end
 if s.hot then local ok,_,minimum=R.bank_status(s);return ok and 'HOT DICE · Reroll all six or bank.' or ('HOT DICE · Reroll six dice: minimum bank '..minimum) end
 if next(s.selected) then return R.selection(s) and (H.selection_text(s)..' · Click Set aside.') or 'Invalid selection: every selected die must score.' end
 if s.scored then local ok,_,_,reason=R.bank_status(s);return ok and 'Reroll or bank your turn points.' or reason end
 return 'Select scoring dice with the mouse or keys 1–6.'
end
function H.eligible(s)
 local ids,count={},0
 if s.phase~='ready' then return ids,count end
 -- R.options uses the shared scoring cache and preserves physical IDs.
 -- A visual hint is still only a hint; it never alters selected dice.
 for _,option in ipairs(R.options(s)) do
  for _,id in ipairs(option.ids) do
   if not ids[id] then ids[id]=true;count=count+1 end
  end
 end
 return ids,count
end
-- An unfinished group is still useful if all chosen physical IDs are
-- contained in at least one legal option from this throw.
function H.can_complete(s)
 if s.phase~='ready' or not next(s.selected) then return false end
 for _,option in ipairs(R.options(s)) do
  local all=true
  for id in pairs(s.selected) do
   if math.floor(option.mask/2^(id-1))%2==0 then all=false;break end
  end
  if all then return true end
 end
 return false
end
function H.selected_count(s)
 local n=0;for i=1,6 do if s.selected[i] and not s.used[i] then n=n+1 end end;return n
end
function H.selection_text(s)
 local o=R.selection_option(s);if not o then return nil end
 local labels,counts={},{}
 for _,g in ipairs(o.groups) do if not counts[g.label] then labels[#labels+1]=g.label;counts[g.label]=0 end;counts[g.label]=counts[g.label]+1 end
 for i,label in ipairs(labels) do if counts[label]>1 then labels[i]=counts[label]..' × '..label end end
 return table.concat(labels,' + ')..' · '..(o.remaining==0 and '6 dice to reroll (hot)' or o.remaining..' dice to reroll')
end
function H.reroll_indices(s)
 local result={};for i=1,6 do if s.hot or not s.used[i] then result[#result+1]=i end end;return result
end
return H
end)()
Bundle.medal_panel = (function()
local M=require('src.farkle.rules').medals
local R=require('src.farkle.rules')
local V={}
local function description(d)
 if not d.enabled then return d.reason end
 if d.effect=='selective_reroll' then
  return d.parameters.same_value and 'Reroll two matching dice that are not set aside. Once per commission.'
   or ('Reroll '..(d.parameters.count==1 and 'one die that is not set aside' or 'up to '..d.parameters.count..' dice that are not set aside')..'. Once per commission.')
 elseif d.effect=='bank_multiplier' then return 'Multiply your turn total by '..d.parameters.factor..' and bank. Normal banking thresholds must already be met.' end
 return d.reason
end
function V.draw(u,txt,button,paragraph)
 local s=u.game
 -- A standalone caller can still supply the historical text callback;
 -- the shipping dialog passes the bounded multi-line presenter.
 local body=paragraph or function(value,x,y,w,_,pt)
  txt(value,x,y,w,pt)
 end
 if u.modal=='medals' then
  txt('MEDAL LABORATORY',425,180,800,30)
  body('Reference experiment. Equipping RESTARTS this commission: points and turns reset, custom die retained.',440,243,1040,78,23,16)
  local pages=math.ceil(#M.list/6);u.medalPage=math.max(1,math.min(u.medalPage or 1,pages))
  for n=1,6 do local d=M.list[(u.medalPage-1)*6+n];if d then
   button(u,'inspect'..n,d.label..(d.enabled and '' or ' [unavailable]'),440,340+(n-1)*70,580,60,true,function() u.medalPreview=d.id end,u.medalPreview==d.id)
  end end
  local d=M.get(u.medalPreview) or M.list[(u.medalPage-1)*6+1]
  txt(d.label,1050,340,420,25)
  body(description(d),1050,402,420,132,23,15)
  body('Uses: '..tostring(d.max_uses or 'passive')..'\n'..d.verification,1050,553,420,142,21,14)
  button(u,'equip','Restart and equip',1050,730,420,66,d.enabled,function() u:equip_reference(d.id) end,true)
  button(u,'medalprev','Previous',440,830,250,60,u.medalPage>1,function() u.medalPage=u.medalPage-1;u.medalPreview=nil end)
  txt(u.medalPage..' / '..pages,790,845,150,24)
  button(u,'medalnext','Next',1050,830,420,60,u.medalPage<pages,function() u.medalPage=u.medalPage+1;u.medalPreview=nil end)
 else
  local d=M.get(s.medal);if not d then return end
  txt(d.label..' / uses '..M.remaining(s),425,180,800,30)
  body(description(d),440,258,1040,79,25,16)
  body(d.effect=='bank_multiplier' and 'Uses your current scoring selection. The bonus affects only this turn, not earlier banked points.' or 'Medal targets are separate from scoring selections. Rerolling does not bank any points.',440,351,1040,93,23,15)
  u.medalDice=u.medalDice or {}
  if d.effect=='selective_reroll' then
   for i=1,6 do
    button(u,'target'..i,'D'..i..' = '..tostring(s.hand[i] or '-'),440+(i-1)*174,460,160,70,s.phase=='ready' and s.hand[i]~=nil and not s.used[i],function() u.medalDice[i]=not u.medalDice[i] or nil end,u.medalDice[i])
   end
  end
  local ids={};for i=1,6 do if u.medalDice[i] then ids[#ids+1]=i end end
  local ok,reason=R.reference_status(s,ids)
  body(reason,440,607,1040,80,25,16)
  body('Uses left: '..M.remaining(s)..' / '..d.max_uses..' | Recharges next commission.',440,705,1040,74,23,15)
  button(u,'activate',d.effect=='bank_multiplier' and 'Apply x2 and bank' or 'Use medal and reroll',440,820,1040,65,ok,function() u:activate_reference(ids) end,true)
 end
end
return V
end)()
Bundle.toast_messages = (function()
local Typography=require('src.core.presentation').typography
-- Presentation-only adaptation of upstream Lovely Toasts.
-- Lazy-loaded because the original module allocates a Font at require time.
-- Never receives mouse/touch input; the physical dice always own the pointer.
local Res=require('src.core.navigation').resolution
local RuntimeUI=require('src.core.runtime_state').ui
local M={}
local engine=nil
local has=false

local function instance()
 if engine then return engine end
 engine=require('lib.lovelyToasts')
 engine.options.queueEnabled=false
 engine.options.tapToDismiss=false
 engine.options.animationDuration=.23
 engine.canvasSize={1920,1080}
 engine.style.paddingLR=18
 engine.style.paddingTB=9
 engine.style.backgroundColor={.13,.09,.065,.92}
 engine.style.textColor={.97,.85,.64,1}
 engine.style.font=Typography.load(
  Typography.primary,RuntimeUI.big_text() and 20 or 17)
 return engine
end

function M.show(message)
 if type(message)~='string' or message=='' then return end
 -- The canonical V2 HUD now emits notifications in every Farkle path.
 -- In headless rules/controller tests LÖVE graphics is intentionally absent:
 -- never load upstream Lovely Toasts before graphics exists.
 if not (love and love.graphics and love.graphics.newFont) then return end
 local t=instance()
 t.options.animationDuration=RuntimeUI.reduced_animations() and .001 or .23
 -- Position 113 in 1920x1080 virtual coordinates, above the actual tray;
 -- right-biased X translation is limited to the HUD drawing call.
 t.show(message,2.0,112)
 has=true
end
function M.update(dt)
 if has then instance().update(math.max(0,dt or 0)) end
end
function M.clear()
 if not has then return end
 _toasts={} -- upstream library uses this global as its private queue.
 has=false
end
function M.draw(blocked)
 if not has or blocked then return end
 local g=love.graphics
 g.push('all')
 Res.begin_ui()
 g.translate(635,0)
 instance().draw()
 Res.end_ui()
 g.pop()
end
return M
end)()
Bundle.folio_view = (function()
local Typography=require('src.core.presentation').typography
local Presentation=Bundle.core
local Art=require('src.data.frontend_schema').palette
local F={}
local fonts={}
local colors={ink=Art.rgb('ink'),red=Art.rgb('cinnabar'),green=Art.rgb('forest'),blue=Art.rgb('slate'),gold=Art.rgb('ochre_dark')}
local words={'Lux','in','folio','manet','et','manus','opus','texit','hora','post','horam','memoria','crescit','inter','folia','silentia'}
function F.draw(s,p,x,y,w,h,txt,target)
 local g=love.graphics
 local bank,pot=Presentation.folio_values(p,s)
 local fixed=math.max(0,math.min(1,bank/math.max(1,target)))
 local wet=math.max(fixed,math.min(1,(bank+pot)/math.max(1,target)))
 local function pigment(color,threshold,span)
  local stable=math.max(0,math.min(1,(fixed-threshold)/span))
  local pending=math.max(0,math.min(1,(wet-threshold)/span))
  local alpha=stable*.94+math.max(0,pending-stable)*.32
  local rgb=colors[color]
  g.setColor(rgb[1],rgb[2],rgb[3],alpha)
  return {rgb[1],rgb[2],rgb[3],alpha}
 end
 g.setColor(Art.rgba('ink',.3));g.rectangle('fill',x+7,y+9,w,h,2)
 g.setColor(Art.rgba('surface',1));g.rectangle('fill',x,y,w,h,2)
 for strip=1,16 do
  g.setColor(Art.rgba('surface_recessed',.018+(strip%3)*.006))
  g.rectangle('fill',x,y+strip*h/17,w,h/34)
 end
 g.setColor(Art.rgba('border',.45));g.setLineWidth(1)
 g.rectangle('line',x+2,y+2,w-4,h-4,2)
 txt('FOLIO '..s.stage,x+w*.18,y+h*.045,w*.64,math.max(13,math.floor(w*.043)),Art.rgba('text_muted',1),'center')
 local left,right,top,bottom=x+w*.20,x+w*.82,y+h*.17,y+h*.85
 g.setColor(Art.rgba('earth',.15))
 g.line(left,y+h*.13,left,bottom);g.line(right,y+h*.13,right,bottom)
 for row=1,17 do
  local baseline=top+row*h*.036
  g.setColor(Art.rgba('quiet',.13));g.setLineWidth(.7)
  g.line(left,baseline,right,baseline)
  local rowLeft=row<5 and left+w*.18 or left
  local available=right-rowLeft
  for word=1,4 do
   local index=(row-1)*4+word
   local threshold=(index-1)/90
   local color=pigment('ink',threshold,.025)
   local text=words[(row*3+word*5)%#words+1]
  local size=math.max(9,math.floor(w*.033))
  fonts[size]=fonts[size] or Typography.load(Typography.primary,size)
  local font=fonts[size]
  local fit=math.min(1,(available/4-3)/math.max(1,font:getWidth(text)))
  g.setFont(font);g.setColor(unpack(color))
  g.print(text,rowLeft+(word-1)*available/4,baseline-h*.026,0,fit,1)
  end
 end
 local initial=pigment('red',.045,.14)
 txt('M',left,top+h*.012,w*.19,math.floor(w*.17),initial)
 pigment('gold',.16,.12);g.setLineWidth(math.max(1,w*.004))
 g.rectangle('line',left-w*.015,top-h*.005,w*.18,h*.15)
 local stemX=x+w*.11
 for segment=1,24 do
  local start=y+h*(.13+(segment-1)*.030)
  local finish=start+h*.030
  pigment('green',(segment-1)/29,.06)
  g.setLineWidth(math.max(1,w*.004))
  g.line(stemX+math.sin(segment*.8)*w*.022,start,stemX+math.sin((segment+1)*.8)*w*.022,finish)
  local side=segment%2==0 and 1 or -1
  local leafX=stemX+side*w*.045
  pigment(segment%3==0 and 'blue' or 'green',(segment-1)/27,.07)
  g.push();g.translate(leafX,start+h*.012);g.rotate(side*.65)
  g.ellipse('fill',0,0,w*.014,h*.020);g.pop()
  if segment%3==1 then
   local flowerX=stemX-side*w*.045
   pigment(segment%2==0 and 'blue' or 'red',segment/28,.06)
   for petal=1,5 do
    local angle=petal*math.pi*2/5
    g.ellipse('fill',flowerX+math.cos(angle)*w*.014,start+math.sin(angle)*w*.014,w*.012,w*.009)
   end
   pigment('gold',segment/28,.06);g.circle('fill',flowerX,start,w*.007)
  end
 end
 for segment=1,15 do
  local offset=(segment-1)/15
  local ornamentX=left+offset*(right-left)
  pigment(segment%3==0 and 'red' or 'blue',.20+offset*.70,.06)
  g.setLineWidth(math.max(1,w*.004))
  g.arc('line','open',ornamentX,y+h*.115,w*.022,0,math.pi)
  pigment('gold',.28+offset*.65,.06)
  g.circle('fill',ornamentX,y+h*.115,w*.005)
 end
 for segment=1,10 do
  pigment('red',.56+(segment-1)*.04,.05)
  local ornamentY=top+(segment-1)*(bottom-top)/10
  g.line(right+w*.035,ornamentY,right+w*.035,ornamentY+h*.035)
  pigment('gold',.60+(segment-1)*.035,.04)
  g.circle('fill',right+w*.035,ornamentY+h*.045,w*.006)
 end
 local pulse=p and p.conclusion and p.conclusion.kind=='bank' and 1-p.conclusion.age/Presentation.feedback_duration or 0
 if pulse>0 then
  g.setColor(Art.rgba('ochre',pulse*.5));g.setLineWidth(2)
  g.rectangle('line',x+5,y+5,w-10,h-10,2)
 end
 txt(s.bank..' assicurati',x+w*.15,y+h*.90,w*.72,math.max(12,math.floor(w*.039)),Art.rgba('forest',1),'center')
 txt(s.pot..' a rischio',x+w*.15,y+h*.94,w*.72,math.max(12,math.floor(w*.039)),Art.rgba('risk',1),'center')
 g.setLineWidth(1)
 return {fixed=fixed,wet=wet}
end
return F
end)()
Bundle.core.hud_model = Bundle.hud_model
Bundle.core.medal_panel = Bundle.medal_panel
Bundle.core.toast_messages = Bundle.toast_messages
Bundle.core.folio_view = Bundle.folio_view
return Bundle.core
