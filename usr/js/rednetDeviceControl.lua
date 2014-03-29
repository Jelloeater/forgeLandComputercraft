-- RedNet Cable Control System v10
-- Author: Jesse

os.loadAPI("/bb/api/jsonV2")
os.loadAPI("/bb/api/colorFuncs")

debugmode = false
debugEventFlag = false
editDevicesMenuFlag = false

rednetSide = "bottom" -- Where is the redNet cable
devicesFilePath = "/devices.cfg"

monitorDefaultColor = colors.white
terminalDefaultColor = colors.white
progressBarColor = colors.yellow
bootLoaderColor = colors.green
rednetIndicatorColor = colors.blue

fillColor = colors.yellow
dumpColor = colors.green
onColor = colors.green
offColor = colors.red

statusIndent = 22 -- Indent for Status (28 for 1x2 22 for 2x4 and bigger)
terminalIndent1 = 7 -- Determines dash location
terminalIndent2 = 36 -- Determines (On/Off ... etc location)
terminalHeaderOffset = 0

-----------------------------------------------------------------------------------------------------------------------
-- Parsers (we keep the user from breaking everything that is good...)
-- function colorFuncs.toColor( colornameIn )
-- 	if colornameIn == "white" then return colors.white end
-- 	if colornameIn == "orange" then return colors.orange end
-- 	if colornameIn == "magenta" then return colors.magenta end
-- 	if colornameIn == "lightBlue" then return colors.lightBlue end
-- 	if colornameIn == "yellow" then return colors.yellow end
-- 	if colornameIn == "lime" then return colors.lime end
-- 	if colornameIn == "pink" then return colors.pink end
-- 	if colornameIn == "gray" then return colors.gray end
-- 	if colornameIn == "lightGray" then return colors.lightGray end
-- 	if colornameIn == "cyan" then return colors.cyan end
-- 	if colornameIn == "purple" then return colors.purple end
-- 	if colornameIn == "blue" then return colors.blue end
-- 	if colornameIn == "brown" then return colors.brown end
-- 	if colornameIn == "green" then return colors.green end
-- 	if colornameIn == "red" then return colors.red end
-- 	if colornameIn == "black" then return colors.black end
-- end

-- function colorFuncs.toString( colorINTin )
-- 	if colorINTin == 1 then return "white" end
-- 	if colorINTin == 2 then return "orange" end
-- 	if colorINTin == 4 then return "magenta" end
-- 	if colorINTin == 8 then return "lightBlue" end
-- 	if colorINTin == 16 then return "yellow" end
-- 	if colorINTin == 32 then return "lime" end
-- 	if colorINTin == 64 then return "pink" end
-- 	if colorINTin == 128 then return "gray" end
-- 	if colorINTin == 256 then return "lightGray" end
-- 	if colorINTin == 512 then return "cyan" end
-- 	if colorINTin == 1024 then return "purple" end
-- 	if colorINTin == 2048 then return "blue" end
-- 	if colorINTin == 4096 then return "brown" end
-- 	if colorINTin == 8192 then return "green" end
-- 	if colorINTin == 16384 then return "red" end
-- 	if colorINTin == 32768 then return "black" end
-- end

function parseTrueFalse( stringIN )
	if stringIN == "true" or stringIN == "True" then return true else return false end
end

function parseStartupState( stringIN )
	if stringIN == "fill" or stringIN == "Fill" then return "fill"end
	if stringIN == "dump" or stringIN == "Dump" then return "dump" end
	if stringIN == "on" or stringIN == "On" then return "on" end
	if stringIN == "" then return "off" else return "off" end
end
-----------------------------------------------------------------------------------------------------------------------
-- Debug Functions
function debugMenu( ... )
	while true do
	print("R/N: "..redstone.getBundledOutput(rednetSide).." - "..rednetSide)
	print("(on/off/exit/reboot/json/devlist/colortest)")
	print("save/loaddefault")

	local menuChoice = read()
	if menuChoice == "on" then debugmode = true end
	if menuChoice == "off" then debugmode = false end
	if menuChoice == "exit" then debugMenuFlag = false mainProgram() end
	if menuChoice == "reboot" then run() end
	if menuChoice == "json" then jsonTest()	end
	if menuChoice == "devlist" then textutils.pagedPrint(textutils.serialize(deviceList)) end
	if menuChoice == "colortest" then colortest() end
	if menuChoice == "loaddefault" then loadDefaultDevices() end
	if menuChoice == "save" then saveDevices() end

	end
end

