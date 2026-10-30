-- A logical roll exists only if the gameplay controller accepts the
-- mechanically settled dice. This module has no LOVE/physics dependencies.
local RollEvents={}
function RollEvents.complete(emit,accept,info)
 assert(type(emit)=='function' and type(info)=='table')
 emit('dice.physical_settled',info)
 local accepted=accept==nil or accept(info.values)==true
 if accepted then
  -- Historical observers still receive the legacy event, but never for a
  -- rejected weighted face or a technical physical reroll.
  emit('dice.roll_settled',info)
  emit('dice.roll_accepted',info)
 end
 return accepted
end
return RollEvents
