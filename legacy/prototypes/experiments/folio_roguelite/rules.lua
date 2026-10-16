local R={names={'Rosso','Blu','Giallo','Verde','Marrone','Nero'},
 colors={{.78,.09,.08},{.12,.32,.8},{.94,.76,.12},{.18,.55,.24},{.42,.24,.12},{.07,.06,.07}},
 recipes={{1,3,3,4,2,6},{1,2,2,4,3,5}},decorations={'Iniziale','Bordura','Miniatura'},limit=4}
function R.count(s,kind)
 local n=0; for i=1,6 do if s.slots[i] and (not kind or s.slots[i]==kind) then n=n+1 end end; return n
end
function R.remaining(s)
 local n=0; for i=1,4 do if not s.used[i] then n=n+1 end end; return n
end
function R.needed(s)
 local set,n={},0; for i,c in ipairs(R.recipes[s.folio]) do if not s.slots[i] and not set[c] then set[c]=true; n=n+1 end end
 return set,n
end
function R.advance_possible(s)
 local need=R.needed(s)
 for i=1,4 do if not s.used[i] and need[s.hand[i]] then return true end end
 return false
end
function R.event(s,name,detail)
 local _,k=R.needed(s)
 s.events[#s.events+1]={name,s.folio,s.session,s.technique or 'none',R.count(s,'fixed'),R.count(s,'wet'),R.remaining(s),k,detail or ''}
end
local function session(s)
 s.used={}; s.hand={}; s.phase='start'; s.rolls=0; s.applied=false; s.protected=nil
 s.last='Lancia i quattro dadi. Anche il lavoro incompleto puo essere fissato.'
end
function R.new()
 local s={folio=1,session=1,slots={},events={},model_used=false}; session(s); R.event(s,'new_run'); return s
end
local function finish(s)
 if R.count(s,'fixed')==6 then s.phase=s.folio==1 and 'choice' or 'won'
 elseif s.session>=R.limit then s.phase='lost'
 else s.phase='ended' end
end
function R.can_roll(s)
 if s.phase=='start' then return true end
 if s.phase~='ready' or R.remaining(s)==0 or R.count(s)==6 then return false end
 return s.applied or (s.rolls==1 and not R.advance_possible(s))
end
function R.start(s)
 if not R.can_roll(s) then return false end
 s.risky=s.rolls>0; s.phase='rolling'; s.rolls=s.rolls+1; s.applied=false
 R.event(s,s.risky and 'reroll' or 'initial_roll',s.protected or ''); return true
end
function R.settle(s,values)
 if s.phase~='rolling' then return false end
 for i=1,4 do if not s.used[i] then local v=values[i]; if type(v)~='number' or v%1~=0 or v<1 or v>6 then return false end end end
 for i=1,4 do if not s.used[i] then s.hand[i]=values[i] end end
 s.phase='ready'; s.last='Scegli un dado, poi un requisito dello stesso pigmento.'
 R.event(s,'settled',table.concat(s.hand,'/'))
 if s.risky and not R.advance_possible(s) then
  local saved=0
  for i=1,6 do if s.slots[i]=='wet' then
   if i==s.protected then s.slots[i]='fixed'; saved=1 else s.slots[i]=nil end
  end end
  s.protected=nil; s.last=saved==1 and 'Fallimento: il Fissativo ha salvato una applicazione.' or 'Fallimento: perse solo le applicazioni umide.'
  finish(s); R.event(s,'bust',saved)
 end
 return true
end
function R.assign(s,die,slot)
 if s.phase~='ready' or not R.recipes[s.folio][slot] or not s.hand[die] or s.used[die] or s.slots[slot] then return false end
 if s.hand[die]~=R.recipes[s.folio][slot] then return false end
 s.slots[slot]='wet'; s.used[die]=true; s.applied=true
 s.last='Pigmento applicato: resta umido finche non fissi il lavoro.'; R.event(s,'assign',die..'>'..slot); return true
end
function R.bank(s)
 if s.phase~='ready' then return false end
 for i=1,6 do if s.slots[i]=='wet' then s.slots[i]='fixed' end end
 s.protected=nil; s.last='Lavoro fissato. Le parti incomplete restano sul folio.'
 finish(s); R.event(s,'bank'); return true
end
function R.next_session(s)
 if s.phase~='ended' then return false end
 s.session=s.session+1; session(s); R.event(s,'next_session'); return true
end
function R.choose(s,technique)
 if s.phase~='choice' or (technique~='fixative' and technique~='model') then return false end
 s.technique=technique; s.folio=2; s.session=1; s.slots={}; s.model_used=false
 session(s); R.event(s,'technique',technique); return true
end
function R.protect(s,slot)
 if s.phase~='ready' or s.technique~='fixative' or s.slots[slot]~='wet' then return false end
 s.protected=slot; s.last='Questa applicazione verra fissata anche se il rilancio fallisce.'
 R.event(s,'protect',slot); return true
end
function R.transfer(s,from,to)
 if s.phase~='ready' or s.technique~='model' or s.model_used or not s.slots[from] or s.slots[to] then return false end
 local recipe=R.recipes[s.folio]
 if not recipe[to] or recipe[from]~=recipe[to] or math.ceil(from/2)==math.ceil(to/2) then return false end
 s.slots[to]=s.slots[from]; s.slots[from]=nil; s.model_used=true
 if s.protected==from then s.protected=to end
 s.last='Applicazione trasferita: conserva lo stato fissato o umido. Nessun dado restituito.'
 R.event(s,'transfer',from..'>'..to); return true
end
function R.bust_probability(s)
 local _,k=R.needed(s); return ((6-k)/6)^R.remaining(s)
end
return R
