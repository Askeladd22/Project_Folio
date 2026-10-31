-- Projection-space pullback while holding a group.
-- Fitted tray scales cancel changes to view.distance; apply the zoom AFTER
-- fitting so the camera, GPU draw, legacy painter, projected hits and
-- mouse-to-world conversion all agree on exactly the same final scale.
local M={}
M.held_scale=.90
M.response=10
function M.advance(owner,now,is_group_held)
 assert(type(owner)=='table','controller required')
 now=type(now)=='number' and now or 0
 local old=owner._group_projection_scale or 1
 local prev=owner._group_projection_time
 local dt=prev and math.max(0,math.min(.1,now-prev)) or 0
 local goal=is_group_held and M.held_scale or 1
 local t=1-math.exp(-M.response*dt)
 local value=old+(goal-old)*t
 if math.abs(goal-value)<.0002 then value=goal end
 owner._group_projection_scale=value
 owner._group_projection_time=now
 return value
end
return M