function colortest( ... )
	local colorIn = read()
	local colorINT = colorFuncs.toColor(colorIn)
	print (colorINT)
end
function jsonTest( ... )
		prettystring = jsonV2.encodePretty(deviceList)
		textutils.pagedPrint(prettystring)
		local fileHandle = fs.open("/jsontest","w")
		fileHandle.write(prettystring)
		fileHandle.close()
		print("Table Size: " .. table.getn(deviceList))
end
function debugEvent()
	print("To escape, press tilde twice")
	while true do 
		print(os.pullEvent())
		event,key = os.pullEvent()
		if key == 41 then 
			debugMenu() -- Returns to main program
			break
		end
	end 
end

-----------------------------------------------------------------------------------------------------------------------
-- Switch Class
local Switch = {}  -- the table representing the class, which will double as the metatable for the instances
Switch.__index = Switch -- failed table lookups on the instances should fallback to the class table, to get methods

function Switch.new(labelIn,redNetSwitchColorIn,confirmFlagIn, defaultStateIn)
	local self = setmetatable({},Switch) -- Lets class self refrence to create new objects based on the class
	
	self.type = "switch"
	self.label = labelIn
	self.defaultState = defaultStateIn or "off"

	-- All nil values will get filled in by other functions
	self.terminalSwitchOn = nil
	self.terminalSwitchOff = nil

	self.statusFlag = false -- Default State
	self.lineNumber = nil
	self.redNetSwitchColor = redNetSwitchColorIn
	self.confirmFlag = confirmFlagIn or false -- Default if not specificed
	return self
end

-- Getters
-- we don't need getters, you can just access values directly, I DO WHAT I WANT! (object.privateVariable)

-- Methods
function Switch.monitorStatus( self,lineNumberIn )
	monitor.setCursorPos(1, lineNumberIn)
	monitor.write(self.label)

	if self.statusFlag == false then self.status = "OFFLINE"	monitor.setTextColor(offColor) end
	if self.statusFlag == true then	self.status = "ONLINE"	monitor.setTextColor(onColor) end

	monitor.setCursorPos(statusIndent, lineNumberIn)
	monitor.write(self.status)
	monitor.setTextColor(monitorDefaultColor)
end

function Switch.terminalWrite( self, lineNumberIn )
	term.setCursorPos(1,lineNumberIn+terminalHeaderOffset)
	term.write(self.terminalSwitchOn.."/"..self.terminalSwitchOff)
	term.setCursorPos(terminalIndent1,lineNumberIn+terminalHeaderOffset)
	term.write(" -   ")

	if self.statusFlag == false then term.setTextColor(offColor) end
	if self.statusFlag == true then	term.setTextColor(onColor) end
	term.write(self.label)
	term.setTextColor(terminalDefaultColor)

	term.setCursorPos(terminalIndent2+8,lineNumberIn+terminalHeaderOffset)  -- Extra indent to save space

	term.setTextColor(terminalDefaultColor)		term.write("(")	
	term.setTextColor(self.redNetSwitchColor)	term.write("On")
	term.setTextColor(terminalDefaultColor)		term.write("/Off)")
end

function Switch.on( self )
	if self.confirmFlag == true then 
		local confirmInput = confirmOnMenu(self.label) -- Calls menu, returns flag

		if confirmInput == true then
			if self.statusFlag == false then -- Off State
				redstone.setBundledOutput(rednetSide, redstone.getBundledOutput(rednetSide)+self.redNetSwitchColor)
				self.statusFlag = true
			end
		end
	end

	if self.confirmFlag == false then
		if self.statusFlag == false then -- Off State
			redstone.setBundledOutput(rednetSide, redstone.getBundledOutput(rednetSide)+self.redNetSwitchColor)
			self.statusFlag = true
		end
	end
end

function Switch.off( self )
	if self.statusFlag == true then -- On State
		redstone.setBundledOutput(rednetSide, redstone.getBundledOutput(rednetSide)-self.redNetSwitchColor)
		self.statusFlag = false
	end
end

-----------------------------------------------------------------------------------------------------------------------
-- Tank Class
local Tank = {}
Tank.__index = Tank -- failed table lookups on the instances should fallback to the class table, to get methods

-- Tank Constructor
function Tank.new(labelIn, redNetFillColorIn,redNetDumpColorIn,defaultStateIn) -- Constructor, but is technically one HUGE function
	local self = setmetatable({},Tank) -- Lets class self refrence to create new objects based on the class

	-- Instance Variables
	self.type = "tank"
	self.label = labelIn
	self.defaultState = defaultStateIn or "off"

	-- All nil values will get filled in by other functions
	self.terminalFill = nil
	self.terminalDump = nil
	self.terminalOff = nil

	self.fillFlag = false -- Default state
	self.dumpFlag = false -- Default state

	self.lineNumber = nil
	self.redNetFillColor = redNetFillColorIn
	self.redNetDumpColor = redNetDumpColorIn
	return self
