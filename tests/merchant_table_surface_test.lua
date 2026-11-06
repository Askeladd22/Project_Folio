-- Strictly visual Merchant surface: pure determinism and GPU lifetime.
local Surface=require('src.engine3d.merchant_table_surface')
assert(Surface.width==1024 and Surface.height==512,
 'texture resolution must preserve crisp border at 720p and 1080p')
assert(Surface.palette.leather[1]<.40 and Surface.palette.leather[2]<.22,
 'game surface must remain visually quiet and darker than ivory dice')
local counts={canvas=0,push=0,pop=0,lines=0,rect=0,polygon=0}
local texture={setFilter=function(self,a,b)
 assert(a=='linear' and b=='linear')end,release=function()error('should not release valid canvas')end}
local graphic={
 newCanvas=function(w,h)
  counts.canvas=counts.canvas+1
  assert(w==1024 and h==512)
  return texture
 end,
 push=function()counts.push=counts.push+1 end,
 pop=function()counts.pop=counts.pop+1 end,
 origin=function()end,setCanvas=function(c)assert(c==texture)end,
 clear=function(r,g,b,a)assert(a==1 and r<.40 and g<.22 and b<.20)end,
 setColor=function()end,setLineWidth=function()end,
 line=function()counts.lines=counts.lines+1 end,
 rectangle=function()counts.rect=counts.rect+1 end,
 polygon=function()counts.polygon=counts.polygon+1 end,
 translate=function()end,scale=function()end,rotate=function()end,
}
assert(Surface.create(graphic)==texture,'surface needs a reusable GPU Canvas')
assert(counts.canvas==1 and counts.push==counts.pop,
 'texture generation must not leak graphics transformations')
assert(counts.lines>30 and counts.lines<140 and
 counts.rect>1700 and counts.rect<1800 and
 counts.polygon>=16 and counts.polygon<=30,
 'only deterministic grain, double rule and corner ornaments are allowed')
local renderer=assert(io.open('src/engine3d/g3d_live.lua','rb')):read('*a')
local source=assert(io.open('src/engine3d/merchant_table_surface.lua','rb')):read('*a')
assert(not source:find('math.random',1,true),
 'the visual surface must not consume gameplay RNG')
assert(renderer:find('if not self.merchantLeather then',1,true),
 'procedural texture must be cached, never rebuilt each frame')
assert(renderer:find('floor_texture=self.merchantLeather',1,true))
assert(renderer:find('rail_texture=self.merchantWood',1,true))
assert(renderer:find('self.floor_model:draw()',1,true),
 'texture cannot replace the depth-aware physical 3D floor')
print('PASS Merchant matte leather: deterministic cached texture, quiet centre and wood frame')
