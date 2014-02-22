--os.unloadAPI("base64")
--os.loadAPI("/api/base64")
--local base64, error = loadfile("/api/base64")
--b64 = base64()

-- Copy of base64 API for easy first download.
-- character table string
local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

-- decoding
function dec(data)
    data = string.gsub(data, '[^'..b..'=]', '')
    return (data:gsub('.', function(x)
        if (x == '=') then return '' end
        local r,f='',(b:find(x)-1)
        for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
        return r;
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
        if (#x ~= 8) then return '' end
        local c=0
        for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
        return string.char(c)
    end))
end

-- Main programm
local arg = {...}
if (#arg ~= 2) then
  print "Usage: download <filename> <user>"
  print "   or: download -a <user>"
  return
end
user = arg[2]

--local baseUrl = "http://hoffe.dyndns.org/?"
local baseUrl = "http://dertroglodyt.dyndns.org:12345/?"

function printOut(json)
  for k, v in pairs(json) do
    print(tostring(k) .. ": " .. tostring(v))
  end
end

function get(filename)
  write("Getting " .. filename .. "..")
  result = http.get(baseUrl
    .."command=download"
    .."&user="..user
    .."&path=/"..user.."/"..filename)
  if (result == nil) then
    print("Unkown error.")
    return
  end
  local s = result.readAll()
  result.close()
  --print(s:sub(1, 6).."#")
  if (s:sub(1, 6) == "ERROR:") then
    print(s)
    return
  end
  local x, y = filename:find(".*/")
  if (y ~=  nil) then
    local path = filename:sub(1, y - 1)
    fs.makeDir(path)
  end
  local f = fs.open(filename, "w")
  --print(b64.dec(s))
  f.write(dec(s))
  f.close()
  print("OK. File downloaded.")
end

function getList(dir)
--  print("Get dir " .. dir)
  result = http.get(baseUrl
    .."command=list"
    .."&path=/"..user.."/"..dir
    .."&user="..user)
  if (result == nil) then
    print("Unkown error.")
    return {}
  end
  local r = {}
  local i = 1
  local s = result.readLine()
  if (s:sub(1, 6) == "ERROR:") then
    result.close()
    print(s)
    return {}
  end
  while (s ~= nil) do
    local typ = s:sub(1, 1)
    local name = s:sub(3)
    r[i] = { isDir = (typ == "d"), path = dir .. "/" .. name }
    i = i + 1
    s = result.readLine()
  end
  result.close()
  return r
end

function getDir(dir)
  for k, v in pairs(getList(dir)) do
--    print("List item " .. v.path)
    if (v.isDir) then
      getDir(v.path)
    else
      get(v.path)
    end
  end
end

if (arg[1] == "-a") then
  getDir("")
else
  get(arg[1])
end