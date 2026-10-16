local M=require('src.gameplay.farkle.medals')
local R=require('src.gameplay.farkle.rules')
local V={}
local function description(d)
 if not d.enabled then return d.reason end
 if d.effect=='selective_reroll' then
  return d.parameters.same_value and 'Reroll two matching dice that are not set aside. Once per commission.'
   or ('Reroll '..(d.parameters.count==1 and 'one die that is not set aside' or 'up to '..d.parameters.count..' dice that are not set aside')..'. Once per commission.')
 elseif d.effect=='bank_multiplier' then return 'Multiply your turn total by '..d.parameters.factor..' and bank. Normal banking thresholds must already be met.' end
 return d.reason
end
function V.draw(u,txt,button)
 local s=u.game
 if u.modal=='medals' then
  txt('MEDAL LABORATORY',425,180,800,30)
  txt('Reference experiment. Equipping RESTARTS this commission: points and turns reset, custom die retained.',440,248,1040,23)
  local pages=math.ceil(#M.list/6);u.medalPage=math.max(1,math.min(u.medalPage or 1,pages))
  for n=1,6 do local d=M.list[(u.medalPage-1)*6+n];if d then
   button(u,'inspect'..n,d.label..(d.enabled and '' or ' [unavailable]'),440,340+(n-1)*70,580,60,true,function() u.medalPreview=d.id end,u.medalPreview==d.id)
  end end
  local d=M.get(u.medalPreview) or M.list[(u.medalPage-1)*6+1]
  txt(d.label,1050,340,420,25)
  txt(description(d),1050,405,420,23)
  txt('Uses: '..tostring(d.max_uses or 'passive')..'\n'..d.verification,1050,560,420,21)
  button(u,'equip','Restart and equip',1050,730,420,66,d.enabled,function() u:equip_reference(d.id) end,true)
  button(u,'medalprev','Previous',440,830,250,60,u.medalPage>1,function() u.medalPage=u.medalPage-1;u.medalPreview=nil end)
  txt(u.medalPage..' / '..pages,790,845,150,24)
  button(u,'medalnext','Next',1050,830,420,60,u.medalPage<pages,function() u.medalPage=u.medalPage+1;u.medalPreview=nil end)
 else
  local d=M.get(s.medal);if not d then return end
  txt(d.label..' / uses '..M.remaining(s),425,180,800,30)
  txt(description(d),440,260,1040,25)
  txt(d.effect=='bank_multiplier' and 'Uses your current scoring selection. The bonus affects only this turn, not earlier banked points.' or 'Medal targets are separate from scoring selections. Rerolling does not bank any points.',440,355,1040,23)
  u.medalDice=u.medalDice or {}
  if d.effect=='selective_reroll' then
   for i=1,6 do
    button(u,'target'..i,'D'..i..' = '..tostring(s.hand[i] or '-'),440+(i-1)*174,460,160,70,s.phase=='ready' and s.hand[i]~=nil and not s.used[i],function() u.medalDice[i]=not u.medalDice[i] or nil end,u.medalDice[i])
   end
  end
  local ids={};for i=1,6 do if u.medalDice[i] then ids[#ids+1]=i end end
  local ok,reason=R.reference_status(s,ids)
  txt(reason,440,610,1040,25)
  txt('Uses left: '..M.remaining(s)..' / '..d.max_uses..' | Recharges next commission.',440,710,1040,23)
  button(u,'activate',d.effect=='bank_multiplier' and 'Apply x2 and bank' or 'Use medal and reroll',440,820,1040,65,ok,function() u:activate_reference(ids) end,true)
 end
end
return V
