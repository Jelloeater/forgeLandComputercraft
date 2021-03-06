-- RedNet Cable Control System v10
-- Author: Jesse

os.loadAPI("/bb/api/jsonV2")
os.loadAPI("/bb/api/colorFuncs")

debugmode = false
editDevicesMenuFlag = false
editSettingsMenuFlag = false
devicesFilePath = "/devices.cfg"
settingsFilePath = "/settings.cfg"

-----------------------------------------------------------------------------------------------------------------------
-- Settings Class
settings = {}  -- the table representing the class, holds all the data, we don't need a singleton because THIS IS LUA.

settings.rednetSide = "bottom" -- Where is the redNet cable

settings.monitorDefaultColor = colors.white
settings.terminalDefaultColor = colors.white
settings.progressBarColor = colors.yellow
settings.bootLoaderColor = colors.green
settings.rednetIndicatorColor = colors.blue

settings.fillColor = colors.yellow
settings.dumpColor = colors.green
settings.onColor = colors.green
settings.offColor = colors.red

settings.statusIndent = 22 -- Indent for Status (28 for 1x2 22 for 2x4 and bigger)
settings.terminalIndent1 = 7 -- Determines dash location
settings.terminalIndent2 = 36 -- Determines (On/Off ... etc location)
settings.terminalHeaderOffset = 0
settings.monitorHeader = "Device Control"
settings.terminalHeader = "Device Control"


function listSettings( ... ) -- Need two print commands due to formating
	term.clear()
	print("Settings - I hope you know what you're doing -_-")
	print("")
	term.write("rednetSide = ") print(settings.rednetSide)
	term.write("monitorDefaultColor = ") print(settings.monitorDefaultColor)
	term.write("terminalDefaultColor = ") print(settings.terminalDefaultColor)
	term.write("progressBarColor = ") print(settings.progressBarColor)
	term.write("bootLoaderColor = ") print(settings.bootLoaderColor)
	term.write("rednetIndicatorColor = ") print(settings.rednetIndicatorColor)
	term.write("fillColor = ") print(settings.fillColor)
	term.write("dumpColor = ") print(settings.dumpColor)
	term.write("onColor = ") print(settings.onColor)
	term.write("offColor = ") print(settings.offColor)
	term.write("statusIndent = ") print(settings.statusIndent)
	term.write("terminalIndent1 = ") print(settings.terminalIndent1)
	term.write("terminalIndent2 = ") print(settings.terminalIndent2)
	term.write("terminalHeaderOffset = ") print(settings.terminalHeaderOffset)
	term.write("monitorHeader = ") print(settings.monitorHeader)
	term.write("terminalHeader = ") print(settings.terminalHeader)
end

function editSettingsMenu( ... )
	term.clear()

	while true do 
		listSettings()
		term.setCursorPos(1,19)	term.write("(setting name / eXit): ")
		local menuChoice = read()
		
		if menuChoice == "rednetSide" then settings.rednetSide = read() end
		if menuChoice == "monitorDefaultColor" then listColors() settings.monitorDefaultColor = colorFuncs.toColor(read()) end
		if menuChoice == "terminalDefaultColor" then listColors() settings.terminalDefaultColor = colorFuncs.toColor(read()) end
		if menuChoice == "progressBarColor" then listColors() settings.progressBarColor = colorFuncs.toColor(read()) end
		if menuChoice == "bootLoaderColor" then listColors() settings.bootLoaderColor = colorFuncs.toColor(read()) end
		if menuChoice == "rednetIndicatorColor" then listColors() settings.rednetIndicatorColor = colorFuncs.toColor(read()) end
		if menuChoice == "fillColor" then listColors() settings.fillColor = colorFuncs.toColor(read()) end
		if menuChoice == "dumpColor" then listColors() settings.dumpColor = colorFuncs.toColor(read()) end
		if menuChoice == "onColor" then listColors() settings.onColor = colorFuncs.toColor(read()) end
		if menuChoice == "offColor" then listColors() settings.offColor = colorFuncs.toColor(read()) end
		if menuChoice == "statusIndent" then settings.statusIndent = tonumber(read()) end
		if menuChoice == "terminalIndent1" then settings.terminalIndent1 = tonumber(read()) end
		if menuChoice == "terminalIndent2" then settings.terminalIndent2 = tonumber(read()) end
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
-- Parsers (we keep the user from breaking everything that is good...)

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
	print("R/N: "..redstone.getBundledOutput(settings.rednetSide).." - "..settings.rednetSide)
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
		prettystring = jsonV2.encodePretty(settings)
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

	if self.statusFlag == false then self.status = "OFFLINE"	monitor.setTextColor(settings.offColor) end
	if self.statusFlag == true then	self.status = "ONLINE"	monitor.setTextColor(settings.onColor) end

	monitor.setCursorPos(settings.statusIndent, lineNumberIn)
	monitor.write(self.status)
	monitor.setTextColor(settings.monitorDefaultColor)