end

function Tank.monitorStatus( self,lineNumberIn )
	monitor.setCursorPos(1, lineNumberIn)
	monitor.write(self.label)

	if self.fillFlag == false and self.dumpFlag == false then	self.status = "OFFLINE"	monitor.setTextColor(offColor) end
	if self.fillFlag == true and self.dumpFlag == false then	self.status = "FILLING"	monitor.setTextColor(fillColor) end
	if self.fillFlag == false and self.dumpFlag == true then	self.status = "EMPTYING"	monitor.setTextColor(dumpColor) end

	monitor.setCursorPos(statusIndent,lineNumberIn)
	monitor.write(self.status)
	monitor.setTextColor(monitorDefaultColor)
end

function Tank.terminalWrite( self,lineNumberIn )
	term.setCursorPos(1,lineNumberIn+terminalHeaderOffset)
	term.write(self.terminalFill.."/"..self.terminalDump.."/"..self.terminalOff)
	term.setCursorPos(terminalIndent1,lineNumberIn+terminalHeaderOffset)
	term.write(" -   ")

	if self.fillFlag == false and self.dumpFlag == false then term.setTextColor(offColor) end
	if self.fillFlag == true and self.dumpFlag == false then term.setTextColor(fillColor) end
	if self.fillFlag == false and self.dumpFlag == true then term.setTextColor(dumpColor) end
	term.write(self.label)
	
	term.setCursorPos(terminalIndent2,lineNumberIn+terminalHeaderOffset)

	term.setTextColor(terminalDefaultColor)	term.write("(")	
	term.setTextColor(self.redNetFillColor)	term.write("Fill")
	term.setTextColor(terminalDefaultColor)	term.write("/")
	term.setTextColor(self.redNetDumpColor)	term.write("Empty")
	term.setTextColor(terminalDefaultColor)	term.write("/Off)")
end

function Tank.fill( self )
	if self.fillFlag == false and self.dumpFlag == false then -- Off State
	redstone.setBundledOutput(rednetSide, redstone.getBundledOutput(rednetSide)+self.redNetFillColor)
	self.fillFlag = true
	self.dumpFlag = false
	end

	if self.fillFlag == false and self.dumpFlag == true then -- Dump State
	redstone.setBundledOutput(rednetSide, redstone.getBundledOutput(rednetSide)+self.redNetFillColor)
	redstone.setBundledOutput(rednetSide, redstone.getBundledOutput(rednetSide)-self.redNetDumpColor)
	self.fillFlag = true
	self.dumpFlag = false
	end
end

function Tank.dump( self )
	if self.fillFlag == false and self.dumpFlag == false then -- Off State
	redstone.setBundledOutput(rednetSide, redstone.getBundledOutput(rednetSide)+self.redNetDumpColor)
	self.fillFlag = false
	self.dumpFlag = true
	end

	if self.fillFlag == true and self.dumpFlag == false then -- Fill State
	redstone.setBundledOutput(rednetSide, redstone.getBundledOutput(rednetSide)-self.redNetFillColor)
	redstone.setBundledOutput(rednetSide, redstone.getBundledOutput(rednetSide)+self.redNetDumpColor)
	self.fillFlag = false
	self.dumpFlag = true
	end
end

function Tank.off( self )
	if self.fillFlag == true then -- Fill State
	redstone.setBundledOutput(rednetSide, redstone.getBundledOutput(rednetSide)-self.redNetFillColor)
	self.fillFlag = false
	end

	if self.dumpFlag == true then -- Dump State
	redstone.setBundledOutput(rednetSide, redstone.getBundledOutput(rednetSide)-self.redNetDumpColor)
	self.dumpFlag = false
	end
end

-----------------------------------------------------------------------------------------------------------------------
-- Main Program Logic

function run(	)
	bootLoader() -- Not just for show, give redNet time to reset
	mainProgram()

end

