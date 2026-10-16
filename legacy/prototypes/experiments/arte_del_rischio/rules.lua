-- Pure deterministic rules. Numbers below identify pigments, never die values.
local R={names={'Rosso','Blu','Giallo','Verde','Marrone','Nero'},
 colors={{.78,.09,.08},{.12,.32,.8},{.94,.76,.12},{.18,.55,.24},{.42,.24,.12},{.07,.06,.07}},
 projects={{name='Capolettera rubro',recipe={1,1},base=3},
 {name='Fregio vegetale',recipe={4,4,3},base=6},
 {name='Miniatura istoriata',recipe={1,2,3,6},base=10}}}
function R.has(mask,i) return math.floor(mask/2^(i-1))%2==1 end
function R.score(p,hand)
 if not p then return 0 end
 local counts,allowed={},{}
 for _,c in ipairs(hand) do counts[c]=(counts[c] or 0)+1 end
 for _,c in ipairs(R.projects[p].recipe) do
  if (counts[c] or 0)<1 then return 0 end
  counts[c]=counts[c]-1; allowed[c]=true
 end
 local value=R.projects[p].base
 for c,n in pairs(counts) do if allowed[c] then value=value+2*n end end
 return value
end
function R.new(variant)
 assert(variant=='A' or variant=='B' or variant=='C')
 return {variant=variant,turn=1,score=0,temptations=0,works={},counts={0,0,0},
 phase='choose',rerolls=2,hand={},changed=false,tempted=false,last='Scegli e prepara'}
end
function R.select(s,p)
 if not R.projects[p] or s.finished then return false end
 if s.phase=='choose' and s.variant~='B' then s.project=p; return true end
 if s.phase~='ready' or p==s.project then return false end
 if s.variant=='B' and not s.project then s.project=p; return true end
 if s.variant=='C' and not s.changed then s.project=p; s.changed=true; return true end
 return false
end
function R.reward(s) return math.max(0,R.score(s.project,s.hand)-(s.changed and 2 or 0)) end
function R.start(s,mask,tempt)
 if s.finished or type(mask)~='number' or mask<1 or mask>15 or mask%1~=0 then return false end
 if s.phase=='choose' then
  if tempt or mask~=15 or (s.variant~='B' and not s.project) then return false end
 elseif s.phase=='ready' and s.project then
  if tempt then
   if s.rerolls~=0 or s.tempted then return false end
  elseif s.rerolls<=0 then return false end
 else return false end
 s.risk=s.phase=='ready' and R.score(s.project,s.hand) or 0
 if s.phase=='ready' then
  if tempt then s.tempted=true; s.temptations=s.temptations+1; s.score=s.score-s.temptations
  else s.rerolls=s.rerolls-1 end
 end
 s.mask=mask; s.phase='rolling'; return true
end
local function ending(s,message)
 s.phase='ended'; s.last=message
 if s.turn==8 then
  s.finished=true
  s.won=s.score>=25 and s.counts[1]>0 and s.counts[2]>0 and s.counts[3]>0
 end
end
function R.settle(s,values)
 if s.phase~='rolling' then return false end
 for i=1,4 do if R.has(s.mask,i) then
  local v=values[i]; if type(v)~='number' or v%1~=0 or v<1 or v>6 then return false end
 end end
 for i=1,4 do if R.has(s.mask,i) then s.hand[i]=values[i] end end
 s.phase='ready'; s.last='Dadi fermi: trattieni, assicura o rischia'
 if s.risk>0 and R.score(s.project,s.hand)<=s.risk then ending(s,'Rischio fallito') end
 return true
end
function R.bank(s)
 if s.phase~='ready' or R.score(s.project,s.hand)==0 then return false end
 local reward=R.reward(s); s.score=s.score+reward; s.counts[s.project]=s.counts[s.project]+1
 local h={}; for i,c in ipairs(s.hand) do h[i]=c end
 s.works[#s.works+1]={project=s.project,hand=h,points=reward,turn=s.turn}
 ending(s,'Opera assicurata: +'..reward); return true
end
function R.abandon(s)
 if s.finished or (s.phase~='ready' and s.phase~='choose') then return false end
 ending(s,'Turno abbandonato'); return true
end
function R.next_turn(s)
 if s.phase~='ended' or s.finished then return false end
 s.turn=s.turn+1; s.phase='choose'; s.project=nil; s.rerolls=2; s.hand={}
 s.changed=false; s.tempted=false; s.risk=0; s.last='Nuova preparazione'; return true
end
return R
