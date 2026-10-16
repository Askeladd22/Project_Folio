local M = {}
M.ease = {
    smooth=function(t) return t*t*(3-2*t) end,
    out=function(t) return 1-(1-t)^3 end,
    cubic=function(t) return t<.5 and 4*t^3 or 1-(-2*t+2)^3/2 end,
}
function M.clamp(v,a,b) return math.max(a,math.min(b,v)) end
function M.stage(t,a,b) return M.clamp((t-a)/(b-a),0,1) end
local State={}; State.__index=State
function M.new()
    return setmetatable({time=0,duration=2.4,intensity=.7,playing=false,
        loop=false,disabled=false,reduced=false,completions=0},State)
end
function State:progress() return self:immediate() and 1 or M.clamp(self.time/self.duration,0,1) end
function State:immediate() return self.disabled or self.reduced end
function State:play()
    self.time=self:immediate() and self.duration or 0
    self.playing=not self:immediate()
end
function State:pause() self.playing=false end
function State:set_duration(v)
    local p=self:progress(); self.duration=M.clamp(v,.4,6); self.time=p*self.duration
end
function State:set_disabled(v) self.disabled=v; if self:immediate() then self.time=self.duration; self:pause() end end
function State:set_reduced(v) self.reduced=v; if self:immediate() then self.time=self.duration; self:pause() end end
function State:update(dt)
    if not self.playing or self:immediate() then return end
    self.time=self.time+math.max(dt,0)
    if self.time+1e-10>=self.duration then
        if self.loop then
            local n=math.floor((self.time+1e-10)/self.duration)
            self.completions=self.completions+n
            self.time=math.max(0,self.time-n*self.duration)
        else self.time=self.duration; self.completions=self.completions+1; self.playing=false end
    end
end
return M
