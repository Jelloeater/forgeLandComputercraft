-- Test of BitBucket API
os.loadAPI("pb/json")
local root = "https://api.bitbucket.org/1.0/repositories/dertroglodyt/computercraftprograms/src/tip/"

function get(filename)
  local result = http.get(root .. filename)
  local data = json.decode(result.readAll())
  result.close()
  return data
end

local result = get("")
print(result)
print("dirs: " .. result.directories)
print("files: ")
for i=0, #result.files do
  print("  " .. result.files[i].path)
end
