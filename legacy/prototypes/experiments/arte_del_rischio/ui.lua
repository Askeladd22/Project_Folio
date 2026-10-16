local R=require('experiments.arte_del_rischio.rules')
local Layout=require('src.features.scriptorium.page_layout')
local Desk=require('src.features.scriptorium.desk_view')
local Resolution=require('src.core.resolution_manager')
local Bridge=require('src.core.engine_bridge')
local U={state='waiting',held={},dice_results={},buttons={},age=0}
local fonts={}
local function text(s,x,y,w,size,color)
 local g=love.graphics; fonts[size]=fonts[size] or g.newFont(size); g.setFont(fonts[size])
 g.setColor(unpack(color or {.16,.1,.06,1})); g.printf(s,x,y,w,'left')
end
function U:isDeskLayout() return true end
function U:enter() if not self.game then self:reset('A') end end
function U:reset(v)
 if self.state=='rolling' then return end
 self.game=R.new(v); self.held={}; self.dice_results={}; self.state='waiting'; self.age=0
 for _,d in ipairs(dice or {}) do d.kept=false end
end
function U:update(dt) self.age=self.age+dt end
function U:request(tempt)
 local s=self.game; local mask=0
 for i=1,4 do if s.phase=='choose' or not self.held[i] then mask=mask+2^(i-1) end end
 if not R.start(s,mask,tempt) then return false end
 local indices={}; for i=1,4 do
  dice[i].kept=not R.has(mask,i)
  if R.has(mask,i) then indices[#indices+1]=i end
 end
 self.state='rolling'; self.onRollRequest(nil,indices); return true
end
function U:onDiceSettled(values)
 if not self.game or self.game.phase~='rolling' then return end
 local h={}; for _,d in ipairs(values) do h[d.index]=d.value end
 assert(R.settle(self.game,h),'invalid physical face callback')
 self.dice_results={} -- legacy usability glow would distort the six pigments
 self.state='placing'; self.age=0
end
function U:toggle(i)
 if self.game.phase~='ready' then return end
 self.held[i]=not self.held[i]; dice[i].kept=self.held[i]
end
local function button(self,id,label,x,y,w,h,enabled,fn)
 local g=love.graphics
 g.setColor(enabled and .92 or .64,enabled and .84 or .61,enabled and .65 or .54,1)
 g.rectangle('fill',x,y,w,h,5,5); g.setColor(.33,.21,.1,1); g.rectangle('line',x,y,w,h,5,5)
 text(label,x+10,y+8,w-20,18)
 self.buttons[id]={x=x,y=y,w=w,h=h,enabled=enabled,fn=fn}
end
local function recipe(p)
 local a={}; for _,c in ipairs(R.projects[p].recipe) do a[#a+1]=R.names[c] end; return table.concat(a,' + ')
end
local function ornament(work,x,y,alpha)
 local g=love.graphics; local p=work.project
 local c=R.colors[R.projects[p].recipe[1]]; g.setColor(c[1],c[2],c[3],alpha)
 g.setLineWidth(4)
 if p==1 then
  g.rectangle('line',x,y,105,105); text('A',x+22,y+5,85,72,{c[1],c[2],c[3],alpha})
 elseif p==2 then
  g.line(x+50,y,x+50,y+100)
  for j=0,3 do g.ellipse('fill',x+32,y+15+j*23,20,8); g.ellipse('fill',x+68,y+25+j*23,20,8) end
  g.setColor(unpack(R.colors[3])); g.circle('fill',x+50,y+6,8)
 else
  g.rectangle('line',x,y,105,105); g.polygon('fill',x+15,y+95,x+50,y+36,x+90,y+95)
  g.setColor(unpack(R.colors[3])); g.circle('fill',x+51,y+28,16)
  g.setColor(unpack(R.colors[2])); g.arc('line','open',x+51,y+28,25,0,math.pi*2)
 end
 text('+'..work.points,x+30,y+112,80,18)
end
function U:draw()
 local s=self.game; if not s then return end
 local g=love.graphics; self.buttons={}
 Resolution.begin_ui(); Desk.draw_background(Layout.get())
 text("L'ARTE DEL RISCHIO  /  "..s.variant,655,84,610,27)
 text('Turno '..s.turn..'/8   Punti netti: '..s.score..' / 25',660,129,590,21)
 text('Obiettivo: 25 punti e almeno un’opera per tipo',660,164,590,18)
 for i,work in ipairs(s.works) do ornament(work,665+((i-1)%4)*150,217+math.floor((i-1)/4)*176,math.min(1,self.age*3+.25)) end
 if #s.works==0 then text('Le opere assicurate appariranno qui.',690,310,520,24) end
 text('TRE PROGETTI',112,145,340,24)
 for p,proj in ipairs(R.projects) do
  local y=192+(p-1)*126
  local can=(s.phase=='choose' and s.variant~='B') or (s.phase=='ready' and ((s.variant=='B' and not s.project) or (s.variant=='C' and not s.changed and s.project~=p)))
  button(self,'project'..p,(s.project==p and '> ' or '')..proj.name,110,y,360,43,can,function() R.select(s,p) end)
  text(recipe(p),120,y+50,340,17)
  text(proj.base..' punti; '..(p==3 and 'senza finiture' or 'finiture +2')..' | Opere: '..s.counts[p],120,y+79,340,17)
 end
 text('PREPARAZIONE',1455,148,345,24)
 local free=false; for i=1,4 do if not self.held[i] then free=true end end
 local phase=s.phase=='rolling' and 'I dadi stanno rotolando...' or (s.phase=='ready' and not free and 'Tutti trattenuti: libera un dado per rilanciare.' or s.last)
 text(phase,1455,195,345,22)
 text('Rilanci ordinari: '..s.rerolls..' / 2',1455,275,345,21)
 local maximum=s.project and (({7,8,10})[s.project]-(s.changed and 2 or 0)) or 10
 text('Assicurabile: '..R.reward(s)..'  /  Massimo: '..maximum,1455,313,345,21)
 text('Tentazioni: '..s.temptations..'  |  Penalita: -'..(s.temptations*(s.temptations+1)/2),1455,351,345,18)
 text('Prossima Tentazione: -'..(s.temptations+1)..' anche se fallisci.',1455,389,345,18)
 text(s.variant=='A' and 'A: progetto vincolato prima del lancio.' or s.variant=='B' and 'B: scegli dopo il primo lancio, poi resta vincolato.' or 'C: un cambio dopo il lancio; opera -2 punti.',1455,447,345,19)
 text(R.score(s.project,s.hand)>0 and R.reward(s)==maximum and 'Massimo raggiunto: rilanciare causa una perdita certa.' or 'Rischiare un’opera completa richiede piu punti lordi: altrimenti perdi la preparazione.',1455,515,345,18)
 local layout=Layout.get()
 Desk.draw_layer('palette_frame',layout.dock,function() end)
 Desk.draw_layer('actions_frame',layout.actions,function() end)
 text('DADI TRATTENUTI',112,709,350,21)
 text('Clic sui dadi 3D o tasti 1–4.\nTrattieni / libera prima del rilancio.',112,745,350,18)
 for i=1,4 do text(i..': '..(s.hand[i] and R.names[s.hand[i]] or '—')..(self.held[i] and ' [FERMO]' or ''),112+((i-1)%2)*180,808+math.floor((i-1)/2)*34,180,17) end
 local ready=s.phase=='ready' and s.project~=nil
 local canroll=(s.phase=='choose' and (s.project or s.variant=='B')) or (ready and s.rerolls>0 and free)
 button(self,'roll',s.phase=='choose' and 'Lancia [Spazio]' or 'Rilancia [Spazio]',1450,704,180,48,canroll,function() self:request(false) end)
 button(self,'bank','Assicura [Invio]',1640,704,180,48,ready and R.score(s.project,s.hand)>0,function() R.bank(s); self.age=0 end)
 button(self,'tempt','Tentazione [T]',1450,767,180,48,ready and s.rerolls==0 and not s.tempted and free,function() self:request(true) end)
 button(self,'pass',s.phase=='ended' and 'Turno seguente' or 'Abbandona',1640,767,180,48,s.phase~='rolling' and not s.finished,function()
  if s.phase=='ended' then R.next_turn(s); self.held={}; for _,d in ipairs(dice) do d.kept=false end
  else R.abandon(s) end
 end)
 for i,v in ipairs({'A','B','C'}) do button(self,'variant'..v,'Nuova '..v,90+(i-1)*133,955,122,45,s.phase~='rolling',function() self:reset(v) end) end
 text('Nuova A/B/C ricomincia la partita. Esc: chiudi il prototipo.',90,1013,440,16,{1,.95,.8,1})
 if s.finished then text(s.won and 'COMMISSIONE RIUSCITA' or 'COMMISSIONE INCOMPLETA',1435,910,420,26) end
 Resolution.end_ui()
end
function U:drawDeskOverlays(hits)
 self.hits=hits
 -- Hits are in screen coordinates; labels follow the actual projected dice.
 for _,hit in ipairs(hits or {}) do
  local i=hit.index or hit.roll_index
  if i then
   local x,y=(hit.x or 0)-55,(hit.y or 0)+(hit.r or 25)
   local name=self.game.hand[i] and R.names[self.game.hand[i]] or ''
   if self.state=='rolling' and not self.held[i] then name='...' end
   love.graphics.setColor(.08,.055,.03,.9); love.graphics.rectangle('fill',x-4,y-3,140,23)
   text(i..' '..name..(self.held[i] and ' [F]' or ''),x,y,138,15,{1,1,.8,1})
  end
 end
end
function U:mousepressed(x,y,b)
 if b~=1 or self.state=='rolling' then return end
 local vx,vy=Resolution.to_virtual(x,y)
 for _,r in pairs(self.buttons) do if r.enabled and vx>=r.x and vy>=r.y and vx<=r.x+r.w and vy<=r.y+r.h then r.fn(); return end end
 local i=Bridge.pickTrayDie(x,y); if i then self:toggle(i) end
end
function U:keypressed(k)
 if k=='escape' then love.event.quit(); return end
 if self.state=='rolling' then return end
 if tonumber(k) and tonumber(k)>=1 and tonumber(k)<=4 then self:toggle(tonumber(k)); return end
 local id=({space='roll',['return']='bank',t='tempt',n='pass',a='variantA',b='variantB',c='variantC'})[k]
 local r=id and self.buttons[id]; if r and r.enabled then r.fn() end
end
return U
