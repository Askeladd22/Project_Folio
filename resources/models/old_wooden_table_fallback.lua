-- Original low-poly trestle fallback, informed by the uploaded old wooden
-- table's proportions. This is NOT the Alex Krush mesh/texture: install
-- resources/models/old_wooden_table_game_ready_asset.glb for that asset.
-- Visual only: physical board/walls and six dice keep their existing bounds.
local M={}
-- Original, low-poly trestle inspired by the KIFIR medieval table.
-- Tone references the Alex Krush wood albedo; neither author supplied
-- these procedural vertices or textures.
M.finish={plank_tints={.54,.58,.56},underside=.70,trestle=.55}
local function quad(out,a,b,c,d,tint,ext)
 local ux,uy,uz=b[1]-a[1],b[2]-a[2],b[3]-a[3]
 local vx,vy,vz=c[1]-a[1],c[2]-a[2],c[3]-a[3]
 local nx,ny,nz=uy*vz-uz*vy,uz*vx-ux*vz,ux*vy-uy*vx
 local len=math.sqrt(nx*nx+ny*ny+nz*nz)
 if len<1e-8 then return end
 nx,ny,nz=nx/len,ny/len,nz/len
 local function emit(p)
  local u=(p[1]-ext[1])/(ext[2]-ext[1])
  local v=math.abs(nz)>.7 and
   (p[2]-ext[3])/(ext[4]-ext[3]) or
   (p[3]+2.4)/2.8
  out[#out+1]={p[1],p[2],p[3],u,v,nx,ny,nz,
   tint,tint*.94,tint*.88,1}
 end
 for _,p in ipairs({a,b,c,a,c,d}) do emit(p) end
end
local function block(out,x1,x2,y1,y2,z1,z2,tint,ext)
 local A={x1,y1,z1};local B={x2,y1,z1}
 local C={x2,y2,z1};local D={x1,y2,z1}
 local E={x1,y1,z2};local F={x2,y1,z2}
 local G={x2,y2,z2};local H={x1,y2,z2}
 quad(out,E,F,G,H,tint,ext) -- top
 quad(out,D,C,B,A,tint*.76,ext) -- underside
 quad(out,A,B,F,E,tint*.84,ext)
 quad(out,C,D,H,G,tint*.78,ext)
 quad(out,B,C,G,F,tint*.88,ext)
 quad(out,D,A,E,H,tint*.82,ext)
end
function M.mesh(extents)
 assert(type(extents)=='table' and #extents==4,'table limits required')
 local x1,x2,y1,y2=extents[1],extents[2],extents[3],extents[4]
 assert(x1<x2 and y1<y2,'invalid board size')
 local v={}
 -- An understated old tavern tabletop, adapted separately to the immutable
 -- gameplay area; no giant apron, no thick picture-frame rail.
 local count=3
 for i=1,count do
  local a=y1+(y2-y1)*(i-1)/count+.018
  local b=y1+(y2-y1)*i/count-.018
  local shade=M.finish.plank_tints[i]
  block(v,x1,x2,a,b,-.15,.003,shade,extents)
 end
 -- Narrow apron is only furniture, *not* a wall that contains a die.
 local inset=1.05
 block(v,x1+inset,x2-inset,y1+.35,y1+.58,-.31,-.15,.45,extents)
 block(v,x1+inset,x2-inset,y2-.58,y2-.35,-.31,-.15,.45,extents)
 -- Trestle stance is 1.7:1, rather than the 2.31:1 dice-field ratio.
 local cx=(x1+x2)*.5;local cy=(y1+y2)*.5
 local halfX=math.min((x2-x1)*.28,(y2-y1)*.48)
 local halfY=(y2-y1)*.29
 local leg=.46
 for _,sx in ipairs({-1,1}) do
  for _,sy in ipairs({-1,1}) do
   local px=cx+sx*halfX;local py=cy+sy*halfY
   block(v,px-leg,px+leg,py-leg,py+leg,-1.78,-.31,.47,extents)
   block(v,px-1.05,px+1.05,py-.30,py+.30,-1.88,-1.67,.43,extents)
  end
 end
 -- Central low stretcher evokes a period trestle; most stays off camera.
 block(v,cx-halfX+leg,cx+halfX-leg,cy-.21,cy+.21,-1.58,-1.37,.40,extents)
 -- Heavy cross-braced end trestles, purely decorative and beneath z=0.
 for _,sx in ipairs({-1,1}) do
  local px=cx+sx*halfX
  block(v,px-.61,px+.61,cy-halfY-.65,cy-halfY+.65,
   -1.60,-1.40,.49,extents)
  block(v,px-.61,px+.61,cy+halfY-.65,cy+halfY+.65,
   -1.60,-1.40,.49,extents)
 end
 return {verts=v,min={x1,y1,-1.88},max={x2,y2,.003},unlit=false}
end
return M
