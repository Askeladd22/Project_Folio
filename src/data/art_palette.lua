-- Project Folio's canonical muted manuscript palette.
-- Inspired by illustrated medieval landscapes, incunabula and material
-- pigments, not by photographic colour-grading or generic fantasy UI.
-- Pure Lua: safe to load in headless tests, independent of LÖVE/renderer.
local P={}
P.hex={
 paper='#E7DCC8',paper_mid='#D8C9B1',paper_shadow='#C3B097',
 plaster='#DCD5C8',stone='#BFB4A1',dust='#9B9285',
 timber_light='#A78663',timber='#856448',earth='#6E533C',
 earth_dark='#4E3B2C',ink='#352A23',
 sage_light='#AAB09A',sage='#8E957B',olive='#72785C',
 forest='#59604A',
 clay='#C38B7A',brick='#A85F52',cinnabar='#8D4B43',
 burgundy='#6F3A35',
 mist='#B3C0C1',slate_light='#8E9EA0',
 slate='#6F8087',slate_dark='#4F5E66',
 ochre_light='#D4B66A',ochre='#BE9A4F',ochre_dark='#9F8344',
}
P.roles={
 background='plaster',
 surface='paper',
 surface_alt='paper_mid',
 surface_recessed='paper_shadow',
 text='ink',
 text_muted='earth',
 border='timber',
 focus='slate_dark',
 selection='sage',
 reward='ochre_dark',
 risk='cinnabar',
 quiet='dust',
 physical='mist',
}
local cache={}
local function resolve(name)
 local role=P.roles[name] or name
 local hex=P.hex[role]
 assert(hex,'Unknown Project Folio colour: '..tostring(name))
 return role,hex
end
function P.hex_for(name)
 local _,hex=resolve(name)
 return hex
end
function P.rgb(name)
 local role,hex=resolve(name)
 if not cache[role] then
  cache[role]={
   tonumber(hex:sub(2,3),16)/255,
   tonumber(hex:sub(4,5),16)/255,
   tonumber(hex:sub(6,7),16)/255,
  }
 end
 -- Return a copy, never leak the shared palette to drawing code that
 -- changes alpha or modifies a component in-place.
 return {cache[role][1],cache[role][2],cache[role][3]}
end
function P.rgba(name,alpha)
 local c=P.rgb(name)
 c[4]=alpha==nil and 1 or alpha
 return c
end
return P
