local R=require('src.gameplay.farkle.rules')
-- Pure Farkle presentation semantics only. Layout lives in ui_v2/.
local H={}
function H.reward_active(s) return s.phase=='upgrade' or s.phase=='medal' end
function H.help_sections(s)
 local p=R.points;local c=R.contracts[s.stage];local rows={}
 for v=1,6 do rows[v]={v,p.kind[3][v],p.kind[4][v],p.kind[5][v],p.kind[6][v]} end
 return {
  {title='How to play',lines={
   '1. Press Space to roll all six dice.',
   '2. Select a combination: click the dice or press 1–6.',
   '3. Press Set aside [A]. Selected dice leave the tray.',
   '4. Reroll the remaining dice or Bank [Enter].',
   'You can also bank a valid selection without setting it aside first.',
   'Banked points are safe. Turn points remain at risk.',
   'Reach the target within the turns shown above.'}},
  {title='Combinations & scores',rows=rows,lines={
   'Singles: 1 = '..p.single[1]..' points   ·   5 = '..p.single[5]..' points',
   'Straight 1–5 or 2–6: '..p.small..'   ·   Straight 1–6: '..p.straight,
   'Three pairs: '..p.pairs..'   ·   Full house (4+2): '..p.full..'   ·   Two triplets: '..p.triples}},
  {title='Special rules',lines={
   'Farkle: no scoring combination. You lose your unbanked turn points.',
   'Previously banked points always remain safe.',
   'Hot dice: after setting aside every die, reroll all six or bank.',
   'First bank: at least '..(c.entry_min or 0)..' points. Later banks: at least '..(c.bank_min or 0)..'.',
   'Each combination uses dice from one roll. No die counts twice.',
   'You may set aside only some of the scoring dice.',
   'Medal exceptions are explained in the medal panel.'}}
 }
end
function H.commission_closed(s)
 return s.phase=='lost' or s.phase=='won' or s.phase=='upgrade' or s.phase=='medal' or s.phase=='advance'
end
function H.state_text(u)
 local s=u.game
 if u.physicalFailure then return u.physicalFailure end
 if u.physicalNotice then return u.physicalNotice end
 if s.phase=='lost' then return 'Commission failed: no turns left. The run ends here.' end
 if s.phase=='won' then return 'Three commissions delivered: mini-run complete.' end
 if s.phase=='advance' then return 'Commission delivered. Continue with Next.' end
 if s.phase=='upgrade' or s.phase=='medal' then return 'Commission delivered. Choose your reward on the right.' end
 if s.phase=='rolling' then return u.retry and 'Rerolling the weighted die…' or 'The dice are rolling…' end
 if s.phase=='fresh' then return 'Roll all six dice to begin your turn.' end
 if s.phase=='ended' then
  if u.lastLoss~=nil then return u.lastLoss>0 and ('FARKLE · '..u.lastLoss..' unbanked points lost.') or 'FARKLE · Turn over, no points accumulated.' end
  return 'Banked '..(u.lastBank or 0)..' points. Continue to the next turn.'
 end
 if s.phase=='rescue' then return 'FARKLE · Use the Corrector to save your turn.' end
 if s.hot then local ok,_,minimum=R.bank_status(s);return ok and 'HOT DICE · Reroll all six or bank.' or ('HOT DICE · Reroll six dice: minimum bank '..minimum) end
 if next(s.selected) then return R.selection(s) and (H.selection_text(s)..' · Click Set aside.') or 'Invalid selection: every selected die must score.' end
 if s.scored then local ok,_,_,reason=R.bank_status(s);return ok and 'Reroll or bank your turn points.' or reason end
 return 'Select scoring dice with the mouse or keys 1–6.'
end
function H.eligible(s)
 local ids,count={},0
 if s.phase~='ready' then return ids,count end
 -- R.options uses the shared scoring cache and preserves physical IDs.
 -- A visual hint is still only a hint; it never alters selected dice.
 for _,option in ipairs(R.options(s)) do
  for _,id in ipairs(option.ids) do
   if not ids[id] then ids[id]=true;count=count+1 end
  end
 end
 return ids,count
end
-- An unfinished group is still useful if all chosen physical IDs are
-- contained in at least one legal option from this throw.
function H.can_complete(s)
 if s.phase~='ready' or not next(s.selected) then return false end
 for _,option in ipairs(R.options(s)) do
  local all=true
  for id in pairs(s.selected) do
   if math.floor(option.mask/2^(id-1))%2==0 then all=false;break end
  end
  if all then return true end
 end
 return false
end
function H.selected_count(s)
 local n=0;for i=1,6 do if s.selected[i] and not s.used[i] then n=n+1 end end;return n
end
function H.selection_text(s)
 local o=R.selection_option(s);if not o then return nil end
 local labels,counts={},{}
 for _,g in ipairs(o.groups) do if not counts[g.label] then labels[#labels+1]=g.label;counts[g.label]=0 end;counts[g.label]=counts[g.label]+1 end
 for i,label in ipairs(labels) do if counts[label]>1 then labels[i]=counts[label]..' × '..label end end
 return table.concat(labels,' + ')..' · '..(o.remaining==0 and '6 dice to reroll (hot)' or o.remaining..' dice to reroll')
end
function H.reroll_indices(s)
 local result={};for i=1,6 do if s.hot or not s.used[i] then result[#result+1]=i end end;return result
end
return H
