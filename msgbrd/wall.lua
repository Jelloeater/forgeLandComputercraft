-- Message Wall Client v1
-- Author: Jesse

os.loadAPI('jsonV2')
os.loadAPI("colorFuncs")
debugmode = false
searchMessagesMenuFlag = false
editSettingsMenuFlag = false
settingsFilePath = "/devconfig/settings.cfg"
terminalWidth, terminalHeight = term.getSize()

-----------------------------------------------------------------------------------------------------------------------
-- Settings Class
settings = {}  -- the table representing the class, holds all the data, we don't need a singleton because THIS IS LUA.
settings.serverURL = ''
settings.numberOfMessagesToGet = 15
settings.refreshInterval = 60


settings.monitorDefaultColor = colors.white
settings.terminalDefaultColor = colors.white
settings.progressBarColor = colors.yellow
settings.bootLoaderColor = colors.green

settings.statusIndent = 22 -- Indent for Status (28 for 1x2 22 for 2x4 and bigger)
settings.terminalIndent1 = 6 -- Determines dash location
settings.terminalHeaderOffset = 0
settings.monitorHeader = "Message List"
settings.terminalHeader = "Message List"

function listSettings( ... ) -- Need two print commands due to formating
	term.clear()
	print("Settings - I hope you know what you're doing -_-")
	print("")
	term.write("serverURL = ") print(settings.serverURL)
	term.write("numberOfMessagesToGet = ") print(settings.numberOfMessagesToGet)
	term.write("refreshInterval = ") print(settings.refreshInterval)
	term.write("monitorDefaultColor = ") print(settings.monitorDefaultColor)
	term.write("terminalDefaultColor = ") print(settings.terminalDefaultColor)
	term.write("progressBarColor = ") print(settings.progressBarColor)
	term.write("bootLoaderColor = ") print(settings.bootLoaderColor)
	term.write("statusIndent = ") print(settings.statusIndent)
	term.write("terminalIndent1 = ") print(settings.terminalIndent1)
	term.write("terminalHeaderOffset = ") print(settings.terminalHeaderOffset)
	term.write("monitorHeader = ") print(settings.monitorHeader)
	term.write("terminalHeader = ") print(settings.terminalHeader)
end

function editSettingsMenu( ... )
	term.clear()

	while true do 
		listSettings()
		term.setCursorPos(1,terminalHeight)	term.write("(setting name / eXit): ")
		local menuChoice = read()

		if menuChoice == "serverURL" then settings.serverURL = read() end
		if menuChoice == "numberOfMessagesToGet" then settings.numberOfMessagesToGet = tonumber(read()) end
		if menuChoice == "refreshInterval" then settings.refreshInterval = tonumber(read()) end
		if menuChoice == "monitorDefaultColor" then colorFuncs.listColors() settings.monitorDefaultColor = colorFuncs.toColor(read()) end
		if menuChoice == "terminalDefaultColor" then colorFuncs.listColors() settings.terminalDefaultColor = colorFuncs.toColor(read()) end
		if menuChoice == "progressBarColor" then colorFuncs.listColors() settings.progressBarColor = colorFuncs.toColor(read()) end
		if menuChoice == "bootLoaderColor" then colorFuncs.listColors() settings.bootLoaderColor = colorFuncs.toColor(read()) end
		if menuChoice == "statusIndent" then settings.statusIndent = tonumber(read()) end
		if menuChoice == "terminalIndent1" then settings.terminalIndent1 = tonumber(read()) end
		if menuChoice == "terminalHeaderOffset" then settings.terminalHeaderOffset = tonumber(read()) end
		if menuChoice == "monitorHeader" then settings.monitorHeader = read() end
		if menuChoice == "terminalHeader" then settings.terminalHeader = read() end
		if menuChoice == "exit" or menuChoice == "x" then break end
	end 

	saveSettings()
	editSettingsMenuFlag = false
	mainProgram()
end

function saveSettings( ... )
	local prettystring = jsonV2.encodePretty(settings)
	local fileHandle = fs.open(settingsFilePath,"w")
	fileHandle.write(prettystring)
	fileHandle.close()
