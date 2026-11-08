-- "Il Mercante e la posta": isolated decision prototype. Shapes and text only.
local source=love.filesystem.getSource()
package.path=source..'/../../?.lua;'..package.path

local Match=require('experiments.merchant_wager_lab.match')
local Corrector=require('experiments.merchant_wager_lab.corrector')
local Rules=require('src.farkle.rules')
local Log=require('experiments.merchant_wager_lab.log')
local Simulate=require('experiments.merchant_wager_lab.simulate')
local Analysis=require('experiments.merchant_wager_lab.analysis')
local Config=require('experiments.merchant_wager_lab.config')
local Duel=require('experiments.merchant_wager_lab.duel')
local Box=require('experiments.merchant_wager_lab.box')
local Presentation=require('experiments.merchant_wager_lab.presentation')
local MoneyDuel=require('experiments.merchant_wager_lab.money_duel')
local MoneyLog=require('experiments.merchant_wager_lab.money_log')
local Currency=require('experiments.merchant_wager_lab.currency')

local W,H=1280,720
local C={
 bg={0.13,0.12,0.11},panel={0.20,0.18,0.16},line={0.42,0.38,0.32},text={0.94,0.91,0.84},dim={0.62,0.58,0.52},
 player={0.25,0.50,0.85},merchant={0.80,0.28,0.24},pot={0.93,0.78,0.36},paper={0.96,0.93,0.84},
 die={0.95,0.93,0.88},pip={0.12,0.10,0.09},select={0.98,0.80,0.25},aside={0.55,0.53,0.50},
 off={0.30,0.28,0.26},good={0.45,0.80,0.45},danger={0.88,0.28,0.24},
}
local fonts={}
local lab={match=nil,duel=nil,id=1,saved=false,timer=0,completed=0,message='',buttons={},dice={},v3dice={},capture=nil,
 screen='mode',mode=nil,variant='A',seed_text='101',seed_focused=false,
 box_expanded=false,money=nil,v4dice={},money_ledger_expanded=false,
 money_raises_enabled=true,
 corrector=nil,corrector_dice={},corrector_notes_focused=false,
 corrector_feedback={decision_changes='',threat=nil,notes=''},corrector_feedback_saved=false,
 feedback={pressure=nil,banking=nil,influence=nil,notes=''},feedback_saved=false,
 v3_feedback={counteroffer_rerolls=nil,banked_below_estimate=nil,merchant_decisions_clear=nil,
  felt_competitive=nil,loss_cause=nil,notes=''},v3_feedback_saved=false}
local view={s=1,x=0,y=0}

local function color(c,a) love.graphics.setColor(c[1],c[2],c[3],a or 1) end
local function text(s,x,y,font,c,w,align)
 love.graphics.setFont(font or fonts.body);color(c or C.text)
 if w then love.graphics.printf(s,x,y,w,align or 'left') else love.graphics.print(s,x,y) end
end
local function score_text(value) return tostring(value or 0)..' punti' end
local function panel(x,y,w,h,title,accent)
 color(C.panel);love.graphics.rectangle('fill',x,y,w,h,8)
 color(accent or C.line);love.graphics.setLineWidth(2);love.graphics.rectangle('line',x,y,w,h,8)
 if title then text(title,x+16,y+10,fonts.head,accent or C.text) end
end

local pips={[1]={{0,0}},[2]={{-1,-1},{1,1}},[3]={{-1,-1},{0,0},{1,1}},[4]={{-1,-1},{1,-1},{-1,1},{1,1}},
 [5]={{-1,-1},{1,-1},{0,0},{-1,1},{1,1}},[6]={{-1,-1},{1,-1},{-1,0},{1,0},{-1,1},{1,1}}}
local function die(x,y,size,value,state)
 local fill=state=='aside' and C.aside or C.die
 color(fill);love.graphics.rectangle('fill',x,y,size,size,size*0.16)
 local edge=state=='selected' and C.select or state=='kept' and C.pot or C.line
 color(edge);love.graphics.setLineWidth(state=='selected' and 5 or 2);love.graphics.rectangle('line',x,y,size,size,size*0.16)
 if not value then text('–',x,y+size*0.3,fonts.head,C.pip,size,'center');return end
 color(C.pip);local cx,cy,d=x+size/2,y+size/2,size*0.26
 for _,p in ipairs(pips[value]) do love.graphics.circle('fill',cx+p[1]*d,cy+p[2]*d,size*0.08) end
end

-- One sheet token. Reserves are solid in the owner's colour; pot sheets are
-- paper-coloured with the depositor's stripe, so the three places never blur.
local function sheet(x,y,owner,inPot)
 local c=owner=='player' and C.player or C.merchant
 if inPot then
  color(C.paper);love.graphics.rectangle('fill',x,y,30,40,3)
  color(c);love.graphics.rectangle('fill',x,y,30,8,3)
  color(C.pot);love.graphics.setLineWidth(2);love.graphics.rectangle('line',x,y,30,40,3)
  text(owner=='player' and 'A' or 'M',x,y+14,fonts.small,C.pip,30,'center')
 else
  color(c);love.graphics.rectangle('fill',x,y,30,40,3)
  color(C.paper,0.6);love.graphics.rectangle('line',x+4,y+4,22,32,2)
 end
end
local function reserve(x,y,owner,n,label)
 text(label..': '..n..(n==1 and ' foglio' or ' fogli'),x,y,fonts.body,owner=='player' and C.player or C.merchant)
 for i=1,n do sheet(x+(i-1)*36,y+24,owner,false) end
 if n==0 then text('(riserva vuota)',x,y+34,fonts.small,C.dim) end
end

local function new_match(seed,variant)
 lab.match=Match.new(seed or love.math.random(1,2147483646),variant or lab.variant)
 lab.variant=lab.match.config.variant;lab.seed_text=tostring(lab.match.seed)
 lab.id=Log.next_id_v2(love.filesystem);lab.saved=false;lab.feedback_saved=false;lab.timer=0
 lab.mode='v2';lab.screen='match'
 lab.feedback={pressure=nil,banking=nil,influence=nil,notes=''}
 lab.message='Lancia i sei dadi per iniziare il round 1.'
end

local function new_duel(seed)
 lab.id=Log.next_id_v3(love.filesystem)
 lab.duel=Duel.new(seed or love.math.random(1,2147483646),lab.id)
 lab.match=nil;lab.mode='v3';lab.screen='v3';lab.saved=false;lab.v3_feedback_saved=false
 lab.v3_feedback={counteroffer_rerolls=nil,banked_below_estimate=nil,merchant_decisions_clear=nil,
  felt_competitive=nil,loss_cause=nil,notes=''}
 lab.seed_text=tostring(lab.duel.seed);lab.timer=0;lab.box_expanded=false
end

local function new_money_duel(seed)
 lab.id=MoneyLog.next_id(love.filesystem)
 lab.money=MoneyDuel.new(seed or love.math.random(1,2147483646),lab.id,
  {raises_enabled=lab.money_raises_enabled})
 lab.duel=nil;lab.match=nil;lab.corrector=nil
 lab.mode='money';lab.screen='money';lab.saved=false;lab.seed_focused=false
 lab.seed_text=tostring(lab.money.seed);lab.money_ledger_expanded=false
 lab.save_note=nil
end

local function new_corrector(seed)
 lab.id=Log.next_id_corrector(love.filesystem)
 lab.corrector=Corrector.new(seed or love.math.random(1,2147483646),lab.id)
 lab.match=nil;lab.duel=nil;lab.mode='corrector';lab.screen='corrector'
 lab.seed_text=tostring(lab.corrector.seed);lab.saved=false;lab.corrector_feedback_saved=false
 lab.corrector_feedback={decision_changes='',threat=nil,notes=''}
 lab.corrector_notes_focused=false;lab.seed_focused=false
 lab.message='Il centro contiene tre fogli. Lancia i sei dadi per iniziare.'
end

local function after_player_action()
 local m=lab.match
 if m.phase=='merchant' then lab.timer=0.9 end
end

local actions={
 roll=function() local m=lab.match;if Match.roll(m) then
  if m.phase=='merchant' then lab.message='FARKLE! Perdi i punti provvisori del turno.'
  else lab.message='Seleziona i dadi che fanno punti (clic o tasti 1–6).' end
  after_player_action() end end,
 take=function() if Match.take(lab.match) then
  lab.message=lab.match.turn.hot and 'HOT DICE: puoi rilanciare tutti e sei i dadi.' or 'Accantonati. Rilancia i dadi liberi o incassa.' end end,
 bank=function() local m=lab.match;local before=m.score.player
  if Match.bank(m) then lab.message='Incassati '..(m.score.player-before)..' punti.';after_player_action() end end,
 see=function() if Match.see(lab.match) then lab.message='Vedo: aggiungi un foglio. Round '..lab.match.round..'.' end end,
 pass=function() if Match.pass(lab.match) then lab.message='Passo: il Mercante conquista il piatto.' end end,
 replay=function() new_match(lab.match.seed,lab.match.config.variant) end,
 variants=function() lab.screen='mode' end,
}
local function enabled(name)
 local m=lab.match
 if name=='replay' or name=='variants' then return true end
 if lab.timer>0 then return false end
 return ({roll=Match.can_roll,take=Match.can_take,bank=Match.can_bank,see=Match.can_see,pass=Match.can_pass})[name](m)
end

local function layout_buttons()
 local m=lab.match
 local roll=m.phase=='player' and m.turn.phase~='fresh' and 'Rilancia' or 'Lancia'
 local defs={{'roll',roll..' [Spazio]'},{'take','Accantona [A]'},{'bank','Incassa [I]'},
  {'see','Vedo [V]'},{'pass','Passo [P]'},{'replay','Stesso seed [R]'},{'variants','Varianti [Esc]'}}
 lab.buttons={}
 for i,d in ipairs(defs) do lab.buttons[i]={id=d[1],label=d[2],x=40+(i-1)*170,y=604,w=162,h=48} end
end

local function save_if_over()
 local m=lab.match
 if m.phase~='over' or lab.saved then return end
 if lab.capture then lab.saved=true;lab.save_note='Modalità cattura: partita non registrata.';return end
 local record=Match.record(m,lab.id)
 local ok,err=pcall(Log.save_v2,love.filesystem,m,record)
 lab.saved=true;lab.completed=lab.completed+1
 lab.match_record=record
 lab.save_note=ok and ('Partita #'..lab.id..' registrata in '..love.filesystem.getSaveDirectory()) or ('Registro non scritto: '..tostring(err))
 lab.screen='feedback'
end

