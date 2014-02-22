-- Updates all files in "/pb/" per wget from pastebin
-- The HTTP API must be enabled in mod_ComputerCraft.cfg before being used.
-- To enable it open .minecraft/config/mod_ComputerCraft.cfg and change enableAPI_http=0 to enableAPI_http=1.
-- Put this file into .minecraft\mods\ComputerCraft\lua\rom\programs\.
-- Enter a ComputerCraft terminal and type "webupdate".

local arg ={...}

-- Get an pastebin.com account (free) and find your developer key under "api" at the very top of pastebin
-- homepage. Needed only for future upload function.
-- Create a pastebin entry (name doen't matter) and copy it's RAW link to here.
-- This file hold sthe list of files you want to copy to your terminals and should look like this:
-- leativedir/filename1 http://<RAW-link to file1>
-- leativedir/filename2 http://<RAW-link to file2>
-- etc.
-- (relativedirs are optional)
local accounts = {
  trog = {devKey = "72402d2c356eab72478bcb96fb0c80d4", fileList = "http://pastebin.com/raw.php?i=Lc36wPBR"}
  , zeerix = {devKey = "", fileList = "http://pastebin.com/raw.php?i="}
  , zinnusl = {devKey = "", fileList = "http://pastebin.com/raw.php?i="}
}


function split(text, sep)
  local sep, fields = sep or " ", {}
  local pattern = string.format("([^%s]+)", sep)
  text:gsub(pattern, function(c) fields[#fields+1] = c end)
  return fields
end

function splitKeyValue(str, divider)  --Separates @str on @divider
  if not divider then
    return nil
  end
  str = tostring(str)
  str = str:gsub("%\n", " ")
--  print(str)
  local subs = split(str)
--  print(#subs)

  local list = {}
  for n=1, #subs, 2 do
--    print(tostring(n).." "..subs[n]..": "..subs[n+1])
    list[subs[n]] = subs[n+1]
  end
  return list
end

-- Get user account
local user = arg[1]
if not user then
  error("Usage: webupdate <account name>")
end
if not accounts[user] then
  error("Unknown account <"..user..">")
end
if not accounts[user].fileList then
  error("Unknown file list for account <"..user..">")
end

-- Get listing of all files
print("Getting file list...")
local response = http.get(accounts[user].fileList)
if (response) then
  local sResponse = response.readAll()
  response.close()
-- Parse file list [relativePath pastebinLink]
  local list = splitKeyValue(sResponse, " ")
-- Delete local pb directory and all files in it if already existing
    fs.delete("/pb")
-- And recreate it
    fs.makeDir("/pb")
-- Get all files on list
  for sFilePath, sLink in pairs(list) do
    write("Downloading "..sFilePath.."...")
-- Get content of file
    local response = http.get(sLink)
    sResponse = response.readAll()
-- Create sub dirs if necessary
    local dirs = split(sFilePath, "/")
    if #dirs == 0 then
      dirs = split(sFilePath, "\\")
    end
    local sPath = "/pb"
    for i=1, #dirs-1 do
      sPath = sPath.."/"..dirs[i]
    end
    fs.makeDir(sPath)
-- Add directory to relative file path
    sFilePath = "/pb/"..sFilePath
-- Write retrieved content to file
    local file = fs.open(sFilePath, "w")
    if not file then
      error("Could not open file <"..sFilePath.."> for write.")
    end
    file.write(sResponse)
    file.close()
    print("ok")
  end
  print("Update done.")
else
  error("Error getting file list")
end