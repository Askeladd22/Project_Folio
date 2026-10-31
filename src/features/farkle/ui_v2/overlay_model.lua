-- UI v2 P3: pure, read-only projection of physical and scoring feedback.
-- Coordinates of dice hits and marquee remain REAL SCREEN pixels from the
-- existing g3d/engine bridge. No physics, camera, roll or input mutations.
local H=require('src.features.farkle.hud_model')
local R=require('src.gameplay.farkle.rules')
local Marquee=require('src.features.farkle.marquee_selection')
local M={}

local function finite(n)
 return type(n)=='number' and n==n and n~=math.huge and n~=-math.huge
end

function M.build(u,hits)
 local result={markers={},marquee=nil,hand=nil,physicalCount=0}
 local s=u and u.game
 if not s or u.modal or H.reward_active(s) then return result end

 if u.marquee and Marquee.dragged(u.marquee) then
  result.marquee=Marquee.rectangle(u.marquee)
 end

 result.physicalCount=Marquee.count(u.dragSelected)
 if u.mouseThrow then
  local gesture=u.mouseThrow
  local count=gesture.group and type(gesture.held)=='table'
    and #gesture.held or 1
  if finite(gesture.x) and finite(gesture.y) then
   result.hand={x=gesture.x,y=gesture.y,count=math.max(1,count)}
  end
  -- Never paint six per-die selections on top of a gathered physical group.
  -- Also suppress scoring highlights while a throw is physically in hand.
  return result
 end

 local eligible=s.phase=='ready' and H.eligible(s) or {}
 local hasScoreSelection=s.phase=='ready' and s.selected
    and next(s.selected)~=nil
 local selectionValid=hasScoreSelection and R.selection(s)~=nil
 for _,hit in ipairs(hits or {}) do
  local id=hit.index or hit.roll_index
  if type(id)=='number' and id%1==0 and id>=1 and id<=6
      and finite(hit.x) and finite(hit.y) then
   local kind
   if u.dragSelected and u.dragSelected[id] then
    kind='physical'
   elseif s.phase=='ready' and s.selected and s.selected[id] then
    kind=selectionValid and 'score' or 'invalid'
   elseif eligible[id] then
    kind='eligible'
   end
   if kind then
    result.markers[#result.markers+1]={
     id=id,x=hit.x,y=hit.y,r=finite(hit.r) and
       math.max(8,math.min(100,hit.r)) or 24,kind=kind
    }
   end
  end
 end
 return result
end

return M
