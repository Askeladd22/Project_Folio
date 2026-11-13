-- Visual-only legibility gate. All scoring and hitbox ownership remain
-- in Farkle rules/controller. Runs with Lua 5.4 and LuaJIT without LÖVE.
local Fit=require('src.farkle.ui').text_fit.label
local Layout=require('src.farkle.ui').layout
local Surface=require('src.screens.folio_surface').menu_surface
local R=require('src.farkle.rules')
local P=require('src.farkle.presentation')
local Res=require('src.core.navigation').resolution

local function mock_width(str,px)
 return #tostring(str)*px*.57,px*1.16
end
local plain,px,cut=Fit.fit('Incassa 100 pt',mock_width,24,12,610,34)
assert(plain=='Incassa 100 pt' and not cut and px<=24)
local shrunk,small,cut2=Fit.fit('Prossima commissione [N]',
 mock_width,48,12,390,34)
assert(not cut2 and shrunk=='Prossima commissione [N]' and small<48)
local accented,_,shortened=Fit.fit(string.rep('è',40),
 mock_width,20,14,130,24)
assert(shortened and accented:sub(-3)=='...')
-- Truncation must preserve both bytes in each original accented glyph.
local prefix=accented:sub(1,#accented-3)
assert(#prefix%2==0 and not prefix:find('[^\195\168]'),
 'UTF-8 abbreviation split a multi-byte character')
assert(Fit.fit('Oversize',mock_width,30,20,0,0)=='',
 'zero-size cells must never draw outside their bounds')

local layout=Layout.build()
assert(Layout.validate(layout))
local metrics={
 {layout.secured_caption,layout.secured_value},
 {layout.risk_caption,layout.risk_value},
 {layout.objective_caption,layout.objective_value},
 {layout.turns_caption,layout.turns_value},
}
for _,pair in ipairs(metrics) do
 for _,rect in ipairs(pair) do
  assert(Layout.contains(layout.score_panel,rect),'metric outside scorecard')
  assert(Layout.overlap(layout.tray,rect)==0,'metric obscures the physical D6')
 end
 assert(Layout.overlap(pair[1],pair[2])==0,'metric caption overlaps its value')
end
assert(Layout.overlap(layout.secured_caption,layout.risk_caption)==0)
assert(Layout.overlap(layout.objective_caption,layout.turns_caption)==0)
print('PASS UI V2 canonical legibility: UTF-8 label fit and scorecard cell geometry')
