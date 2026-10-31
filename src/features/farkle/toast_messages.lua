-- Presentation-only adaptation of upstream Lovely Toasts.
-- Lazy-loaded because the original module allocates a Font at require time.
-- Never receives mouse/touch input; the physical dice always own the pointer.
local Res=require('src.core.resolution_manager')
local RuntimeUI=require('src.core.runtime_ui')
local M={}
local engine=nil
local has=false

local function instance()
 if engine then return engine end
 engine=require('lib.lovelyToasts')
 engine.options.queueEnabled=false
 engine.options.tapToDismiss=false
 engine.options.animationDuration=.23
 engine.canvasSize={1920,1080}
 engine.style.paddingLR=18
 engine.style.paddingTB=9
 engine.style.backgroundColor={.13,.09,.065,.92}
 engine.style.textColor={.97,.85,.64,1}
 engine.style.font=love.graphics.newFont(
  'resources/font/IMFeENsc28P.ttf',RuntimeUI.big_text() and 20 or 17)
 return engine
end

function M.show(message)
 if type(message)~='string' or message=='' then return end
 -- The canonical V2 HUD now emits notifications in every Farkle path.
 -- In headless rules/controller tests LÖVE graphics is intentionally absent:
 -- never load upstream Lovely Toasts before graphics exists.
 if not (love and love.graphics and love.graphics.newFont) then return end
 local t=instance()
 t.options.animationDuration=RuntimeUI.reduced_animations() and .001 or .23
 -- Position 113 in 1920x1080 virtual coordinates, above the actual tray;
 -- right-biased X translation is limited to the HUD drawing call.
 t.show(message,2.0,112)
 has=true
end
function M.update(dt)
 if has then instance().update(math.max(0,dt or 0)) end
end
function M.clear()
 if not has then return end
 _toasts={} -- upstream library uses this global as its private queue.
 has=false
end
function M.draw(blocked)
 if not has or blocked then return end
 local g=love.graphics
 g.push('all')
 Res.begin_ui()
 g.translate(635,0)
 instance().draw()
 Res.end_ui()
 g.pop()
end
return M
