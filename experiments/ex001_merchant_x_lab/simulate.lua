-- EX-001 only. The canonical Farkle evaluator and original V4 remain authoritative.
local Money=require('experiments.merchant_wager_lab.money_duel')
local Rules=require('src.farkle.rules')
local RNG=require('experiments.merchant_wager_lab.rng')
local M={}
M.modes={'baseline','redraw'}
M.policies={'prudent','balanced','daring','random_legal'}
local stops={prudent=30,balanced=50,daring=80}
local function choose_best(turn)
 local best
 for _,o in ipairs(Rules.options(turn)) do
  if not best or o.points>best.points or
      (o.points==best.points and #o.ids<#best.ids) then best=o end
 end
 return assert(best)
end
function M.play(seed,mode,policy)
 assert(mode=='baseline' or mode=='redraw')
 assert(stops[policy] or policy=='random_legal')
 local m=Money.new(seed,seed,{raises_enabled=false,opening_x_mode=mode})
 local random=RNG.new_rng(1+((seed*69621+1277)%2147483646))
 local chosen_actions=0
 for step=1,400 do
  if m.phase=='over' then
   Money.Wager.assert_conservation(m.wager)
   assert(m.wager.pot==0 and m.wager.wallet.artist+m.wager.wallet.merchant==480)
   assert(#m.base.completed_hands==#m.wager.hands)
   return m,chosen_actions
  elseif m.phase=='betting' then
   assert(Money.start_dice(m))
  elseif m.phase=='player' then
   local t=m.base.turn
   if Rules.can_roll(t) then
    assert(Money.roll(m))
   elseif t.phase=='ready' then
    local o
    if policy=='random_legal' then
     local opts=Rules.options(t)
     o=assert(opts[random(1,#opts)])
    else o=choose_best(t) end
    for _,id in ipairs(o.ids) do assert(Money.toggle(m,id)) end
    local valid=Money.can_bank(m)
    local should_bank
    if policy=='random_legal' then should_bank=valid and random(1,2)==1
    else should_bank=valid and (t.pot+o.points>=stops[policy] or
       Rules.count_free(t)-#o.ids<=1) end
    chosen_actions=chosen_actions+1
    if should_bank then assert(Money.bank(m))
    else assert(Money.take(m)) end
   else error('EX-001 unexpected Farkle state '..tostring(t.phase)) end
  elseif m.phase=='merchant_decision' then assert(Money.advance_merchant(m))
  elseif m.phase=='hand_end' then assert(Money.next_hand(m))
  else error('EX-001 unknown phase '..tostring(m.phase)) end
  Money.Wager.assert_conservation(m.wager)
 end
 error('EX-001 exceeded 400 steps seed '..seed..' policy '..policy..' mode '..mode)
end
local function csv_line(...)
 local fields={...}
 for i,v in ipairs(fields) do
  local s=tostring(v)
  if s:find('[,"\r\n]') then s='"'..s:gsub('"','""')..'"' end
  fields[i]=s
 end
 return table.concat(fields,',')..'\n'
end
local function wilson(w,n)
 local z=1.959963984540054
 local p=w/n
 local d=1+z*z/n
 local c=(p+z*z/(2*n))/d
 local h=z*math.sqrt((p*(1-p)+z*z/(4*n))/n)/d
 return c-h,c+h
end
function M.pilot(first,last,dir)
 assert(first>=1 and first%1==0 and last>=first and last-first<5000)
 local mf,hf
 if dir then
  mf=assert(io.open(dir..'/ex001_matches.csv','w'))
  hf=assert(io.open(dir..'/ex001_hands.csv','w'))
  mf:write('seed,policy,mode,winner,hand_count,artist_denari,merchant_denari,opening_x,auto_hands,player_choices\n')
  hf:write('seed,policy,mode,hand,winner,end_reason,opening_draws,opening_x,initial_offer,player_result,player_actions,merchant_counteroffers,merchant_withdrawals\n')
 end
 local report={}
 for _,p in ipairs(M.policies) do
  local measures={}
  local diffs={}
  for _,mode in ipairs(M.modes) do
   measures[mode]={n=0,wins=0,hands=0,auto=0,opening_x=0,opening_draws=0,
     hands_with_actions=0,choices=0,counteroffers=0,withdrawals=0,denari=0,insolvent=0}
  end
  for seed=first,last do
   local wins={}
   for _,mode in ipairs(M.modes) do
    local m,choices=M.play(seed,mode,p)
    local k=measures[mode]
    k.n=k.n+1
    local won=m.winner=='artist' and 1 or 0
    wins[mode]=won
    k.wins=k.wins+won
    k.denari=k.denari+m.wager.wallet.artist
    k.choices=k.choices+choices
    if m.end_reason=='insolvent' then k.insolvent=k.insolvent+1 end
    local auto,opening_x=0,0
    for _,h in ipairs(m.base.completed_hands) do
     k.hands=k.hands+1
     local hx=0
     for _,s in ipairs(h.initial_symbols) do if s=='X' then hx=hx+1 end end
     if mode=='redraw' then
      assert(h.opening_draw_count==2+hx)
      assert(#h.opening_numeric_symbols==2)
      assert(h.end_reason~='initial_x')
     else assert(h.opening_draw_count==2) end
     opening_x=opening_x+hx
     k.opening_x=k.opening_x+hx
     k.opening_draws=k.opening_draws+h.opening_draw_count
     local is_auto=h.end_reason=='initial_x' and 1 or 0
     auto=auto+is_auto;k.auto=k.auto+is_auto
     k.counteroffers=k.counteroffers+(h.counteroffers or 0)
     k.withdrawals=k.withdrawals+(h.merchant_withdrawals or 0)
     if #h.player_decisions>0 then k.hands_with_actions=k.hands_with_actions+1 end
     if hf then
      hf:write(csv_line(seed,p,mode,h.number,h.winner,h.end_reason,h.opening_draw_count,
       hx,h.initial_offer,h.player_result or 0,#h.player_decisions,
       h.counteroffers or 0,h.merchant_withdrawals or 0))
     end
    end
    if mf then mf:write(csv_line(seed,p,mode,m.winner,#m.base.completed_hands,
      m.wager.wallet.artist,m.wager.wallet.merchant,opening_x,auto,choices)) end
   end
   diffs[#diffs+1]=wins.redraw-wins.baseline
  end
  local n=last-first+1
  local sum,sq=0,0
  for _,x in ipairs(diffs) do sum=sum+x;sq=sq+x*x end
  local delta=sum/n
  local variance=n>1 and math.max(0,(sq-sum*sum/n)/(n-1)) or 0
  local lo=delta-1.96*math.sqrt(variance/n)
  local hi=delta+1.96*math.sqrt(variance/n)
  for _,mode in ipairs(M.modes) do
   local k=measures[mode]
   local low,high=wilson(k.wins,n)
   report[#report+1]=string.format('%s | %s | %d/%d [%.3f,%.3f] | %d | %d/%d | %.3f | %d | %.2f | %d',
    p,mode,k.wins,n,low,high,k.auto,k.hands_with_actions,k.hands,
    k.opening_draws/k.hands,k.counteroffers,k.denari/n,k.insolvent)
  end
  report[#report+1]=string.format('%s paired delta B-A win proportion: %+.4f approx95 [%.4f,%.4f]',
    p,delta,lo,hi)
 end
 if mf then mf:close();hf:close() end
 return table.concat(report,'\n')
end
function M.report(first,last,dir)
 return table.concat({'EX-001 V4 A/B (pilot), seeds '..first..'..'..last,
 'Scripted policies, no voluntary raises, original V4 is default.',
 'Wilson95 for each arm; normal approx paired delta; not a human playtest.',
 'policy | mode | artist wins/n [Wilson95] | auto-hands | hands with actions/all | draws/hand | counters | avg artist denari | insolvent',
 M.pilot(first,last,dir)},'\n')
end
return M