function mainProgram( ... )
	while true do
		if debugMenuFlag then  debugMenu() break end -- Kicks in from menuInput command
		-- Lets us break out of the main program to do other things
		if editDevicesMenuFlag then editDevicesMenu() break end -- Kicks in from menuInput command

		if monitorPresentFlag then  monitorRedraw() end -- PASSIVE OUTPUT
		termRedraw() -- PASSIVE OUTPUT

		-- parallel.waitForAny(menuInput, clickMonitor,clickTerminal,netCommands) -- Getting  unable to create new native thread
		parallel.waitForAny(menuInput, clickMonitor,clickTerminal) -- ACTIVE INPUT Working fine
	end
end

function bootLoader( ... )
	term.clear()
	term.setTextColor(bootLoaderColor)

	term.setCursorPos(1,1)
	term.write("SYSTEM BOOTING")
	term.setCursorPos(1,19)
	term.setTextColor(progressBarColor)
	term.write(".")
	term.setTextColor(bootLoaderColor)
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
	
	if monitorPresentFlag then
		term.write(" - Located Monitor: ".. monitorSide)
		monitor = peripheral.wrap(monitorSide) -- Monitor wrapper, default location, for easy access
		monitor.setTextScale(1) -- Sets Text Size (.5 for 1x2 1 for 2x4 2.5 for 5x7 (MAX))
		monitor.setCursorPos(5, 5)
		monitor.clear()
		monitor.write("SYSTEM BOOT IN PROGRESS")
	end
	if monitorPresentFlag == false then term.write(" - NO MONITOR FOUND") end

	term.setCursorPos(1,19)
	term.setTextColor(progressBarColor)
	term.write("..........")
	term.setTextColor(bootLoaderColor)
	os.sleep(.5)

	---------------------------------------------------------------------------------------------------------
	-- Setup Network
	term.setCursorPos(1,3)
	term.write("Initalizing network")

	if peripheral.isPresent("top") and peripheral.getType("top") == "modem" then modemSide = "top" modemPresentFlag = true end
	if peripheral.isPresent("bottom") and peripheral.getType("bottom") == "modem" then modemSide = "bottom" modemPresentFlag = true end
	if peripheral.isPresent("left") and peripheral.getType("left") == "modem" then modemSide = "left" modemPresentFlag = true end
	if peripheral.isPresent("right") and peripheral.getType("right") == "modem" then modemSide = "right" modemPresentFlag = true end
	
	if modemPresentFlag then term.write(" - Located Modem: ".. modemSide)  rednet.open(modemSide) end
	if modemPresentFlag == false then term.write(" - NO MODEM FOUND") end

	term.setCursorPos(1,19)
	term.setTextColor(progressBarColor)
	term.write("....................")
	term.setTextColor(bootLoaderColor)
	redstone.setBundledOutput(rednetSide,0) -- Resets Rednet Network
	os.sleep(.25)

	---------------------------------------------------------------------------------------------------------
	-- Create objects
	term.setCursorPos(1,4)
	term.write("Initalizing devices")
	term.setCursorPos(1,19)
	term.setTextColor(progressBarColor)
	term.write("..............................")
	term.setTextColor(bootLoaderColor)
	setUpDevices() -- Sets up objects
	os.sleep(.25)

	---------------------------------------------------------------------------------------------------------
	-- Startup physical system
	term.setCursorPos(1,5)
	term.write("Initalizing startup state")
	term.setCursorPos(1,19)
	term.setTextColor(progressBarColor)
	term.write("........................................")
	term.setTextColor(bootLoaderColor)
	setStartupState() -- Sets startup state
	os.sleep(.25)

	---------------------------------------------------------------------------------------------------------
	-- Wait a-bit
	term.setCursorPos(1,6)
	term.write("Please wait")
	os.sleep(1)
	term.setCursorPos(1,19)
	term.setTextColor(progressBarColor)
	term.write("..................................................")
	term.setTextColor(bootLoaderColor)
	os.sleep(.25)

	term.setTextColor(terminalDefaultColor)
end

-----------------------------------------------------------------------------------------------------------------------
-- Termainl & Monitor Output
function writeMenuHeader( ... )
	term.setTextColor(terminalDefaultColor)
	term.clear()
	term.setCursorPos(13,1)
	term.write("Device Control System v10")
	term.setCursorPos(46,19)

	term.write("(")

	if rednetSide == "top" then  
		term.setTextColor(rednetIndicatorColor) 
		term.write("T") 
		term.setTextColor(terminalDefaultColor) 
		term.write("BLR") 
	end

	if rednetSide == "bottom" then  
		term.setTextColor(terminalDefaultColor) 
		term.write("T") 
		term.setTextColor(rednetIndicatorColor) 
		term.write("B")
		term.setTextColor(terminalDefaultColor) 
		term.write("LR")
	end

	if rednetSide == "left" then  
		term.setTextColor(terminalDefaultColor) 
		term.write("TB") 
		term.setTextColor(rednetIndicatorColor) 
		term.write("L")
		term.setTextColor(terminalDefaultColor) 
		term.write("R")
	end

	if rednetSide == "right" then  
		term.setTextColor(terminalDefaultColor) 
		term.write("TBL") 
		term.setTextColor(rednetIndicatorColor) 
		term.write("R")
	end

	term.setTextColor(terminalDefaultColor) -- Change text back to normal, just to be safe
	term.write(")")

