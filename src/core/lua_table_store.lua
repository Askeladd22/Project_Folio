local Codec=require('src.core.settings_data_codec')
local Store={}
local MAX_BYTES=128*1024
local function filesystem(options)
 if options and options.filesystem then return options.filesystem end
 return love and love.filesystem
end
local function read(fs,path)
 if not fs or type(fs.getInfo)~='function' or type(fs.read)~='function' then
  return nil,nil,'unavailable'
 end
 if not fs.getInfo(path) then return nil,nil,'missing' end
 local raw,err=fs.read(path)
 if type(raw)~='string' then return nil,tostring(err or 'read failed'),'load_error' end
 if #raw>MAX_BYTES then return nil,'settings too large','invalid_data' end
 return raw
end
function Store.load(path,options)
 local fs=filesystem(options)
 local raw,err,status=read(fs,path)
 if not raw then return nil,err,status end
 local value,problem=Codec.decode(raw,options and options.legacy)
 if not value then return nil,problem,'invalid_data' end
 return value,nil,nil
end
function Store.save(path,data,options)
 if type(data)~='table' then return false,'settings must be a table' end
 local fs=filesystem(options)
 if not fs or type(fs.write)~='function' or type(fs.read)~='function' or
    type(fs.getInfo)~='function' then return false,'filesystem unavailable' end
 local raw,err=Codec.encode(data)
 if not raw then return false,err end
 -- The old valid contents remain in a sidecar; LÖVE has no guaranteed
 -- atomic rename on all platforms. Recover from .bak if a write is torn.
 local previous=read(fs,path)
 if previous and Codec.decode(previous) then
  local ok,why=fs.write(path..'.bak',previous)
  if not ok then return false,'backup failed: '..tostring(why) end
 end
 local ok,why=fs.write(path..'.pending',raw)
 if not ok then return false,'pending settings write failed: '..tostring(why) end
 local verify=read(fs,path..'.pending')
 if verify~=raw then return false,'pending settings verification failed' end
 ok,why=fs.write(path,raw)
 if not ok then return false,'settings write failed: '..tostring(why) end
 local committed=read(fs,path)
 if committed~=raw then return false,'settings write verification failed' end
 if type(fs.remove)=='function' then fs.remove(path..'.pending') end
 return true
end
return Store
