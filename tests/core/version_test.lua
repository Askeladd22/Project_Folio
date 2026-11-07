-- The menu and version registry must use exactly the same canonical file.
local Version=require('src.core.presentation').version
local f=assert(io.open('version.txt','rb'))
local raw=f:read('*a');f:close()
local value=assert(Version.parse(raw))
assert(value:match('^%d+%.%d+%.%d+$'),
 'canonical game version must be X.Y.Z without a -dev/prerelease suffix')
assert(Version.current()==value,'game version must come from version.txt')
assert(Version.parse('1.2.3')=='1.2.3')
assert(Version.parse('0.2.0-dev.42')=='0.2.0-dev.42')
assert(Version.parse('v0.1')==nil)
assert(Version.parse('01.2.3')==nil)
assert(Version.parse('1.2.3 garbage')==nil)
local menu=assert(io.open('src/screens/frontend.lua','rb'))
local source=menu:read('*a');menu:close()
assert(source:find('Version.current()',1,true),
 'menu footer must display canonical version')
assert(not source:find('get_menu_music_volume',1,true),
 'menu must not bypass the central audio manager volume policy')
local schema=assert(io.open('src/data/frontend_schema.lua','rb'))
local data=schema:read('*a');schema:close()
assert(not data:find('v0.1',1,true),
 'the old hardcoded alpha version must not return')
local changes=assert(io.open('CHANGELOG.md','rb'))
local log=changes:read('*a');changes:close()
assert(log:find('## ['..value..']',1,true),
 'changelog must include the canonical version')
print('PASS project version is canonical: SemVer, menu footer, changelog')