end

function Switch.terminalWrite( self, lineNumberIn )
	term.setCursorPos(1,lineNumberIn+settings.terminalHeaderOffset)
	term.write(self.terminalSwitchOn.."/"..self.terminalSwitchOff)
	term.setCursorPos(settings.terminalIndent1,lineNumberIn+settings.terminalHeaderOffset)
	term.write(" -   ")

	if self.statusFlag == false then term.setTextColor(settings.offColor) end
	if self.statusFlag == true then	term.setTextColor(settings.onColor) end
	term.write(self.label)
	term.setTextColor(settings.terminalDefaultColor)

	term.setCursorPos(settings.terminalIndent2+8,lineNumberIn+settings.terminalHeaderOffset)  -- Extra indent to save space

	term.setTextColor(settings.terminalDefaultColor)		term.write("(")	
	term.setTextColor(self.redNetSwitchColor)	term.write("On")
	term.setTextColor(settings.terminalDefaultColor)		term.write("/Off)")
end

function Switch.on( self )
	if self.confirmFlag == true then 
		local confirmInput = confirmOnMenu(self.label) -- Calls menu, returns flag

		if confirmInput == true then
			if self.statusFlag == false then -- Off State
				redstone.setBundledOutput(settings.rednetSide, redstone.getBundledOutput(settings.rednetSide)+self.redNetSwitchColor)
				self.statusFlag = true
			end
		end
	end

	if self.confirmFlag == false then
		if self.statusFlag == false then -- Off State
			redstone.setBundledOutput(settings.rednetSide, redstone.getBundledOutput(settings.rednetSide)+self.redNetSwitchColor)
			self.statusFlag = true
		end
	end
end

function Switch.off( self )
	if self.statusFlag == true then -- On State
		redstone.setBundledOutput(settings.rednetSide, redstone.getBundledOutput(settings.rednetSide)-self.redNetSwitchColor)
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

	if self.fillFlag == false and self.dumpFlag == false then	self.status = "OFFLINE"	monitor.setTextColor(settings.offColor) end
	if self.fillFlag == true and self.dumpFlag == false then	self.status = "FILLING"	monitor.setTextColor(settings.fillColor) end
	if self.fillFlag == false and self.dumpFlag == true then	self.status = "EMPTYING"	monitor.setTextColor(settings.dumpColor) end

	monitor.setCursorPos(settings.statusIndent,lineNumberIn)
	monitor.write(self.status)
	monitor.setTextColor(settings.monitorDefaultColor)
end

function Tank.terminalWrite( self,lineNumberIn )
	term.setCursorPos(1,lineNumberIn+settings.terminalHeaderOffset)
	term.write(self.terminalFill.."/"..self.terminalDump.."/"..self.terminalOff)
	term.setCursorPos(settings.terminalIndent1,lineNumberIn+settings.terminalHeaderOffset)
	term.write(" -   ")

	if self.fillFlag == false and self.dumpFlag == false then term.setTextColor(settings.offColor) end
	if self.fillFlag == true and self.dumpFlag == false then term.setTextColor(settings.fillColor) end
	if self.fillFlag == false and self.dumpFlag == true then term.setTextColor(settings.dumpColor) end
	term.write(self.label)
	
	term.setCursorPos(settings.terminalIndent2,lineNumberIn+settings.terminalHeaderOffset)

	term.setTextColor(settings.terminalDefaultColor)	term.write("(")	
	term.setTextColor(self.redNetFillColor)	term.write("Fill")
	term.setTextColor(settings.terminalDefaultColor)	term.write("/")
	term.setTextColor(self.redNetDumpColor)	term.write("Empty")
	term.setTextColor(settings.terminalDefaultColor)	term.write("/Off)")
