package.path="./?.lua;./?/init.lua;"..package.path
local Store=require('src.core.lua_table_store')
local Codec=require('src.core.settings_data_codec')
local function fs()
 local files={}
 return {
  files=files,
  getInfo=function(path) if files[path] then return {type='file'} end end,
  read=function(path) return files[path] end,
  write=function(path,text) files[path]=text;return true end,
  remove=function(path) files[path]=nil;return true end,
 }
end
local disk=fs()
local settings={game={language='English',verbose_logs=false},
  audio={master_volume=.8, music_volume=.6}, video={show_fps=true}}
assert(Store.save('settings_data.json',settings,{filesystem=disk}))
local read,err=Store.load('settings_data.json',{filesystem=disk})
assert(read and not err and read.game.language=='English' and
       read.audio.master_volume==.8 and read.video.show_fps==true)
assert(disk.files['settings_data.json']:sub(1,1)=='{')
assert(disk.files['settings_data.json.pending']==nil)
local bad,problem,status=Store.load('missing.json',{filesystem=disk})
assert(not bad and not problem and status=='missing')
disk.files['settings_data.json']='{"game":'
local broken,reason,kind=Store.load('settings_data.json',{filesystem=disk})
assert(not broken and kind=='invalid_data' and reason)
local fallback=Store.load('settings_data.json.bak',{filesystem=disk})
-- A backup is written only before replacing an existing valid settings file.
assert(not fallback)
disk.files['settings_data.json']='{"game":{"language":"English"}}'
assert(Store.save('settings_data.json',settings,{filesystem=disk}))
disk.files['settings_data.json']='{"incomplete":'
fallback=Store.load('settings_data.json.bak',{filesystem=disk})
assert(fallback and fallback.game.language=='English')
local executed=false
disk.files['settings_data.lua']='return (function() executed=true; return {game={language="English"}} end)()'
local value,malice,kind=Store.load('settings_data.lua',{filesystem=disk,legacy=true})
assert(not value and malice and kind=='invalid_data' and not executed)
disk.files['settings_data.lua']='return {\n  game = {language = "English", verbose_logs = true,},\n  audio = {master_volume = 0.55,},\n}'
local legacy=Store.load('settings_data.lua',{filesystem=disk,legacy=true})
assert(legacy and legacy.game.verbose_logs and legacy.audio.master_volume==.55)
assert(not Codec.decode('{"a":1,"a":2}'))
assert(not Codec.decode('{"a": { "b": true } } trailing'))
assert(not Codec.decode('{"x":NaN}'))
local utf=Codec.decode('{"x":"\\u00e9","face":"\\uD83C\\uDFB2"}')
assert(utf and #utf.x==2 and #utf.face==4)
local x,large=Codec.encode({x=math.huge});assert(not x and large)
print('PASS safe settings codec, legacy migration, corrupt recovery, no Lua execution')
