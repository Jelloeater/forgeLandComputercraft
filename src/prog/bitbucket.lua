-- Recursivly retrieves all files of a BitBucket repository.
--
-- The HTTP API must be enabled in mod_ComputerCraft.cfg before being used.
-- To enable it open .minecraft/config/mod_ComputerCraft.cfg and change enableAPI_http=0 to enableAPI_http=1.
--
-- Files are stored in a directory "/bb". Subdirectories of the repository get created localy too.
-- For use in IDE projects the "/src/" in path name gets stripped off.
-- For ease of use the ".lua" extension also gets stripped off.

-- The BitBucket API returns json objects. To use them in lua we need this api.
os.loadAPI("/bb/api/json")

-- https://api.bitbucket.org/1.0/repositories/<your user name>/<your repository name>/src/tip/
local root = "https://api.bitbucket.org/1.0/repositories/Jelloeater/forgelandcomputercraft/src/tip/"

function get(filename)
  local result = http.get(root .. filename)
  local data = result.readAll()
  result.close()
--  print(data)
  local obj = json.decode(data)
  return obj
end

function getLocalPath(dir)
  return "/bb" .. string.gsub(dir, "/src/", "/")
end

function getDir(dir)
  local localDir = getLocalPath(dir .. "/")
  if not fs.exists(localDir) then
    fs.makeDir(localDir)
  end
  local result = get(dir)
  for i=1, #result.files do
    if string.find(result.files[i].path, ".hgignore") then
      print("Skipping .hgignore")
    else
      print("Getting file " .. result.files[i].path .. "...")
      local fd = get(result.files[i].path)
      local filename = string.gsub(getLocalPath("/" .. result.files[i].path), ".lua", "")
      local file = fs.open(filename, "w")
      if not file then
        error("Could not open file <" .. filename .. "> for write.")
      end
      file.write(fd.data)
      file.close()
    end
  end
  for i=1, #result.directories do
    print("Getting dir " .. result.path .. result.directories[i] .. "...")
    getDir(result.path .. result.directories[i])
  end
end

fs.delete("/bb")
local result = getDir("")
print("Done")