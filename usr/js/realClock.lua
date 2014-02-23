--Loads API from repo
os.loadAPI("/bb/api/json")

--Monitor JSONstoreect to output to
m = peripheral.wrap("right")
m.setTextSize(5)
m.setTextColor("green")


function run() 
  while true do
    local ok, err = pcall(getTime)
    if not ok then
      print("Had an issue... " .. err)
    end
    sleep(60) -- Sleep for 1 minute 
  end
end

function getTime()
	--Clears monitor
	m.clear()
	--Gets JSON RawJSONing from web and parse
	RawJSON = http.get("http://json-time.appspot.com/time.json").readAll()
	JSONstore = json.decode(RawJSON)
  hourInt = tonumber(JSONstore.hour)
  hourInt = hourInt + 7 --Sets timezone
  hourString = tostring(hourInt)

	m.write(JSONstore.hour..":"..JSONstore.minute)
end

run()
print("Tick Tock Motherfucker!")