end

function loadSettings( ... )
	local fileHandle = fs.open(settingsFilePath,"r")
	local RAWjson = fileHandle.readAll()
	fileHandle.close()

	settings = jsonV2.decode(RAWjson)
end
-----------------------------------------------------------------------------------------------------------------------
-- Message Class
local Message = {}  -- the table representing the class, which will double as the metatable for the instances
Message.__index = Message -- failed table lookups on the instances should fallback to the class table, to get methods

function Message.new(message, timestamp, index)
	local self = setmetatable({},Message) 
	-- Lets class self refrence to create new objects based on the class	
	self.message = message or nil
	self.timestamp = timestamp or nil
	self.index = index or nil
	return self
end

function Message.terminalWrite(self, lineNumberIn ) -- Runs first
	term.setCursorPos(1,lineNumberIn+settings.terminalHeaderOffset)
	
	term.write(self.index)
	term.setCursorPos(settings.terminalIndent1,lineNumberIn+settings.terminalHeaderOffset)
	term.write("- ")
	term.write(self.message) 

	local timestampText = "("..self.timestamp..")"
	local timestampLength = string.len(timestampText)

	term.setCursorPos(terminalWidth - timestampLength, lineNumberIn+settings.terminalHeaderOffset)
	term.write(timestampText)
end

function Message.monitorStatus(self,lineNumberIn ) -- Runs second if monitor is available
	monitor.setCursorPos(1,lineNumberIn+settings.terminalHeaderOffset)
	
	monitor.write(tostring(self.index))
	monitor.setCursorPos(settings.terminalIndent1,lineNumberIn+settings.terminalHeaderOffset)
	monitor.write("- ")
	monitor.write(self.message) 

	local timestampText = "("..self.timestamp..")"
	local timestampLength = string.len(timestampText)
	local x, y = monitor.getSize()
	monitor.setCursorPos(x - timestampLength, lineNumberIn+settings.terminalHeaderOffset)
	monitor.write(timestampText)
end

-----------------------------------------------------------------------------------------------------------------------

function createMessage()
	print("Enter message to be created: ")
	local message = read()
	http.post(settings.serverURL..'/post','create='..message)
end

function removeMessage()
	print("Enter index to be removed: ")
	local removeIndex = read()
	http.post(settings.serverURL..'/post','delete='..removeIndex)
end

function editMessage()
	print("Enter index to edit: ")
	local index  = read()
	print("Enter New Message: ")
	local message = read()
	http.post(settings.serverURL..'/post','edit='..message..'&index='..index)
end

function getMessages(numberToGet)
	-- Gets message table
	x = http.get(settings.serverURL..'/get/'.. numberToGet)
	jsonStr = x.readAll()
	jsonObj = jsonV2.decode(jsonStr)

	messageTable = {} -- Clears the table
	for i=1,table.getn(jsonObj) do
		table.insert(messageTable, Message.new(
			jsonObj[i].message, jsonObj[i].timestamp,jsonObj[i].index))
	end

end

function searchMessages(messageToSearchFor)
	-- Gets message table
	x = http.get(settings.serverURL..'/query/'.. messageToSearchFor)
	jsonStr = x.readAll()
	jsonObj = jsonV2.decode(jsonStr)

	if jsonStr ~= "]" then -- Prevents empty querys
		messageTable = {} -- Clears the table
		for i=1,table.getn(jsonObj) do
			table.insert(messageTable, Message.new(
				jsonObj[i].message, jsonObj[i].timestamp,jsonObj[i].index))
		end
	else
		print('Message Not Found (press any key to continue)')
		read()
	end
end

