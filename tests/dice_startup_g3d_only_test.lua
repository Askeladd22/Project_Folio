-- Regression for the real dice_runtime.lua startup code, NOT a copied spawn.
-- Headless Lua 5.4 and LuaJIT can invoke the unmodified spawn function body
-- using lightweight physical-body stubs, without a GPU or a LÖVE window.
-- Would have caught the nil global 'light' left by CPU painter retirement.
local function read(path)
 local file=assert(io.open(path,'rb'))
 local content=file:read('*a')
 file:close()
 return content
end
local source=read('src/app/dice_runtime.lua')
local first=assert(source:find('local function spawn_initial_dice()',1,true))
local last=assert(source:find('\nlocal function seed_rng()',first,true))
local actual=source:sub(first,last-1)
assert(not actual:find('light.plastic',1,true),
 'CPU painter material must not be referenced by the g3d dice spawn')
assert(not actual:find('material = die_material',1,true),
 'CPU painter material field is not consumed by g3d')

local config=require('src.core.dice_config').load()
local pool={}
local expected=0
for _,spec in ipairs(config.pool) do
 expected=expected+spec.count
 local faces={}
 for i=1,(spec.kind=='d8' and 8 or 6) do faces[i]={1,2,3} end
 pool[#pool+1]={
  kind=spec.kind,count=spec.count,sides=spec.sides,
  template={faces=faces,faceValueMap={1,2,3,4,5,6,7,8}},
 }
end
assert(expected>=6,'the physical startup must configure at least six dice')

local bodies, applied={},0
local function body_factory(size)
 local body={size=size}
 function body:set(position,velocity,spin)
  self.position,self.velocity,self.spin=position,velocity,spin
  bodies[#bodies+1]=self
  return self
 end
 return body
end
for _,entry in ipairs(pool) do entry.body_factory=body_factory end
local dice,box={},{}
local function clone(source_table,overrides)
 local result={}
 for k,v in pairs(source_table) do result[k]=v end
 for k,v in pairs(overrides) do result[k]=v end
 return result
end
local args={
 get_total_dice_count=function() return expected end,
 DICE_SIZE_BASE=config.sizes.base,
 DICE_SIZE_SCALE_REFERENCE_COUNT=config.sizes.scale_reference_dice_count,
 DICE_SIZE_MIN=config.sizes.min,
 DICE_POOL=pool,
 d6=pool[1].template,
 newD6Body=body_factory,
 initial_position_for_slot=function(slot,index)
  assert(slot=='main' or slot=='mini')
  assert(index>=1)
  return 10+index,20+index
 end,
 build_face_colors=function(_,n)
  local colors={}
  for i=1,n do colors[i]={255,255,255,255} end
  return colors
 end,
 D8_PROTO_COLOR={255,0,0,255},
 D6_PROTO_COLOR={245,226,192,255},
 D8_PROTO_TEXT={0,0,0,255},
 D6_PROTO_TEXT={0,0,0,255},
 DICE_INITIAL_POSITION_Z=config.initial_state.position_z,
 DICE_INITIAL_VELOCITY_EVEN=config.initial_state.velocity_even,
 DICE_INITIAL_VELOCITY_ODD=config.initial_state.velocity_odd,
 DICE_INITIAL_SPIN=config.initial_state.spin,
 clone=clone,
 materials={
  get=function(name) assert(name=='bone');return {name=name} end,
  apply=function(body,kind)
   assert(body and kind and kind.name=='bone')
   applied=applied+1
  end,
 },
 box=box,
 dice=dice,
}
local params={
 'get_total_dice_count','DICE_SIZE_BASE','DICE_SIZE_SCALE_REFERENCE_COUNT',
 'DICE_SIZE_MIN','DICE_POOL','d6','newD6Body',
 'initial_position_for_slot','build_face_colors','D8_PROTO_COLOR',
 'D6_PROTO_COLOR','D8_PROTO_TEXT','D6_PROTO_TEXT',
 'DICE_INITIAL_POSITION_Z','DICE_INITIAL_VELOCITY_EVEN',
 'DICE_INITIAL_VELOCITY_ODD','DICE_INITIAL_SPIN','clone',
 'materials','box','dice',
}
local wrapper={'return function(args)'}
for _,name in ipairs(params) do
 wrapper[#wrapper+1]='local '..name..'=args.'..name
end
wrapper[#wrapper+1]=actual
wrapper[#wrapper+1]='return spawn_initial_dice()'
wrapper[#wrapper+1]='end'
local loader=loadstring or load
local callable=assert(loader(table.concat(wrapper,'\n'),'dice_runtime_startup_fixture'))()
assert(rawget(_G,'light')==nil,
 'regression fixture must not sneak in the retired light global')
callable(args)
assert(#dice==expected and #box==expected and #bodies==expected,
 'real startup did not spawn and register all configured physical dice')
assert(applied==expected,'startup must apply physical bone material to each body')
for index,entry in ipairs(dice) do
 assert(entry.body==box[index] and entry.die and entry.die.faces)
 assert(entry.die.material==nil,'legacy CPU material leaked into g3d die')
 assert(entry.body.position[3]==config.initial_state.position_z)
 assert(entry.kind=='d6' or entry.kind=='d8')
 assert(#entry.die.faceColors==#entry.die.faces)
 assert(not entry.kept and entry.value==nil)
end
print('PASS real dice startup spawns physical D6/D8 without retired light, CPU materials or GPU dependencies')