local function draw_merchant(m)
 panel(40,70,560,250,'Il Mercante  (3 D6)',C.merchant)
 text('Punteggio',440,80,fonts.small,C.dim,140,'right')
 text(tostring(m.score.merchant),440,96,fonts.big,C.merchant,140,'right')
 reserve(60,118,'merchant',m.reserve.merchant,'Riserva del Mercante')
 text('Ultimo turno:',60,196,fonts.small,C.dim)
 local r=m.merchant_last
 if r then
  for row,s in ipairs(r.steps) do
   local kept={};for _,p in ipairs(s.kept or {}) do kept[p]=true end
   text(row==1 and 'Lancio' or 'Rilancio',60,222+(row-1)*44,fonts.small,C.dim)
   for i=1,m.config.merchant_dice do
    die(140+(i-1)*44,212+(row-1)*44,38,s.faces[i],kept[i] and 'kept' or (s.faces[i] and 'free' or 'aside'))
   end
   text(s.action=='farkle' and 'Farkle' or ('+'..(s.points or 0)),290,222+(row-1)*44,fonts.body,s.action=='farkle' and C.merchant or C.pot)
  end
 else
  for i=1,m.config.merchant_dice do die(140+(i-1)*44,212,38,nil,'free') end
 end
 text(m.merchant_action,350,196,fonts.small,C.text,236)
end

local function draw_pot(m)
 panel(620,70,620,250,'Piatto (la posta in gioco)',C.pot)
 text(m.pot..(m.pot==1 and ' foglio' or ' fogli'),1040,16+70,fonts.head,C.pot,180,'right')
 local x=640
 if m.phase~='over' then
  for _=1,m.deposited.player do if x<1200 then sheet(x,120,'player',true);x=x+36 end end
  for _=1,m.deposited.merchant do if x<1200 then sheet(x,120,'merchant',true);x=x+36 end end
 end
 if m.phase=='over' then
  text('Il piatto è stato assegnato.',640,124,fonts.small,C.dim)
  local who=({player='Vince l\'Artista',merchant='Vince il Mercante',tie='Parità'})[m.winner]
  local why=({threshold='soglia raggiunta',max_rounds='round esauriti',pass='il giocatore passa'})[m.end_reason]
  text(who..' ('..why..')',640,180,fonts.head,m.winner=='player' and C.player or m.winner=='merchant' and C.merchant or C.text)
  text(m.winner=='tie' and 'Ognuno riprende i fogli depositati.' or ('Conquista '..m.pot_at_end..' fogli dal piatto.'),640,212,fonts.body)
  text(lab.save_note or '',640,240,fonts.small,C.dim,580)
  text('Partite completate in questa sessione: '..lab.completed,640,288,fonts.small,C.good)
 else
  text('Depositati: Artista '..m.deposited.player..' · Mercante '..m.deposited.merchant..'   (piatto massimo '..m.max_pot..')',640,170,fonts.small,C.dim)
  if m.phase=='raise' then
   text('Il Mercante dice «Alzo»!',640,196,fonts.head,C.merchant)
   text('Vedo: aggiungi 1 foglio e continua.  Passo: abbandoni e il Mercante prende tutto il piatto.',640,228,fonts.small,C.text,580)
  elseif m.phase=='merchant' then text('Turno del Mercante…',640,200,fonts.head,C.merchant) end
 end
end

local function draw_player(m)
 panel(40,336,1200,252,'L\'Artista  (tu: 6 D6, Farkle canonico)',C.player)
 text('Punteggio',1060,346,fonts.small,C.dim)
 text(tostring(m.score.player),1060,362,fonts.big,C.player)
 reserve(60,384,'player',m.reserve.player,'La tua riserva')
 local t=m.turn;lab.dice={}
 local playing=m.phase=='player'
 for i=1,6 do
  local x,y=360+(i-1)*84,388
  local state=t.used[i] and 'aside' or t.selected[i] and 'selected' or 'free'
  die(x,y,70,playing and t.hand[i] or nil,playing and state or 'free')
  text('#'..i..(playing and t.used[i] and ' acc.' or ''),x,y+76,fonts.small,C.dim,70,'center')
  lab.dice[i]={x=x,y=y,s=70}
 end
 local sel=Match.selection_points(m)
 local hasSel=playing and next(t.selected)~=nil
 text('Provvisorio del turno: '..(playing and t.pot or 0),360,494,fonts.head,C.pot)
 text(hasSel and (sel and ('Selezione: +'..sel) or 'Selezione non valida') or '',700,498,fonts.body,sel and C.select or C.merchant)
 text(lab.message,360,532,fonts.body,C.text,860)
end