function bootLoader( ... )
	term.clear()
	if fs.exists (settingsFilePath) then loadSettings() 
	else
		print('Enter IP Address (Ex 127.0.0.1)')
		ipaddress = read()
		print('Enter port (Ex 80)')
		port = read()
		settings.serverURL = 'http://'..ipaddress..':'..port
		saveSettings()
	end 
	-- Loads settings
	term.setTextColor(settings.bootLoaderColor)

	term.setCursorPos(1,1)
	term.write("SYSTEM BOOTING - Loading Settings")
	term.setCursorPos(1,terminalHeight)
	term.setTextColor(settings.progressBarColor)
	term.write(".")
	term.setTextColor(settings.bootLoaderColor)
	os.sleep(.5)

	---------------------------------------------------------------------------------------------------------
	-- Detect and Setup monitor if present
	monitorPresentFlag = false -- Default global flag
	monitorSide = ""-- Default Side
	
	term.setCursorPos(1,2)
	term.write("Detecting Monitor")
	os.sleep(.25)

	if peripheral.isPresent("top") and peripheral.getType("top") == "monitor" then monitorSide = "top" monitorPresentFlag = true end
	if peripheral.isPresent("bottom") and peripheral.getType("bottom") == "monitor" then monitorSide = "bottom" monitorPresentFlag = true end
	if peripheral.isPresent("left") and peripheral.getType("left") == "monitor" then monitorSide = "left" monitorPresentFlag = true end
	if peripheral.isPresent("right") and peripheral.getType("right") == "monitor" then monitorSide = "right" monitorPresentFlag = true end
	if peripheral.isPresent("back") and peripheral.getType("back") == "monitor" then monitorSide = "back" monitorPresentFlag = true end
	
	if monitorPresentFlag then
		term.write(" - Located Monitor: ".. monitorSide)
		monitor = peripheral.wrap(monitorSide) -- Monitor wrapper, default location, for easy access
		monitor.setTextScale(1) -- Sets Text Size (.5 for 1x2 1 for 2x4 2.5 for 5x7 (MAX))
		monitor.setCursorPos(5, 5)
		monitor.clear()
		monitor.write("SYSTEM BOOT IN PROGRESS")
	end
	if monitorPresentFlag == false then term.write(" - NO MONITOR FOUND") end

	term.setCursorPos(1,terminalHeight)
	term.setTextColor(settings.progressBarColor)
	term.write("..........")
	term.setTextColor(settings.bootLoaderColor)
	os.sleep(.5)

	---------------------------------------------------------------------------------------------------------
	-- Wait a-bit
	term.setCursorPos(1,6)
	term.write("Please wait")
	os.sleep(1)
	term.setCursorPos(1,terminalHeight)
	term.setTextColor(settings.progressBarColor)
	term.write("..................................................")
	term.setTextColor(settings.bootLoaderColor)
	os.sleep(.25)

	term.setTextColor(settings.terminalDefaultColor)
end

-----------------------------------------------------------------------------------------------------------------------
-- Termainl & Monitor Output
function writeMenuHeader( ... )
	term.setTextColor(settings.terminalDefaultColor)
	term.clear()
	local terminalHeaderText = settings.terminalHeader .. " - ".." ["..tostring(os.getComputerID()).."]"
	local x, y = term.getSize()
	local terminalWidth = x
	local headerLength = string.len(terminalHeaderText)

	term.setCursorPos(terminalWidth/2 - headerLength/2, 1)
	term.write(terminalHeaderText)
end

function writeMonitorHeader( ... )
	monitor.clear()
	local x, y = monitor.getSize()
	local monitorWidth = x
	local headerLength = string.len(settings.monitorHeader)

	monitor.setCursorPos(monitorWidth/2 - headerLength/2, 1)
	monitor.write(settings.monitorHeader)
end

function writeMenuFooter( ... )
	if pocket then 
		term.setCursorPos(1,terminalHeight)
		term.write("sRch/Cre/Ed/rM/Get/Set:")
	else
		term.setCursorPos(1,terminalHeight)
		term.write("(seaRch/Create/Edit/reMove/Get/Settings): ")
	end
end

function monitorRedraw( ... ) -- Status Monitor Display
	writeMonitorHeader()
	for i=1,table.getn(messageTable) do -- Gets arraylist size
		messageTable[i]:monitorStatus(i+1)
	end
end

