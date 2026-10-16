local R=require('experiments.folio_roguelite.rules')
local Layout=require('src.features.scriptorium.page_layout')
local Desk=require('src.features.scriptorium.desk_view')
local Res=require('src.core.resolution_manager')
local Bridge=require('src.core.engine_bridge')
local U={state='waiting',dice_results={},buttons={}}
local fonts={}
local function text(s,x,y,w,size,color)
 local g=love.graphics; fonts[size]=fonts[size] or g.newFont(size); g.setFont(fonts[size])
 g.setColor(unpack(color or {.16,.1,.06,1})); g.printf(s,x,y,w,'left')
end
local function button(self,id,label,x,y,w,h,enabled,fn)
 local g=love.graphics
 g.setColor(enabled and .94 or .70,enabled and .86 or .66,enabled and .69 or .57,1)
 g.rectangle('fill',x,y,w,h,5,5); g.setColor(.36,.24,.12); g.rectangle('line',x,y,w,h,5,5)
 text(label,x+9,y+8,w-18,18)
 self.buttons[id]={x=x,y=y,w=w,h=h,enabled=enabled,fn=fn}
end
function U:isDeskLayout() return true end
function U:enter() if not self.game then self:reset() end end
function U:sync()
 for i,d in ipairs(dice or {}) do d.kept=self.game.used[i] or false end
 if self.game.phase~='rolling' then self.state=self.game.phase=='start' and 'waiting' or 'placing' end
end
function U:reset()
 if self.state=='rolling' then return end
 self.game=R.new(); self.selected=nil; self.mode=nil; self.source=nil; self.dice_results={}; self.logged=0
 self.runid=os.date('%Y%m%d-%H%M%S')..'-'..math.floor(love.timer.getTime()*1000); self:sync()
end
function U:update()
 for i=(self.logged or 0)+1,#self.game.events do
  if not love.filesystem.getInfo('runs.csv') then love.filesystem.write('runs.csv','run,event,folio,session,technique,fixed,wet,dice_available,colors_needed,detail\n') end
  love.filesystem.append('runs.csv',self.runid..','..table.concat(self.game.events[i],',')..'\n')
  self.logged=i
 end
