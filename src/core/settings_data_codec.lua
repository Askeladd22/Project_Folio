-- Bounded data-only codec; neither JSON nor legacy Lua syntax executes code.
local Codec={}
local MAX_SIZE=128*1024
local MAX_DEPTH=24
local MAX_FIELDS=2048

local function quote(s)
 return '"'..s:gsub('[%z\1-\31\\"]',function(c)
  local t={['"']='\\"',['\\']='\\\\',['\n']='\\n',['\r']='\\r',['\t']='\\t'}
  return t[c] or string.format('\\u%04x',c:byte())
 end)..'"'
end

local function encode_value(v,depth,seen)
 if depth>MAX_DEPTH then error('settings nesting too deep') end
 local k=type(v)
 if k=='string' then return quote(v) end
 if k=='boolean' then return v and 'true' or 'false' end
 if k=='number' then
  if v~=v or v==math.huge or v==-math.huge then error('nonfinite setting') end
  return tostring(v)
 end
 if k~='table' then error('unsupported setting type: '..k) end
 if seen[v] then error('cyclic settings table') end
 seen[v]=true
 local keys={};for key in pairs(v) do
  if type(key)~='string' then error('settings keys must be strings') end
  keys[#keys+1]=key
  if #keys>MAX_FIELDS then error('too many settings fields') end
 end
 table.sort(keys)
 local out={}
 for _,key in ipairs(keys) do
  out[#out+1]=quote(key)..':'..encode_value(v[key],depth+1,seen)
 end
 seen[v]=nil
 return '{'..table.concat(out,',')..'}'
end
function Codec.encode(data)
 local ok,result=pcall(encode_value,data,0,{})
 if not ok then return nil,tostring(result) end
 if #result>MAX_SIZE then return nil,'settings too large' end
 return result..'\n'
end

local function utf8(cp)
 if cp<128 then return string.char(cp) end
 if cp<2048 then return string.char(192+math.floor(cp/64),128+cp%64) end
 if cp<65536 then
  return string.char(224+math.floor(cp/4096),128+math.floor(cp/64)%64,128+cp%64)
 end
 return string.char(240+math.floor(cp/262144),128+math.floor(cp/4096)%64,
                    128+math.floor(cp/64)%64,128+cp%64)
end
local function reader(text,legacy)
 if type(text)~='string' or #text>MAX_SIZE then error('invalid settings size') end
 local i,n,fields=1,#text,0
 local function skip()
  local _,last=text:find('^%s*',i)
  i=(last or i-1)+1
 end
 local function peek() skip();return text:sub(i,i) end
 local function take(c) skip();if text:sub(i,i)~=c then error('expected '..c) end;i=i+1 end
 local function word()
  skip()
  local w=text:match('^([%a_][%w_]*)',i)
  if w then i=i+#w end
  return w
 end
 local function str()
  skip()
  local mark=text:sub(i,i)
  if mark~='"' and (not legacy or mark~="'") then error('expected quoted string') end
  i=i+1
  local out={}
  while i<=n do
   local c=text:sub(i,i);i=i+1
   if c==mark then return table.concat(out) end
   if c=='\\' then
    local b=text:sub(i,i);i=i+1
    local map={n='\n',r='\r',t='\t',b='\b',f='\f',v='\v',a='\a',['\\']='\\',
               ['"']='"',["'"]="'",['0']='\0'}
    if b=='u' and not legacy then
     local code=text:sub(i,i+3)
     if not code:match('^%x%x%x%x$') then error('invalid unicode escape') end
     i=i+4
     local cp=tonumber(code,16)
     if cp>=0xD800 and cp<=0xDBFF then
      if text:sub(i,i+1)~='\\u' then error('missing low surrogate') end
      i=i+2;local tail=text:sub(i,i+3)
      if not tail:match('^%x%x%x%x$') then error('invalid low surrogate') end
      i=i+4;local lo=tonumber(tail,16)
      if lo<0xDC00 or lo>0xDFFF then error('invalid surrogate pair') end
      cp=0x10000+(cp-0xD800)*1024+lo-0xDC00
     elseif cp>=0xDC00 and cp<=0xDFFF then error('unpaired surrogate') end
     out[#out+1]=utf8(cp)
    elseif legacy and b:match('%d') then
     local digits=b
     for _=1,2 do
      local nextc=text:sub(i,i)
      if not nextc:match('%d') then break end
      digits=digits..nextc;i=i+1
     end
     local num=tonumber(digits)
     if num>255 then error('invalid legacy byte') end
     out[#out+1]=string.char(num)
    elseif map[b] then
     out[#out+1]=map[b]
    else error('unsupported string escape') end
   else
    if c:byte()<32 then error('control character in string') end
    out[#out+1]=c
   end
  end
  error('unterminated string')
 end
 local parse
 parse=function(depth)
  if depth>MAX_DEPTH then error('settings nesting too deep') end
  local c=peek()
  if c=='{' then
   take('{')
   local obj={}
   while peek()~='}' do
    fields=fields+1;if fields>MAX_FIELDS then error('too many settings fields') end
    local key
    if legacy then
     if peek()=='[' then
      take('[')
      if peek()=='"' or peek()=="'" then key=str()
      else
       local start=i
       while text:sub(i,i):match('[%d%-]') and i<=n do i=i+1 end
       key=tonumber(text:sub(start,i-1))
       if not key then error('bad legacy key') end
      end
      take(']')
     else
      key=word()
      if not key then error('invalid legacy key') end
     end
     take('=')
    else
     key=str();take(':')
    end
    if obj[key]~=nil then error('duplicate settings key') end
    obj[key]=parse(depth+1)
    local delim=peek()
    if delim==',' then
     take(',')
    elseif delim~='}' then error('missing settings delimiter') end
    if peek()=='' then error('unterminated settings object') end
   end
   take('}')
   return obj
  end
  if c=='"' or legacy and c=="'" then return str() end
  skip()
  local number=text:match('^(-?%d+%.?%d*[eE]?[+%-]?%d*)',i)
  -- The old Lua table syntax also allows a leading decimal point.
  if not number and legacy then
   number=text:match('^(-?%.%d+[eE]?[+%-]?%d*)',i)
  end
  if number and #number>0 then
   local val=tonumber(number)
   if not val or val~=val or val==math.huge or val==-math.huge then error('invalid number') end
   i=i+#number;return val
  end
  local w=word()
  if w=='true' then return true end
  if w=='false' then return false end
  if legacy and w=='nil' then error('nil entries are not supported') end
  error('unsupported settings value')
 end
 if legacy then
  if word()~='return' then error('expected legacy table return') end
 end
 local result=parse(0)
 if type(result)~='table' then error('settings root must be an object') end
 if peek()~='' then error('unexpected code after settings') end
 return result
end
function Codec.decode(raw,legacy)
 local ok,result=pcall(reader,raw,legacy==true)
 if not ok then return nil,tostring(result) end
 return result
end
return Codec