end

function writeMonitorHeader( ... )
	monitor.clear()
	monitor.setCursorPos(1, 1)
	monitor.write("        Device Status")
end

function confirmOnMenu( labelIn )
	local confirmOnFlagOut = false
	
	term.clear()
	term.setTextColor(colors.yellow)
	term.setCursorPos(10,8)	term.write("Are you sure you want to activate: ")
	term.setTextColor(colors.magenta)
	term.setCursorPos(20,10)	term.write(labelIn)

	term.setTextColor(colors.red)
	term.setCursorPos(1,19)	term.write("Please type yes to confirm: ")
	local inputOption = read()
	if inputOption == "yes" then confirmOnFlagOut = true end

	term.setTextColor(terminalDefaultColor) -- Change text back to normal

	return confirmOnFlagOut
end

function monitorRedraw( ... ) -- Status Monitor Display
	writeMonitorHeader()

	for i=1,table.getn(deviceList) do -- Gets arraylist size
		deviceList[i]:monitorStatus(i+1)
	end

end

function termRedraw( ... ) -- Terminal Display
	writeMenuHeader()

	for i=1,table.getn(deviceList) do -- Gets arraylist size
		deviceList[i]:terminalWrite(i+1)
	end

	term.setCursorPos(1,19)
	term.write("Select # (On/oFf/Craft/Edit): ")
end

function updateTerminalDeviceMenuNumbers( ... )
	local terminalMenuChoice = 1

	for i=1,table.getn(deviceList) do -- Gets arraylist size
		local devIn = deviceList[i] -- Loads device list to object

		if devIn.type == "switch" then 
			devIn.terminalSwitchOn = tostring(terminalMenuChoice)
			devIn.terminalSwitchOff = tostring(terminalMenuChoice + 1)
			terminalMenuChoice = terminalMenuChoice + 2
		end

		if devIn.type == "tank" then 
			devIn.terminalFill = tostring(terminalMenuChoice)
			devIn.terminalDump = tostring(terminalMenuChoice + 1)
			devIn.terminalOff = tostring(terminalMenuChoice + 2)
			terminalMenuChoice = terminalMenuChoice + 3
		end
	end
end

-----------------------------------------------------------------------------------------------------------------------
-- User Input

function menuInput( ... )
	local inputOption = read()
	menuOption(inputOption) -- Normal Options
	menuOptionCustom(inputOption) -- Custom Options at bottom
end

function clickMonitor()
  event, side, xPos, yPos = os.pullEvent("monitor_touch")
	for i=1,table.getn(deviceList) do -- Gets arraylist size
		local devIn = deviceList[i] -- Loads device list to object
		
		if yPos == i +1 then -- 1 to offset header
			if devIn.type == "switch" then
				if devIn.statusFlag == false and devIn.confirmFlag == false then devIn:on() break end
				if devIn.statusFlag == true then devIn:off() break end
			end

			if devIn.type == "tank" then 
				if devIn.fillFlag == false and devIn.dumpFlag == false then devIn:fill() break end -- Off -> Fill
				if devIn.fillFlag == true and devIn.dumpFlag == false then devIn:dump() break end -- Fill -> Dump
				if devIn.fillFlag == false and devIn.dumpFlag == true then devIn:off() break end -- Dump -> Off
			end
		end
	end
end

function clickTerminal()
event, side, xPos, yPos = os.pullEvent("mouse_click")

	for i=1,table.getn(deviceList) do -- Gets arraylist size
		local devIn = deviceList[i] -- Loads device list to object
		
		if yPos == i + 1 then -- 1 to offset header
			if devIn.type == "switch" then
				if devIn.statusFlag == false and devIn.confirmFlag == false then devIn:on() break end
				if devIn.statusFlag == true then devIn:off() break end
			end

			if devIn.type == "tank" then 
				if devIn.fillFlag == false and devIn.dumpFlag == false then devIn:fill() break end -- Off -> Fill
				if devIn.fillFlag == true and devIn.dumpFlag == false then devIn:dump() break end -- Fill -> Dump
				if devIn.fillFlag == false and devIn.dumpFlag == true then devIn:off() break end -- Dump -> Off
			end
		end
	end