end
function U:request()
 if not R.start(self.game) then return false end
 self.selected=nil; self.mode=nil; self.source=nil; self:sync()
 local indices={}; for i=1,4 do if not self.game.used[i] then indices[#indices+1]=i end end
 self.state='rolling'; self.onRollRequest(nil,indices); return true
end
function U:onDiceSettled(values)
 local h={}; for _,d in ipairs(values) do h[d.index]=d.value end
 assert(R.settle(self.game,h),'Invalid physical callback')
 self.dice_results={}; self:sync()
end
function U:select(i)
 if self.game.phase~='ready' or self.game.used[i] or not self.game.hand[i] then return end
 self.selected=i; self.mode=nil; self.source=nil
end
function U:slot(i)
 local s=self.game
 if s.phase~='ready' then return end
 if self.mode=='protect' then
  if R.protect(s,i) then self.mode=nil end
 elseif self.mode=='transfer' then
  if self.source then
   if R.transfer(s,self.source,i) then self.mode=nil; self.source=nil
   elseif s.slots[i] then self.source=i end
  elseif s.slots[i] then self.source=i end
 elseif self.selected then
  if R.assign(s,self.selected,i) then self.selected=nil; self:sync()
  else s.last='Scegli un requisito libero dello stesso pigmento del dado.' end
 end
end
local function ink(s,slot)
 local c=R.colors[R.recipes[s.folio][slot]]; local g=love.graphics
 if s.slots[slot] then g.setColor(c[1],c[2],c[3],s.slots[slot]=='fixed' and 1 or .62)
 else g.setColor(.28,.20,.12,.19) end
end
local function folio(s)
 local g=love.graphics
 ink(s,1); g.setLineWidth(7); g.line(700,390,737,263,779,390); g.line(716,340,762,340)
 ink(s,2); g.setLineWidth(3); g.rectangle('line',685,250,108,155); g.circle('fill',737,242,7)
 ink(s,3); g.setLineWidth(5); g.line(920,250,920,405)
 for j=0,4 do ink(s,3+j%2); g.ellipse('fill',903+(j%2)*34,266+j*28,22,9) end
 ink(s,4); g.circle('fill',920,242,9); g.circle('fill',920,413,9)
 ink(s,5); g.rectangle('line',1050,246,142,165); g.polygon('fill',1062,397,1119,302,1180,397)
 ink(s,6); g.circle('fill',1119,282,22); g.setLineWidth(4); g.line(1085,355,1151,355)
 for p=1,3 do
  local n=0; for i=p*2-1,p*2 do if s.slots[i] then n=n+1 end end
  text(R.decorations[p]..' '..n..'/2',675+(p-1)*183,443,180,20)
 end
 g.setLineWidth(1)
end
function U:draw()
 local s=self.game; if not s then return end
 local g=love.graphics; self.buttons={}; local ready=s.phase=='ready'
 Res.begin_ui(); local layout=Layout.get(); Desk.draw_background(layout)
 text('MANUSCRIPT / FOLIO IN DIVENIRE',657,82,630,27)
 text('Folio '..s.folio..'/2     Sessione '..s.session..'/'..R.limit,663,127,600,24)
 text('Fissate '..R.count(s,'fixed')..'/6    Umide '..R.count(s,'wet')..'    Riserva '..R.remaining(s)..'/4',663,172,610,21)
 folio(s)
 text('Colore pieno: fissato. Colore tenue: ancora umido.\nLe tracce grigie indicano il lavoro da realizzare.',673,502,560,18)
 text('RICETTE DEL FOLIO',113,141,360,25)
 text('Scegli un dado, poi il suo requisito.\nOgni applicazione consuma quel dado.',113,183,360,18)
 for p=1,3 do
  local y=257+(p-1)*124; text(R.decorations[p],113,y,365,22)
  for j=1,2 do
   local i=(p-1)*2+j; local st=s.slots[i]
   local label=R.names[R.recipes[s.folio][i]]..' - '..(st=='fixed' and 'FISSATO' or st=='wet' and 'UMIDO' or 'libero')
   if s.protected==i then label=label..' [P]' end
   if self.source==i then label='> '..label end
   button(self,'slot'..i,label,110,y+31+(j-1)*38,365,35,ready,function() self:slot(i) end)
  end
 end
 text('SESSIONE DI BOTTEGA',1452,145,375,24)
 local instruction=s.phase=='rolling' and 'I dadi stanno rotolando...' or self.mode=='protect' and 'Scegli una applicazione UMIDA da proteggere.' or self.mode=='transfer' and (self.source and 'Scegli un requisito libero compatibile in un altro ornamento.' or 'Scegli una applicazione da trasferire.') or s.last
 text(instruction,1452,193,365,22)
 local protected=s.protected and 1 or 0
 text('Se fallisci perdi '..math.max(0,R.count(s,'wet')-protected)..' applicazioni umide.\nIl lavoro fissato rimane.',1452,310,365,21)
 if ready and R.can_roll(s) then text(string.format('Rischio teorico del rilancio: %.1f%%\nD6 uniformi, non misura della fisica.',R.bust_probability(s)*100),1452,391,365,17) end
 local tech=s.technique=='fixative' and 'FISSATIVO\nProteggi una applicazione umida per sessione. Al fallimento viene fissata.' or s.technique=='model' and ('MODELLO PREPARATORIO\nSposta una applicazione compatibile. '..(s.model_used and 'Gia usato in questo folio.' or 'Un uso per folio.')) or 'Nessuna tecnica.\nCompleta il primo folio per sceglierne una.'
 text(tech,1452,462,365,19)
 if s.technique then
  button(self,'technique',s.technique=='fixative' and 'Scegli protezione [T]' or 'Trasferisci [T]',1450,568,375,43,ready and (s.technique=='fixative' and R.count(s,'wet')>0 or s.technique=='model' and not s.model_used and R.count(s)>0),function()
   self.mode=s.technique=='fixative' and 'protect' or 'transfer'; self.source=nil; self.selected=nil
  end)
 end
 Desk.draw_layer('palette_frame',layout.dock,function() end)
 Desk.draw_layer('actions_frame',layout.actions,function() end)
 text('RISERVA DELLA SESSIONE',112,706,365,22)
 for i=1,4 do
  local label=i..'  '..(s.hand[i] and R.names[s.hand[i]] or 'da lanciare')..(s.used[i] and ' / usato' or '')
  if self.selected==i then label='> '..label end
  button(self,'die'..i,label,110,748+(i-1)*38,365,34,ready and not s.used[i],function() self:select(i) end)
 end
 button(self,'roll',s.phase=='start' and 'Lancia [Spazio]' or 'Rilancia [Spazio]',1450,706,183,48,R.can_roll(s),function() self:request() end)
 button(self,'bank','Fissa [Invio]',1643,706,183,48,ready,function() R.bank(s); self:sync() end)
 button(self,'next','Sessione seguente [N]',1450,768,376,48,s.phase=='ended',function() R.next_session(s); self.selected=nil; self.mode=nil; self:sync() end)
 text('Si rilanciano tutti i dadi non usati.\nApplica almeno un dado prima di rilanciare un risultato positivo.',1452,880,365,18,{1,.95,.8,1})
 button(self,'restart','Nuova prova [R]',110,951,365,43,s.phase~='rolling',function() self:reset() end)
 text('1-4: scegli dado. Clic: requisito. Esc: chiudi.',90,1012,470,17,{1,.95,.8,1})
 if s.phase=='choice' then
  g.setColor(.94,.87,.70,.98); g.rectangle('fill',643,208,626,385,9,9)
  text('PRIMO FOLIO COMPLETATO',672,230,570,26)
  text('Scegli una tecnica per il secondo folio.',672,272,565,21)
  button(self,'fixative','Fissativo: salva una applicazione dal fallimento',670,322,570,60,true,function() R.choose(s,'fixative'); self:sync() end)
  button(self,'model','Modello preparatorio: trasferisce un pigmento',670,407,570,60,true,function() R.choose(s,'model'); self:sync() end)
  text('Il trasferimento cambia la composizione, non il totale\ndei pigmenti mancanti. Confronta anche questo limite.',675,491,560,18)
 elseif s.phase=='won' or s.phase=='lost' then
  g.setColor(.94,.87,.70,.97); g.rectangle('fill',650,550,605,90,5,5)
  text(s.phase=='won' and 'DUE FOLII COMPIUTI' or 'SESSIONI ESAURITE',675,561,560,27)
  text('Osserva il lavoro rimasto. R avvia una nuova prova.',675,603,560,18)
 end
 Res.end_ui()
end
function U:drawDeskOverlays(hits)
 self.hits=hits
 for _,hit in ipairs(hits or {}) do
  local i=hit.index or hit.roll_index
  if i then
   local x,y=hit.x-66,hit.y+(hit.r or 25); local s=self.game
   local label=s.hand[i] and R.names[s.hand[i]] or ''
   if s.phase=='rolling' and not s.used[i] then label='...' end
   love.graphics.setColor(.08,.055,.03,.92); love.graphics.rectangle('fill',x-4,y-3,158,24)
   text((self.selected==i and '> ' or '')..i..' '..label..(s.used[i] and ' [USATO]' or ''),x,y,154,15,{1,1,.8,1})
  end
 end
end
function U:mousepressed(x,y,b)
 if b~=1 or self.state=='rolling' then return end
 local vx,vy=Res.to_virtual(x,y)
 for _,r in pairs(self.buttons) do if r.enabled and vx>=r.x and vx<=r.x+r.w and vy>=r.y and vy<=r.y+r.h then r.fn(); return end end
 local i=Bridge.pickTrayDie(x,y); if i then self:select(i) end
end
function U:keypressed(k)
 if k=='escape' then love.event.quit(); return end
 if self.state=='rolling' then return end
 if tonumber(k) and tonumber(k)>=1 and tonumber(k)<=4 then self:select(tonumber(k)); return end
 local id=({space='roll',['return']='bank',n='next',r='restart',t='technique'})[k]
 local b=id and self.buttons[id]; if b and b.enabled then b.fn() end
end
return U
