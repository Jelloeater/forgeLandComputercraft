--Loads API from repo
os.loadAPI("/bb/api/json")

--Monitor JSONstoreect to output to
local m = peripheral.wrap("right")

local function run() 
  while true do
    local ok, err = pcall(getTime)
    if not ok then
      print("Had an issue... " .. err)
    end
    sleep(600) -- Sleep for 10 minutes    
  end
end

local function getTime()
	--Clears monitor
	m.clear()
	--Gets JSON RawJSONing from web and parse
	RawJSON = http.get("http://json-time.appspot.com/time.json").readAll()
	JSONstore = json.decode(RawJSON)
	m.write(JSONstore.hour+":"+JSONstore.minute)
end

print("Tick Tock Motherfucker!")