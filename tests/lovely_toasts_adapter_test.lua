-- Headless adapter verification for unchanged upstream Lovely Toasts.
-- The real library needs LÖVE graphics at require time; mock only that API.
local oldLove,oldUnpack,oldToasts=love,unpack,_toasts
-- Mandatory V2 notifications must be a no-op without a graphical runtime.
local UI=require('src.features.farkle.toast_messages')
love=nil
UI.show('Headless Farkle event')
UI.update(.1)
UI.draw(false)
assert(_toasts==oldToasts,
 'headless Farkle notification must not initialize upstream library')
unpack=unpack or table.unpack
local calls={draw=0,rect=0,mouse=0}
local dummyFont={
 getWidth=function(_,text) return #text*9 end,
 getHeight=function() return 19 end,
}
local fg={1,1,1,1}
love={graphics={
 newFont=function(path,size) return dummyFont end,
 getFont=function() return dummyFont end,
 getWidth=function() return 1920 end,
 getHeight=function() return 1080 end,
 getDimensions=function() return 1920,1080 end,
 getColor=function() return fg[1],fg[2],fg[3],fg[4] end,
 setColor=function(r,g,b,a) fg={r,g,b,a} end,
 setFont=function() end,
 push=function() end,pop=function() end,
 translate=function() end,scale=function() end,
 rectangle=function() calls.rect=calls.rect+1 end,
 print=function() calls.draw=calls.draw+1 end,
}}
UI.show('Una glossa del monaco')
assert(#_toasts==1 and _toasts[1].text=='Una glossa del monaco')
local upstream=require('lib.lovelyToasts')
assert(upstream.options.tapToDismiss==false,
 'a toast must never intercept the physical dice mouse controls')
assert(upstream.options.queueEnabled==false,
 'no overlapping stacks of unreadable messages')
assert(upstream.style.font==dummyFont)
UI.update(.2)
UI.draw(false)
assert(calls.rect>0 and calls.draw>0)
local count=calls.draw
UI.draw(true)
assert(calls.draw==count,'modals must suppress decorative notifications')
UI.show('La figura rientra nella pagina')
assert(#_toasts==1 and _toasts[1].text=='La figura rientra nella pagina')
UI.clear()
assert(#_toasts==0)
UI.draw(false)
assert(calls.draw==count,'cleared notifications must not draw')
love=oldLove
unpack=oldUnpack
_toasts=oldToasts
print('PASS vendored Lovely Toasts: nonblocking, one message, scaled draw, modal suppression, cleanup')
