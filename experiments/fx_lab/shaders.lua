local S={}
local sources={
ink=[[
extern number progress;
extern number strength;
vec4 effect(vec4 color, Image tex, vec2 uv, vec2 screen) {
 vec4 px=Texel(tex,uv)*color;
 number edge=progress*1.12-.06;
 number wave=sin(uv.y*47.0)*.012*strength;
 number mask=1.0-smoothstep(edge-.025,edge+.025,uv.x+wave);
 return px*mask;
}]],
gold=[[
extern number progress;
extern number strength;
vec4 effect(vec4 color, Image tex, vec2 uv, vec2 screen) {
 vec4 px=Texel(tex,uv)*color;
 number sweep=progress*1.8-.4;
 number band=exp(-pow((uv.x+uv.y*.32-sweep)*14.0,2.0));
 number envelope=sin(progress*3.14159265);
 number medalMask=1.0-smoothstep(65.0,68.0,length(uv*vec2(540.0,370.0)-vec2(260.0,205.0)));
 return vec4(px.rgb+vec3(.40,.32,.14)*band*strength*envelope*medalMask*px.a,px.a);
}]],
light=[[
extern number progress;
extern number strength;
vec4 effect(vec4 color, Image tex, vec2 uv, vec2 screen) {
 vec4 px=Texel(tex,uv)*color;
 vec2 delta=(uv-vec2(.62,.52))*vec2(1.0,1.25);
 number glow=exp(-dot(delta,delta)*15.0)*sin(progress*3.14159265)*strength;
 return vec4(px.rgb+vec3(.20,.13,.05)*glow,px.a);
}]],
}
function S.load()
    S.errors={}; S.items={}
    for name,code in pairs(sources) do
        local ok,result=pcall(love.graphics.newShader,code)
        if ok then S.items[name]=result else S.errors[name]=tostring(result) end
    end
end
function S.use(name,p,intensity)
    local s=S.items[name]
    if s then s:send('progress',p); s:send('strength',intensity); love.graphics.setShader(s) end
    return s~=nil
end
function S.clear() love.graphics.setShader() end
return S