end

function Tank.fill( self )
	if self.fillFlag == false and self.dumpFlag == false then -- Off State
	redstone.setBundledOutput(settings.rednetSide, redstone.getBundledOutput(settings.rednetSide)+self.redNetFillColor)
	self.fillFlag = true
	self.dumpFlag = false
	end

	if self.fillFlag == false and self.dumpFlag == true then -- Dump State
	redstone.setBundledOutput(settings.rednetSide, redstone.getBundledOutput(settings.rednetSide)+self.redNetFillColor)
	redstone.setBundledOutput(settings.rednetSide, redstone.getBundledOutput(settings.rednetSide)-self.redNetDumpColor)
	self.fillFlag = true
	self.dumpFlag = false
	end
end

function Tank.dump( self )
	if self.fillFlag == false and self.dumpFlag == false then -- Off State
	redstone.setBundledOutput(settings.rednetSide, redstone.getBundledOutput(settings.rednetSide)+self.redNetDumpColor)
	self.fillFlag = false
	self.dumpFlag = true
	end

	if self.fillFlag == true and self.dumpFlag == false then -- Fill State
	redstone.setBundledOutput(settings.rednetSide, redstone.getBundledOutput(settings.rednetSide)-self.redNetFillColor)
	redstone.setBundledOutput(settings.rednetSide, redstone.getBundledOutput(settings.rednetSide)+self.redNetDumpColor)
	self.fillFlag = false
	self.dumpFlag = true
	end
end

function Tank.off( self )
	if self.fillFlag == true then -- Fill State
	redstone.setBundledOutput(settings.rednetSide, redstone.getBundledOutput(settings.rednetSide)-self.redNetFillColor)
	self.fillFlag = false
	end

	if self.dumpFlag == true then -- Dump State
	redstone.setBundledOutput(settings.rednetSide, redstone.getBundledOutput(settings.rednetSide)-self.redNetDumpColor)
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
		if editSettingsMenuFlag then editSettingsMenu() break end -- Kicks in from menuInput command

		if monitorPresentFlag then  monitorRedraw() end -- PASSIVE OUTPUT
		termRedraw() -- PASSIVE OUTPUT

		-- parallel.waitForAny(menuInput, clickMonitor,clickTerminal,netCommands) -- Getting  unable to create new native thread
		parallel.waitForAny(menuInput, clickMonitor,clickTerminal) -- ACTIVE INPUT Working fine
	end
end

