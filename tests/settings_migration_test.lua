package.path="./?.lua;./?/init.lua;"..package.path
local files={}
love={filesystem={
 getInfo=function(p) return files[p] and {type='file'} or nil end,
 read=function(p) return files[p] end,
 write=function(p,v) files[p]=v;return true end,
 remove=function(p) files[p]=nil;return true end
}}
local Settings=require('src.core.settings_state')
files['settings_data.lua']='return {audio={master_volume=.35},game={language="English"},video={show_fps=true}}'
local s=Settings.load()
assert(s.audio.master_volume==.35 and s.video.show_fps==true)
assert(type(files['settings_data.json'])=='string')
assert(files['settings_data.lua']~=nil,'migration must preserve original')
Settings.set(s);assert(Settings.save())
assert(files['settings_data.json.bak']~=nil)
files['settings_data.json']='{"audio":'
local restored=Settings.load()
assert(restored.audio.master_volume==.35)
-- Unexpected legacy expressions are never evaluated, even on migration.
files['settings_data.json']=nil
files['settings_data.lua']='return (function() os.execute("exit 1"); return {} end)()'
local defaults=Settings.load()
assert(defaults.audio.master_volume==Settings.get_defaults().audio.master_volume)
print('PASS settings migration, backup recovery, normalization, malicious legacy rejection')
