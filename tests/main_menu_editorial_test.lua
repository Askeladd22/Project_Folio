-- Regression guard for the quiet, legible main menu. This changes
-- presentation only: never menu IDs, hitboxes, transitions or callbacks.
local Schema = require("src.data.main_menu_schema")
local Surface = require("src.features.ui_v2.menu_surface")
local oldLove = love

local g = {pushes=0,pops=0,rectangles=0,lines=0,polygons=0}
love={graphics={
 push=function()g.pushes=g.pushes+1 end,
 pop=function()g.pops=g.pops+1 end,
 setColor=function()end,
 setLineWidth=function()end,
 rectangle=function()g.rectangles=g.rectangles+1 end,
 line=function()g.lines=g.lines+1 end,
 polygon=function()g.polygons=g.polygons+1 end,
}}
local rect={x=44,y=53,w=560,h=650}
Surface.panel(rect,{style="editorial",alpha=1})
Surface.rule(80,220,460,1,{quiet=true})
Surface.item({x=80,y=240,w=460,h=56},
             {style="editorial",primary=true,active=true})
Surface.item({x=80,y=300,w=460,h=56},
             {style="editorial",disabled=true})
assert(g.pushes==g.pops,"editorial primitives must restore Love graphics")
assert(g.polygons==0,"no fake gilded lozenges on the main menu")
assert(g.lines>=2 and g.rectangles>=3,
       "editorial surfaces must render legible selection and rule")
local function read(path)
 local f=assert(io.open(path,"rb"))
 local s=f:read("*a");f:close()
 return s
end
local code=read("src/features/main_menu/module.lua")
assert(code:find('style="editorial"',1,true),
       "main menu must opt in to editorial surface")
assert(code:find('illustrated=menu_bg_path == ILLUSTRATED_BG_PATH',1,true),
       'only authored illustration should use lighter vignette')
assert(code:find("local emphasized = item.primary and item.enabled",1,true),
       "disabled Continue must not compete with the enabled New Game")
assert(not code:find("get_footer_alpha_label",1,true))
local expected={"continue","new-game","bot-duel","settings","wishlist","quit"}
assert(#Schema.menu_items==#expected)
for i,item in ipairs(Schema.menu_items) do
 assert(item.id==expected[i],"menu functionality or order changed")
end
assert(not Schema.menu_items[1].enabled and Schema.menu_items[2].enabled)
assert(Schema.menu_items[5].label.default=="Wishlist")
love=oldLove
print("PASS editorial main menu: readable hierarchy, minimal surface, actions preserved")