local function hitbox(id,label,x,y,w,h,active,selected)
 lab.buttons[#lab.buttons+1]={id=id,label=label,x=x,y=y,w=w,h=h,active=active~=false,selected=selected or false}
 color(selected and C.select or active==false and C.off or C.line)
 love.graphics.rectangle('fill',x,y,w,h,6)
 color(selected and C.pip or active==false and C.dim or C.text)
 text(label,x+5,y+math.max(7,(h-(fonts.body:getHeight()))/2),fonts.body,selected and C.pip or active==false and C.dim or C.text,w-10,'center')
end

local function draw_mode()
 lab.buttons={}
 text('Merchant Wager Lab',60,60,fonts.big,C.text)
 text('Scegli un esperimento opt-in. Partite e registri restano separati.',60,125,fonts.body,C.dim,1150)
 local cards={
  {id='mode_v2',x=55,w=370,accent=C.line,title='V2 — A/B/C',
   body='Farkle contro il Mercante. Varianti di punteggio iniziale e posta.'},
  {id='mode_v3',x=455,w=370,accent=C.merchant,title='V3 — Cassa tipografica',
   body='Controfferta con caratteri mobili e rischio di estrarre X.'},
  {id='mode_corrector',x=855,w=370,accent=C.pot,title='Il Correttore',
   body='Rivale a sei dadi, furto di fogli su Farkle e acquisti da 500 punti.'},
 }
 for _,card in ipairs(cards) do
  color(C.panel);love.graphics.rectangle('fill',card.x,205,370,310,8)
  color(card.accent);love.graphics.setLineWidth(2);love.graphics.rectangle('line',card.x,205,370,310,8)
  text(card.title,card.x+22,242,fonts.head,card.accent,326)
  text(card.body,card.x+22,315,fonts.body,C.dim,326)
  hitbox(card.id,card.id=='mode_v2' and 'Scegli A / B / C' or
   card.id=='mode_v3' and 'Gioca la V3' or 'Avvia il prototipo',card.x+22,425,326,54,true)
 end
 hitbox('mode_money','V4 — Duello monetario · lira, soldo e denaro',360,545,560,48,true)
 text('La V4 usa sei dadi Farkle e la cassa V3; puntate separate, nessun cambio dei punteggi.',
  60,618,fonts.small,C.dim,1150)
end

local function draw_setup()
 local g=love.graphics
 lab.buttons={}
 text('Il Mercante e la posta',60,38,fonts.big,C.text)
 text('Scegli una condizione sperimentale. Regole, seed e soglia restano uguali tra le varianti.',60,100,fonts.body,C.dim,1160)
 local variants={
  {id='A',title='A — Controllo',desc='Punteggio iniziale: 0 – 0',stake='Posta iniziale: 2 fogli'},
  {id='B',title='B — Inseguimento',desc='Artista: 0  ·  Mercante: 30',stake='Posta iniziale: 2 fogli'},
  {id='C',title='C — Alta posta',desc='Punteggio iniziale: 0 – 0',stake='Posta iniziale: 4 fogli'},
 }
 for i,v in ipairs(variants) do
  local x=60+(i-1)*395;local y=165;local w=370;local h=205
  color(C.panel);g.rectangle('fill',x,y,w,h,8)
  color(lab.variant==v.id and C.select or C.line);g.setLineWidth(lab.variant==v.id and 4 or 2);g.rectangle('line',x,y,w,h,8)
  text(v.title,x+18,y+20,fonts.head,lab.variant==v.id and C.select or C.text,w-36)
  text(v.desc,x+18,y+78,fonts.body,C.text,w-36)
  text(v.stake,x+18,y+112,fonts.body,C.pot,w-36)
  local reserved=v.id=='C' and 2 or 3
  text(('Fogli totali: 4 a testa  ·  riserva iniziale: %d'):format(reserved),x+18,y+150,fonts.small,C.dim,w-36)
  hitbox('variant_'..v.id,'Seleziona',x+18,y+174,w-36,24,true,lab.variant==v.id)
 end

 text('Seed numerico',70,414,fonts.head,C.text)
 color(C.panel);g.rectangle('fill',260,408,250,42,6)
 color(lab.seed_focused and C.select or C.line);g.setLineWidth(2);g.rectangle('line',260,408,250,42,6)
 text(lab.seed_text..(lab.seed_focused and '|' or ''),273,416,fonts.body,C.text,220)
 lab.buttons[#lab.buttons+1]={id='seed_field',x=260,y=408,w=250,h=42,active=true}
 text('Seed comuni per il confronto:',70,474,fonts.body,C.dim)
 for i,seed in ipairs(Config.seeds) do hitbox('seed_'..seed,tostring(seed),300+(i-1)*115,466,100,42,true,lab.seed_text==tostring(seed)) end
 local seed=tonumber(lab.seed_text)
 local valid=seed and seed%1==0 and seed>=1 and seed<2147483647
 text(valid and 'Lo stesso seed usa flussi casuali separati e riproducibili per Artista e Mercante.' or 'Inserisci un intero da 1 a 2147483646.',70,540,fonts.small,valid and C.dim or C.merchant,850)
 hitbox('start','Inizia variante '..lab.variant,940,520,260,62,valid)
 hitbox('back_mode','Torna a V2 / V3',70,600,230,48,true)
 text('Premi Invio per iniziare.',330,615,fonts.small,C.dim)
end

local function draw_corrector_setup()
 lab.buttons={}
 text('Prototipo incontro — Il Correttore',60,54,fonts.big,C.text)
 text('Tu usi il Farkle canonico. Il Correttore usa solo 4/5/6 e può rubare fogli quando fa Farkle.',
  60,125,fonts.body,C.dim,1120)
 text('Seed numerico',70,238,fonts.head,C.text)
 color(C.panel);love.graphics.rectangle('fill',260,230,260,48,6)
 color(lab.seed_focused and C.select or C.line);love.graphics.rectangle('line',260,230,260,48,6)
 text(lab.seed_text..(lab.seed_focused and '|' or ''),274,241,fonts.body,C.text,230)
 lab.buttons[#lab.buttons+1]={id='seed_field',x=260,y=230,w=260,h=48,active=true}
 text('Seed comuni:',70,320,fonts.body,C.dim)
 for i,seed in ipairs(Config.seeds) do
  hitbox('seed_'..seed,tostring(seed),250+(i-1)*120,310,105,44,true,lab.seed_text==tostring(seed))
 end
 text('Il Correttore accantona tutti i 4/5/6 validi, rilancia sotto 300 punti e, da 300, usa un D6: 1–3 incassa, 4–6 rilancia.',
  70,400,fonts.body,C.text,1080)
 text('Ogni foglio costa 500 punti; in caso di Farkle il Correttore prende prima dal centro, poi da te.',
  70,454,fonts.body,C.text,1080)
 local seed=tonumber(lab.seed_text)
 local valid=seed and seed%1==0 and seed>=1 and seed<2147483647
 hitbox('start_corrector','Inizia',920,540,260,58,valid)
 hitbox('back_mode','Torna alla scelta',70,540,250,58,true)
 text(valid and 'I flussi casuali di Artista e Correttore sono separati.' or
  'Inserisci un intero da 1 a 2147483646.',350,558,fonts.small,valid and C.dim or C.merchant,530)
end

local function draw_v3_setup()
 lab.buttons={}
 text('V3 — La cassa tipografica',60,50,fonts.big,C.text)
 text('Quattro fogli totali a testa; un foglio ciascuno nel piatto. Primo a due mani.',60,120,fonts.body,C.dim,1120)
 text('Cassa pubblica: '..Box.description(),60,210,fonts.body,C.text,1120)
 text('Seed numerico',70,330,fonts.head,C.text)
 color(C.panel);love.graphics.rectangle('fill',260,324,250,42,6)
 color(lab.seed_focused and C.select or C.line);love.graphics.rectangle('line',260,324,250,42,6)
 text(lab.seed_text..(lab.seed_focused and '|' or ''),273,332,fonts.body,C.text,220)
 lab.buttons[#lab.buttons+1]={id='seed_field',x=260,y=324,w=250,h=42,active=true}
 text('Seed comuni:',70,400,fonts.body,C.dim)
 for i,seed in ipairs(Config.seeds) do hitbox('seed_'..seed,tostring(seed),250+(i-1)*115,390,100,42,true,lab.seed_text==tostring(seed)) end
 local seed=tonumber(lab.seed_text);local valid=seed and seed%1==0 and seed>=1 and seed<2147483647
 text(valid and 'Flussi separati: dadi Artista e cassa Mercante.' or 'Inserisci un intero da 1 a 2147483646.',
 70,475,fonts.body,valid and C.dim or C.merchant,850)
 hitbox('start_v3','Inizia V3',900,500,280,60,valid)
 hitbox('back_mode','Torna a V2 / V3',70,590,230,48,true)
end

local function draw_money_setup()
 lab.buttons={}
 text('V4 — Il Mercante e la posta',60,44,fonts.big,C.text)
 text('Dadi Farkle + cassa tipografica V3 + lira di piccoli veneziana.',60,110,fonts.body,C.dim,1130)
 text('1 lira a testa. Ante 2 soldi; un rialzo di 2 soldi per mano, prima del lancio.',60,183,fonts.head,C.pot,1120)
 text('1 lira = 20 soldi = 240 denari. Il punteggio Farkle NON viene convertito in denaro.',
  60,234,fonts.body,C.text,1150)
 text('Seed numerico',70,332,fonts.head,C.text)
 color(C.panel);love.graphics.rectangle('fill',260,326,240,45,6)
 color(lab.seed_focused and C.select or C.line)
 love.graphics.rectangle('line',260,326,240,45,6)
 text(lab.seed_text..(lab.seed_focused and '|' or ''),272,335,fonts.body,C.text,225)
 lab.buttons[#lab.buttons+1]={id='seed_field',x=260,y=326,w=240,h=45,active=true}
 for i,seed in ipairs(Config.seeds) do
  hitbox('seed_'..seed,tostring(seed),270+(i-1)*118,405,100,42,true,lab.seed_text==tostring(seed))
 end
 hitbox('money_toggle_raises',lab.money_raises_enabled and 'Rialzi: ATTIVI' or 'Rialzi: DISATTIVATI',
  660,405,280,43,true,lab.money_raises_enabled)
 local seed=tonumber(lab.seed_text)
 local valid=seed and seed%1==0 and seed>=1 and seed<2147483647
 hitbox('start_money','Avvia V4',875,530,305,60,valid)
 hitbox('back_mode','Torna agli esperimenti',70,542,290,50,true)
 text('Il Mercante può proporre, chiamare o rifiutare il rialzo: solo informazioni pubbliche.',
  60,640,fonts.small,C.dim,1100)
end

local function draw_feedback()
 local g=love.graphics;local m=lab.match;local f=lab.feedback
 lab.buttons={}
 text('Valutazione della partita',60,32,fonts.big,C.text)
 text(('Partita #%d  ·  Variante %s — %s  ·  Seed %d'):format(lab.id,m.config.variant,m.config.variant_label,m.seed),60,94,fonts.body,C.dim)
 text(('Punteggio finale: Artista %d  –  Mercante %d  ·  %s'):format(m.score.player,m.score.merchant,
  m.score.player==m.score.merchant and 'parità' or m.score.player>m.score.merchant and 'Artista in vantaggio' or 'Mercante in vantaggio'),
 60,126,fonts.head,m.score.merchant>m.score.player and C.merchant or C.player)
 text('La tua percezione (non viene dedotta dalle azioni):',60,178,fonts.body,C.text)
 text('Pressione percepita',60,220,fonts.head,C.text)
 local pressures={{'none','Nessuna'},{'moderate','Moderata'},{'strong','Forte'}}
 for i,v in ipairs(pressures) do hitbox('pressure_'..v[1],v[2],340+(i-1)*205,212,180,44,true,f.pressure==v[1]) end
 text('Il Mercante ha modificato le tue decisioni di banking?',60,284,fonts.body,C.text)
 local banking={{'yes','Sì'},{'no','No'},{'unknown','Non saprei'}}
 for i,v in ipairs(banking) do hitbox('banking_'..v[1],v[2],660+(i-1)*155,274,140,44,true,f.banking==v[1]) end
 text('Cosa ha influenzato maggiormente le decisioni?',60,346,fonts.body,C.text)
 local influences={{'score_lead','Vantaggio del Mercante'},{'sheet_value','Valore dei fogli'},
  {'farkle_risk','Rischio del Farkle'},{'none','Nessuno di questi'}}
 for i,v in ipairs(influences) do hitbox('influence_'..v[1],v[2],60+(i-1)*295,380,275,44,true,f.influence==v[1]) end
 text('Note facoltative:',60,450,fonts.body,C.dim)
 color(C.panel);g.rectangle('fill',60,480,1120,76,6)
 color(lab.notes_focused and C.select or C.line);g.setLineWidth(2);g.rectangle('line',60,480,1120,76,6)
 text(f.notes..(lab.notes_focused and '|' or ''),74,491,fonts.body,C.text,1090)
 lab.buttons[#lab.buttons+1]={id='notes_field',x=60,y=480,w=1120,h=76,active=true}
 if not lab.feedback_saved then
  local valid=f.pressure and f.banking and f.influence
  hitbox('save_feedback','Salva valutazione',900,590,280,56,valid)
  text('Seleziona una risposta per ogni domanda; le note sono facoltative.',60,606,fonts.small,C.dim,800)
 else
  text('Valutazione registrata. Grazie per aver partecipato.',60,606,fonts.body,C.good,800)
  hitbox('replay','Ripeti questa variante e seed',640,590,260,56,true)
  hitbox('variants','Torna alla scelta A/B/C',920,590,260,56,true)
 end
 text('I risultati sono esplorativi: nove partite non dimostrano un effetto causale.',60,680,fonts.small,C.dim)
 text(lab.save_note or lab.feedback_error or '',60,654,fonts.small,C.dim,1150)
end

local function draw_corrector(m)
  lab.buttons={};lab.dice={}
  local actor_names={player='Artista',corrector='Correttore',table='Sistema'}
  local action_names={
   player_roll='Lancio Artista',player_reroll='Rilancio Artista',player_farkle='Farkle Artista',
   player_set_aside='Dadi accantonati',player_banked='Artista incassa',
   player_bought_sheet='Artista compra un foglio',corrector_turn_started='Inizia il turno del Correttore',
   corrector_scored='Correttore accantona dadi',corrector_must_reroll='Rilancio obbligatorio',
   corrector_bank_decision='Decisione di incasso del Correttore',
   corrector_banked='Correttore incassa',corrector_farkle='Farkle del Correttore',
   sheet_stolen_from_center='Foglio rubato dal centro',
   sheet_stolen_from_player='Foglio rubato all’Artista',
   encounter_ended='Incontro concluso',
  }
  text(('IL CORRETTORE  ·  partita #%d  ·  seed %d  ·  turno %d'):format(lab.id,m.seed,m.turn_number),
   40,20,fonts.body,C.dim,1200,'center')
  local sheet_difference=m.sheets.player-m.sheets.corrector
  local point_difference=m.points.player-m.points.corrector
  local lead,lead_color
  if sheet_difference>0 then lead='ARTISTA AVANTI +'..sheet_difference..' FOGLI';lead_color=C.player
  elseif sheet_difference<0 then lead='CORRETTORE AVANTI +'..(-sheet_difference)..' FOGLI';lead_color=C.merchant
  elseif point_difference>0 then
   lead='PARITÀ NEI FOGLI · ARTISTA AVANTI +'..point_difference..' PUNTI';lead_color=C.player
  elseif point_difference<0 then
   lead='PARITÀ NEI FOGLI · CORRETTORE AVANTI +'..(-point_difference)..' PUNTI';lead_color=C.merchant
  else lead='PARITÀ';lead_color=C.pot end
  text(lead,40,47,fonts.small,lead_color,1200,'center')

  panel(40,78,350,154,'Artista',C.player)
  text('Punti non spesi: '..m.points.player,60,112,fonts.head,C.player,310)
  reserve(60,150,'player',m.sheets.player,'Fogli tuoi')
  panel(465,78,350,154,'Centro',C.pot)
  text(m.pot..(m.pot==1 and ' foglio' or ' fogli'),490,122,fonts.big,C.pot,290,'center')
  text('Prezzo per foglio: 500 punti',490,183,fonts.small,C.dim,290,'center')
  panel(890,78,350,154,'Il Correttore · 6 D6',C.merchant)
  text('Punti non spesi: '..m.points.corrector,910,112,fonts.head,C.merchant,310)
  text('Fogli del Correttore: '..m.sheets.corrector,910,148,fonts.body,C.merchant)
  for i=1,6 do
   die(910+(i-1)*48,176,38,m.corrector_dice and m.corrector_dice[i],
    m.corrector_kept and m.corrector_kept[i] and 'kept' or 'free')
  end

  panel(40,250,1200,275,'Il tuo turno · 6 D6 canonici',C.player)
  text('Punti totali',1000,264,fonts.small,C.dim,180,'right')
  text(tostring(m.points.player),1000,280,fonts.big,C.player,180,'right')
  local playing=m.phase=='player'
  local t=m.turn
  local selection=playing and Rules.selection(t) or nil
  local selected=playing and next(t.selected)~=nil
  for i=1,6 do
   local x=350+(i-1)*86;local y=295
   local state=t.used[i] and 'aside' or t.selected[i] and 'selected' or 'free'
   die(x,y,68,t.hand[i],state)
   text('#'..i..(t.used[i] and ' acc.' or ''),x,y+72,fonts.small,C.dim,68,'center')
   lab.dice[i]={x=x,y=y,s=68}
  end
  text('Provvisorio: '..(t.pot or 0)..(selection and ('  ·  Selezione: +'..selection) or ''),
   350,390,fonts.head,selection and C.select or C.pot,790)
  local phase_text=playing and
   (t.phase=='fresh' and 'Lancia i dadi.' or selected and 'Accantona la selezione valida o modificala.' or
    'Seleziona dadi validi, poi accantona; puoi anche incassare.') or
   m.phase=='after_player' and 'Turno concluso. Puoi comprare fogli, affrontare il Correttore o chiudere.' or
   'Turno automatico del Correttore.'
  text(lab.message~='' and lab.message or phase_text,350,433,fonts.body,C.text,820)
  local last=m.last_event and ((actor_names[m.last_event.actor] or m.last_event.actor)..' — '..
   (action_names[m.last_event.action] or m.last_event.action)) or 'nessuna'
  text('Ultima azione: '..last,
   350,479,fonts.small,C.dim,820)

  local defs={
   {'cr_roll',t.phase=='fresh' and 'Lancia [Spazio]' or 'Rilancia [Spazio]',Corrector.can_roll(m)},
   {'cr_take','Accantona [A]',Corrector.can_take(m)},
   {'cr_bank','Incassa [I]',Corrector.can_bank(m)},
   {'cr_buy','Compra foglio [C]',Corrector.can_buy(m)},
   {'cr_opponent','Turno Correttore [O]',Corrector.can_advance_corrector(m)},
   {'cr_close','Chiudi incontro [Esc]',Corrector.can_close(m)},
   {'cr_replay','Stesso seed [R]',true},
  }
  for i,b in ipairs(defs) do
   local x=40+(i-1)*170
   hitbox(b[1],b[2],x,548,158,48,b[3])
  end
  text('Farkle giocatore: '..m.player_farkles..'  ·  Farkle Correttore: '..m.corrector_farkles..
   '  ·  Fogli rubati: '..m.sheets_stolen,40,626,fonts.small,C.dim,1200,'center')
  text('Punti: Artista '..m.points.player..' — Correttore '..m.points.corrector..
   '  ·  Fogli: '..m.sheets.player..' / '..m.sheets.corrector..'  ·  Centro: '..m.pot,
   40,654,fonts.small,C.text,1200,'center')
 end

local function draw_corrector_feedback()
  local m=lab.corrector;local f=lab.corrector_feedback
  lab.buttons={}
  text('Feedback — Il Correttore',60,36,fonts.big,C.text)
  local winner_label=m.winner=='player' and 'vince l’Artista' or
   m.winner=='corrector' and 'vince il Correttore' or 'parità'
  text(('Partita #%d · seed %d · %s · fogli Artista %d / Correttore %d / centro %d'):format(
   lab.id,m.seed,winner_label,m.sheets.player,m.sheets.corrector,m.pot)..(' · punti %d / %d'):format(
   m.points.player,m.points.corrector),60,100,fonts.body,C.dim,1150)
  text('Decisioni di banking con una selezione valida: '..m.player_decision_opportunities,
   60,144,fonts.small,C.dim)
  text('Quante volte hai cambiato la scelta per la presenza del rivale?',60,180,fonts.body,C.text)
  color(C.panel);love.graphics.rectangle('fill',850,168,180,44,6)
  color(lab.corrector_notes_focused=='count' and C.select or C.line);love.graphics.rectangle('line',850,168,180,44,6)
  text(f.decision_changes..(lab.corrector_notes_focused=='count' and '|' or ''),865,177,fonts.body,C.text,150)
  lab.buttons[#lab.buttons+1]={id='corrector_count',x=850,y=168,w=180,h=44,active=true}
  local changed=tonumber(f.decision_changes)
  if changed and m.player_decision_opportunities>0 then
   text(('Quota riferita: %d / %d (%.1f%%)'):format(changed,m.player_decision_opportunities,
    changed/m.player_decision_opportunities*100),60,218,fonts.small,C.dim)
  end
  text('La minaccia si è sentita?',60,252,fonts.head,C.text)
  local threats={{'yes','Sì'},{'partial','Parziale'},{'no','No'}}
  for i,v in ipairs(threats) do
   hitbox('cr_threat_'..v[1],v[2],400+(i-1)*190,242,170,44,true,f.threat==v[1])
  end
  text('Nota libera (una riga, facoltativa):',60,330,fonts.body,C.dim)
  color(C.panel);love.graphics.rectangle('fill',60,360,1120,76,6)
  color(lab.corrector_notes_focused=='notes' and C.select or C.line);love.graphics.rectangle('line',60,360,1120,76,6)
  text(f.notes..(lab.corrector_notes_focused=='notes' and '|' or ''),74,371,fonts.body,C.text,1090)
  lab.buttons[#lab.buttons+1]={id='corrector_notes',x=60,y=360,w=1120,h=76,active=true}
  if not lab.corrector_feedback_saved then
   local count=tonumber(f.decision_changes)
   local valid=count and count%1==0 and count>=0 and
    count<=m.player_decision_opportunities and f.threat
   hitbox('save_corrector_feedback','Salva feedback',900,500,280,56,valid)
   text('Inserisci un conteggio intero e scegli una risposta sulla minaccia.',60,514,fonts.small,C.dim,800)
  else
   text('Feedback registrato.',60,514,fonts.body,C.good)
   hitbox('cr_replay','Ripeti con lo stesso seed',630,500,260,56,true)
   hitbox('back_mode','Torna alla scelta',920,500,260,56,true)
  end
  text(lab.save_note or lab.feedback_error or '',60,590,fonts.small,C.dim,1150)
end

local function draw_v3_feedback()
 local f=lab.v3_feedback;local d=lab.duel
 lab.buttons={}
 text('Feedback V3 — incontro completato',50,24,fonts.head,C.text)
 text(('Partita #%d · seed %d · Mani Artista %d — Mercante %d · Vince %s'):format(
  lab.id,d.seed,d.hands_won.artist,d.hands_won.merchant,d.winner=='artist' and 'Artista' or 'Mercante'),
 50,64,fonts.body,C.dim,1180)
 local questions={
  {key='counteroffer_rerolls',title='1. La controfferta ti ha fatto rilanciare più del solito?',choices={{'yes','Sì'},{'no','No'},{'not_sure','Non saprei'}}},
  {key='banked_below_estimate',title='2. Hai incassato apposta meno perché pensavi improbabile il sorpasso?',choices={{'yes','Sì'},{'no','No'},{'not_sure','Non saprei'}}},
  {key='merchant_decisions_clear',title='3. Le decisioni del Mercante ti sono sembrate comprensibili?',choices={{'yes','Sì'},{'no','No'},{'not_sure','Non saprei'}}},
  {key='felt_competitive',title='4. Hai percepito di competere contro un avversario?',choices={{'yes','Sì'},{'no','No'},{'not_sure','Non saprei'}}},
  {key='loss_cause',title='5. Se hai perso una mano, la causa ti è sembrata…',choices={{'choice','Scelta'},{'luck','Fortuna'},{'both','Entrambe'},{'not_lost','Non ho perso'}}},
 }
 local y=111
 for _,q in ipairs(questions) do
  text(q.title,60,y,fonts.body,C.text,600)
  local start=690;local width=#q.choices==4 and 125 or 150
  for i,c in ipairs(q.choices) do
   hitbox('v3_feedback_'..q.key..'_'..c[1],c[2],start+(i-1)*(width+8),y-6,width,34,true,f[q.key]==c[1])
  end
  y=y+78
 end
 text('Annotazioni facoltative:',60,505,fonts.small,C.dim)
 color(C.panel);love.graphics.rectangle('fill',60,530,1120,54,6)
 color(lab.notes_focused and C.select or C.line);love.graphics.rectangle('line',60,530,1120,54,6)
 text(f.notes..(lab.notes_focused and '|' or ''),72,541,fonts.small,C.text,1090)
 lab.buttons[#lab.buttons+1]={id='v3_notes',x=60,y=530,w=1120,h=54,active=true}
 if not lab.v3_feedback_saved then
  local valid=f.counteroffer_rerolls and f.banked_below_estimate and f.merchant_decisions_clear and f.felt_competitive and f.loss_cause
  hitbox('save_v3_feedback','Salva feedback',900,608,280,48,valid)
  text('Rispondi a tutte le domande per salvare.',60,619,fonts.small,C.dim,800)
 else
  text('Feedback salvato.',60,619,fonts.body,C.good)
  hitbox('v3_summary','Riepilogo incontro',360,608,240,48,true)
  hitbox('replay_v3','Rigioca stesso seed',620,608,250,48,true)
  hitbox('back_mode','Torna a V2 / V3',890,608,260,48,true)
 end
 text(lab.save_note or lab.feedback_error or '',60,682,fonts.small,C.dim,1150)
end

local function v3_button(id,label,x,y,w,h,active,primary,accent)
 local b={id=id,label=label,x=x,y=y,w=w,h=h,active=active~=false}
 lab.buttons[#lab.buttons+1]=b
 local fill=not b.active and C.off or primary and (accent or C.player) or C.panel
 color(fill);love.graphics.rectangle('fill',x,y,w,h,7)
 color(not b.active and C.dim or primary and C.text or accent or C.line)
 love.graphics.setLineWidth(primary and 3 or 2);love.graphics.rectangle('line',x,y,w,h,7)
 text(label,x+8,y+(h-fonts.body:getHeight())/2,fonts.body,
  b.active and C.text or C.dim,w-16,'center')
end

local function draw_v3_details(d)
 local labels={'V10','V20','V30','V40','X'}
 local initial={6,5,4,2,3}
 local remaining=Box.remaining(d.box);local discarded=Box.discarded(d.box)
 color(C.bg,0.94);love.graphics.rectangle('fill',0,0,W,H)
 panel(150,105,980,500,'Cassa tipografica · dettagli pubblici',C.pot)
 text('Composizione iniziale',185,164,fonts.section,C.text)
 text('Residui nella cassa',185,216,fonts.section,C.text)
 text('Caratteri negli scarti',185,268,fonts.section,C.text)
 for i,label in ipairs(labels) do
  local x=470+(i-1)*120
  local accent=i==5 and C.danger or C.pot
  text(label..'  '..initial[i],x,164,fonts.body,accent,112,'center')
  text(label..'  '..remaining[i],x,216,fonts.body,accent,112,'center')
  text(label..'  '..discarded[i],x,268,fonts.body,accent,112,'center')
 end
 text(('Totale rimasto: %d / 20   ·   X rimaste: %d   ·   Rimescolamenti: %d'):format(
  #d.box.draw_pile,remaining[5],d.box.reshuffles),185,326,fonts.body,C.text,900)
 text('Estrazioni di questa mano',185,374,fonts.section,C.text)
 text(#d.hand.symbols>0 and table.concat(d.hand.symbols,'  →  ') or '(nessuna)',
  185,408,fonts.body,C.text,900)
 text('Ultima estrazione',185,454,fonts.section,C.text)
 local last=d.hand.symbols[#d.hand.symbols]
 text(last or '(nessuna)',420,451,fonts.head,last=='X' and C.danger or C.pot)
 text('Questa vista mostra solo informazioni pubbliche e non modifica la partita.',
  185,506,fonts.body,C.dim,900)
 lab.buttons={}
 v3_button('box_details','Chiudi dettagli [E / Esc]',300,548,280,40,true,false,C.pot)
 v3_button('replay_v3','Stesso seed [R]',590,548,190,40,true,false,C.line)
 v3_button('back_mode','Varianti [Esc]',790,548,190,40,true,false,C.line)
end

local function draw_v3()
 local d=lab.duel;local h=d.hand;local turn=d.turn
 lab.buttons={};lab.v3dice={}
 local score_color=d.hands_won.artist==d.hands_won.merchant and C.text or
  d.hands_won.artist>d.hands_won.merchant and C.player or C.pot
 panel(40,14,1200,84,nil,C.line)
 text('MERCHANT WAGER LAB · V3',58,25,fonts.title,C.text)
 text(Presentation.phase_name(d):upper(),58,58,fonts.small,
  d.phase=='merchant_decision' and C.pot or d.phase=='hand_end' and C.good or C.dim)
 text('ARTISTA',424,22,fonts.small,C.player,100,'center')
 text(tostring(d.hands_won.artist),524,31,fonts.big,score_color,64,'center')
 text('—',593,39,fonts.head,C.dim,40,'center')
 text(tostring(d.hands_won.merchant),636,31,fonts.big,score_color,64,'center')
 text('MERCANTE',702,22,fonts.small,C.pot,126,'center')
 text(('MANO %d / 3'):format(h.number),1015,24,fonts.body,C.text,200,'right')
 text(('seed %d'):format(d.seed),1015,55,fonts.small,C.dim,200,'right')

 panel(40,114,790,418,'Il tuo turno · 6 D6 canonici',C.player)
 text('ARTISTA',62,157,fonts.small,C.player)
 text('DA BATTERE',620,157,fonts.small,C.dim,185,'right')
 text(h.player_result~=nil and score_text(h.player_result) or score_text(h.offer),
  620,176,fonts.head,C.pot,185,'right')
 local selection,group=Rules.selection(turn)
 local selected_count=0;for _ in pairs(turn.selected) do selected_count=selected_count+1 end
 local available=d.phase=='player' and Rules.count_free(turn) or 0
 local metrics={
  {label='PROVVISORIO',value=tostring(turn.pot),accent=C.pot},
  {label='DADI DISPONIBILI',value=tostring(available),accent=C.text},
  {label='SELEZIONE',value=selection and ('+'..selection) or '—',accent=selection and C.select or C.dim},
  {label='SELEZIONATI',value=tostring(selected_count),accent=C.text},
 }
 for i,metric in ipairs(metrics) do
  local x=62+(i-1)*183
  color(C.bg);love.graphics.rectangle('fill',x,190,168,58,5)
  text(metric.label,x+8,195,fonts.small,C.dim,152,'center')
  text(metric.value,x+8,213,fonts.head,metric.accent,152,'center')
 end
 local show_dice=d.phase=='player' or next(turn.hand)~=nil
 if show_dice then
  for i=1,6 do
   local x=74+(i-1)*122;local y=277
   local has_face=turn.hand[i]~=nil
   local state=turn.used[i] and 'kept' or turn.selected[i] and 'selected' or 'free'
   die(x,y,76,has_face and turn.hand[i] or nil,state)
   local tag=turn.used[i] and 'ACCANTONATO' or turn.selected[i] and 'SELEZIONATO' or
    has_face and 'LIBERO' or 'NON LANCIATO'
   local tag_color=turn.used[i] and C.pot or turn.selected[i] and C.select or C.dim
   text(tag,x-17,y+83,fonts.small,tag_color,110,'center')
   lab.v3dice[i]={x=x,y=y,s=76,active=Duel.can_toggle(d,i)}
  end
 end
 local instruction
 if d.phase=='player' then
  instruction=turn.phase=='fresh' and 'Pronto: lancia sei dadi.' or
   turn.hot and 'HOT DICE: il prossimo lancio usa di nuovo tutti e sei i dadi.' or
   'Accantona una selezione valida, poi rilancia o incassa.'
 else instruction='Risultato dell’ultimo lancio conservato per questa mano.' end
 text(instruction,62,397,fonts.body,C.text,740)
 local risk=turn.pot>0 and 'RISCHIO: il Farkle azzera il provvisorio.' or
  'Farkle: provvisorio perso; l’offerta iniziale decide la mano.'
 if d.phase=='player' then
  text(risk,62,434,fonts.body,turn.pot>0 and C.danger or C.dim,740)
  text(('Riserva %d fogli   ·   Piatto %d fogli'):format(d.reserve.artist,d.pot),
   62,480,fonts.body,C.pot,740)
 else
  text(('Esito Artista: %s   ·   Offerta Mercante: %s'):format(
   score_text(h.player_result),score_text(h.offer)),62,447,fonts.body,C.text,740)
 end

 panel(850,114,390,202,'Il Mercante · offerta',C.pot)
 text('OFFERTA CORRENTE',870,153,fonts.small,C.dim)
 text(score_text(h.offer),870,172,fonts.big,C.pot)
 text(('Iniziale %s'):format(score_text(h.initial_offer)),1070,178,fonts.body,C.text,150,'right')
 text('RISULTATO ARTISTA',870,230,fonts.small,C.dim)
 text(h.player_result~=nil and score_text(h.player_result) or 'in attesa',
  870,250,fonts.head,C.player,350)
 local remaining=Box.remaining(d.box)
 local last=h.symbols[#h.symbols]
 local difference=h.player_result and (h.player_result-h.offer) or nil
 text(difference and ('Differenza Artista − offerta: %+d'):format(difference) or
  'Da battere: offerta iniziale del Mercante',870,278,fonts.small,C.text,350)
 text(('Ultimo: %s   ·   Cassa: %d   ·   X: %d'):format(
  last or 'nessuno',#d.box.draw_pile,remaining[5]),870,298,fonts.small,
  last=='X' and C.danger or C.text,350)

 panel(850,330,390,202,'Ultimo evento',C.line)
 local message=Presentation.event_message(d)
 local event_color=(h.end_reason=='artist_farkle' or h.end_reason=='counteroffer_x') and C.danger or
  (d.phase=='hand_end' or d.phase=='over') and (h.winner=='artist' and C.good or C.danger) or C.text
 text(message,870,369,fonts.body,event_color,350)
 local recent=Presentation.recent_events(d,2)
 local y=451
 for _,entry in ipairs(recent) do
  text('· '..entry,870,y,fonts.small,C.dim,350);y=y+25
 end
 if #recent==0 then text('Le azioni recenti appariranno qui.',870,y,fonts.small,C.dim,350) end

 local actions=Presentation.actions(d)
 local gap=14;local total=0
 for _,action in ipairs(actions) do total=total+action.width end
 if #actions>1 then total=total+gap*(#actions-1) end
 local x=(W-total)/2
 for _,action in ipairs(actions) do
  local accent=d.phase=='merchant_decision' and C.pot or
   (action.id=='v3_bank' or action.id=='v3_next' or action.id=='open_v3_feedback') and C.good or C.player
  v3_button(action.id,action.label,x,558,action.width,50,true,action.primary,accent)
  x=x+action.width+gap
 end
 v3_button('box_details',lab.box_expanded and 'Cassa aperta [E]' or 'Dettagli cassa [E]',
  40,637,210,38,true,false,C.pot)
 text(('Partita #%d · seed ripetibile, non stessa sequenza se cambi le decisioni'):format(lab.id),
  276,647,fonts.small,C.dim,600,'center')
 v3_button('replay_v3','Stesso seed [R]',940,637,145,38,true,false,C.line)
 v3_button('back_mode','Varianti [Esc]',1095,637,145,38,true,false,C.line)

 if d.phase=='hand_end' or d.phase=='over' then
  color(C.bg,0.94);love.graphics.rectangle('fill',90,127,1100,390,10)
  color(d.phase=='over' and C.good or h.winner=='artist' and C.good or C.danger)
  love.graphics.setLineWidth(4);love.graphics.rectangle('line',90,127,1100,390,10)
  text(Presentation.hand_heading(d),130,166,fonts.big,
   d.phase=='over' and C.good or h.winner=='artist' and C.good or C.danger,1020,'center')
  text(Presentation.end_details(d),170,240,fonts.head,C.text,940,'center')
  text(('MANI VINTE   ARTISTA %d   —   %d MERCANTE'):format(
   d.hands_won.artist,d.hands_won.merchant),170,330,fonts.head,C.player,940,'center')
  if d.phase=='over' then
   text(('Piatto assegnato: %d fogli · riserve finali: Artista %d / Mercante %d'):format(
    d.pot_at_end,d.reserve.artist,d.reserve.merchant),170,390,fonts.body,C.pot,940,'center')
   text(lab.save_note or '',170,440,fonts.body,lab.save_note and lab.save_note:match('Errore') and C.danger or C.dim,940,'center')
  else
   text(('Ultima estrazione: %s · %s'):format(last or 'nessuna',
    Presentation.event_message(d)),170,390,fonts.body,
    last=='X' and C.danger or C.text,940,'center')
  end
 end
 if lab.box_expanded then draw_v3_details(d) end
end

local function draw_money()
 local m=lab.money;local d=m.base;local h=d.hand;local w=m.wager;local t=d.turn
 lab.buttons={};lab.v4dice={}
 panel(40,14,1200,82,nil,C.line)
 text('MERCHANT DUEL · V4 / LIRA DI PICCOLI',58,26,fonts.title,C.text)
 text('Mano '..h.number..'/3 · Incisore '..d.hands_won.artist..
  ' – '..d.hands_won.merchant..' Mercante',58,61,fonts.small,C.pot)
 text('seed '..m.seed..' · '..(m.raises_enabled and 'rialzi attivi' or 'senza rialzi'),
  880,40,fonts.small,C.dim,334,'right')
 panel(40,109,790,425,'INCISORE · 6 D6 Farkle',C.player)
 text('Punti provvisori',62,158,fonts.small,C.dim)
 text(tostring(t.pot),62,180,fonts.big,C.pot)
 local selection=Rules.selection(t)
 text('Selezione '..(selection and ('+'..selection) or '—'),
  230,169,fonts.head,selection and C.select or C.dim)
 text('Da battere: '..h.offer..' punti',540,177,fonts.head,C.merchant,263,'right')
 for i=1,6 do
  local x=65+(i-1)*124
  local state=t.used[i] and 'kept' or t.selected[i] and 'selected' or 'free'
  die(x,263,76,t.hand[i],state)
  text(t.used[i] and 'Accantonato' or t.selected[i] and 'Selezionato' or
   t.hand[i] and 'Libero' or 'Da lanciare',x-12,347,fonts.small,C.dim,102,'center')
  lab.v4dice[i]={x=x,y=263,s=76}
 end
 local phase_names={betting='PUNTATA INIZIALE',raise_pending='RIALZO DEL MERCANTE',
  player='TURNO FARKLE',merchant_decision='CONTROFFERTA',
  hand_end='MANO CONCLUSA',over='INCONTRO CONCLUSO'}
 text(phase_names[m.phase] or m.phase,62,387,fonts.head,C.pot,740)
 local message
 if m.phase=='raise_pending' then message='Il Mercante rilancia: accetta +2 soldi oppure ritirati.'
 elseif m.phase=='betting' then message='Puoi proporre un rialzo, oppure iniziare a lanciare.'
 elseif m.phase=='player' then
  message=t.phase=='fresh' and 'Lancia i dadi: il Mercante ha gia formulato la sua offerta.' or
   'Seleziona dadi validi, accantona e rilancia oppure incassa.'
 elseif m.phase=='merchant_decision' then
  local preview=Duel.preview_decision(d)
  message=('Possibilita pubblica di sorpasso %.1f%%; soglia IA %.0f%%.'):format(
   preview.chance*100,preview.threshold*100)
 else message=(h.end_reason or m.end_reason or 'Risultato definito') end
 text(message,62,434,fonts.body,C.text,735)
 text('Patrimonio: '..Currency.format(w.wallet.artist),
  62,479,fonts.head,C.player,740)
 panel(850,109,390,191,'MERCANTE · CASSA',C.merchant)
 text('Offerta '..h.offer..' punti',870,155,fonts.head,C.pot)
 text('Iniziale '..h.initial_offer..' · estratti '..table.concat(h.symbols,' '),
  870,186,fonts.small,C.text,345)
 local counts=Box.remaining(d.box)
 text(('Rimasti: V10 %d · V20 %d · V30 %d'):format(counts[1],counts[2],counts[3]),
  870,217,fonts.small,C.dim,340)
 text(('V40 %d · X %d · scarti %d'):format(counts[4],counts[5],#d.box.discard),
  870,242,fonts.small,C.dim,340)
 panel(850,312,390,222,'POSTA · ECONOMIA',C.pot)
 text('Piatto: '..Currency.format(w.pot),870,354,fonts.head,C.pot,348)
 text('Mercante: '..Currency.format(w.wallet.merchant),
  870,394,fonts.body,C.merchant,350)
 text('Artista: '..Currency.format(w.wallet.artist),
  870,428,fonts.body,C.player,350)
 text('Ante 2 soldi · Rialzo 2 soldi',870,461,fonts.small,C.dim,348)
 text('Fogli: '..d.hands_won.artist..' / '..d.hands_won.merchant..
  ' · Ultima transazione: '..((w.ledger[#w.ledger] or {}).action or 'nessuna'),
  870,486,fonts.small,C.dim,350)
 local actions={}
 local function add(id,label,active)
  actions[#actions+1]={id=id,label=label,active=active~=false}
 end
 if m.phase=='betting' then
  add('money_raise','Rialza · 2 soldi',MoneyDuel.can_propose(m))
  add('money_start','Lancia la mano',true)
  add('money_fold','Ritirati',true)
 elseif m.phase=='raise_pending' then
  add('money_accept','Accetta · 2 soldi',w.wallet.artist>=MoneyDuel.Wager.RAISE)
  add('money_fold','Rifiuta e ritirati',true)
 elseif m.phase=='player' then
  add('money_roll',t.phase=='fresh' and 'Lancia [Spazio]' or 'Rilancia [Spazio]',MoneyDuel.can_roll(m))
  add('money_take','Accantona [A]',MoneyDuel.can_take(m))
  add('money_bank','Incassa [I]',MoneyDuel.can_bank(m))
  add('money_fold','Ritirati [P]',true)
 elseif m.phase=='merchant_decision' then
  add('money_advance','Risolvi controfferta [C]',true)
 elseif m.phase=='hand_end' then
  add('money_next','Prossima mano [N]',true)
 elseif m.phase=='over' then
  add('money_replay','Nuovo incontro [R]',true)
 end
 local width=math.min(255,math.floor((1160-(#actions-1)*13)/#actions))
 local left=(W-(width*#actions+13*(#actions-1)))/2
 for i,a in ipairs(actions) do
  hitbox(a.id,a.label,left+(i-1)*(width+13),552,width,52,a.active)
 end
 hitbox('money_ledger',lab.money_ledger_expanded and 'Chiudi registro [E]' or 'Registro [E]',
  42,633,230,42,true)
 hitbox('money_replay','Rigioca [R]',898,633,150,42,true)
 hitbox('back_mode','Esperimenti [Esc]',1058,633,180,42,true)
 if m.phase=='hand_end' or m.phase=='over' then
  color(C.bg,0.95);love.graphics.rectangle('fill',210,190,860,250,8)
  color(h.winner=='artist' and C.good or C.danger)
  love.graphics.rectangle('line',210,190,860,250,8)
  local victor=m.phase=='over' and m.winner or h.winner
  text(victor=='artist' and 'VINCE L INCISORE' or 'VINCE IL MERCANTE',
   235,222,fonts.big,victor=='artist' and C.good or C.danger,812,'center')
  text('Posta assegnata · '..Currency.format((w.hands[#w.hands] or {}).award or 0),
   235,294,fonts.head,C.pot,812,'center')
  text('Mani '..d.hands_won.artist..' – '..d.hands_won.merchant..
   ' · '..(m.end_reason or h.end_reason or ''),235,352,fonts.body,C.text,812,'center')
  if m.phase=='over' then
   text(lab.save_note or 'Registro salvato alla conclusione dell incontro.',
    235,393,fonts.small,C.dim,812,'center')
  end
 end
 if lab.money_ledger_expanded then
  color(C.bg,0.97);love.graphics.rectangle('fill',245,104,790,432,8)
  color(C.pot);love.graphics.rectangle('line',245,104,790,432,8)
  text('LIBRO MASTRO · transazioni in denari',270,128,fonts.head,C.pot)
  local first=math.max(1,#w.ledger-11)
  for i=first,#w.ledger do
   local event=w.ledger[i]
   text(('%d. %s · %s · %s · saldo %s · piatto %s'):format(
    event.hand,event.actor,event.action,Currency.format(event.amount),
    Currency.format(event.balance_after),Currency.format(event.pot_after)),
    270,171+(i-first)*28,fonts.small,C.text,730)
  end
 end
end

local function save_feedback()
 local f=lab.feedback
 if lab.feedback_saved or not (f.pressure and f.banking and f.influence) then return end
 local row={id=lab.id,variant=lab.match.config.variant,seed=lab.match.seed,
  pressure=f.pressure,banking_influenced=f.banking,main_influence=f.influence,
  notes=f.notes:gsub('[\r\n]+',' ')}
 local ok,err=pcall(Log.save_feedback,love.filesystem,row)
 if not ok then lab.feedback_error='Errore nel salvataggio: '..tostring(err);return end
 lab.feedback_saved=true;lab.feedback_error=nil
end

local function save_corrector_if_over()
 local m=lab.corrector
 if not m or m.phase~='over' or lab.saved then return end
 if lab.capture then lab.saved=true;lab.save_note='Modalità cattura: partita non registrata.';return end
 local record=Corrector.record(m)
 local ok,err=pcall(Log.save_corrector,love.filesystem,m,record)
 lab.saved=true;lab.completed=lab.completed+1;lab.match_record=record
 lab.save_note=ok and ('Partita #'..lab.id..' registrata in '..love.filesystem.getSaveDirectory()) or
  ('Errore nel registro Correttore: '..tostring(err))
 lab.screen='corrector_feedback'
end

local function save_v3_feedback()
 local f=lab.v3_feedback
 if lab.v3_feedback_saved or not (f.counteroffer_rerolls and f.banked_below_estimate and
  f.merchant_decisions_clear and f.felt_competitive and f.loss_cause) then return end
 local record={id=lab.id,seed=lab.duel.seed,counteroffer_rerolls=f.counteroffer_rerolls,
  banked_below_estimate=f.banked_below_estimate,merchant_decisions_clear=f.merchant_decisions_clear,
  felt_competitive=f.felt_competitive,loss_cause=f.loss_cause,notes=f.notes:gsub('[\r\n]+',' ')}
 local ok,err=pcall(Log.save_v3_feedback,love.filesystem,record)
 if not ok then lab.feedback_error='Errore nel salvataggio feedback V3: '..tostring(err);return end
 lab.v3_feedback_saved=true;lab.feedback_error=nil
end

local function save_corrector_feedback()
 local f=lab.corrector_feedback
 local count=tonumber(f.decision_changes)
 local opportunities=lab.corrector.player_decision_opportunities
 if lab.corrector_feedback_saved or not (count and count%1==0 and count>=0 and
  count<=opportunities and f.threat) then return end
 local record={id=lab.id,seed=lab.corrector.seed,decision_changes=count,
  threat_perceived=f.threat,notes=f.notes:gsub('[\r\n]+',' ')}
 local ok,err=pcall(Log.save_corrector_feedback,love.filesystem,record)
 if not ok then lab.feedback_error='Errore nel feedback Correttore: '..tostring(err);return end
 lab.corrector_feedback_saved=true;lab.feedback_error=nil
end

function love.load(args)
 local seed,simulate,analyze
 for i,a in ipairs(args or {}) do
  if a=='--seed' then seed=tonumber(args[i+1]) end
  if a=='--simulate' then simulate=tonumber(args[i+1]) or 500 end
  if a=='--analyze' then analyze=true end
  if a=='--capture' then lab.capture={step=0,frames=0,shots=0} end
 end
 if analyze then
  local report=Analysis.run(love.filesystem);print(report);love.event.quit(0);return
 end
 if simulate then
  print((Simulate.report(simulate,seed or 1)));love.event.quit(0);return
 end
 fonts.small=love.graphics.newFont(14);fonts.body=love.graphics.newFont(17)
 fonts.section=love.graphics.newFont(19);fonts.head=love.graphics.newFont(22)
 fonts.title=love.graphics.newFont(26);fonts.big=love.graphics.newFont(38)
 love.math.setRandomSeed(os.time())
 if seed then lab.seed_text=tostring(seed) end
 if lab.capture then new_match(seed or 2,'A') end
 if os.getenv('MERCHANT_V4_SMOKE')=='1' then new_money_duel(seed or 101) end
end

local function capture_update()
 -- Opt-in visual check: plays automatically and saves screenshots in the save folder.
 local c=lab.capture;c.frames=c.frames+1
 if c.frames%20~=0 then return end
 local m=lab.match
 local function shot(name) love.graphics.captureScreenshot('capture_'..name..'.png');c.shots=c.shots+1 end
 if m.phase=='over' then shot('over');love.event.quit(0);return end
 if m.phase=='raise' and not c.raise then c.raise=true;shot('raise');return end
 if m.phase=='player' and m.turn.phase=='ready' and not c.ready then
  c.ready=true
  local best;for _,o in ipairs(require('src.farkle.rules').options(m.turn)) do if not best or o.points>best.points then best=o end end
  for _,id in ipairs(best.ids) do Match.toggle(m,id) end
  c.pending=best.ids
  shot('selection');return
 end
 if c.pending then for _,id in ipairs(c.pending) do Match.toggle(m,id) end;c.pending=nil end
 if m.phase=='merchant' then return end
 Simulate.step(m,Simulate.policies[2],'vedo_sempre')
 if m.phase=='merchant' then lab.timer=0.3 end
end

local money_smoke_frames=0
function love.update(dt)
 if lab.screen=='money' and lab.money then
  if lab.money.phase=='over' and not lab.saved then
   local ok,err=pcall(MoneyLog.save,love.filesystem,lab.money)
   lab.saved=ok
   lab.save_note=ok and 'V4: denari, mani e decisioni registrati.' or
    ('Salvataggio V4 non riuscito: '..tostring(err))
  end
  if os.getenv('MERCHANT_V4_SMOKE')=='1' then
   money_smoke_frames=money_smoke_frames+1
   if money_smoke_frames==30 then love.event.quit() end
  end
  return
 end
 if lab.screen=='corrector' or lab.screen=='corrector_feedback' then
  save_corrector_if_over()
  return
 end
 if lab.screen=='v3' and lab.duel then
  if lab.duel.phase=='over' and not lab.saved then
   local ok,err=pcall(Log.save_v3,love.filesystem,lab.duel,Duel.record(lab.duel))
   lab.saved=true;lab.completed=lab.completed+1
   lab.save_note=ok and ('Incontro #'..lab.id..' registrato in '..love.filesystem.getSaveDirectory()) or
    ('Errore nel registro V3: '..tostring(err))
  end
  return
 elseif lab.screen=='corrector_feedback' then
  if key=='escape' and lab.corrector_feedback_saved then lab.screen='mode'
  elseif key=='backspace' and lab.corrector_notes_focused=='count' then
   lab.corrector_feedback.decision_changes=lab.corrector_feedback.decision_changes:sub(1,-2)
  elseif key=='backspace' and lab.corrector_notes_focused=='notes' then
   lab.corrector_feedback.notes=lab.corrector_feedback.notes:sub(1,-2)
  elseif key=='r' and lab.corrector_feedback_saved then press('cr_replay') end
  return
 end
 if lab.screen~='match' or not lab.match then return end
 if lab.timer>0 then
  lab.timer=lab.timer-dt
  if lab.timer<=0 then lab.timer=0;Match.play_merchant(lab.match)
   local m=lab.match
   if m.phase=='player' then lab.message='Round '..m.round..': tocca a te. Lancia i dadi.' end
   if m.phase=='raise' then lab.message='Il Mercante alza la posta: scegli Vedo o Passo.' end
  end
 end
 if lab.capture then capture_update() end
 if lab.match.phase=='over' and not lab.saved then lab.message='Partita conclusa: premi «Nuova partita» [R].' end
 save_if_over()
end

function love.draw()
 local w,h=love.graphics.getDimensions()
 local viewport=Presentation.viewport(w,h,W,H)
 view.s=viewport.scale;view.x=viewport.x;view.y=viewport.y
 love.graphics.clear(C.bg)
 love.graphics.push();love.graphics.translate(view.x,view.y);love.graphics.scale(view.s)
 if lab.screen=='mode' then draw_mode();love.graphics.pop();return end
 if lab.screen=='setup' then draw_setup();love.graphics.pop();return end
 if lab.screen=='corrector_setup' then draw_corrector_setup();love.graphics.pop();return end
 if lab.screen=='v3_setup' then draw_v3_setup();love.graphics.pop();return end
 if lab.screen=='money_setup' then draw_money_setup();love.graphics.pop();return end
 if lab.screen=='feedback' then draw_feedback();love.graphics.pop();return end
 if lab.screen=='corrector' then draw_corrector(lab.corrector);love.graphics.pop();return end
 if lab.screen=='corrector_feedback' then draw_corrector_feedback();love.graphics.pop();return end
 if lab.screen=='v3' then draw_v3();love.graphics.pop();return end
 if lab.screen=='money' then draw_money();love.graphics.pop();return end
 if lab.screen=='v3_feedback' then draw_v3_feedback();love.graphics.pop();return end
 local m=lab.match
 text(('Variante %s — %s  ·  partita #%d  ·  seed %d  ·  round %d/%d  ·  soglia %d  ·  rialzo da %d'):format(
  m.config.variant,m.config.variant_label,lab.id,m.seed,math.min(m.round,m.config.max_rounds),m.config.max_rounds,
  m.config.win_threshold,m.config.raise_threshold),40,24,fonts.body,C.dim,1200,'center')
 local diff=m.score.merchant-m.score.player
 local lead=diff==0 and 'PARITÀ' or diff>0 and ('MERCANTE AVANTI +'..diff) or ('ARTISTA AVANTI +'..(-diff))
 text(lead,40,47,fonts.small,diff>0 and C.merchant or diff<0 and C.player or C.pot,1200,'center')
 draw_merchant(m);draw_pot(m);draw_player(m)
 layout_buttons()
 for _,b in ipairs(lab.buttons) do
  local on=b.id=='replay' or b.id=='variants' or enabled(b.id)
  color(on and C.line or C.off);love.graphics.rectangle('fill',b.x,b.y,b.w,b.h,6)
  if on and (b.id=='see' or b.id=='pass') then color(C.merchant);love.graphics.setLineWidth(3);love.graphics.rectangle('line',b.x,b.y,b.w,b.h,6) end
  text(b.label,b.x,b.y+14,fonts.body,on and C.text or C.dim,b.w,'center')
 end
 text('Punteggio iniziale: Artista '..m.config.initial_player_score..' · Mercante '..m.config.initial_merchant_score..
  '   |   Ultimo evento: '..(m.last_event or '')..'   ·   Rialzi '..m.stats.raises..' (visti '..m.stats.accepted..', passati '..m.stats.declined..')',
  40,672,fonts.small,C.dim,1200)
 love.graphics.pop()
end

local function press(id)
 if lab.screen=='mode' then
  if id=='mode_v2' then lab.mode='v2';lab.screen='setup'
  elseif id=='mode_v3' then lab.mode='v3';lab.screen='v3_setup'
  elseif id=='mode_money' then lab.mode='money';lab.screen='money_setup'
  elseif id=='mode_corrector' then lab.mode='corrector';lab.screen='corrector_setup' end
 elseif id=='back_mode' then lab.screen='mode'
 elseif lab.screen=='setup' or lab.screen=='v3_setup' or lab.screen=='money_setup' or lab.screen=='corrector_setup' then
  if id=='start' then
   local seed=tonumber(lab.seed_text)
   if seed and seed%1==0 and seed>=1 and seed<2147483647 then new_match(seed,lab.variant) end
  elseif id=='start_v3' then
   local seed=tonumber(lab.seed_text)
   if seed and seed%1==0 and seed>=1 and seed<2147483647 then new_duel(seed) end
  elseif id=='start_money' then
    local seed=tonumber(lab.seed_text)
    if seed and seed%1==0 and seed>=1 and seed<2147483647 then new_money_duel(seed) end
   elseif id=='money_toggle_raises' then lab.money_raises_enabled=not lab.money_raises_enabled
   elseif id=='start_corrector' then
   local seed=tonumber(lab.seed_text)
   if seed and seed%1==0 and seed>=1 and seed<2147483647 then new_corrector(seed) end
  elseif id=='seed_field' then lab.seed_focused=true;lab.notes_focused=false
  elseif id and id:match('^variant_') then lab.variant=id:sub(9)
  elseif id and id:match('^seed_') then lab.seed_text=id:sub(6);lab.seed_focused=false
  end
 elseif lab.screen=='money' then
  local m=lab.money
  if id=='money_raise' then MoneyDuel.propose(m)
  elseif id=='money_accept' then MoneyDuel.accept(m)
  elseif id=='money_start' then MoneyDuel.start_dice(m)
  elseif id=='money_fold' then MoneyDuel.fold(m)
  elseif id=='money_roll' then MoneyDuel.roll(m)
  elseif id=='money_take' then MoneyDuel.take(m)
  elseif id=='money_bank' then MoneyDuel.bank(m)
  elseif id=='money_advance' then MoneyDuel.advance_merchant(m)
  elseif id=='money_next' then MoneyDuel.next_hand(m)
  elseif id=='money_ledger' then lab.money_ledger_expanded=not lab.money_ledger_expanded
  elseif id=='money_replay' then new_money_duel(m.seed)
  elseif id=='back_mode' then lab.screen='mode' end
 elseif lab.screen=='v3' then
  local d=lab.duel
  if id=='v3_roll' then Duel.roll(d)
  elseif id=='v3_reroll' then Duel.roll(d)
  elseif id=='v3_take' then Duel.take(d)
  elseif id=='v3_bank' then Duel.bank(d)
  elseif id=='v3_advance' then Duel.advance_merchant(d)
  elseif id=='v3_next' then Duel.next_hand(d)
  elseif id=='box_details' then lab.box_expanded=not lab.box_expanded
  elseif id=='open_v3_feedback' and d.phase=='over' then lab.screen='v3_feedback'
  elseif id=='v3_summary' then lab.screen='v3'
  elseif id=='replay_v3' then new_duel(d.seed)
  elseif id=='back_mode' then lab.screen='mode'
  elseif id and id:match('^seed_') then lab.seed_text=id:sub(6) end
 elseif lab.screen=='feedback' then
  if id=='save_feedback' then save_feedback()
  elseif id=='replay' and lab.feedback_saved then new_match(lab.match.seed,lab.match.config.variant)
  elseif id=='variants' then lab.screen='mode'
  elseif id and id:match('^pressure_') then lab.feedback.pressure=id:sub(10)
  elseif id and id:match('^banking_') then lab.feedback.banking=id:sub(9)
  elseif id and id:match('^influence_') then lab.feedback.influence=id:sub(11)
  elseif id=='notes_field' then lab.notes_focused=true;lab.seed_focused=false end
 elseif lab.screen=='v3_feedback' then
  if id=='save_v3_feedback' then save_v3_feedback()
  elseif id=='replay_v3' and lab.v3_feedback_saved then new_duel(lab.duel.seed)
  elseif id=='v3_summary' and lab.v3_feedback_saved then lab.screen='v3'
  elseif id=='back_mode' and lab.v3_feedback_saved then lab.screen='mode'
  elseif id=='v3_notes' then lab.notes_focused=true
  elseif id and id:match('^v3_feedback_') then
   for _,key in ipairs({'counteroffer_rerolls','banked_below_estimate','merchant_decisions_clear',
    'felt_competitive','loss_cause'}) do
    local prefix='v3_feedback_'..key..'_'
    if id:sub(1,#prefix)==prefix then lab.v3_feedback[key]=id:sub(#prefix+1);break end
   end
  end
 elseif lab.screen=='corrector_feedback' then
  if id=='save_corrector_feedback' then save_corrector_feedback()
  elseif id=='cr_replay' and lab.corrector_feedback_saved then new_corrector(lab.corrector.seed)
  elseif id=='back_mode' and lab.corrector_feedback_saved then lab.screen='mode'
  elseif id=='corrector_count' then lab.corrector_notes_focused='count'
  elseif id=='corrector_notes' then lab.corrector_notes_focused='notes'
  elseif id and id:match('^cr_threat_') then lab.corrector_feedback.threat=id:sub(11)
  end
 elseif lab.screen=='match' then
  if id=='save_feedback' then save_feedback()
  elseif id=='variants' then lab.screen='mode'
  elseif id=='replay' then new_match(lab.match.seed,lab.match.config.variant)
  elseif id and id:match('^pressure_') then lab.feedback.pressure=id:sub(10)
  elseif id and id:match('^banking_') then lab.feedback.banking=id:sub(9)
  elseif id and id:match('^influence_') then lab.feedback.influence=id:sub(11)
  elseif id=='notes_field' then lab.notes_focused=true;lab.seed_focused=false
  elseif enabled(id) then actions[id]() end
 elseif lab.screen=='corrector' then
  local m=lab.corrector
  if id=='cr_roll' then
   if Corrector.roll_player(m) then lab.message=m.phase=='after_player' and
    'Farkle: perdi il provvisorio. Puoi chiudere o passare al Correttore.' or 'Lancio valido: seleziona i dadi che vuoi accantonare.' end
  elseif id=='cr_take' then
   if Corrector.take_player_dice(m) then lab.message='Dadi accantonati. Rilancia i liberi o incassa.' end
  elseif id=='cr_bank' then
   if Corrector.bank_player(m) then lab.message='Punti incassati. Ora puoi comprare fogli o affrontare il Correttore.' end
  elseif id=='cr_buy' then
   if Corrector.buy_sheet(m) then lab.message='Hai speso 500 punti per un foglio.';save_corrector_if_over() end
  elseif id=='cr_opponent' then
   if Corrector.advance_corrector(m) then
    lab.message='Turno del Correttore concluso. Tocca a te.'
    save_corrector_if_over()
   end
  elseif id=='cr_close' then
   if Corrector.close(m) then lab.message='Hai chiuso l’incontro.';save_corrector_if_over() end
  elseif id=='cr_replay' then new_corrector(m.seed)
  end
 end
end

function love.textinput(value)
 if (lab.screen=='setup' or lab.screen=='v3_setup' or lab.screen=='money_setup' or lab.screen=='corrector_setup') and lab.seed_focused then
  if value:match('^%d+$') and #lab.seed_text+#value<=10 then lab.seed_text=lab.seed_text..value end
 elseif lab.screen=='feedback' and lab.notes_focused then
  if #lab.feedback.notes+#value<=500 then lab.feedback.notes=lab.feedback.notes..value end
 elseif lab.screen=='v3_feedback' and lab.notes_focused then
  if #lab.v3_feedback.notes+#value<=500 then lab.v3_feedback.notes=lab.v3_feedback.notes..value end
 elseif lab.screen=='corrector_feedback' and lab.corrector_notes_focused=='count' then
  if value:match('^%d+$') and #lab.corrector_feedback.decision_changes+#value<=6 then
   lab.corrector_feedback.decision_changes=lab.corrector_feedback.decision_changes..value
  end
 elseif lab.screen=='corrector_feedback' and lab.corrector_notes_focused=='notes' then
  if #lab.corrector_feedback.notes+#value<=180 then lab.corrector_feedback.notes=lab.corrector_feedback.notes..value end
 end
end

function love.mousepressed(x,y,button)
 if button~=1 then return end
 x=(x-view.x)/view.s;y=(y-view.y)/view.s
 if lab.screen=='money' then
  for _,b in ipairs(lab.buttons) do
   if x>=b.x and x<=b.x+b.w and y>=b.y and y<=b.y+b.h then
    if b.active~=false then press(b.id) end
    return
   end
  end
  if not lab.money_ledger_expanded then
   for i,d in ipairs(lab.v4dice) do
    if x>=d.x and x<=d.x+d.s and y>=d.y and y<=d.y+d.s then
     MoneyDuel.toggle(lab.money,i);return
    end
   end
  end
  return
 end
 if lab.screen=='v3' then
  for _,b in ipairs(lab.buttons) do
   if x>=b.x and x<=b.x+b.w and y>=b.y and y<=b.y+b.h then
    if b.active then press(b.id) end
    return
   end
  end
  for i,d in ipairs(lab.v3dice) do
   if x>=d.x and x<=d.x+d.s and y>=d.y and y<=d.y+d.s then Duel.toggle(lab.duel,i);return end
  end
  return
 end
 if lab.screen=='corrector' then
  for _,b in ipairs(lab.buttons) do
   if x>=b.x and x<=b.x+b.w and y>=b.y and y<=b.y+b.h then
    if b.active then press(b.id) end
    return
   end
  end
  for i,d in ipairs(lab.dice) do
   if x>=d.x and x<=d.x+d.s and y>=d.y and y<=d.y+d.s then
    Corrector.toggle_player_die(lab.corrector,i);return
   end
  end
  return
 end
 if lab.screen~='match' then
  for _,b in ipairs(lab.buttons) do
   if x>=b.x and x<=b.x+b.w and y>=b.y and y<=b.y+b.h then
    if b.active~=false then press(b.id) end
    return
   end
  end
  if lab.screen=='setup' or lab.screen=='v3_setup' or lab.screen=='money_setup' or lab.screen=='corrector_setup' then lab.seed_focused=false end
  if lab.screen=='feedback' or lab.screen=='v3_feedback' then lab.notes_focused=false end
  if lab.screen=='corrector_feedback' then lab.corrector_notes_focused=false end
  return
 end
 for _,b in ipairs(lab.buttons) do
  if x>=b.x and x<=b.x+b.w and y>=b.y and y<=b.y+b.h then press(b.id);return end
 end
 for i,d in ipairs(lab.dice) do
  if x>=d.x and x<=d.x+d.s and y>=d.y and y<=d.y+d.s and lab.timer<=0 then Match.toggle(lab.match,i);return end
 end
end
function love.keypressed(key)
 if lab.screen=='mode' then
  if key=='a' or key=='2' then press('mode_v2') elseif key=='v' or key=='3' then press('mode_v3')
  elseif key=='c' then press('mode_corrector') elseif key=='4' or key=='m' then press('mode_money') end
  return
 elseif lab.screen=='corrector_setup' then
  if key=='escape' then lab.seed_focused=false
  elseif key=='backspace' and lab.seed_focused then lab.seed_text=lab.seed_text:sub(1,-2)
  elseif key=='return' or key=='kpenter' then press('start_corrector') end
  return
 elseif lab.screen=='setup' then
  if key=='escape' then lab.seed_focused=false
  elseif key=='backspace' and lab.seed_focused then lab.seed_text=lab.seed_text:sub(1,-2)
  elseif key=='return' or key=='kpenter' then press('start')
  elseif key=='a' then lab.variant='A'
  elseif key=='b' then lab.variant='B'
  elseif key=='c' then lab.variant='C' end
  return
 elseif lab.screen=='money_setup' then
  if key=='escape' then lab.screen='mode';lab.seed_focused=false
  elseif key=='backspace' and lab.seed_focused then lab.seed_text=lab.seed_text:sub(1,-2)
  elseif key=='return' or key=='kpenter' then press('start_money') end
  return
 elseif lab.screen=='v3_setup' then
  if key=='escape' then lab.screen='mode';lab.seed_focused=false
  elseif key=='backspace' and lab.seed_focused then lab.seed_text=lab.seed_text:sub(1,-2)
  elseif key=='return' or key=='kpenter' then press('start_v3') end
  return
 elseif lab.screen=='feedback' then
  if key=='escape' and lab.feedback_saved then lab.screen='mode'
  elseif key=='backspace' and lab.notes_focused then lab.feedback.notes=lab.feedback.notes:sub(1,-2)
  elseif key=='r' and lab.feedback_saved then press('replay') end
  return
 elseif lab.screen=='v3_feedback' then
  if key=='escape' and lab.v3_feedback_saved then lab.screen='mode'
  elseif key=='backspace' and lab.notes_focused then lab.v3_feedback.notes=lab.v3_feedback.notes:sub(1,-2)
  elseif key=='r' and lab.v3_feedback_saved then press('replay_v3') end
  return
 elseif lab.screen=='money' then
  if key=='escape' then press('back_mode');return end
  if key=='r' then press('money_replay');return end
  if key=='e' then press('money_ledger');return end
  local m=lab.money
  local die=tonumber(key)
  if die and die>=1 and die<=6 and MoneyDuel.can_toggle(m,die) then
   MoneyDuel.toggle(m,die);return
  end
  local map={space='money_roll',a='money_take',i='money_bank',
   p='money_fold',c='money_advance',n='money_next'}
  if key=='return' or key=='kpenter' then
   if m.phase=='betting' then press('money_start')
   elseif m.phase=='raise_pending' then press('money_accept') end
  elseif map[key] then press(map[key]) end
  return
 elseif lab.screen=='v3' then
  local action,id=Presentation.keyboard_action(lab.duel,key,lab.box_expanded)
  if action=='toggle_die' then Duel.toggle(lab.duel,id)
  elseif action=='box_details' then lab.box_expanded=not lab.box_expanded
  elseif action then press(action) end
  return
 end
 if lab.screen=='corrector' then
  local map={space='cr_roll',a='cr_take',i='cr_bank',c='cr_buy',o='cr_opponent',escape='cr_close',r='cr_replay'}
  if map[key] then press(map[key]);return end
  local i=tonumber(key)
  if i and i>=1 and i<=6 then Corrector.toggle_player_die(lab.corrector,i) end
  return
 end
 local i=tonumber(key)
 if i and i>=1 and i<=6 and lab.timer<=0 then Match.toggle(lab.match,i);return end
 local map={space='roll',a='take',i='bank',v='see',p='pass',r='replay'}
 if map[key] then press(map[key]) end
 if key=='escape' then lab.screen='setup' end
end
