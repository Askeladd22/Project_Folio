-- Optional renderer diagnostic. Never loads the lab in normal gameplay.
-- Kept separate so the canonical entry imports only src/ production modules.
local M={}
function M.start()
 if os.getenv('PROJECT_FOLIO_MINIATURE_LAB')=='1' then
  require('experiments.miniature_2d_lab.main')
  return true
 end
 if os.getenv('MANUSCRIPT_G3D_LAB')=='1' then
  require('experiments.g3d_lab.main')
  return true
 end
 return false
end
return M
