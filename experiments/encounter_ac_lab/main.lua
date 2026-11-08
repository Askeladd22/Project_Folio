-- Independent playable research scene. The production g3d game is untouched.
local src=love.filesystem.getSource()
package.path=src..'/../../?.lua;'..package.path
local E=require('experiments.encounter_ac_lab.engine')
local Sim=require('experiments.encounter_ac_lab.simulate')
local Rules=require('src.farkle.rules')
local W,H=1280,720
local P={bg={.18,.14,.105},paper={.95,.88,.73},ivory={.99,.95,.83},
 ink={.19,.16,.12},soft={.49,.38,.28},green={.24,.40,.34},
 red={.53,.27,.23},gold={.78,.59,.31},white={1,1,1}}
local app={mode='A',seed=101,s=nil,buttons={},dice={},font={},v={x=0,y=0,scale=1},frames=0,room=nil}
local pips={
 [1]={{0,0}},[2]={{-1,-1},{1,1}},[3]={{-1,-1},{0,0},{1,1}},
 [4]={{-1,-1},{1,-1},{-1,1},{1,1}},
 [5]={{-1,-1},{1,-1},{0,0},{-1,1},{1,1}},
 [6]={{-1,-1},{1,-1},{-1,0},{1,0},{-1,1},{1,1}}
}
local function color(c,a) love.graphics.setColor(c[1],c[2],c[3],a or 1) end
local function rect(x,y,w,h,c)
 color(c);love.graphics.rectangle('fill',x,y,w,h,5,5)
end
local function txt(str,x,y,font,c,w)
 local g=love.graphics
 g.setFont(font or app.font.body);color(c or P.ink)
 if w then g.printf(tostring(str),x,y,w,'left') else g.print(tostring(str),x,y) end
end
local function load_data(path)
 local f=io.open(src..'/../../'..path,'rb')
 if not f then return nil end
 local bytes=f:read('*a');f:close()
 return love.filesystem.newFileData(bytes,path:match('([^/]+)$'))
end
local function asset_font(path,size)
 local data=load_data(path)
 if data then
  local ok,result=pcall(love.graphics.newFont,data,size)
  if ok then return result end
 end
 return love.graphics.newFont(size)
end
local function new_game(mode,seed)
 app.mode=mode;app.seed=seed
 app.s=E.new(mode,seed);app.buttons={};app.dice={}
end
local function panel(x,y,w,h)
 rect(x+3,y+4,w,h,P.bg);rect(x,y,w,h,P.paper)
 color(P.soft);love.graphics.rectangle('line',x,y,w,h,5,5)
