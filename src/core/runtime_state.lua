local Bundle = {}
Bundle.store = (function()
local Parts = {}

-- Bounded settings codec
Parts.codec = (function()
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
end)()

-- Settings persistence
Parts.store = (function()
local Codec=Parts.codec
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
end)()

Parts.store.codec = Parts.codec
return Parts.store
end)()
Bundle.runtime = (function()
local Parts = {}

-- Runtime settings
Parts.state = (function()
local RuntimeState = {}

local state = {
    game_settings = nil,
    show_fps = false,
    target_fps = 0,
    ui_scale = 1.0,
    ui_high_contrast = false,
    ui_reduced_animations = false,
}

local function copy_table(value)
    if type(value) ~= "table" then
        return value
    end
    local out = {}
    for k, v in pairs(value) do
        out[k] = copy_table(v)
    end
    return out
end

function RuntimeState.apply_settings(settings)
    local next_settings = copy_table(settings or {})
    local video = type(next_settings.video) == "table" and next_settings.video or {}
    local accessibility = type(next_settings.accessibility) == "table" and next_settings.accessibility or {}

    state.game_settings = next_settings
    state.show_fps = video.show_fps and true or false
    state.target_fps = tonumber(video.fps_limit) or 0
    state.ui_scale = accessibility.big_text and 1.18 or 1.0
    state.ui_high_contrast = accessibility.high_contrast and true or false
    state.ui_reduced_animations = accessibility.reduced_animations and true or false
end

function RuntimeState.get_game_settings()
    return copy_table(state.game_settings)
end

function RuntimeState.should_show_fps()
    return state.show_fps
end

function RuntimeState.get_target_fps()
    return state.target_fps
end

function RuntimeState.get_ui_scale()
    return state.ui_scale
end

function RuntimeState.is_ui_high_contrast()
    return state.ui_high_contrast
end

function RuntimeState.is_ui_reduced_animations()
    return state.ui_reduced_animations
end

return RuntimeState
end)()

-- Accessibility helpers
Parts.ui = (function()

local RuntimeUI = {}
local RuntimeState = Parts.state

local function accessibility()
    local state = RuntimeState.get_game_settings()
    if state and state.accessibility then
        return state.accessibility
    end
    return {
        big_text = false,
        high_contrast = false,
        reduced_animations = false,
    }
end

function RuntimeUI.scale()
    return RuntimeState.get_ui_scale() or 1
end

function RuntimeUI.big_text()
    return accessibility().big_text and true or false
end

function RuntimeUI.high_contrast()
    return accessibility().high_contrast and true or false
end

function RuntimeUI.reduced_animations()
    return accessibility().reduced_animations and true or false
end

function RuntimeUI.sized(px)
    local scaled = math.floor((px * RuntimeUI.scale()) + 0.5)
    return math.max(8, scaled)
end

return RuntimeUI
end)()

Parts.state.ui = Parts.ui
return Parts.state
end)()
Bundle.settings = (function()

local SettingsState = {}
local Logger = require('src.core.engine_bridge').logger
local RuntimeState = Bundle.runtime
local SettingsStore = Bundle.store
local Schema = require('src.core.config').schema
local SettingsSchema = require('src.data.frontend_schema').settings

local expect_string = Schema.expect_string
local PERSISTENCE_SCHEMA = SettingsSchema.persistence
local FILE_PATH = expect_string(PERSISTENCE_SCHEMA.file_path, "settings_schema.persistence.file_path")
local FILE_FORMAT = expect_string(PERSISTENCE_SCHEMA.format, "settings_schema.persistence.format")
local LEGACY_PATH = expect_string(PERSISTENCE_SCHEMA.legacy_file_path, "settings_schema.persistence.legacy_file_path")

if FILE_FORMAT ~= "json" then
    error("Unsupported settings persistence format: " .. tostring(FILE_FORMAT))
end

local BASE_DEFAULTS = {
    game = {
        language = "English",
        verbose_logs = false,
    },
    controls = {
        mouse_sensitivity = 0.55,
        invert_y = false,
        prompt_input = "Keyboard",
    },
    accessibility = {
        big_text = false,
        high_contrast = false,
        reduced_animations = false,
    },
    video = {
        window_mode = "Borderless",
        fps_limit = 0,
        show_fps = false,
    },
    audio = {
        master_volume = 0.8,
        sfx_volume = 0.7,
        music_volume = 0.6,
        mute_sfx = false,
        mute_music = false,
    },
}

local current = nil
local last_windowed_w = nil
local last_windowed_h = nil

local function clamp(v, min_v, max_v)
    if v < min_v then return min_v end
    if v > max_v then return max_v end
    return v
end

local function deep_copy(value)
    if type(value) ~= "table" then
        return value
    end

    local out = {}
    for k, v in pairs(value) do
        out[k] = deep_copy(v)
    end
    return out
end

local function copy_table(tbl)
    local out = {}
    if type(tbl) ~= "table" then
        return out
    end
    for k, v in pairs(tbl) do
        out[k] = v
    end
    return out
end

local function split_path(path)
    local parts = {}
    for part in string.gmatch(path or "", "[^%.]+") do
        parts[#parts + 1] = part
    end
    return parts
end

local function get_path_value(tbl, path)
    local curr = tbl
    for _, part in ipairs(split_path(path)) do
        if type(curr) ~= "table" then
            return nil
        end
        curr = curr[part]
    end
    return curr
end

local function set_path_value(tbl, path, value)
    local parts = split_path(path)
    if #parts == 0 then
        return
    end
    local curr = tbl
    for i = 1, #parts - 1 do
        local key = parts[i]
        if type(curr[key]) ~= "table" then
            curr[key] = {}
        end
        curr = curr[key]
    end
    curr[parts[#parts]] = value
end

local function merge_with_defaults(default_value, loaded_value)
    if type(default_value) ~= "table" then
        if type(loaded_value) == type(default_value) then
            return loaded_value
        end
        return default_value
    end

    local out = {}
    for k, dv in pairs(default_value) do
        local lv = nil
        if type(loaded_value) == "table" then
            lv = loaded_value[k]
        end
        out[k] = merge_with_defaults(dv, lv)
    end
    return out
end

local function merge_tables_union(primary, fallback)
    if type(primary) ~= "table" then
        if primary ~= nil then
            return primary
        end
        return deep_copy(fallback)
    end

    local out = {}
    if type(fallback) == "table" then
        for key, value in pairs(fallback) do
            out[key] = deep_copy(value)
        end
    end

    for key, value in pairs(primary) do
        if type(value) == "table" and type(out[key]) == "table" then
            out[key] = merge_tables_union(value, out[key])
        else
            out[key] = deep_copy(value)
        end
    end

    return out
end

local function build_defaults_from_schema(schema)
    local out = {}
    local tabs = type(schema) == "table" and schema.tabs or {}

    for _, tab in ipairs(tabs or {}) do
        local controls = type(tab) == "table" and tab.controls or {}
        for _, control in ipairs(controls or {}) do
            local setting = type(control) == "table" and control.setting or nil
            if type(setting) == "string" and setting ~= "" then
                local default_value = nil
                if control.type == "choice" then
                    local idx = math.floor(tonumber(control.default_index) or tonumber(control.value_index) or 1)
                    if idx < 1 then
                        idx = 1
                    end
                    if type(control.value_map) == "table" and control.value_map[idx] ~= nil then
                        default_value = control.value_map[idx]
                    elseif type(control.options) == "table" and control.options[idx] ~= nil then
                        default_value = control.options[idx]
                    end
                elseif control.default ~= nil then
                    default_value = control.default
                elseif control.value ~= nil then
                    default_value = control.value
                end

                if default_value ~= nil then
                    set_path_value(out, setting, default_value)
                end
            end
        end
    end

    return out
end

local function build_choice_validators(schema)
    local out = {}
    local tabs = type(schema) == "table" and schema.tabs or {}

    for _, tab in ipairs(tabs or {}) do
        local controls = type(tab) == "table" and tab.controls or {}
        for _, control in ipairs(controls or {}) do
            if control.type == "choice" and type(control.setting) == "string" then
                local allowed = {}
                if type(control.value_map) == "table" then
                    for _, value in ipairs(control.value_map) do
                        allowed[value] = true
                    end
                elseif type(control.options) == "table" then
                    for _, value in ipairs(control.options) do
                        allowed[value] = true
                    end
                end

                if next(allowed) then
                    out[control.setting] = allowed
                end
            end
        end
    end

    return out
end

local SCHEMA_DEFAULTS = build_defaults_from_schema(SettingsSchema)
local DEFAULTS = merge_tables_union(SCHEMA_DEFAULTS, BASE_DEFAULTS)
local CHOICE_VALIDATORS = build_choice_validators(SettingsSchema)

local function normalize_choice(out, path)
    local allowed = CHOICE_VALIDATORS[path]
    if type(allowed) ~= "table" then
        return
    end

    local value = get_path_value(out, path)
    if allowed[value] then
        return
    end

    set_path_value(out, path, get_path_value(DEFAULTS, path))
end

local function normalize(data)
    local out = merge_with_defaults(DEFAULTS, data)

    normalize_choice(out, "game.language")
    out.game.verbose_logs = out.game.verbose_logs and true or false

    normalize_choice(out, "controls.prompt_input")
    out.controls.mouse_sensitivity = clamp(tonumber(out.controls.mouse_sensitivity) or DEFAULTS.controls.mouse_sensitivity, 0, 1)
    out.controls.invert_y = out.controls.invert_y and true or false

    out.accessibility.big_text = out.accessibility.big_text and true or false
    out.accessibility.high_contrast = out.accessibility.high_contrast and true or false
    out.accessibility.reduced_animations = out.accessibility.reduced_animations and true or false

    normalize_choice(out, "video.window_mode")
    out.video.fps_limit = tonumber(out.video.fps_limit) or DEFAULTS.video.fps_limit
    normalize_choice(out, "video.fps_limit")
    out.video.show_fps = out.video.show_fps and true or false

    out.audio.master_volume = clamp(tonumber(out.audio.master_volume) or DEFAULTS.audio.master_volume, 0, 1)
    out.audio.sfx_volume = clamp(tonumber(out.audio.sfx_volume) or DEFAULTS.audio.sfx_volume, 0, 1)
    out.audio.music_volume = clamp(tonumber(out.audio.music_volume) or DEFAULTS.audio.music_volume, 0, 1)
    out.audio.mute_sfx = out.audio.mute_sfx and true or false
    out.audio.mute_music = out.audio.mute_music and true or false

    return out
end

local function ensure_current()
    if not current then
        current = deep_copy(DEFAULTS)
    end
end

local function sanitize_dimension(v, fallback)
    local n = math.floor(tonumber(v) or fallback or 0)
    if n < 1 then
        return math.floor(fallback or 1)
    end
    return n
end

local function get_desktop_dimensions(flags, fallback_w, fallback_h)
    local out_w = sanitize_dimension(fallback_w, 1280)
    local out_h = sanitize_dimension(fallback_h, 720)

    if not (love and love.window and love.window.getDesktopDimensions) then
        return out_w, out_h
    end

    local display_index = 1
    if type(flags) == "table" and type(flags.display) == "number" then
        display_index = flags.display
    end

    local ok, dw, dh = pcall(love.window.getDesktopDimensions, display_index)
    if ok and type(dw) == "number" and type(dh) == "number" and dw > 0 and dh > 0 then
        return math.floor(dw), math.floor(dh)
    end

    return out_w, out_h
end

local function default_windowed_size(desktop_w, desktop_h)
    local min_w = math.min(960, desktop_w)
    local min_h = math.min(540, desktop_h)
    local w = clamp(math.floor(desktop_w * 0.84), min_w, desktop_w)
    local h = clamp(math.floor(desktop_h * 0.84), min_h, desktop_h)
    return w, h
end

function SettingsState.get_defaults()
    return deep_copy(DEFAULTS)
end

function SettingsState.get()
    ensure_current()
    return deep_copy(current)
end

function SettingsState.set(next_settings)
    current = normalize(next_settings)
    return deep_copy(current)
end

function SettingsState.reset()
    current = deep_copy(DEFAULTS)
    return deep_copy(current)
end

function SettingsState.load()
    local loaded, err, status = SettingsStore.load(FILE_PATH)
    if status == "invalid_data" or status == "load_error" then
        Logger.debug("[SettingsState] primary data damaged: "..tostring(err))
        loaded = SettingsStore.load(FILE_PATH..".bak")
    elseif status == "missing" then
        -- Restricted parser: reads only table literals, NEVER executes Lua.
        local legacy,legacy_err = SettingsStore.load(LEGACY_PATH,{legacy=true})
        if legacy then
            loaded = legacy
            local ok,write_err = SettingsStore.save(FILE_PATH,normalize(legacy))
            if not ok then
                Logger.debug("[SettingsState] migration pending: "..tostring(write_err))
            end
        elseif legacy_err then
            Logger.debug("[SettingsState] legacy data rejected: "..tostring(legacy_err))
        end
    end
    current = normalize(loaded)
    return deep_copy(current)
end

function SettingsState.save()
    ensure_current()
    local ok, err = SettingsStore.save(FILE_PATH, current)
    return ok, err
end

function SettingsState.apply()
    ensure_current()
    Logger.set_enabled(current.game and current.game.verbose_logs)

    if love and love.audio and love.audio.setVolume then
        pcall(function()
            love.audio.setVolume(current.audio.master_volume)
        end)
    end

    if love and love.window and love.window.getMode and love.window.setMode then
        local mode = current.video.window_mode
        local curr_w, curr_h, curr_flags = love.window.getMode()
        curr_w = sanitize_dimension(curr_w, 1280)
        curr_h = sanitize_dimension(curr_h, 720)
        curr_flags = curr_flags or {}

        local desktop_w, desktop_h = get_desktop_dimensions(curr_flags, curr_w, curr_h)
        local target_w
        local target_h
        local flags = copy_table(curr_flags)

        if not curr_flags.fullscreen and not curr_flags.borderless then
            if curr_w < desktop_w or curr_h < desktop_h then
                last_windowed_w = curr_w
                last_windowed_h = curr_h
            end
        end

        flags.resizable = true
        local fps_limit = tonumber(current.video.fps_limit) or 0
        if fps_limit <= 0 then
            -- Unlimited FPS requires disabling VSync, otherwise refresh rate still caps frames.
            flags.vsync = 0
        elseif flags.vsync == nil or flags.vsync == 0 then
            flags.vsync = 1
        end

        if mode == "Fullscreen" then
            flags.fullscreen = true
            flags.fullscreentype = "desktop"
            flags.borderless = false
            target_w = desktop_w
            target_h = desktop_h
            flags.x = nil
            flags.y = nil
        elseif mode == "Borderless" then
            flags.fullscreen = false
            flags.fullscreentype = "desktop"
            flags.borderless = true
            target_w = desktop_w
            target_h = desktop_h
            flags.x = 0
            flags.y = 0
        else
            flags.fullscreen = false
            flags.fullscreentype = "desktop"
            flags.borderless = false
            local default_w, default_h = default_windowed_size(desktop_w, desktop_h)
            local min_w = math.min(960, desktop_w)
            local min_h = math.min(540, desktop_h)
            local can_use_saved = (type(last_windowed_w) == "number" and type(last_windowed_h) == "number")
            if can_use_saved and last_windowed_w >= desktop_w and last_windowed_h >= desktop_h then
                can_use_saved = false
            end

            local source_w = can_use_saved and last_windowed_w or default_w
            local source_h = can_use_saved and last_windowed_h or default_h
            target_w = clamp(sanitize_dimension(source_w, default_w), min_w, desktop_w)
            target_h = clamp(sanitize_dimension(source_h, default_h), min_h, desktop_h)
            flags.x = nil
            flags.y = nil
        end

        local ok, success = pcall(love.window.setMode, target_w, target_h, flags)
        if (not ok) or (success == false) then
            local fallback_flags = {
                resizable = true,
                vsync = flags.vsync or 1,
                fullscreen = false,
                fullscreentype = "desktop",
                borderless = false,
            }
            pcall(love.window.setMode, target_w, target_h, fallback_flags)
            Logger.debug("[SettingsState] window mode apply failed, fallback to windowed.")
        elseif mode == "Windowed" then
            last_windowed_w = target_w
            last_windowed_h = target_h
        end
    end

    RuntimeState.apply_settings(current)
end

SettingsState.FILE_PATH = FILE_PATH

return SettingsState
end)()
Bundle.runtime.settings = Bundle.settings
Bundle.runtime.store = Bundle.store
return Bundle.runtime
