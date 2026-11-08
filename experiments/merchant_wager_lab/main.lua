-- Merchant Duel V4 / Project Folio. Only the surviving playable laboratory.
-- Reuses Project Folio printshop, swappable Merchant portrait and Aldine Aetna / Cardo.
-- Farkle rules and Merchant token logic remain in their tested headless modules.
local source=love.filesystem.getSource()
package.path=source..'/../../?.lua;'..package.path
local Money=require('experiments.merchant_wager_lab.money_duel')
local Log=require('experiments.merchant_wager_lab.money_log')
local Sim=require('experiments.merchant_wager_lab.money_simulate')
local Currency=require('experiments.merchant_wager_lab.currency')
local Rules=require('src.farkle.rules')
local Box=require('experiments.merchant_wager_lab.box')

local W,H=1280,720
local P={
 ink={0.22,0.17,0.12},soft={0.44,0.34,0.24},
 paper={0.91,0.85,0.70},paperLight={0.96,0.92,0.82},
 paperShade={0.82,0.75,0.60},gold={0.64,0.39,0.17},
 olive={0.27,0.37,0.31},wine={0.49,0.26,0.22},
 grey={0.52,0.47,0.39},ivory={0.96,0.93,0.85},
 shadow={0.09,0.07,0.055},highlight={0.95,0.78,0.43},
}
local font={}
local art={}
local view={scale=1,x=0,y=0}
local app={money=nil,seed=101,id=1,raises=true,buttons={},dice={},
 mode='play',overlay=nil,saved=false,save_note='',frames=0,settingsSeed=101,settingsRaises=true}
local pips={
 [1]={{0,0}}, [2]={{-1,-1},{1,1}},
 [3]={{-1,-1},{0,0},{1,1}}, [4]={{-1,-1},{1,-1},{-1,1},{1,1}},
 [5]={{-1,-1},{1,-1},{0,0},{-1,1},{1,1}},
 [6]={{-1,-1},{1,-1},{-1,0},{1,0},{-1,1},{1,1}},
}
local function set(c,a)
 love.graphics.setColor(c[1],c[2],c[3],a or 1)
end
local function printat(str,x,y,f,col,width,align)
 local g=love.graphics
 g.setFont(f or font.body);set(col or P.ink)
 if width then g.printf(tostring(str),x,y,width,align or 'left')
 else g.print(tostring(str),x,y) end
end
local function fillrect(x,y,w,h,c,r,alpha)
 set(c,alpha or 1)
 love.graphics.rectangle('fill',x,y,w,h,r or 0,r or 0)
end
local function stroke(x,y,w,h,c,r,width)
 set(c);love.graphics.setLineWidth(width or 1)
 love.graphics.rectangle('line',x,y,w,h,r or 0,r or 0)
end
local function rule(x,y,w,c)
 set(c or P.grey,0.7);love.graphics.line(x,y,x+w,y)
end
local function file_data(path)
 local name=path:match('([^/]+)$') or path
 local f=io.open(source..'/../../'..path,'rb')
 if not f then return nil end
 local bytes=f:read('*a');f:close()
 return love.filesystem.newFileData(bytes,name)
end
local function asset_image(path)
 local data=file_data(path)
 if not data then return nil end
 local ok,img=pcall(love.graphics.newImage,data)
 if ok then img:setFilter('linear','linear');return img end
 return nil
end
local function asset_font(path,size)
 local data=file_data(path)
 if data then
  local ok,f=pcall(love.graphics.newFont,data,size)
  if ok then return f end
 end
 return love.graphics.newFont(size)
end
local function draw_fit(image,x,y,w,h,alpha)
 if not image then return end
 local iw,ih=image:getDimensions()
 local scale=math.min(w/iw,h/ih)
 local dx=x+(w-iw*scale)*0.5
 local dy=y+(h-ih*scale)*0.5
 love.graphics.setColor(1,1,1,alpha or 1)
 love.graphics.draw(image,dx,dy,0,scale,scale)
