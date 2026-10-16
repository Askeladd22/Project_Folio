-- Compatibility for external harnesses; no independent bootstrap.
assert(love.filesystem.load('main.lua'))()
