function love.conf(t)
 -- Separate save identity: playtest CSVs never touch the main game's run log.
 t.identity='project-folio-merchant-wager-lab'
 t.version='11.4'
 t.console=false
 t.window.title='Project Folio | Il Mercante e la posta'
 t.window.width=1280;t.window.height=720
 t.window.resizable=true;t.window.minwidth=960;t.window.minheight=540
 t.window.vsync=1
 t.modules.physics=false;t.modules.audio=false;t.modules.sound=false;t.modules.joystick=false
 for _,a in ipairs(arg or {}) do
  if a=='--money-simulate' then t.window=false;t.modules.window=false;t.modules.graphics=false end
 end
end
