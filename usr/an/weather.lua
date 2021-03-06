os.loadAPI("/bb/api/jsonV2")

local m = peripheral.wrap("right")

local function getNews()
  m.clear()
  theNews = http.post("http://files.AndrewNatoli.com/mcapi/weather/weather.php","egg")
  theNews = theNews.readAll()
  theNews = jsonV2.decode(theNews)
  m.setCursorPos(1,1)
  m.write("Stony Brook, NY")
  m.setCursorPos(1,2)
  m.write(theNews.summary)
  m.setCursorPos(1,3)
  m.write(theNews.temp .. "*F")
  m.setCursorPos(1,4)
  m.write("Updated @  " .. theNews.time)    
  print("Got the latest weather - " .. theNews.time)
end

local function run() 
  while true do
    local ok, err = pcall(getNews)
    if not ok then
      print("Had an issue... " .. err)
    end
    sleep(600) -- Sleep for 10 minutes    
  end
end

print("Welcome to weather funtime!")
run()
