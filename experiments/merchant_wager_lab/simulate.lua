-- Automatic, reproducible matches with fixed player policies. Measures how often
-- the stake actually comes into play; it does not tune or change any rule.
local Rules=require('src.farkle.rules')
local Match=require('experiments.merchant_wager_lab.match')
local M={}

-- Exploratory policies, not a model of real players. stop: bank at this turn
-- total; few: bank at this total when only 1-2 dice would remain.
M.policies={
 {name='prudente',stop=30,few=20},
 {name='equilibrato',stop=50,few=40},
 {name='audace',stop=80,few=80},
}
M.responses={
 vedo_sempre=function() return 'see' end,
 passo_se_dietro=function(m) return m.score.merchant>m.score.player and 'pass' or 'see' end,
}

local function best(t)
 local winner
 for _,o in ipairs(Rules.options(t)) do
  if not winner or o.points>winner.points or o.points==winner.points and #o.ids<#winner.ids then winner=o end
 end
 return winner
end

-- One automatic action; also drives the lab's optional screenshot capture.
function M.step(m,policy,response)
 if m.phase=='merchant' then assert(Match.play_merchant(m))
 elseif m.phase=='raise' then
  if M.responses[response](m)=='see' then assert(Match.see(m)) else assert(Match.pass(m)) end
 elseif m.turn.phase=='fresh' then assert(Match.roll(m))
 else
  local o=assert(best(m.turn),'scoring roll without options')
  for _,id in ipairs(o.ids) do assert(Match.toggle(m,id)) end
  local total=m.turn.pot+o.points;local free=Rules.count_free(m.turn)-#o.ids
  if free>0 and (total>=policy.stop or free<=2 and total>=policy.few) then assert(Match.bank(m))
  else assert(Match.take(m));assert(Match.roll(m)) end
 end
end

function M.play(seed,policy,response,overrides)
 local m=Match.new(seed,overrides)
 for _=1,500 do
  if m.phase=='over' then return m end
  M.step(m,policy,response)
 end
 error('simulated match did not terminate')
end

function M.summary(count,first_seed,overrides)
 local rows={}
 for _,policy in ipairs(M.policies) do
  for _,response in ipairs({'vedo_sempre','passo_se_dietro'}) do
   local a={policy=policy.name,response=response,matches=0,early=0,rounds=0,raises=0,with_raise=0,
    blocked=0,accepted=0,declined=0,player=0,merchant=0,tie=0,max_pot=0}
   for i=1,count do
    local m=M.play(first_seed+i-1,policy,response,overrides)
    local s=m.stats
    a.matches=a.matches+1;a.rounds=a.rounds+m.rounds_played
    if m.rounds_played<m.config.max_rounds and m.end_reason=='threshold' then a.early=a.early+1 end
    a.raises=a.raises+s.raises;if s.raises>0 then a.with_raise=a.with_raise+1 end
    a.blocked=a.blocked+s.raise_blocked_end;a.accepted=a.accepted+s.accepted;a.declined=a.declined+s.declined
    a[m.winner]=a[m.winner]+1;a.max_pot=a.max_pot+m.max_pot
   end
   rows[#rows+1]=a
  end
 end
 return rows
end

-- The Merchant's turn alone: independent of any player policy.
function M.merchant_profile(count,first_seed,overrides)
 local Merchant=require('experiments.merchant_wager_lab.merchant')
 local c=Match.new(first_seed,overrides).config
 local total,farkles,raises=0,0,0
 for i=1,count do
  local r=Merchant.play(Match.new_rng(first_seed+i-1),c)
  total=total+r.banked
  if r.farkle then farkles=farkles+1 end
  if r.banked>=c.raise_threshold then raises=raises+1 end
 end
 return {average=total/count,farkle=farkles/count,raise=raises/count}
end

function M.report(count,first_seed)
 local rows=M.summary(count,first_seed)
 local p=M.merchant_profile(count*10,first_seed)
 local out={('Simulazione: %d partite per politica, seed %d..%d'):format(count,first_seed,first_seed+count-1),
  ('Turno del Mercante (%d turni isolati): media %.1f punti, Farkle %.1f%%, turni da rialzo %.1f%%'):format(
   count*10,p.average,100*p.farkle,100*p.raise),
  'politica    risposta         round  fine<3r  rialzi/p  con-rialzo  bloccati  vedo  passo  V-art  V-merc  pari  piatto-max'}
 for _,a in ipairs(rows) do
  local n=a.matches
  out[#out+1]=('%-11s %-16s %5.2f  %6.1f%%  %8.2f  %9.1f%%  %8d  %4d  %5d  %4.1f%%  %5.1f%%  %3.1f%%  %10.2f'):format(
   a.policy,a.response,a.rounds/n,100*a.early/n,a.raises/n,100*a.with_raise/n,a.blocked,a.accepted,a.declined,
   100*a.player/n,100*a.merchant/n,100*a.tie/n,a.max_pot/n)
 end
 return table.concat(out,'\n'),rows
end
return M