end

function menuOption( menuChoice ) -- Menu Options for Terminal

	if menuChoice == "debug" then debugMenuFlag = true end -- Sets flag to true so we break out of main program
	if menuChoice == "edit" or menuChoice == "e" then editDevicesMenuFlag = true end -- Exits to edit menu

	if menuChoice == "on" or menuChoice == "o" then activateAll() end
	if menuChoice == "off" or menuChoice == "f" then shutdownAll() end

	if menuChoice == "L" then rednetSide = "left" end
	if menuChoice == "R" then rednetSide = "right" end
	if menuChoice == "T" then rednetSide = "top" end
	if menuChoice == "B" then rednetSide = "bottom" end

	for i=1,table.getn(deviceList) do -- Gets arraylist size
		local devIn = deviceList[i] -- Loads device list to object

		if devIn.type == "switch" then 
			if menuChoice == devIn.terminalSwitchOn then devIn:on() end
			if menuChoice == devIn.terminalSwitchOff then devIn:off() end
		end

		if devIn.type == "tank" then 
			if menuChoice == devIn.terminalFill then devIn:fill() end
			if menuChoice == devIn.terminalDump then devIn:dump() end
			if menuChoice == devIn.terminalOff then devIn:off() end
		end
	end
end

-----------------------------------------------------------------------------------------------------------------------
-- Device Actions
function setUpDevices( ... )
	deviceList = {} -- Master device list, stores all the devices, starts off empty.

	if fs.exists (devicesFilePath) then 
		loadDevicesFromFile()
	else
		loadDefaultDevices()
	end

	updateTerminalDeviceMenuNumbers() -- Adds in terminal numbers to make menu work
	saveDevices()
end

function loadDevicesFromFile( ... )
	local fileHandle = fs.open(devicesFilePath,"r")
	local RAWjson = fileHandle.readAll()
	fileHandle.close()

	local deviceListImport = jsonV2.decode(RAWjson)

	for i=1,table.getn(deviceListImport) do -- Gets arraylist size
		local devIn = deviceListImport[i]
		if devIn.type == "switch"  then 
			table.insert(deviceList, Switch.new(
				devIn.label,devIn.redNetSwitchColor,devIn.confirmFlag,devIn.defaultState))
		end

		if devIn.type == "tank"  then 
			table.insert(deviceList, Tank.new(
				devIn.label,devIn.redNetFillColor,devIn.redNetDumpColor,devIn.defaultState))
		end
	end	
end

function setStartupState()
	for i=1,table.getn(deviceList) do -- Gets arraylist size
		local devIn = deviceList[i]
		if devIn.defaultState == "dump" then devIn:dump() end
		if devIn.defaultState == "fill" then devIn:fill() end
		if devIn.defaultState == "on" and devIn.confirmFlag == false then devIn:on() end
	end	
end

function activateAll()
	for i=1,table.getn(deviceList) do
		local devIn = deviceList[i] -- Sets device from arrayList to local object
		if devIn.type == "switch" and devIn.confirmFlag == false then devIn:on() end
		if devIn.type == "tank" then devIn:dump() end
	end
end

function shutdownAll()
	for i=1,table.getn(deviceList) do
		deviceList[i]:off()
	end
end

-----------------------------------------------------------------------------------------------------------------------
-- Network Actions

function netSendMessage( idIn,message )
	if modemPresentFlag == true then
		local id = tonumber (idIn)
		rednet.send(id,message)
	end
end

function netBroadcast(message )
	if modemPresentFlag == true then
		rednet.broadcast(message)
	end
end

function netGetMessage(listenID, timeoutIN)
	if modemPresentFlag == true then
		local waitFlag = true
		while waitFlag do
			local senderId, message, distance = rednet.receive(timeoutIN)
			if os.getComputerID() ~= senderId then -- Reject Loopback
				if listenID == senderId then
				waitFlag = false
				return message
				end
			end
		end
	end
end

function netGetMessageAny(timeoutIN)
	if modemPresentFlag == true then
		local waitFlag = true
		while waitFlag do
			local senderId, message, distance = rednet.receive(timeoutIN)
			if os.getComputerID() ~= senderId then -- Reject Loopback
				return message
			end
		end
	end
end

-----------------------------------------------------------------------------------------------------------------------
-- Device Menu
function listColors( ... )
print("Color codes: white - orange - magenta - lightBlue - yellow - lime - pink - gray - lightGray - cyan - purple - blue - brown - green - red - black")
end

