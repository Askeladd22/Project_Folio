-- Presentation geometry only for canonical Farkle UI V2 dialogs.
-- Modal overlays intentionally cover the 3D board; controller hitboxes
-- and command IDs are still authoritative in ui_v2/dialogs.lua.
local M={}
local function rect(x,y,w,h) return {x=x,y=y,w=w,h=h} end
local function contains(a,b)
 return b.x>=a.x and b.y>=a.y and
  b.x+b.w<=a.x+a.w and b.y+b.h<=a.y+a.h
end
local function overlap(a,b)
 return a.x<b.x+b.w and b.x<a.x+a.w and
  a.y<b.y+b.h and b.y<a.y+a.h
end
M.frame=rect(390,145,1140,800)
M.close=rect(1295,175,205,56)
M.header_rule={x=425,y=240,w=1070}
M.reward_frame=rect(390,210,1140,650)
M.reward_rule={x=440,y=418,w=1040}
M.reward_cards={
 rect(430,438,510,218),
 rect(980,438,510,218),
}
M.reward_buttons={
 rect(440,685,490,85),
 rect(990,685,490,85),
}

-- Compact in-game pause/navigation leaf; unrelated dialog geometry is unchanged.
M.pause_frame=rect(615,226,690,620)
M.pause_close=rect(1165,252,100,44)
M.pause_title=rect(670,277,440,48)
M.pause_intro=rect(670,326,490,34)
M.pause_items={
 rect(674,378,572,62),rect(674,450,572,62),
 rect(674,522,572,62),rect(674,594,572,62),
}
M.pause_confirm_frame=rect(635,292,650,440)
M.pause_confirm_close=rect(1137,316,107,44)
M.pause_confirm_title=rect(688,370,425,50)
M.pause_confirm_actions={
 rect(690,568,540,62),rect(690,644,540,62),
}
function M.validate()
 local bounds=rect(0,0,1920,1080)
 for _,r in ipairs({M.frame,M.reward_frame,M.close,
   M.reward_cards[1],M.reward_cards[2],
   M.reward_buttons[1],M.reward_buttons[2]}) do
  if not contains(bounds,r) then return false,'dialog outside viewport' end
 end
 for _,pair in ipairs({
  {M.pause_frame,M.pause_close},
  {M.pause_frame,M.pause_title},
  {M.pause_frame,M.pause_intro},
  {M.pause_confirm_frame,M.pause_confirm_close},
  {M.pause_confirm_frame,M.pause_confirm_title},
 }) do
  if not contains(pair[1],pair[2]) then return false,'pause item outside frame' end
 end
 for _,r in ipairs(M.pause_items) do
  if not contains(M.pause_frame,r) then return false,'pause action outside frame' end
 end
 for _,r in ipairs(M.pause_confirm_actions) do
  if not contains(M.pause_confirm_frame,r) then return false,'confirm action outside frame' end
 end
 for i=2,#M.pause_items do
  if overlap(M.pause_items[i-1],M.pause_items[i]) then
   return false,'pause actions overlap'
  end
 end
 if overlap(M.pause_confirm_actions[1],M.pause_confirm_actions[2]) then
  return false,'confirm actions overlap'
 end
 if not contains(M.frame,M.close) then
  return false,'close outside standard dialog'
 end
 for i=1,2 do
  if not contains(M.reward_frame,M.reward_cards[i]) or
    not contains(M.reward_frame,M.reward_buttons[i]) then
   return false,'reward element outside folio'
  end
  if overlap(M.reward_cards[i],M.reward_buttons[i]) then
   return false,'reward action obscured by its description'
  end
 end
 if overlap(M.reward_cards[1],M.reward_cards[2]) or
  overlap(M.reward_buttons[1],M.reward_buttons[2]) then
  return false,'reward columns overlap'
 end
 for _,rule in ipairs({{M.frame,M.header_rule},
                       {M.reward_frame,M.reward_rule}}) do
  local frame,r=rule[1],rule[2]
  if r.x<frame.x or r.x+r.w>frame.x+frame.w or
    r.y<frame.y or r.y>frame.y+frame.h then
   return false,'rule outside dialog'
  end
 end
 return true
end
return M