function termRedraw( ... ) -- Terminal Display
	if searchMessagesMenuFlag == true then
		for i=1,table.getn(messageTable) do -- Gets arraylist size
			messageTable[i]:terminalWrite(i)
		end
	else
		writeMenuHeader()
		for i=1,table.getn(messageTable) do -- Gets arraylist size
			messageTable[i]:terminalWrite(i+1)
		end
		writeMenuFooter()
	end
end

-----------------------------------------------------------------------------------------------------------------------
-- User Input

function menuInput( ... )
	local inputOption = read()
	menuOption(inputOption) -- Normal Options
end

function clickMonitor()
  event, side, xPos, yPos = os.pullEvent("monitor_touch")
	-- for i=1,table.getn(deviceList) do -- Gets arraylist size
	-- 	local devIn = deviceList[i] -- Loads device list to object
		
	-- 	if yPos == i + 1 then -- 1 to offset header
	-- 		if devIn.type == "switch" then
	-- 			if devIn.statusFlag == false and devIn.confirmFlag == false then devIn:on() break end
	-- 			if devIn.statusFlag == true then devIn:off() break end
	-- 		end
	-- 	end
	-- end
end

function clickTerminal()
event, side, xPos, yPos = os.pullEvent("mouse_click")

	-- for i=1,table.getn(deviceList) do -- Gets arraylist size
	-- 	local devIn = deviceList[i] -- Loads device list to object
		
	-- 	if yPos == i + 1 + settings.terminalHeaderOffset then -- 1 to offset header
	-- 		if devIn.type == "switch" then
	-- 			if devIn.statusFlag == false and devIn.confirmFlag == false then devIn:on() break end
	-- 		end
	-- 	end
	-- end
end

function menuOption( menuChoice ) -- Menu Options for Terminalr
	if menuChoice == "search" or menuChoice == "r" then searchMessagesMenuFlag = true end -- Exits to edit menu
	if menuChoice == "settings" or menuChoice == "s" then editSettingsMenuFlag = true end -- Exits to edit menu
	if menuChoice == "create" or menuChoice == "c" then createMessage() end -- Sets flag to true so we break out of main program
	if menuChoice == "edit" or menuChoice == "e" then editMessage() end -- Exits to edit menu
	if menuChoice == "remove" or menuChoice == "m" then removeMessage() end -- Exits to edit menu
	if menuChoice == "get" or menuChoice == "g" then getMessages(settings.numberOfMessagesToGet) end

end

function searchMessagesMenu( ... )
	term.clear()
	while true do 
		if pocket then
			term.setCursorPos(1,terminalHeight)	term.write("(SEARCH / eXit: ")
		else
			term.setCursorPos(1,terminalHeight)	term.write("(Enter Search / eXit): ")
		end
		
		local menuChoice = read()
		if menuChoice == "exit" or menuChoice == "x" then 
			break 
		else
			if menuChoice ~= "" then
				term.clear()
				searchMessages(menuChoice)
				termRedraw() -- PASSIVE OUTPUT
				if monitorPresentFlag then  monitorRedraw() end -- PASSIVE OUTPUT
			end
		end
	end 

	searchMessagesMenuFlag = false
	mainProgram()
end

function autoRefresh( ... )
	while true do
		getMessages(settings.numberOfMessagesToGet)
		termRedraw() -- PASSIVE OUTPUT
		if monitorPresentFlag then  monitorRedraw() end -- PASSIVE OUTPUT
		os.sleep(settings.refreshInterval)
	end
end
-----------------------------------------------------------------------------------------------------------------------
-- Main Program
function run( ... )
	bootLoader()
	mainProgram()
end

function mainProgram( ... )

	while true do
		getMessages(settings.numberOfMessagesToGet)
		if searchMessagesMenuFlag then searchMessagesMenu() break end -- Kicks in from menuInput command
		if editSettingsMenuFlag then editSettingsMenu() break end -- Kicks in from menuInput command

		terminalWidth, terminalHeight = term.getSize() -- Incase of resize

		termRedraw() -- PASSIVE OUTPUT
		if monitorPresentFlag then  monitorRedraw() end -- PASSIVE OUTPUT
		parallel.waitForAny(menuInput,clickTerminal,clickMonitor,autoRefresh)
	end
end

run()