function addDevice( ... )
	print("Enter device name to be added: ")
	local deviceLabel = read()
	print("Enter device type to be added (Tank/[Switch]): ")
	local deviceType = read()

	if deviceType == "tank" or deviceType == "t" then 
		listColors()
		print("Enter redNet FILL color code: ")
		local colorCodeFill = colorFuncs.toColor(read())
		print("Enter redNet DUMP color code: ")
		local colorCodeDump = colorFuncs.toColor(read())
		print("Enter startup state (fill/dump/[off]): ")
		local startupState = parseStartupState(read())

		if colorCodeFill == nil or colorCodeDump == nil or deviceLabel == "" then term.clear() print("INVALID SETTINGS") os.sleep(2) else
		table.insert(deviceList, Tank.new(deviceLabel,colorCodeFill,colorCodeDump,startupState)) end

	else
		-- Default to switch creation
		listColors()

		print("Enter redNet color code: ")
		local colorCodeOn = colorFuncs.toColor(read())
		print("Enter confirm flag (true/[false]): ")
		local confirmFlag = parseTrueFalse(read())
		print("Enter startup state (on/[off]): ")
		local startupState = parseStartupState(read())

		if colorCodeOn == nil or startupState == "fill" or startupState == "dump" or deviceLabel == "" then 
			term.clear() print("INVALID SETTINGS") os.sleep(2) 
		else
			if confirmFlag == true and startupState == "off" then 
				table.insert(deviceList, Switch.new(deviceLabel,colorCodeOn,confirmFlag,startupState)) end

			if confirmFlag == false then -- No confirm flag = startup state doesn't matter, it's all good man.
				table.insert(deviceList, Switch.new(deviceLabel,colorCodeOn,confirmFlag,startupState)) 
			else
				term.clear() print("INVALID SETTINGS") os.sleep(2)
			end
		end
	end

end

function editDevice( ... )
	print("Enter device to edit: ")
	local editDevice = read()

	print("Enter new label: ")
	local newLabel = read()

	for i=1,table.getn(deviceList) do -- Gets arraylist size
		if deviceList[i].label == editDevice then
			if newLabel ~= "" then deviceList[i].label = newLabel end

			if deviceList[i].type == "switch" then 
				listColors()
				
				print("Enter new redNet color code ["..colorFuncs.toString(deviceList[i].redNetSwitchColor).."] : ")
				local colorIn = read()
				local colorCodeOn = colorFuncs.toColor(colorIn)

				print("Enter confirm flag (true/[false]) ["..tostring(deviceList[i].confirmFlag).."]: ")
				local confirmIn = read()
				local confirmFlagIn = parseTrueFalse(confirmIn)

				print("Enter startup state (on/[off]) ["..deviceList[i].defaultState.."]: ")
				local startupIn = read()
				local startupState = parseStartupState(startupIn)
			
				-- Try and edit a switch
				if startupState == "fill" or startupState == "dump" then term.clear() print("INVALID SETTINGS") os.sleep(2)	break end

				if startupIn ~= "" then -- Ignore blank input
					if confirmFlagIn == false then deviceList[i].defaultState = startupState end -- No confirm = AOK
					if confirmFlagIn == true and startupState == "off" then deviceList[i].defaultState = startupState end -- Confim flag + Start off = AOK
					-- else do nothing
				end

				if confirmIn ~= "" then 
					if confirmFlagIn == false then deviceList[i].confirmFlag = confirmFlagIn end
					if confirmFlagIn == true and startupState == "off" then deviceList[i].confirmFlag = confirmFlagIn end
				end

				if colorIn ~= "" and colorCodeOn ~= nil then deviceList[i].redNetSwitchColor = colorCodeOn 	end 
				-- Non blank AND correct color = set color, a incorrect color returns NOTHING, which blocks setter

			break
			end

			if deviceList[i].type == "tank" then 
				listColors()

				print("Enter new redNet FILL color code ["..colorFuncs.toString(deviceList[i].redNetFillColor).."] : ")
				local colorFillIn = read()
				local colorCodeFill = colorFuncs.toColor(colorFillIn)

				print("Enter new redNet FILL color code ["..colorFuncs.toString(deviceList[i].redNetDumpColor).."] : ")
				local colorDumpIn = read()
				local colorCodeDump = colorFuncs.toColor(colorDumpIn)

				print("Enter startup state (fill/dump/[off]) ["..deviceList[i].defaultState.."]: ")
				local startupIn = read()
				local startupState = parseStartupState(startupIn)

				-- Entering nothing or invalid options will prevent changes from being made
				if startupState == "on" then term.clear() print("INVALID SETTINGS") os.sleep(2) break end
				
				if startupIn ~= "" then deviceList[i].defaultState = startupState end -- Parser default covers our ass from the user
				if colorFillIn ~= "" and colorCodeFill ~= nil then deviceList[i].redNetFillColor = colorCodeFill end
				if colorDumpIn ~= "" and colorCodeDump ~= nil then deviceList[i].redNetDumpColor = colorCodeDump end
				-- Non blank AND correct color = set color, a incorrect color returns NOTHING, which blocks setter
				

			break
			end
			
		end
	end
