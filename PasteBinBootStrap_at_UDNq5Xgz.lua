if not fs.exists("/bb") then
  fs.makeDir("/bb")
end
if not fs.exists("/bb/api") then
  fs.makeDir("/bb/api")
end
if not fs.exists("/bb/prog") then
  fs.makeDir("/bb/prog")
end


local url_bb = 'https://bitbucket.org/Jelloeater/forgelandcomputercraft/raw/tip/src/prog/bitbucket.lua'
local result = http.get(url_bb)
local data = result.readAll()
local file = fs.open("/bb/prog/bitbucket", "w")
if not file then
  error("Could not open file 'bitbucket' for write.")
end
file.write(data)
file.close()

local url_json = 'https://bitbucket.org/Jelloeater/forgelandcomputercraft/raw/tip/src/api/json.lua'
result = http.get(url_json)
data = result.readAll()
local file = fs.open("/bb/api/json", "w")
if not file then
  error("Could not open file 'json' for write.")
end
file.write(data)
file.close()

shell.run("/bb/prog/bitbucket")

print("install finished")