function bootLoader( ... )
	term.clear()
	if fs.exists (settingsFilePath) then loadSettings() end -- Loads settings
	term.setTextColor(settings.bootLoaderColor)

	term.setCursorPos(1,1)
	term.write("SYSTEM BOOTING - Loading Settings")
	term.setCursorPos(1,19)
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

	term.setCursorPos(1,19)
	term.setTextColor(settings.progressBarColor)
	term.write("..........")
	term.setTextColor(settings.bootLoaderColor)
	os.sleep(.5)

	---------------------------------------------------------------------------------------------------------
	-- Setup Network
	term.setCursorPos(1,3)
	term.write("Initalizing network")

	if peripheral.isPresent("top") and peripheral.getType("top") == "modem" then modemSide = "top" modemPresentFlag = true end
	if peripheral.isPresent("bottom") and peripheral.getType("bottom") == "modem" then modemSide = "bottom" modemPresentFlag = true end
	if peripheral.isPresent("left") and peripheral.getType("left") == "modem" then modemSide = "left" modemPresentFlag = true end
	if peripheral.isPresent("right") and peripheral.getType("right") == "modem" then modemSide = "right" modemPresentFlag = true end
	if peripheral.isPresent("back") and peripheral.getType("back") == "modem" then modemSide = "back" modemPresentFlag = true end
	
	if modemPresentFlag then term.write(" - Located Modem: ".. modemSide)  rednet.open(modemSide) end
	if modemPresentFlag == false then term.write(" - NO MODEM FOUND") end

	term.setCursorPos(1,19)
	term.setTextColor(settings.progressBarColor)
	term.write("....................")
	term.setTextColor(settings.bootLoaderColor)
	redstone.setBundledOutput(settings.rednetSide,0) -- Resets Rednet Network
	os.sleep(.25)

	---------------------------------------------------------------------------------------------------------
	-- Create objects
	term.setCursorPos(1,4)
	term.write("Initalizing devices")
	term.setCursorPos(1,19)
	term.setTextColor(settings.progressBarColor)
	term.write("..............................")
	term.setTextColor(settings.bootLoaderColor)
	setUpDevices() -- Sets up objects
	os.sleep(.25)

	---------------------------------------------------------------------------------------------------------
	-- Startup physical system
	term.setCursorPos(1,5)
	term.write("Initalizing startup state")
	term.setCursorPos(1,19)
	term.setTextColor(settings.progressBarColor)
	term.write("........................................")
	term.setTextColor(settings.bootLoaderColor)
	setStartupState() -- Sets startup state
	os.sleep(.25)

	---------------------------------------------------------------------------------------------------------
	-- Wait a-bit
	term.setCursorPos(1,6)
	term.write("Please wait")
	os.sleep(1)
	term.setCursorPos(1,19)
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
	local x, y = term.getSize()
	local terminalWidth = x
	local headerLength = string.len(settings.terminalHeader)

	term.setCursorPos(terminalWidth/2 - headerLength/2, 1)
	term.write(settings.terminalHeader)

	-- Writes Footer Indicator, yes it's in the header function, and no, I don't care.
	term.setCursorPos(46,19)

	term.write("(")

	if settings.rednetSide == "top" then  
		term.setTextColor(settings.rednetIndicatorColor) 
		term.write("T") 
		term.setTextColor(settings.terminalDefaultColor) 
		term.write("BLR") 
	end

	if settings.rednetSide == "bottom" then  
		term.setTextColor(settings.terminalDefaultColor) 
		term.write("T") 
		term.setTextColor(settings.rednetIndicatorColor) 
		term.write("B")
		term.setTextColor(settings.terminalDefaultColor) 
		term.write("LR")
	end

	if settings.rednetSide == "left" then  
		term.setTextColor(settings.terminalDefaultColor) 
		term.write("TB") 
		term.setTextColor(settings.rednetIndicatorColor) 
		term.write("L")
		term.setTextColor(settings.terminalDefaultColor) 
		term.write("R")
	end

	if settings.rednetSide == "right" then  
		term.setTextColor(settings.terminalDefaultColor) 
		term.write("TBL") 
		term.setTextColor(settings.rednetIndicatorColor) 
		term.write("R")
	end

	term.setTextColor(settings.terminalDefaultColor) -- Change text back to normal, just to be safe
	term.write(")")

end

function writeMonitorHeader( ... )
	monitor.clear()
	local x, y = monitor.getSize()
	local monitorWidth = x
	local headerLength = string.len(settings.monitorHeader)

	monitor.setCursorPos(monitorWidth/2 - headerLength/2, 1)
	monitor.write(settings.monitorHeader)
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

	term.setTextColor(settings.terminalDefaultColor) -- Change text back to normal

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
	term.write("Select # (On/oFf/Settings/Craft/Edit): ")
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

function clickTerminal()
event, side, xPos, yPos = os.pullEvent("mouse_click")

	for i=1,table.getn(deviceList) do -- Gets arraylist size
		local devIn = deviceList[i] -- Loads device list to object
		
		if yPos == i + 1 + settings.terminalHeaderOffset then -- 1 to offset header
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
	if menuChoice == "settings" or menuChoice == "s" then editSettingsMenuFlag = true end -- Exits to edit menu

	if menuChoice == "on" or menuChoice == "o" then activateAll() end
	if menuChoice == "off" or menuChoice == "f" then shutdownAll() end

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