end
local function button(id,label,x,y,w,h,enabled,primary)
 local on=enabled~=false
 app.buttons[#app.buttons+1]={id=id,x=x,y=y,w=w,h=h,on=on}
 rect(x,y,w,h,primary and P.green or P.ivory)
 color(primary and P.green or P.soft,on and 1 or .2)
 love.graphics.rectangle('line',x,y,w,h,5,5)
 txt(label,x+8,y+11,app.font.body,primary and P.white or on and P.ink or P.soft,w-16)
end
local function die(id,x,y,s)
 local v=s.turn.hand[id]
 local used=s.turn.used[id];local selected=s.turn.selected[id]
 local size=85
 rect(x+3,y+4,size,size,P.bg)
 rect(x,y,size,size,used and P.gold or selected and P.gold or P.ivory)
 color(selected and P.green or P.soft);love.graphics.setLineWidth(selected and 4 or 1)
 love.graphics.rectangle('line',x,y,size,size,7,7)
 if v then
  color(P.ink,used and .4 or 1)
  for _,pip in ipairs(pips[v]) do
   love.graphics.circle('fill',x+size/2+pip[1]*size*.24,
    y+size/2+pip[2]*size*.24,5)
  end
 else txt('?',x+31,y+24,app.font.heading,P.soft) end
 txt(used and 'Usato' or selected and 'Scelto' or 'Libero',
  x+15,y+94,app.font.small,P.soft)
 app.dice[#app.dice+1]={id=id,x=x,y=y,size=size}
end
local function draw_board(s)
 panel(817,116,429,461)
 txt('PROVE CONTENDIBILI',844,137,app.font.heading,P.ink)
 for i,l in ipairs(s.lanes) do
  local y=207+(i-1)*111
  rect(838,y,384,94,P.ivory)
  txt(l.name,855,y+10,app.font.label,P.ink)
  txt(('Incisore: %d'):format(l.player),855,y+52,app.font.body,P.green)
  txt(('Rivale: %d'):format(l.rival),1025,y+52,app.font.body,P.red)
  if l.owner then txt('SIGILLATA: '..(l.owner=='player' and 'INCISORE' or 'RIVALE'),
   1013,y+9,app.font.small,P.soft,200) end
 end
end
local function draw_left(s)
 panel(35,116,761,461)
 txt('IL TUO FARKLE',60,135,app.font.heading,P.ink)
 txt('Sei D6 · combinazioni originali · nessun secondo Farkle avversario',
  60,184,app.font.small,P.soft)
 app.dice={}
 for i=1,6 do die(i,61+(i-1)*121,266,s) end
 txt(('PROVVISORIO: %d punti'):format(s.turn.pot),61,454,app.font.label,P.ink)
 local selection=Rules.selection(s.turn)
 txt(selection and ('SELEZIONE: +%d punti'):format(selection) or
  'Seleziona una combinazione valida, poi accantona o incassa.',
  61,497,app.font.body,selection and P.green or P.soft,706)
 if s.phase=='offer' then
  local p=E.PAIRS[s.pair]
  local preview=E.preview_offer(s)
  txt(('%d sigilli: %s +%d / %s +%d'):format(s.offered_marks,
   s.lanes[p[1]].name,s.left,s.lanes[p[2]].name,s.offered_marks-s.left),
   61,528,app.font.small,P.ink,702)
  txt(('Il rivale sceglierebbe %s · tua iniziativa +1'):format(
   s.lanes[preview.rival_id].name),61,550,app.font.small,P.green,702)
 elseif s.phase=='claim' then
  txt(('Hai %d sigilli: scegli una prova disponibile.'):format(s.claim_marks),
    61,540,app.font.small,P.green,700)
 elseif s.phase=='finished' then
  txt('ESITO: '..(s.winner=='player' and 'VINCE L’INCISORE' or
   s.winner=='rival' and 'VINCE IL RIVALE' or 'PAREGGIO'),
   61,540,app.font.label,P.green,700)
 end
end
local function draw_controls(s)
 panel(35,588,1211,115)
 txt(s.last,57,598,app.font.small,P.ink,1150)
 app.buttons={}
 if s.phase=='dice' then
  button('roll','LANCIA / RILANCIA [SPAZIO]',48,637,335,47,E.can_roll(s),true)
  button('take','ACCANTONA [A]',397,637,260,47,Rules.selection(s.turn)~=nil)
  button('bank','INCASSA [I]',671,637,283,47,E.can_bank(s),true)
 elseif s.phase=='offer' then
  button('pair','COPPIA [TAB]',48,637,243,47)
  button('less','- [SINISTRA]',305,637,153,47,s.left>1)
  button('more','+ [DESTRA]',474,637,152,47,s.left<s.offered_marks-1)
  button('offer','CONFERMA OFFERTA [INVIO]',644,637,310,47,true,true)
 elseif s.phase=='claim' then
  for i=1,3 do
   button('claim_'..i,'PROVA '..i,48+(i-1)*304,637,291,47,
    s.lanes[i].owner==nil,true)
  end
 elseif s.phase=='round_end' then
  button('next','PROSSIMA PROVA [INVIO]',48,637,441,47,true,true)
 else button('restart','RICOMINCIA [R]',48,637,441,47,true,true) end
 button('mode','CAMBIA A/C [M]',986,639,238,43)
end
local function press(id)
 local s=app.s
 if id=='mode' then new_game(s.mode=='A' and 'C' or 'A',app.seed)
 elseif id=='restart' then new_game(app.mode,app.seed)
 elseif id=='roll' then E.roll(s)
 elseif id=='take' then E.take(s)
 elseif id=='bank' then E.bank(s)
 elseif id=='pair' then E.pair_next(s)
 elseif id=='less' then E.split(s,-1)
 elseif id=='more' then E.split(s,1)
 elseif id=='offer' then E.resolve_offer(s)
 elseif id=='next' then E.next_round(s)
 else
  local target=id:match('^claim_(%d+)$')
  if target then E.claim(s,tonumber(target)) end
 end
end
function love.load(args)
 local seed,mode,simulate
 for i,arg in ipairs(args or {}) do
  if arg=='--seed' then seed=tonumber(args[i+1])
  elseif arg=='--mode' then mode=args[i+1]
  elseif arg=='--simulate' then simulate=tonumber(args[i+1]) or 30 end
 end
 if simulate then
  print(Sim.report(simulate,seed or 101))
  love.event.quit(0);return
 end
 app.font.heading=asset_font('resources/font/AldineAetna-Regular.ttf',31)
 app.font.body=asset_font('resources/font/Cardo-Regular.ttf',20)
 app.font.label=asset_font('resources/font/Cardo-Regular.ttf',24)
 app.font.small=asset_font('resources/font/Cardo-Regular.ttf',17)
 local data=load_data('resources/scenes/printshop-room.png')
 if data then
  local ok,img=pcall(love.graphics.newImage,data)
  if ok then app.room=img end
 end
 new_game(mode=='C' and 'C' or 'A',seed or 101)
end
function love.update(dt)
 if os.getenv('ENCOUNTER_AC_SMOKE')=='1' then
  app.frames=app.frames+1
  if app.frames>=40 then love.event.quit(0) end
 end
end
function love.draw()
 if not app.s then return end
 local g=love.graphics
 local ww,hh=g.getDimensions()
 local scale=math.min(ww/W,hh/H)
 local v=app.v;v.scale=scale;v.x=(ww-W*scale)/2;v.y=(hh-H*scale)/2
 g.clear(P.bg);g.push();g.translate(v.x,v.y);g.scale(scale)
 rect(0,0,W,H,P.bg)
 if app.room then
  local iw,ih=app.room:getDimensions()
  color(P.white,.25);g.draw(app.room,0,0,0,W/iw,H/ih)
 end
 panel(35,20,1211,87)
 txt('Project Folio · Laboratorio A/C',58,26,app.font.heading,P.ink)
 txt(app.s.mode=='A' and 'A · OFFERTE E CONTROMOSSE' or 'C · PROVE CONTESE',
  58,75,app.font.small,P.soft)
 txt(('Prova %d / %d · Seed %d'):format(app.s.round,app.s.max_rounds,app.seed),
  980,47,app.font.small,P.ink)
 draw_left(app.s);draw_board(app.s);draw_controls(app.s)
 g.pop()
end
function love.mousepressed(x,y,b)
 if b~=1 or not app.s then return end
 local v=app.v
 x=(x-v.x)/v.scale;y=(y-v.y)/v.scale
 for _,it in ipairs(app.buttons) do
  if it.on and x>=it.x and x<=it.x+it.w and y>=it.y and y<=it.y+it.h then
   press(it.id);return
  end
 end
 if app.s.phase=='dice' then
  for _,d in ipairs(app.dice) do
   if x>=d.x and x<=d.x+d.size and y>=d.y and y<=d.y+d.size then
    E.toggle(app.s,d.id);return
   end
  end
 end
end
function love.keypressed(key)
 if not app.s then return end
 local s=app.s
 if key=='m' then press('mode')
 elseif key=='r' then press('restart')
 elseif key=='tab' then press('pair')
 elseif key=='left' then press('less')
 elseif key=='right' then press('more')
 elseif key=='space' then press('roll')
 elseif key=='a' then press('take')
 elseif key=='i' then press('bank')
 elseif key:match('^[1-6]$') then E.toggle(s,tonumber(key))
 elseif key=='return' or key=='kpenter' then
  if s.phase=='offer' then press('offer')
  elseif s.phase=='round_end' then press('next')
  elseif s.phase=='finished' then press('restart') end
 elseif s.phase=='claim' and (key=='z' or key=='x' or key=='c') then
  press('claim_'..({z=1,x=2,c=3})[key])
 end
end
