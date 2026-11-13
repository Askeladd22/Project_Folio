-- Production F8 workshop: preserve all selectable g3d tray styles.
local Workshop=require('src.farkle.tabletop').tray_workshop
local saved=Workshop.current
Workshop.current='book'
for _,expected in ipairs{'current','A','B','C','book'} do
 local actual=Workshop.cycle()
 assert(actual==expected and Workshop.current==expected,
  'F8 style cycle changed at '..expected)
end
Workshop.current='invalid'
local ok,msg=pcall(Workshop.cycle)
assert(not ok and tostring(msg):find('unrecognized g3d tray style',1,true),
 'unrecognized style must not be silently accepted')
Workshop.current=saved
print('PASS F8 style cycle, wraparound and invalid-style guard')
