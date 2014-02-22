local function serializeInt(i)
  local s = ""
  repeat
    s = s .. string.char((i % 128) + ((i >= 128) and 128 or 0))
    i = math.floor(i / 128)
  until i == 0
  return s
end

-- returns int, next position
local function deserializeInt(s,pos)
  local k = pos
  local i = 0
  local m = 1
  while true do
    local b = string.byte(s:sub(k,k))
    i = i + m * (b % 128)
    m = m * 128
    k = k + 1
    if b < 128 then
      break
    end
  end
  return i, k
end

local nextid_key = {}
local function serializeInternal(obj, seen, toString)
  if obj ~= nil and seen[obj] then
    if toString then
      return "<obj>, "
    else
      return "\06" .. serializeInt(seen[obj])
    end
  end
  if type(obj) == "table" then
    local id = seen[nextid_key]
    seen[nextid_key] = id + 1
    seen[obj] = id

    local s = "\05"
    if toString then
      s = "{ "
    end
    local ikeys = {}
    for k,v in ipairs(obj) do
      ikeys[k] = v
      s = s .. serializeInternal(v, seen, toString)
    end
    if not toString then
      s = s .. serializeInternal(nil, seen, toString)
    end
    for k,v in pairs(obj) do
      if ikeys[k] == nil then
        if toString then
          s = s .. k .. ": " .. serializeInternal(v, seen, toString)
        else
          s = s .. serializeInternal(k, seen, toString) .. serializeInternal(v, seen, toString)
        end
      end
    end
    if not toString then
      s = s .. serializeInternal(nil, seen, toString)
    else
      s = s .. "}, "
    end
    return s
  elseif type(obj) == "number" then
    local ns = tostring(obj)
    if toString then
      return ns .. ", "
    else
      return "\04" .. serializeInt(ns:len()) .. ns
    end
  elseif type(obj) == "string" then
    if toString then
      return "'" .. obj .."', "
    else
      return "\03" .. serializeInt(obj:len()) .. obj
    end
  elseif type(obj) == "boolean" then
    if obj then
      if toString then
        return "<true>, "
      else
        return "\01"
      end
    else
      if toString then
        return "<false>, "
      else
        return "\02"
      end
    end
  elseif type(obj) == "nil" then
    if toString then
      return "<nil>, "
    else
      return "\00"
    end
  elseif type(obj) == "userdata" then
    error("cannot serialize userdata")
  elseif type(obj) == "thread" then
    error("cannot serialize threads")
  elseif type(obj) == "function" then
    error("cannot serialize functions")
  else
    error("unknown type: " .. type(obj))
  end
end

function serialize(obj)
  return serializeInternal(obj, {[nextid_key] = 0}, false)
end

function toString(obj)
  return serializeInternal(obj, {[nextid_key] = 0}, true)
end

function deserialize(s)
  local pos = 1
  local seen = {}
  local nextid = 0

  local function internal()
    local tch = s:sub(pos,pos)
    local len
    pos = pos + 1
    if tch == "\00" then
      return nil
    elseif tch == "\01" then
      return true
    elseif tch == "\02" then
      return false
    elseif tch == "\03" then
      len, pos = deserializeInt(s, pos)
      local rv = s:sub(pos, pos+len-1)
      pos = pos + len
      return rv
    elseif tch == "\04" then
      len, pos = deserializeInt(s, pos)
      local rv = s:sub(pos, pos+len-1)
      pos = pos + len
      return tonumber(rv)
    elseif tch == "\05" then
      local id = nextid
      nextid = id + 1
      local t = {}
      seen[id] = t

      local k = 1
      while true do
        local v = internal()
        if v == nil then
          break
        end
        t[k] = v
        k = k + 1
      end

      while true do
        local k = internal()
        if k == nil then
          break
        end
        local v = internal()
        if v == nil then
          break
        end
        t[k] = v
      end
      return t
    elseif tch == "\06" then
      local id
      id, pos = deserializeInt(s, pos)
      return seen[id]
    else
      return nil
    end
  end
  return internal()
end

function varToFile(name, var)
  if name == nil then
    error("Illegal argument: Name is nil")
  end
  if var== nil then
    error("Illegal argument: Var is nil")
  end
  local file = io.open("var_"..name, "w")
  if file == nil then
    error("Cannot open file <var_"..name.."> for write.")
  end
  file:write(serialize(var))
  file:close()
end

function varFromFile(name)
  if name == nil then
    error("Illegal argument: Name is nil")
  end
  local file = io.open("var_"..name, "r")
  if file ~= nil then
    local var = deserialize(file:read("*a"))
    file:close()
    return var
  end
  return nil
end