local Bridge=require('src.core.renderer_lab_boot')
local previous=os.getenv
os.getenv=function(name)
 if name=='MANUSCRIPT_G3D_LAB' then return nil end
 return previous(name)
end
assert(Bridge.start()==false,'normal startup must ignore the optional renderer lab')
assert(package.loaded['experiments.g3d_lab.main']==nil,
       'renderer lab must not be imported during ordinary gameplay')
os.getenv=previous
print('PASS renderer lab remains opt-in; normal startup loads no g3d')
