-- Fixed presentation geometry for the optional Monk duel.
-- Contains NO input handlers, scoring or dice physics. The restart rectangle
-- must continue to match controller.lua's existing hardcoded mouse hitbox.
local Layout=require('src.features.farkle.ui_v2.layout_candidates')
local M={}
local function rect(x,y,w,h) return {x=x,y=y,w=w,h=h} end

M.status_panel=rect(1512,128,352,172)
M.title=rect(1528,137,320,24)
M.score=rect(1528,171,320,26)
M.round=rect(1528,202,320,22)
M.last_roll=rect(1528,230,320,24)
M.status=rect(1528,266,320,24)
M.status_rule={x=1528,y=163,w=320}
M.message_rule={x=1528,y=260,w=320}

-- This is an intentional end-of-duel MODAL over the 3D play field.
-- Never move this hitbox unless controller.lua is changed in the same PR.
M.result_panel=rect(600,440,720,152)
M.result_title=rect(625,452,670,38)
M.result_help=rect(625,493,670,29)
M.retry=rect(780,540,350,45)
M.retry_label=rect(797,547,316,30)

function M.validate()
 local base=Layout.build('single_folio')
 local sidebar=base.sidebar_frame
 local folio_in_duel=rect(base.folio.x,320,base.folio.w,370)
 if not sidebar or not Layout.contains(sidebar,M.status_panel) then
  return false,'Monk ledger must remain inside the manuscript binding'
 end
 if Layout.overlap(M.status_panel,folio_in_duel)>0 or
   Layout.overlap(M.status_panel,base.tray)>0 or
   Layout.overlap(M.status_panel,base.header)>0 then
  return false,'Monk ledger hides folio, header or 3D dice'
 end
 for _,r in ipairs({M.title,M.score,M.round,M.last_roll,M.status}) do
  if not Layout.contains(M.status_panel,r) then
   return false,'text escapes the Monk ledger'
  end
 end
 for _,rule in ipairs({M.status_rule,M.message_rule}) do
  if rule.x<M.status_panel.x or rule.x+rule.w>M.status_panel.x+
    M.status_panel.w or rule.y<M.status_panel.y or
    rule.y>M.status_panel.y+M.status_panel.h then
   return false,'rule escapes the Monk ledger'
  end
 end
 if not Layout.contains(M.result_panel,M.retry) or
   not Layout.contains(M.result_panel,M.result_title) or
   not Layout.contains(M.result_panel,M.result_help) or
   not Layout.contains(M.retry,M.retry_label) then
  return false,'end-of-duel modal composition is invalid'
 end
 if M.retry.x~=780 or M.retry.y~=540 or M.retry.w~=350 or
   M.retry.h~=45 then
  return false,'restart must match the existing controller hitbox'
 end
 return true
end

return M
