-- Optional P1 wireframe-over-game diagnostic. Not a playable HUD.
-- Enabled only by MANUSCRIPT_UI_V2_LAYOUT_STUDY=1 in main.lua.
-- This never changes the actual tray, g3d physics or any button hitbox.
local Layout=require('src.features.farkle.ui_v2.layout_candidates')
local Res=require('src.core.resolution_manager')
local M={}
function M.install()
 local oldLoad=love.load
 local oldDraw=love.draw
 local oldKey=love.keypressed
 local chosen=1
 local message='F6: cambia proposta     F7: screenshot     Esc: esci'
 local font
 local function zone(g,box,label,fill,line)
  g.setColor(unpack(fill));g.rectangle('fill',box.x,box.y,box.w,box.h,5)
  g.setColor(unpack(line));g.setLineWidth(3)
  g.rectangle('line',box.x,box.y,box.w,box.h,5);g.setLineWidth(1)
  g.setFont(font)
  g.print(label,box.x+12,box.y+8)
 end
 function love.load(...)
  if oldLoad then oldLoad(...) end
  local Nav=require('src.core.navigation')
  assert(Nav.go('scriptorium'),'P1 layout study could not open scriptorium')
  font=love.graphics.newFont(19)
 end
 function love.draw(...)
  if oldDraw then oldDraw(...) end
  local g=love.graphics
  local which=Layout.variants[chosen]
  local x=Layout.build(which)
  g.push('all')
  Res.begin_ui()
  -- Mask only for design comparison: this overlay is NOT a second
  -- renderer nor a gameplay UI. Existing g3d dice still run underneath.
  g.setColor(.055,.042,.03,.84)
  g.rectangle('fill',0,0,1920,1080)
  zone(g,x.book,'LIBRO 3D (volume)',{.28,.20,.12,.38},{.81,.66,.38,1})
  zone(g,x.page_main,'PAGINA GIOCABILE',{.71,.63,.47,.19},{.86,.75,.55,.78})
  if x.page_info then
   zone(g,x.page_info,'SECONDA PAGINA',{.71,.63,.47,.25},{.86,.75,.55,.9})
  end
  zone(g,x.tray,'AREA FISICA g3d - 6 D6',{.1,.37,.31,.48},{.28,.93,.77,.95})
  zone(g,x.shelf,'DADI ACCANTONATI',{.42,.31,.17,.5},{.95,.83,.57,.9})
  zone(g,x.folio,'PROGRESSO MANOSCRITTO',{.40,.27,.42,.44},{.90,.63,.94,.95})
  zone(g,x.context,'CONTESTO / RICOMPENSE',{.28,.30,.50,.38},{.73,.75,.98,.9})
  zone(g,x.header,'COMMISSIONE   OBIETTIVO   ASSICURATI   RISCHIO   TURNI',
       {.18,.18,.17,.9},{.9,.83,.62,.9})
  zone(g,x.message,'FEEDBACK DEL TURNO',{.17,.17,.16,.8},{.73,.74,.68,.7})
  zone(g,x.primary,'AZIONE 1',{.40,.27,.10,.9},{.96,.78,.40,1})
  zone(g,x.secondary,'AZIONE 2',{.25,.25,.24,.9},{.87,.84,.72,1})
  local cmp=Layout.comparison()
  g.setColor(1,.93,.76,1);g.setFont(font)
  g.print('P1 SOLO STUDIO - '..which..' - nessuna interazione reale',78,84)
  local line=string.format('Tray: %d x %d (%.0f%% del legacy)   |   F6 alterna A/B   |   F7 salva PNG',
     x.tray.w,x.tray.h,
     100*x.tray.w*x.tray.h/(1460*808))
  g.print(line,78,1042)
  Res.end_ui()
  g.pop()
 end
 function love.keypressed(key,...)
  if key=='f6' then
   chosen=chosen%#Layout.variants+1
   return
  elseif key=='f7' then
   local name='ui-v2-p1-'..Layout.variants[chosen]..'.png'
   love.graphics.captureScreenshot(function(data)
    local ok,err=love.filesystem.write(name,data:encode('png'):getString())
    if ok then print('P1 wireframe: '..love.filesystem.getSaveDirectory()..'/'..name)
    else print('P1 screenshot failed: '..tostring(err)) end
   end)
   return
  elseif key=='escape' then
   love.event.quit()
   return
  end
  if oldKey then return oldKey(key,...) end
 end
end
return M
