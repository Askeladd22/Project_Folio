-- Pure pigment vocabulary and active UI wiring: no LÖVE required.
local Art=require('src.data.art_palette')
assert(Art.hex_for('surface')=='#E7DCC8')
assert(Art.hex_for('ink')=='#352A23')
assert(Art.hex_for('selection')=='#8E957B')
assert(Art.hex_for('risk')=='#8D4B43')
assert(Art.hex_for('focus')=='#4F5E66')
local function luma(c)
 local function linear(x)
  return x<=0.04045 and x/12.92 or ((x+0.055)/1.055)^2.4
 end
 return 0.2126*linear(c[1])+0.7152*linear(c[2])+0.0722*linear(c[3])
end
local function ratio(a,b)
 local la,lb=luma(a),luma(b)
 return (math.max(la,lb)+.05)/(math.min(la,lb)+.05)
end
assert(ratio(Art.rgb('text'),Art.rgb('surface'))>7,
 'Ink must remain very legible on parchment')
assert(ratio(Art.rgb('text_muted'),Art.rgb('surface'))>4.5,
 'Muted secondary text must retain readable contrast')
assert(ratio(Art.rgb('text'),Art.rgb('surface_alt'))>7)
for name,hex in pairs(Art.hex) do
 assert(hex:match('^#%x%x%x%x%x%x$'),'bad pigment '..name)
 local col=Art.rgb(name)
 for i=1,3 do assert(col[i]>=0 and col[i]<=1) end
 local alpha=Art.rgba(name,.42)
 assert(alpha[4]==.42 and #alpha==4)
 local copy=Art.rgb(name);copy[1]=-1
 assert(Art.rgb(name)[1]>=0,'palette shared mutable rgb: '..name)
end
for name,role in pairs(Art.roles) do
 assert(Art.hex_for(name)==Art.hex[role],'unknown role '..name)
end
local ok=pcall(function()return Art.rgb('fluorescent_green') end)
assert(not ok,'unknown colours must not silently fall back')
local function source(path)
 local f=assert(io.open(path,'rb'))
 local s=f:read('*a');f:close()
 return s
end
local expected={
 'src/features/ui_v2/menu_surface.lua',
 'src/features/main_menu/module.lua',
 'src/features/farkle/ui_v2/hud.lua',
 'src/features/farkle/ui_v2/dialogs.lua',
 'src/features/farkle/folio_view.lua',
 'src/features/settings/module.lua',
 'src/features/campaign_select/module.lua',
 'src/core/menu_particles.lua',
 'src/data/settings_ui_schema.lua',
}
for _,path in ipairs(expected) do
 assert(source(path):find('src.data.art_palette',1,true),
  'shipping UI not connected to canonical palette: '..path)
end
print('PASS art palette: 26 HEX pigments, semantic roles, contrast and UI wiring')
