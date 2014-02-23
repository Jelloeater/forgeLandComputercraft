--Loads API from repo
os.loadAPI("/bb/api/json")

--Monitor JSONstoreect to output to
m = peripheral.wrap("right")
m.setTextScale(4) -- Fits in 2 monitors
m.setTextColor(8192)


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
  m.setCursorPos(1,1) --Resets the cursor back to the beginning
	--Gets JSON RawJSONing from web and parse

	RawJSON = http.get("http://json-time.appspot.com/time.json").readAll()
	JSONstore = json.decode(RawJSON)
  hourInt = tonumber(JSONstore.hour)


  hourInt = hourInt + 7 --Sets timezone
  hourInt = hourInt - 24 --Converts to 12 hr

  amPM ="a" --Default to morning

  if hourInt < 24
    hourInt - 24
    amPM = "p"
  end

  hourString = tostring(hourInt)

  timeOutput = hourString..":"..JSONstore.minute..amPM

	m.write(timeOutput)
  print(timeOutput)
end

run() --Runs the program

-- Color Refrence
-- white      1
-- orange     2   
-- magenta    4   
-- lightBlue  8 
-- yellow     16  
-- lime       32
-- pink       64
-- gray       128   
-- lightGray  256
-- cyan       512   
-- purple     1024
-- blue       2048  
-- brown      4096  
-- green      8192  
-- red        16384   
-- black      32768   