end

function removeDevice( ... )
	print("Enter device to be removed: ")
	local removeDevice = read()

	for i=1,table.getn(deviceList) do -- Gets arraylist size
		if deviceList[i].label == removeDevice then 
			table.remove(deviceList, i)
			print("Removed "..removeDevice)
			break
		end
	end
end

function listDevices( ... ) -- Need two print commands due to formating
	term.clear()
	print("Device List")
	for i=1,table.getn(deviceList) do 
		if deviceList[i].type == "tank" then print("Type: "..deviceList[i].type.."     Label: "..deviceList[i].label) end
		if deviceList[i].type == "switch" then print("Type: "..deviceList[i].type.."   Label: "..deviceList[i].label) end
	end
end

function editDevicesMenu( ... )
	term.clear()

	while true do 
		listDevices()
		term.setCursorPos(1,19)	term.write("(Add / Edit / Remove / Clear / eXit): ")
		local menuChoice = read()
		
		if menuChoice == "add" or menuChoice == "a" then addDevice() end
		if menuChoice == "edit" or menuChoice == "e" then editDevice() end
		if menuChoice == "remove" or menuChoice == "r" then removeDevice() end
		if menuChoice == "clear" or menuChoice == "c" then clearList() end
		if menuChoice == "exit" or menuChoice == "x" then break end
	end 

	updateTerminalDeviceMenuNumbers() -- Updates terminal numbers to reflect changes
	saveDevices()
	editDevicesMenuFlag = false
	mainProgram()
end

function saveDevices( ... )
	local prettystring = jsonV2.encodePretty(deviceList)
	local fileHandle = fs.open(devicesFilePath,"w")
	fileHandle.write(prettystring)
	fileHandle.close()
end

function clearList( ... )
	print("Are you sure you want to ERASE ALL DEVICES? (yes/no)")
	local menuChoice = read()
	if menuChoice == "yes" then deviceList={} end
end

function loadDefaultDevices( ... )
	-- Defaults for factory
	table.insert(deviceList, Tank.new("Roof Tank",colors.white,colors.orange,"dump"))
	table.insert(deviceList, Tank.new("Backup Tank",colors.lime,colors.pink,"fill"))
	table.insert(deviceList, Switch.new("Basement Gens",colors.lightBlue))
	table.insert(deviceList, Switch.new("Smeltery",colors.magenta))
	table.insert(deviceList, Switch.new("1st Flr Gens + Lava",colors.purple))
	table.insert(deviceList, Switch.new("2nd Flr Gens + AE",colors.gray))
	table.insert(deviceList, Switch.new("Quarry Gens",colors.cyan))
	table.insert(deviceList, Switch.new("Net Bridge + Gens",colors.lightGray))
	table.insert(deviceList, Switch.new("Player Lava",colors.yellow))
	table.insert(deviceList, Switch.new("Purge Valve",colors.black,true))
	table.insert(deviceList, Switch.new("Recyclers",colors.blue))
end

-----------------------------------------------------------------------------------------------------------------------
-- **DONT EDIT ANYTHING ABOVE HERE**

function netCommands( ... )
	-- command = getMessage(3) -- Computer ID to listen from
	command = netGetMessageAny()
	-- if command == "hi" then deviceList[4]:on() end
end

function menuOptionCustom( menuChoice ) -- Custom Options for Terminal
	if menuChoice == "craft" or menuChoice == "c" then craft() end

end

function craft(  )
	shutdownAll()
	for i=1,table.getn(deviceList) do -- Gets arraylist size
		if deviceList[i].label == "Roof Tank" then deviceList[i]:dump() end
		if deviceList[i].label == "Backup Tank" then deviceList[i]:fill() end
		if deviceList[i].label == "2nd Flr Gens + AE" then deviceList[i]:on() end
	end	
end

run() --Runs main program