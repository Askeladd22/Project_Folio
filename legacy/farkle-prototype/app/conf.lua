-- Compatibility shim: root conf.lua owns the save identity and window config.
assert(love.filesystem.load('conf.lua'))()
