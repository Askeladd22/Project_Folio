local R=require('src.gameplay.farkle.rules')
local H={tray={x=40,y=146,w=1320,h=650},slots={x=56,y=804,w=206,h=54,step=218},feedback={x=64,y=878,w=1272}}
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
function H.options(s)
 if s.phase~='ready' then return {} end
 local counts={0,0,0,0,0,0};for i=1,6 do if not s.used[i] and s.hand[i] then counts[s.hand[i]]=counts[s.hand[i]]+1 end end
 local out={}
 for _,v in ipairs({1,5}) do if counts[v]>0 then
  local n,p=counts[v],R.score({v})
  out[#out+1]=n==1 and ('1 die showing '..v..' = '..p)
   or n==2 and ('2 dice showing '..v..' = '..2*p..' ('..p..' each)')
   or (n..' dice showing '..v..': '..p..' each as singles')
 end end
 for v=1,6 do for n=3,counts[v] do local a={};for j=1,n do a[j]=v end;out[#out+1]=n..' dice showing '..v..' = '..R.score(a) end end
 for _,a in ipairs({{1,2,3,4,5},{2,3,4,5,6},{1,2,3,4,5,6}}) do
  local valid=true;for _,v in ipairs(a) do if counts[v]==0 then valid=false end end
  if valid then out[#out+1]=table.concat(a,'-')..' = '..R.score(a) end
 end
 local special={}
 for _,o in ipairs(R.options(s)) do for _,g in ipairs(o.groups) do
  if g.label=='Three pairs' or g.label=='Full house (4+2)' or g.label=='Two triplets' then
   if not special[g.label] then special[g.label]=true;out[#out+1]=g.label..' = '..g.points end
  end
 end end
 return out
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
function H.selected_count(s)
 local n=0;for i=1,6 do if s.selected[i] and not s.used[i] then n=n+1 end end;return n
end
function H.option_text(o)
 local labels={};for _,g in ipairs(o.groups) do labels[#labels+1]=g.label end
 return '#'..table.concat(o.ids,', #')..' · '..table.concat(labels,' + ')..' = '..o.points..' · '..(o.remaining==0 and '6 dice (hot)' or o.remaining..' dice remaining')
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