end
local function draw_cover(image,x,y,w,h,alpha)
 if not image then return end
 local iw,ih=image:getDimensions()
 local scale=math.max(w/iw,h/ih)
 love.graphics.setScissor(x,y,w,h)
 love.graphics.setColor(1,1,1,alpha or 1)
 love.graphics.draw(image,x+(w-iw*scale)*.5,y+(h-ih*scale)*.5,0,scale,scale)
 love.graphics.setScissor()
end
local function button(id,label,x,y,w,h,style,enabled)
 enabled=enabled~=false
 app.buttons[#app.buttons+1]={id=id,x=x,y=y,w=w,h=h,enabled=enabled}
 local bg=style=='primary' and P.olive or
  style=='danger' and P.wine or
  style=='quiet' and P.paperShade or P.paperLight
 fillrect(x,y,w,h,bg,3,enabled and 1 or 0.38)
 stroke(x,y,w,h,(style=='primary' or style=='danger') and P.shadow or P.soft,3,1)
 printat(label,x+8,y+math.max(6,(h-font.body:getHeight())/2),font.body,
  (style=='primary' or style=='danger') and P.ivory or P.ink,w-16,'center')
end
local function die(x,y,size,face,selected,used,enabled)
 local bg=used and P.paperShade or selected and P.highlight or P.paperLight
 fillrect(x+3,y+5,size,size,P.shadow,9,0.30)
 fillrect(x,y,size,size,bg,8)
 stroke(x,y,size,size,selected and P.gold or used and P.grey or P.soft,8,selected and 4 or 2)
 if face then
  local cx,cy=x+size/2,y+size/2
  local spread=size*0.25
  set(P.ink,used and 0.6 or 1)
  for _,pip in ipairs(pips[face]) do
   love.graphics.circle('fill',cx+pip[1]*spread,cy+pip[2]*spread,size*0.062)
  end
 else printat('–',x,y+size*.24,font.big,P.grey,size,'center') end
end
local function format_cash(n) return Currency.format(n) end
local function new_game(seed)
 app.seed=seed or app.seed
 app.id=Log.next_id(love.filesystem)
 app.money=Money.new(app.seed,app.id,{raises_enabled=app.raises})
 app.saved=false;app.save_note='';app.overlay=nil;app.mode='play'
end
local function phase_help(m)
 if m.phase=='raise_pending' then
  return 'Il Mercante ha aggiunto 2 soldi. Accetta per giocare, oppure concedigli la mano.'
 elseif m.phase=='betting' then
  return 'Le puntate iniziali sono sul tavolo. Puoi alzare la posta prima del primo lancio.'
 elseif m.phase=='player' then
  return 'Scegli i dadi da accantonare. Incassa o rilancia: un Farkle azzera il provvisorio.'
 elseif m.phase=='merchant_decision' then
  return 'Hai incassato. Il Mercante sta valutando la propria controfferta.'
 elseif m.phase=='hand_end' then
  return 'La prova è stata assegnata. Il patrimonio è aggiornato nel libro mastro.'
 end
 return 'L’incontro è concluso. Puoi iniziare una nuova partita.'
end
local function draw_backdrop()
 fillrect(0,0,W,H,P.shadow)
 draw_cover(art.room,0,0,W,H,0.46)
 fillrect(0,0,W,H,P.shadow,0,0.45)
end
local function draw_frame(x,y,w,h)
 fillrect(x+4,y+6,w,h,P.shadow,6,0.55)
 fillrect(x,y,w,h,P.paper,6,0.98)
 stroke(x,y,w,h,P.soft,6,2)
 stroke(x+5,y+5,w-10,h-10,P.paperShade,4,1)
end
local function draw_header(m)
 draw_frame(35,18,1210,76)
 printat('Il Mercante e la posta',53,24,font.title,P.ink)
 printat('UNA SCOMMESSA NELLA BOTTEGA VENEZIANA',56,66,font.small,P.soft)
 printat(('MANO %d DI 3'):format(m.base.hand.number),750,36,font.label,P.soft,180,'center')
 printat(('PROVE  %d  :  %d'):format(m.base.hands_won.artist,m.base.hands_won.merchant),
  945,33,font.head,P.ink,258,'right')
end
local function draw_merchant(m)
 draw_frame(968,111,277,472)
 fillrect(980,123,252,241,P.paperShade,3)
 if art.merchant then
  draw_fit(art.merchant,980,119,252,240,1)
 else
  printat('IL MERCANTE',988,220,font.title,P.soft,236,'center')
 end
 rule(982,369,247)
 printat('IL MERCANTE',989,378,font.head,P.ink,235,'center')
 printat('Offerta attuale',987,415,font.small,P.soft)
 printat(('%d punti'):format(m.base.hand.offer),986,431,font.head,P.wine)
 printat('Patrimonio',987,470,font.small,P.soft)
 printat(format_cash(m.wager.wallet.merchant),986,488,font.body,P.ink,232)
 local remain=Box.remaining(m.base.box)
 printat(('Cassa: %d token disponibili'):format(#m.base.box.draw_pile),986,540,font.small,P.soft,230)
end
local function draw_offer(m)
 draw_frame(35,111,915,239)
 local h=m.base.hand;local w=m.wager
 printat('LA SFIDA',57,127,font.label,P.soft)
 rule(57,158,872)
 printat('OFFERTA DEL MERCANTE',58,171,font.small,P.soft)
 printat(tostring(h.offer),58,193,font.big,P.ink)
 printat('punti da raggiungere',60,257,font.small,P.soft)
 rule(433,174,1,P.paperShade)
 printat('POSTA SUL TAVOLO',477,171,font.small,P.soft)
 printat(format_cash(w.pot),477,196,font.head,P.gold,438)
 if m.phase=='raise_pending' then
  printat('4 soldi iniziali + 2 soldi rilanciati dal Mercante',476,246,font.small,P.soft,448)
  printat('Se accetti: il piatto sale a 8 soldi. Se rifiuti: perdi i 2 già impegnati.',
   56,294,font.body,P.wine,865)
 elseif m.phase=='betting' then
  printat('2 soldi a testa già depositati',476,246,font.small,P.soft,448)
  printat('Un solo rialzo per mano, sempre prima di lanciare i dadi.',
   56,294,font.body,P.ink,855)
 elseif m.phase=='player' then
  printat('La posta è già concordata: ora contano i dadi.',477,246,font.small,P.soft,438)
  printat('Il Mercante può controbattere soltanto dopo il tuo incasso.',
   56,294,font.body,P.ink,855)
 else
  printat('Le lire sono la posta; i punti decidono chi vince.',477,246,font.small,P.soft,442)
  printat(phase_help(m),56,293,font.body,P.ink,857)
 end
end
local function draw_dice(m)
 draw_frame(35,366,915,220)
 local t=m.base.turn
 printat('I TUOI DADI',57,380,font.label,P.ink)
 printat('6 D6 · FARKLE',730,382,font.small,P.soft,200,'right')
 app.dice={}
 for i=1,6 do
  local x=64+(i-1)*146
  local y=418
  die(x,y,94,t.hand[i],t.selected[i],t.used[i],m.phase=='player')
  app.dice[i]={x=x,y=y,s=94,id=i}
  local status=t.used[i] and 'Accantonato' or t.selected[i] and 'Selezionato' or
   t.hand[i] and 'Disponibile' or 'Da lanciare'
  printat(status,x-6,y+102,font.small,t.selected[i] and P.gold or P.soft,108,'center')
 end
 local selected=Rules.selection(t)
 printat(('PROVVISORIO  %d PT'):format(t.pot),58,550,font.small,P.ink)
 printat(selected and ('SELEZIONE  +'..selected..' PT') or
  'Seleziona una combinazione valida',340,550,font.small,selected and P.olive or P.soft,580,'right')
end
local function draw_wallet(m)
 fillrect(35,596,915,26,P.shadow,2,0.75)
 printat('IL TUO PATRIMONIO  '..format_cash(m.wager.wallet.artist),51,599,font.small,P.ivory)
 local phrase=(m.wager.pending=='merchant') and 'Rialzo in attesa di risposta' or
  (m.phase=='betting' and 'Decidi prima di giocare' or
  m.phase=='player' and 'Incassa o rischia un altro lancio' or 'Duello in corso')
 printat(phrase,578,599,font.small,P.paper,360,'right')
end
local function draw_controls(m)
 app.buttons={}
 local y=639
 if m.phase=='raise_pending' then
  button('accept','ACCETTA · +2 SOLDI',48,y,350,48,'primary',true)
  button('fold','RIFIUTA · PERDI 2 SOLDI',414,y,354,48,'danger',true)
 elseif m.phase=='betting' then
  button('raise','ALZA LA POSTA · 2 SOLDI',48,y,312,48,'quiet',
   Money.can_propose(m))
  button('start','LANCIA I DADI',373,y,340,48,'primary',true)
  button('fold','RITIRATI',723,y,203,48,'danger',true)
 elseif m.phase=='player' then
  button('roll',m.base.turn.phase=='fresh' and 'LANCIA [SPAZIO]' or
   'RILANCIA [SPAZIO]',48,y,218,48,'primary',Money.can_roll(m))
  button('take','ACCANTONA [A]',278,y,204,48,'quiet',Money.can_take(m))
  button('bank','INCASSA [I]',494,y,216,48,'primary',Money.can_bank(m))
  button('fold','RITIRATI [P]',722,y,204,48,'danger',true)
 elseif m.phase=='merchant_decision' then
  button('advance','RISOLVI LA CONTROFFERTA [C]',48,y,500,48,'primary')
 elseif m.phase=='hand_end' then
  button('next','PROSSIMA MANO [N]',48,y,395,48,'primary')
 else
  button('replay','NUOVO INCONTRO [R]',48,y,395,48,'primary')
 end
 button('ledger','LIBRO MASTRO [E]',972,599,265,37,'quiet')
 button('box','DETTAGLI CASSA [B]',972,641,265,37,'quiet')
 button('settings','NUOVO INCONTRO [S]',1060,686,177,26,'quiet')
 printat(('SEED %d · %s'):format(app.seed,app.raises and 'rialzi attivi' or 'rialzi disattivati'),
  582,696,font.small,P.paperLight,350,'right')
end
local function draw_result(m)
 local winner=m.phase=='over' and m.winner or m.base.hand.winner
 if not winner then return end
 local heading=m.phase=='over' and 'INCONTRO CONCLUSO' or 'PROVA CONCLUSA'
 fillrect(176,186,879,321,P.shadow,6,0.77)
 draw_frame(192,196,848,290)
 printat(heading,222,218,font.small,P.soft,784,'center')
 printat(winner=='artist' and 'Vince l’Incisore' or 'Vince il Mercante',
  220,246,font.title,winner=='artist' and P.olive or P.wine,790,'center')
 local h=m.wager.hands[#m.wager.hands]
 printat('POSTA ASSEGNATA   '..format_cash(h and h.award or 0),
  220,323,font.head,P.ink,790,'center')
 printat('PROVE CONQUISTATE     INCISORE '..m.base.hands_won.artist..
  ' : '..m.base.hands_won.merchant..' MERCANTE',
  221,370,font.body,P.soft,788,'center')
 printat(m.phase=='over' and 'L’incontro è finito. Il libro mastro conserva tutti i movimenti.' or
  'La prossima prova comincia con una nuova puntata di 2 soldi per parte.',
  222,416,font.body,P.ink,786,'center')
end
local function draw_overlay(m)
 if not app.overlay then return end
 fillrect(0,0,W,H,P.shadow,0,0.72)
 draw_frame(224,102,833,518)
 local title=app.overlay=='ledger' and 'LIBRO MASTRO DELLA BOTTEGA' or
  app.overlay=='settings' and 'NUOVO INCONTRO' or 'CASSA TIPOGRAFICA DEL MERCANTE'
 printat(title,253,127,font.title,P.ink,770)
 rule(253,190,768)
 if app.overlay=='settings' then
  printat('La V4 è l’unico laboratorio giocabile. Scegli le condizioni di prova.',253,206,font.body,P.soft,760)
  printat('SEED DELLA PARTITA',267,265,font.label,P.soft)
  for i,seed in ipairs({101,202,303}) do
   button('seed_'..seed,tostring(seed),267+(i-1)*159,307,145,48,
    app.settingsSeed==seed and 'primary' or 'quiet',true)
  end
  printat('RIALZI',267,401,font.label,P.soft)
  button('toggle_raises',app.settingsRaises and 'ATTIVI · +2 SOLDI' or 'DISATTIVATI',
   420,393,320,49,app.settingsRaises and 'primary' or 'quiet',true)
  button('start_settings','AVVIA IL DUELLO',265,503,410,49,'primary',true)
 elseif app.overlay=='ledger' then
  printat('Ogni movimento è in denari interi; nessun denaro viene creato.',253,206,font.small,P.soft)
  local list=m.wager.ledger
  local start=math.max(1,#list-10)
  for i=start,#list do
   local e=list[i]
   local codes={ANTE='Deposito',RAISE='Rialzo',CALL='Accettazione',
    REFUND='Restituzione',FOLD='Ritiro',PAYOUT='Vincita'}
   local str=('%02d  Mano %d · %s · %s · %s'):format(i,e.hand,
    e.actor=='artist' and 'Incisore' or e.actor=='merchant' and 'Mercante' or 'Tavolo',
    codes[e.action] or e.action,format_cash(e.amount))
   printat(str,258,246+(i-start)*29,font.small,P.ink,745)
  end
  printat('Denari totali: '..Money.Wager.total(m.wager)..' / 480',
   253,573,font.small,P.olive,740)
 else
  local remaining=Box.remaining(m.base.box)
  local values=m.base.box.symbols
  for i=1,5 do
   local card=values[i]
   printat(('%s   +%d pt   %d / %d ancora in cassa'):format(
    card.id,card.points,remaining[i],card.count),269,235+(i-1)*44,font.body,P.ink,720)
  end
  printat(('Scarti %d · rimescolamenti %d'):format(
   #m.base.box.discard,m.base.box.reshuffles),264,508,font.body,P.soft)
 end
 button('close','CHIUDI [ESC]',809,559,215,44,'quiet')
end
local function press(id)
 local m=app.money
 if id=='close' then app.overlay=nil;return end
 if app.overlay=='settings' then
  local pick=id:match('^seed_(%d+)$')
  if pick then app.settingsSeed=tonumber(pick);return end
  if id=='toggle_raises' then app.settingsRaises=not app.settingsRaises;return end
  if id=='start_settings' then
   app.raises=app.settingsRaises;new_game(app.settingsSeed);return
  end
  return
 end
 if app.overlay then return end
 if id=='settings' then
  app.settingsSeed=app.seed;app.settingsRaises=app.raises
  app.overlay='settings';return
 end
 if id=='ledger' then app.overlay='ledger';return end
 if id=='box' then app.overlay='box';return end
 if id=='replay' then new_game(app.seed);return end
 if id=='accept' then Money.accept(m)
 elseif id=='raise' then Money.propose(m)
 elseif id=='start' then Money.start_dice(m)
 elseif id=='fold' then Money.fold(m)
 elseif id=='roll' then Money.roll(m)
 elseif id=='take' then Money.take(m)
 elseif id=='bank' then Money.bank(m)
 elseif id=='advance' then Money.advance_merchant(m)
 elseif id=='next' then Money.next_hand(m)
 end
end
function love.load(args)
 local sim_count,sim_seed,seed
 for i,a in ipairs(args or {}) do
  if a=='--seed' then seed=tonumber(args[i+1]) end
  if a=='--money-simulate' then sim_count=tonumber(args[i+1]) or 100 end
 end
 if sim_count then
  print((Sim.report(sim_count,seed or 1)));love.event.quit(0);return
 end
 app.seed=seed or 101
 font.title=asset_font('resources/font/AldineAetna-Regular.ttf',38)
 font.head=asset_font('resources/font/AldineAetna-Regular.ttf',31)
 font.big=asset_font('resources/font/AldineAetna-Regular.ttf',63)
 font.body=asset_font('resources/font/Cardo-Regular.ttf',20)
 font.label=asset_font('resources/font/Cardo-Regular.ttf',19)
 font.small=asset_font('resources/font/Cardo-Regular.ttf',16)
 art.room=asset_image('resources/scenes/printshop-room.png')
 art.merchant=asset_image('resources/opponents/merchant.png')
 new_game(app.seed)
end
function love.update(dt)
 if not app.money then return end
 if app.money.phase=='over' and not app.saved then
  local ok,err=pcall(Log.save,love.filesystem,app.money)
  app.saved=true
  app.save_note=ok and 'Partita registrata.' or ('Registro non salvato: '..tostring(err))
 end
 if os.getenv('MERCHANT_V4_SMOKE')=='1' then
  app.frames=app.frames+1
  if app.frames>=30 then love.event.quit(0) end
 end
end
function love.draw()
 if not app.money then return end
 local g=love.graphics
 local ww,hh=g.getDimensions()
 local scale=math.min(ww/W,hh/H)
 view.scale=scale;view.x=(ww-W*scale)/2;view.y=(hh-H*scale)/2
 g.clear(P.shadow)
 g.push()
 g.translate(view.x,view.y);g.scale(scale)
 draw_backdrop()
 local m=app.money
 draw_header(m)
 draw_offer(m)
 draw_merchant(m)
 draw_dice(m)
 draw_wallet(m)
 draw_controls(m)
 if m.phase=='hand_end' or m.phase=='over' then draw_result(m) end
 if app.overlay then
  app.buttons={}
  draw_overlay(m)
 end
 g.pop()
end
function love.mousepressed(x,y,button_id)
 if button_id~=1 or not app.money then return end
 x=(x-view.x)/view.scale;y=(y-view.y)/view.scale
 for _,b in ipairs(app.buttons) do
  if b.enabled and x>=b.x and x<=b.x+b.w and y>=b.y and y<=b.y+b.h then
   press(b.id);return
  end
 end
 if app.overlay then return end
 for _,d in ipairs(app.dice) do
  if x>=d.x and x<=d.x+d.s and y>=d.y and y<=d.y+d.s then
   Money.toggle(app.money,d.id);return
  end
 end
end
function love.keypressed(key)
 local m=app.money
 if not m then return end
 if app.overlay then
  if key=='escape' or key=='e' or key=='b' then app.overlay=nil
  elseif (key=='return' or key=='kpenter') and app.overlay=='settings' then
   press('start_settings')
  end
  return
 end
 if key=='s' then press('settings');return end
 if key=='e' then press('ledger');return end
 if key=='b' then press('box');return end
 if key=='r' then press('replay');return end
 if key=='escape' then return end
 if key:match('^[1-6]$') then Money.toggle(m,tonumber(key));return end
 local keys={space='roll',a='take',i='bank',p='fold',c='advance',n='next'}
 if key=='return' or key=='kpenter' then
  if m.phase=='raise_pending' then press('accept')
  elseif m.phase=='betting' then press('start') end
 elseif keys[key] then press(keys[key]) end
end
