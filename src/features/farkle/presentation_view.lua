-- Graphical snapshots only; held bodies remain owned by the physical adapter.
local P=require('src.features.farkle.presentation')
local Res=require('src.core.resolution_manager')
local H=require('src.features.farkle.hud_model')
local V={}
local shelfWood,shelfQuad,shelfWidth
-- Capture draw commands from a graphical body at the origin. The physical
-- vertices/orientation are read, never assigned, translated or integrated.
local function snapshot(entry,projection)
 local view=require('src.engine3d.view');local render=require('src.engine3d.render')
 local saved={};for _,k in ipairs({'pitch','cos_pitch','sin_pitch','yaw','cos_yaw','sin_yaw','projection'}) do saved[k]=view[k] end
 view.pitch=projection.pitch;view.cos_pitch=math.cos(view.pitch);view.sin_pitch=math.sin(view.pitch)
 view.yaw=projection.yaw;view.cos_yaw=math.cos(view.yaw);view.sin_yaw=math.sin(view.yaw);view.projection='orthographic'
 local body={position=vector{0,0,0}}
 for i,v in ipairs(entry.body) do body[i]=vector{v[1],v[2],v[3]} end
 local calls={}
 render.die(function(z,fn) calls[#calls+1]={z=z,fn=fn} end,entry.die,body)
 for k,v in pairs(saved) do view[k]=v end
 if saved.projection==nil then view.projection=nil end
 table.sort(calls,function(a,b) return a.z<b.z end)
 return calls
end
function V.rail()
 local g=love.graphics
 local r=H.slots
 g.setColor(.24,.13,.065);g.rectangle('fill',r.x-6,r.y-5,r.step*5+r.w+12,r.h+10,5)
end
function V.held(u,txt)
 local p=u.presentation;if not p then return end
 local projection=u.trayProjection;if not projection or not projection.front then return end
 local g=love.graphics
 Res.begin_ui()
 local contributors=P.contributing_dice(p)
 local ax,ay=Res.to_virtual(projection.front[1].x,projection.front[1].y)
 local bx,by=Res.to_virtual(projection.front[2].x,projection.front[2].y)
 -- A shallow wooden collecting ledge follows the visible front edge. It is
 -- exclusively scenery; no new wall or body enters the solver or picker.
 local depth=48
 local workshop=require('src.features.farkle.tray_workshop')
 local wax,way,wbx,wby,wdepth=workshop.shelf(ax,ay,bx,by)
 if wax then ax,ay,bx,by,depth=wax,way,wbx,wby,wdepth else
 -- Chamfered apron and inset leather seats: purely graphical collecting shelf.
 g.setColor(.06,.035,.018,.5);g.polygon('fill',ax-10,ay+9,bx+10,by+9,bx+5,by+24,ax-5,ay+24)
 g.setColor(.19,.105,.055);g.polygon('fill',ax-10,ay-4,bx+10,by-4,bx+4,by+17,ax-4,ay+17)
 g.setColor(.34,.215,.12);g.polygon('fill',ax-10,ay-depth+8,ax,ay-depth,bx,by-depth,bx+10,by-depth+8,bx+10,by-4,bx,by+2,ax,ay+2,ax-10,ay-4)
 shelfWood=shelfWood or g.newImage('resources/textures/tray/walnut.png')
 shelfWood:setFilter('linear','linear')
 local width=bx-ax
 if shelfWidth~=width then
  shelfWidth=width
  shelfQuad=g.newQuad(0,1200,math.min(4096,width*3),depth*3,4096,4096)
 end
 -- Isotropic crop: no compression of a square texture into a narrow rail.
 g.setColor(1,.94,.86);g.draw(shelfWood,shelfQuad,ax,ay-depth,0,1/3,1/3)
 g.setColor(.53,.36,.20);g.line(ax,ay-depth,bx,by-depth)
 for j=1,5 do
  g.setColor(.14,.07,.035,.24);g.line(ax+6,ay+3+j*2,bx-6,by+3+j*2)
 end
 for i=1,6 do local t=(i-.5)/6;local x=ax+(bx-ax)*t;local y=ay+(by-ay)*t-depth/2
  local width=math.min(48,(bx-ax)/14)
  g.setColor(.06,.035,.02,.22);g.ellipse('fill',x,y+3,width,11)
  g.setColor(.64,.47,.30,.22);g.ellipse('line',x,y+4,width,11)
 end
 for _,t in ipairs({.015,.985}) do
  local x=ax+(bx-ax)*t;local y=ay+(by-ay)*t
  g.setColor(.43,.32,.17);g.circle('fill',x,y-6,4)
  g.setColor(.15,.10,.055);g.line(x-2,y-6,x+2,y-6)
 end
 end
 for i,e in pairs(p.shelf) do
  local slot=(i-.5)/6
  local x,y=ax+(bx-ax)*slot,ay+(by-ay)*slot-depth/2-16
  local progress=math.min(1,e.age/P.transfer_duration);local t=1-(1-progress)^3
  if e.origin and t<1 then
   local ox,oy=Res.to_virtual(e.origin.x,e.origin.y)
   x=ox+(x-ox)*t;y=oy+(y-oy)*t-20*math.sin(math.pi*progress)
  end
  if contributors[i] then
   g.setColor(.96,.77,.35,.85);g.setLineWidth(2)
   g.ellipse('line',x,y+17,36,12)
   local r=H.slots;g.rectangle('line',r.x+(i-1)*r.step+2,r.y+2,r.w-4,r.h-4,3);g.setLineWidth(1)
  end
  if not e.drawCalls and dice[i] then e.drawCalls=snapshot(dice[i],projection) end
  local scale=projection.scale/Res.get_scale()
  g.push();g.translate(x,y);g.scale(scale)
  for _,call in ipairs(e.drawCalls or {}) do call.fn() end
  g.pop()
 end
 Res.end_ui()
end
function V.feedback(u,txt)
 local e=u.presentation and u.presentation.conclusion;if not e then return false end
 local text=(e.kind=='bank' and ('+'..e.points..' banked') or (e.points..' unbanked points lost'))
 local bonus=u.presentation.bonus or 0
 local counting=u.presentation.score and u.presentation.score.age<P.score_duration
 if bonus>0 and not counting then text=text..' · Base '..(e.points-bonus)..' + Medal '..u.presentation.bonusLabel..' '..bonus end
 txt(text,H.feedback.x,927,H.feedback.w,24)
 local pulse=1-e.age/P.feedback_duration
 if pulse>0 then
  local g=love.graphics;g.setColor(e.kind=='bank' and .25 or .65,.38,.16,pulse*.65)
  g.setLineWidth(3);g.line(H.feedback.x,922,H.feedback.x+H.feedback.w,922);g.setLineWidth(1)
 end
 return true
end
function V.contributions(u,txt)
 local p=u.presentation;local e=p and p.score;if not e or e.age>=P.score_duration then return false end
 local labels={};local sum=0
 for _,g in ipairs(e.groups) do labels[#labels+1]=g.label..' +'..g.points;sum=sum+g.points end
 if #labels>2 then labels={#labels..' combinations +'..sum} end
 if e.bonus>0 then labels[#labels+1]='Medal '..p.bonusLabel..' +'..e.bonus end
 if #labels>0 then
  local total=P.display(p,e.channel,u.game[e.channel])
  txt(table.concat(labels,' · '),H.feedback.x,H.feedback.y,H.feedback.w,24)
  txt('Counting '..(e.channel=='pot' and 'turn points: ' or 'banked points: ')..total..' / '..e.to..'  [Tab: finish]',H.feedback.x,927,H.feedback.w,24)
  return true
 end
 return false
end
return V
