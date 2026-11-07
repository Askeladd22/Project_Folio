-- Regression: player pause, confirmation boundaries and route preservation.
-- This exercises the real V2 dialog callbacks with a headless LÖVE renderer.
local R=require('src.farkle.rules')
local Res=require('src.core.navigation').resolution
local Navigation=require('src.core.navigation')
local ModalLayout=require('src.farkle.ui').layout.modal
local Dialogs=require('src.farkle.ui').dialogs
unpack=unpack or table.unpack

local originalLove=love
local font={
 getWidth=function(_,s)return #tostring(s)*11 end,
 getHeight=function()return 25 end,
 getLineHeight=function()return 1 end,
 getWrap=function(_,s)return #tostring(s)*11,{tostring(s)} end,
}
local noop=function()end
local push,pop=0,0
love={graphics=setmetatable({
 getWidth=function()return 1920 end,
 getHeight=function()return 1080 end,
 getDimensions=function()return 1920,1080 end,
 getFont=function()return font end,
 newFont=function()return font end,
 push=function()push=push+1 end,
 pop=function()pop=pop+1 end,
},{__index=function()return noop end}),
 mouse={getPosition=function()return 0,0 end}}
Res.init(1920,1080)
Res.refresh(1920,1080)
assert(ModalLayout.validate())

local route
Navigation.configure(function(name,params)
 route={name=name,params=params}
end)
local game=R.new()
game.bank=42
game.pot=15
local resets={}
local u={game=game,buttons={roll={enabled=true}},modal='run',

 reset=function(self,mode)
  resets[#resets+1]=mode
  self.modal=nil
 end}
local originalButtons=u.buttons
local function render()
 Dialogs.overlay(u,{})
 assert(push==pop,'pause renderer leaked graphics state')
 assert(u.buttons==originalButtons,'pause must restore game hitboxes')
 assert(u.modalButtons and u.modalButtons.close)
 assert(game.bank==42 and game.pot==15,'pause renderer changed score')
end
render()
assert(u.modalButtons.resume and u.modalButtons.settings
 and u.modalButtons.restart and u.modalButtons.mainmenu)
assert(not u.modalButtons.control and not u.modalButtons.medals,
 'developer actions must not appear in the player pause menu')
u.modalButtons.resume.fn()
assert(u.modal==nil and game.bank==42,'resume changed game state')

u.modal='run';render()
u.modalButtons.settings.fn()
assert(u.modal==nil and route and route.name=='settings'
 and route.params and route.params.return_to=='scriptorium',
 'settings must preserve the active Farkle scene')

u.modal='run';render()
u.modalButtons.restart.fn()
assert(u.modal=='run_restart_confirm' and #resets==0,
 'restart must require confirmation')
render()
assert(u.modalButtons.cancel and u.modalButtons.confirmrestart)
u.modalButtons.cancel.fn()
assert(u.modal=='run' and #resets==0,'cancelled restart changed state')
render()
u.modalButtons.restart.fn()
render()
u.modalButtons.confirmrestart.fn()
assert(#resets==1 and resets[1]=='build','normal run mode changed on restart')
assert(u.modal==nil)

u.game=R.new('control')
u.modal='run'
render()
u.modalButtons.restart.fn()
render()
u.modalButtons.confirmrestart.fn()
assert(resets[2]=='control','restart must preserve the active ruleset')
u.game=game

route=nil
u.modal='run';render()
u.modalButtons.mainmenu.fn()
assert(u.modal=='run_exit_confirm' and route==nil,
 'returning to main menu must require confirmation')
render()
u.modalButtons.cancel.fn()
assert(u.modal=='run' and route==nil)
render()
u.modalButtons.mainmenu.fn()
render()
u.modalButtons.confirmexit.fn()
assert(route and route.name=='main_menu' and u.modal==nil,
 'main menu route not invoked after confirmation')
assert(#resets==2,'leaving a run must not silently reset it')

Navigation.configure(nil)
love=originalLove
print('PASS compact pause routes, restart confirmations, session preservation and ruleset')
