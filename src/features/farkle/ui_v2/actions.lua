-- UI 2.0 experimental command model. Pure LÖVE-free action registration.
-- Authoritative scoring and side effects stay in R / controller.  This
-- module is deliberately separate from geometry, painting and mouse picking.
local R=require('src.gameplay.farkle.rules')
local H=require('src.features.farkle.hud_model')
local Medals=require('src.gameplay.farkle.medals')
local M={}

local function entry(id,label,enabled,fn,slot,detail)
 return {id=id,label=label,enabled=not not enabled,fn=fn,slot=slot,detail=detail}
end

function M.build(u)
 local s=assert(u.game,'UI 2.0 actions require authoritative Farkle game')
 local a={}
 local function add(id,label,enabled,fn,slot,detail)
  a[#a+1]=entry(id,label,enabled,fn,slot,detail)
 end
 local block=s.phase=='rolling'
 if H.reward_active(s) then return a end
 add('help','Regole [?]',not block,function() u.modal='help' end,'header')
 add('runmenu','Menu',not block,function() u.modal='run' end,'header')
 add('folio','Apri folio [F]',not block,function() u.modal='folio' end,'folio')
 if s.phase=='ready' then
  local choices=R.options(s)
  if #choices>0 then add('choices','Combinazioni ('..#choices..')',true,
   function() u.choicePage=1;u.modal='choices' end,'context') end
 end
 if s.medal~='none' then
  local d=Medals.get(s.medal)
  local uses=Medals.remaining(s)
  add('medaluse',(d and d.label or 'Correttore')..' · '..uses..' usi',
    d~=nil and not block and not H.commission_closed(s),
    function() u.medalDice={};u.modal='medaluse' end,'context')
 end

 if u.physicalFailure then
  add('retryphysical','Riprova tiro fisico',true,
   function() u:retry_physical() end,'primary','Recupero tecnico, non Farkle')
 elseif s.phase=='rescue' then
  add('rescue','Usa Correttore [M]',true,
   function() u:request(true) end,'primary','Salva il turno')
  add('fail','Accetta Farkle',true,
   function() u:act('accept_bust',function() return R.fail(s) end) end,
   'secondary','Perdi i punti a rischio')
 elseif H.commission_closed(s) then
  if s.phase=='advance' then
   add('next','Prossima commissione [N]',true,
     function() u:act('next',function() return R.advance(s) end) end,'primary')
  end
 elseif s.phase=='ended' then
  add('next','Prossimo turno [N]',true,
   function() u:act('next',function() return R.next_turn(s) end) end,'primary')
 else
  local pts=R.selection(s)
  local has_selection=next(s.selected)~=nil
  if has_selection then
   local n=H.selected_count(s)
   add('take',pts and ('Accantona '..n..' · +'..pts..' pt') or 'Selezione non valida',
     pts~=nil,function() u:act('take',function() return R.take(s) end) end,
     'primary','[A] · Convalida la combinazione')
  else
   local can=R.can_roll(s) and u.manualRoll==nil
   local label=s.hot and 'Rilancia sei dadi' or
     (s.phase=='fresh' and 'Lancia i sei dadi' or
       'Rilancia '..R.count_free(s)..' dadi')
   add('roll',label,can,function() u:request() end,
    'primary','[Spazio] · Destro: presa fisica')
  end
  local ok,total,min=R.bank_status(s)
  if not has_selection then
   add('bank','Incassa '..total..' pt',ok,
    function() u:act('bank',function() return R.bank_turn(s) end) end,
    'secondary','[Invio] · minimo '..min..' pt')
  end
 end
 return a
end

function M.state(u)
 if u.mouseThrow then
  local count=u.mouseThrow.held and #u.mouseThrow.held or 1
  return count>1 and ('GRUPPO DI '..count..' DADI IN MANO · Esc annulla') or
    'DADO IN MANO · Muovi, rilascia; Esc annulla'
 end
 if u.manualRoll then
  return 'LANCIO MANUALE · '..u.manualRoll.count..' dadi ancora da lanciare'
 end
 return H.state_text(u)
end

return M
