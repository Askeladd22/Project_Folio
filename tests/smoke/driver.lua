-- Explicit diagnostic entry. Never loaded during ordinary play.
local out=assert(os.getenv('MANUSCRIPT_AUDIT_OUT'))
function love.errorhandler(err)
 local f=assert(io.open(out..'/driver-error.txt','w'));f:write(tostring(err)..'\n'..debug.traceback());f:close()
 return function() return 1 end
end
local cases={partial='tests.smoke.partial',['face-gate']='tests.smoke.face_gate',integration='tests.smoke.integration',['turn-feel']='tests.smoke.turn_feel'}
require(assert(cases[os.getenv('MANUSCRIPT_SOURCE_CASE')],'Unknown diagnostic case'))
