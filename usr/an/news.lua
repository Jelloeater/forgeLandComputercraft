os.loadAPI("/bb/api/jsonV2")

local m = peripheral.wrap("left")

local function getNews()
  m.clear()
  theNews = http.post("http://files.AndrewNatoli.com/mcapi/twitter-key.php","egg")
  theNews = theNews.readAll()
  theNews = jsonV2.decode(theNews)
  m.setCursorPos(1,1)
  m.write("@BreakingNews - Updated at " .. theNews.time)
  m.setCursorPos(1,2)
  m.write(theNews.a)
  m.setCursorPos(1,3)
  m.write(theNews.b)
  m.setCursorPos(1,4)
  m.write(theNews.c)    
  print("Got the latest news - " .. theNews.time)
end

local function run() 
  while true do
    local ok, err = pcall(getNews)
    if not ok then
      print("Had an issue... " .. err)
    end
    sleep(420) -- Sleep for 7 minutes    
  end
end

print("Welcome to news funtime!")
run()
