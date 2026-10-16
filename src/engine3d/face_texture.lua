-- Two projected triangles share the exact four corners of a D6 face.
-- This is a local 2D texture mapping; projection, culling and painter order
-- remain the responsibility of render.die. No shader or physical state.
local M={}
local mesh
local vertices={
 {0,0,0,0},{0,0,1,0},{0,0,1,1},
 {0,0,0,0},{0,0,1,1},{0,0,0,1},
}
function M.draw(image,a,b,c,d,e,f,g,h)
 local points={a,b,c,d,e,f,g,h}
 for i=1,8 do
  local v=points[i]
  if type(v)~='number' or v~=v or math.abs(v)>1e20 then return false end
 end
 local area=(c-a)*(f-b)-(d-b)*(e-a)
 local area2=(e-a)*(h-b)-(f-b)*(g-a)
 if math.abs(area)+math.abs(area2)<1e-12 or area*area2<0 then return false end
 local order={1,2,3,1,3,4}
 for i,k in ipairs(order) do vertices[i][1],vertices[i][2]=points[2*k-1],points[2*k] end
 if not mesh then mesh=love.graphics.newMesh(vertices,'triangles','stream')
 else mesh:setVertices(vertices) end
 mesh:setTexture(image)
 love.graphics.draw(mesh)
 -- Keep later face updates from affecting queued draws on older render paths.
 if love.graphics.flushBatch then love.graphics.flushBatch() end
 return true
end
return M
