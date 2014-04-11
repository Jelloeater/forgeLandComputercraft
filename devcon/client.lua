-- RedNet Server Control System v1
-- Author: Jesse

os.loadAPI("/bb/api/jsonV2")
os.loadAPI("/bb/api/colorFuncs")

debugmode = false
editDevicesMenuFlag = false
editSettingsMenuFlag = false
devicesFilePath = "/devconfig/devices.cfg"
settingsFilePath = "/devconfig/settings.cfg"
terminalWidth, terminalHeight = term.getSize()


-----------------------------------------------------------------------------------------------------------------------
-- Settings Class
settings = {}  -- the table representing the class, holds all the data, we don't need a singleton because THIS IS LUA.

settings.monitorDefaultColor = colors.white
settings.terminalDefaultColor = colors.white
settings.progressBarColor = colors.yellow
settings.bootLoaderColor = colors.green

settings.fillColor = colors.yellow
settings.dumpColor = colors.green
settings.onColor = colors.green
settings.offColor = colors.red
settings.missingColor = colors.gray

settings.statusIndent = 22 -- Indent for Status (28 for 1x2 22 for 2x4 and bigger)
settings.terminalIndent1 = 7 -- Determines dash location
settings.terminalIndent2 = 36 -- Determines (On/Off ... etc location)
settings.terminalHeaderOffset = 0
settings.monitorHeader = "Device Control"
settings.terminalHeader = "Device Control"
settings.networkProtocol = "deviceNet"
settings.networkTimeout = .25
settings.startDeviceOnBoot = false


function listSettings( ... ) -- Need two print commands due to formating
	term.clear()
	print("Settings - I hope you know what you're doing -_-")
	print("")
	term.write("monitorDefaultColor = ") print(settings.monitorDefaultColor)
	term.write("terminalDefaultColor = ") print(settings.terminalDefaultColor)
	term.write("progressBarColor = ") print(settings.progressBarColor)
	term.write("bootLoaderColor = ") print(settings.bootLoaderColor)
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
	term.write("networkProtocol = ") print(settings.networkProtocol)
	term.write("networkTimeout = ") print(settings.networkTimeout)
	term.write("startDeviceOnBoot = ") print(settings.startDeviceOnBoot)
end

function editSettingsMenu( ... )
	term.clear()

	while true do 
		listSettings()
		term.setCursorPos(1,terminalHeight)	term.write("(setting name / eXit): ")
		local menuChoice = read()
		
		if menuChoice == "monitorDefaultColor" then listColors() settings.monitorDefaultColor = colorFuncs.toColor(read()) end
		if menuChoice == "terminalDefaultColor" then listColors() settings.terminalDefaultColor = colorFuncs.toColor(read()) end
		if menuChoice == "progressBarColor" then listColors() settings.progressBarColor = colorFuncs.toColor(read()) end
		if menuChoice == "bootLoaderColor" then listColors() settings.bootLoaderColor = colorFuncs.toColor(read()) end
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
		if menuChoice == "networkProtocol" then settings.networkProtocol = read() end
		if menuChoice == "networkTimeout" then settings.networkTimeout = tonumber(read()) end
		if menuChoice == "startDeviceOnBoot" then settings.startDeviceOnBoot =  parseTrueFalse(read()) end

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
	print("(on/off/exit/reboot/json/devlist/colortest/rebootNet/idtaken)")
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
	if menuChoice == "rebootNet" then rednet.broadcast("reboot",settings.networkProtocol) end
	if menuChoice == "idtaken" then print(isIdOnNetwork(tonumber(read()))) end

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

function Switch.new(labelIn,redNetSwitchIDIn,confirmFlagIn, defaultStateIn)
	local self = setmetatable({},Switch) -- Lets class self refrence to create new objects based on the class
	
	self.type = "switch"
	self.label = labelIn
	self.defaultState = defaultStateIn or "off"

	-- All nil values will get filled in by other functions
	self.terminalSwitchOn = nil
	self.terminalSwitchOff = nil

	self.statusFlag = false -- Default State
	self.lineNumber = nil
	self.redNetSwitchID = redNetSwitchIDIn
	self.confirmFlag = confirmFlagIn or false -- Default if not specificed

	self.computerID = nil

	return self
end

-- Getters
-- we don't need getters, you can just access values directly, I DO WHAT I WANT! (object.privateVariable)

-- Methods

function Switch.getStatus(self )
	self.computerID = getComputerAssignment(self.redNetSwitchID) -- Checks if connection is still active
	if self.computerID ~= nil then 
		self.statusFlag = getDeviceInfo(self.redNetSwitchID,self.computerID) 
		if self.statusFlag == false then self.status = "OFFLINE" end
		if self.statusFlag == true then	self.status = "ONLINE" end
	else
		self.status = "MISSING"
	end
end

function Switch.terminalWrite( self, lineNumberIn ) -- Runs first
	self.getStatus(self) -- Calls status

	term.setCursorPos(1,lineNumberIn+settings.terminalHeaderOffset)
	
	if pocket then	else
		term.write(self.terminalSwitchOn.."/"..self.terminalSwitchOff)
		term.setCursorPos(settings.terminalIndent1,lineNumberIn+settings.terminalHeaderOffset)
		term.write(" -   ")
	end

	if self.status == "OFFLINE" then term.setTextColor(settings.offColor) end
	if self.status == "ONLINE" then	term.setTextColor(settings.onColor) end
	if self.status == "MISSING" then  term.setTextColor(settings.missingColor) end
	term.write(self.label) 
	if self.computerID ~= nil then term.write(" ["..self.computerID.."]") else term.write(" [N/A]")end
	term.setTextColor(settings.terminalDefaultColor)

	local deviceInfoText = "("..self.redNetSwitchID..")"
	local deviceInfoTextLength = string.len(deviceInfoText)

	term.setCursorPos(terminalWidth - deviceInfoTextLength, lineNumberIn+settings.terminalHeaderOffset)
	term.write(deviceInfoText)
end

function Switch.monitorStatus( self,lineNumberIn ) -- Runs second if monitor is available
	monitor.setCursorPos(1, lineNumberIn)
	monitor.write(self.label)
	

	if self.status == "OFFLINE" then monitor.setTextColor(settings.offColor) end
	if self.status == "ONLINE" then monitor.setTextColor(settings.onColor) end
	if self.status == "MISSING" then monitor.setTextColor(settings.missingColor) end

	monitor.setCursorPos(settings.statusIndent, lineNumberIn)
	monitor.write(self.status)
	monitor.setTextColor(settings.monitorDefaultColor)
end

function Switch.on( self )
	if self.computerID ~= nil then
		if self.confirmFlag == true then 
			local confirmInput = confirmOnMenu(self.label) -- Calls menu, returns flag

			if confirmInput == true then
				if getDeviceInfo(self.redNetSwitchID, self.computerID) == false then -- Off State
					sendCommand(self.redNetSwitchID,"on",self.computerID)
					if getDeviceInfo(self.redNetSwitchID, self.computerID) == true then self.statusFlag = true end
					if getDeviceInfo(self.redNetSwitchID, self.computerID) == false then self.statusFlag = false end
				end
			end
		end

		if self.confirmFlag == false then
			if getDeviceInfo(self.redNetSwitchID, self.computerID) == false then -- Off State
				sendCommand(self.redNetSwitchID,"on", self.computerID)
				if getDeviceInfo(self.redNetSwitchID, self.computerID) == true then self.statusFlag = true end
				if getDeviceInfo(self.redNetSwitchID, self.computerID) == false then self.statusFlag = false end
			end
		end
	end
end

function Switch.off( self )
	if self.computerID ~= nil then
		if getDeviceInfo(self.redNetSwitchID, self.computerID) == true then -- On State
			sendCommand(self.redNetSwitchID,"off", self.computerID)
			if getDeviceInfo(self.redNetSwitchID, self.computerID) == true then self.statusFlag = true end
			if getDeviceInfo(self.redNetSwitchID, self.computerID) == false then self.statusFlag = false end
		end
	end
end

-----------------------------------------------------------------------------------------------------------------------
-- Tank Class
local Tank = {}
Tank.__index = Tank -- failed table lookups on the instances should fallback to the class table, to get methods

-- Tank Constructor
function Tank.new(labelIn, redNetFillIDIn,redNetDumpIDIn,defaultStateIn) -- Constructor, but is technically one HUGE function
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
	self.redNetFillID = redNetFillIDIn
	self.redNetDumpID = redNetDumpIDIn

	self.computerID = nil
	return self
end

function Tank.getStatus(self )
	self.computerID = getComputerAssignment(self.redNetFillID) -- Checks if connection is still active
	if self.computerID ~= nil then
		self.fillFlag = getDeviceInfo(self.redNetFillID,self.computerID)
		self.dumpFlag = getDeviceInfo(self.redNetDumpID,self.computerID)
		if self.fillFlag == false and self.dumpFlag == false then self.status = "OFFLINE" end
		if self.fillFlag == true and self.dumpFlag == false then self.status = "FILLING" end
		if self.fillFlag == false and self.dumpFlag == true then self.status = "EMPTYING" end
	else
		self.status = "MISSING"
	end
end

function Tank.terminalWrite( self,lineNumberIn )
	self.getStatus(self) -- Calls status

	term.setCursorPos(1,lineNumberIn+settings.terminalHeaderOffset)
	
	if pocket then	else
		term.write(self.terminalFill.."/"..self.terminalDump.."/"..self.terminalOff)
		term.setCursorPos(settings.terminalIndent1,lineNumberIn+settings.terminalHeaderOffset)
		term.write(" -   ")
	end

	if self.status == "OFFLINE" then term.setTextColor(settings.offColor) end
	if self.status == "FILLING" then term.setTextColor(settings.fillColor) end
	if self.status == "EMPTYING" then term.setTextColor(settings.dumpColor) end
	if self.status == "MISSING" then term.setTextColor(settings.missingColor) end

	term.write(self.label) 
	if self.computerID ~= nil then term.write(" ["..self.computerID.."]") else term.write(" [N/A]")end
	term.setTextColor(settings.terminalDefaultColor)

	local deviceInfoText = "("..self.redNetFillID.."/"..self.redNetDumpID..")"
	local deviceInfoTextLength = string.len(deviceInfoText)

	term.setCursorPos(terminalWidth - deviceInfoTextLength, lineNumberIn+settings.terminalHeaderOffset)
	term.write(deviceInfoText)
end

function Tank.monitorStatus( self,lineNumberIn )
	monitor.setCursorPos(1, lineNumberIn)
	monitor.write(self.label)

	if self.status == "OFFLINE" then monitor.setTextColor(settings.offColor) end
	if self.status == "FILLING" then monitor.setTextColor(settings.fillColor) end
	if self.status == "EMPTYING" then monitor.setTextColor(settings.dumpColor) end
	if self.status == "MISSING" then monitor.setTextColor(settings.missingColor) end

	monitor.setCursorPos(settings.statusIndent,lineNumberIn)
	monitor.write(self.status)
	monitor.setTextColor(settings.monitorDefaultColor)
end


function Tank.fill( self )
	if self.computerID ~= nil then
		if getDeviceInfo(self.redNetFillID,self.computerID) == false and getDeviceInfo(self.redNetDumpID,self.computerID) == false then -- Off State
	
		sendCommand(self.redNetFillID,"on",self.computerID)
		self.fillFlag = getDeviceInfo(self.redNetFillID,self.computerID)
		self.dumpFlag = getDeviceInfo(self.redNetDumpID,self.computerID)
		end
	
		if getDeviceInfo(self.redNetFillID,self.computerID) == false and getDeviceInfo(self.redNetDumpID,self.computerID) == true then -- Dump State
		sendCommand(self.redNetFillID,"on",self.computerID)
		sendCommand(self.redNetDumpID,"off",self.computerID)
		self.fillFlag = getDeviceInfo(self.redNetFillID,self.computerID)
		self.dumpFlag = getDeviceInfo(self.redNetDumpID,self.computerID)
		end
	end
end

function Tank.dump( self )
	if self.computerID ~= nil then
		if getDeviceInfo(self.redNetFillID,self.computerID) == false and getDeviceInfo(self.redNetDumpID,self.computerID) == false then -- Off State
		sendCommand(self.redNetDumpID,"on",self.computerID)
		self.fillFlag = getDeviceInfo(self.redNetFillID,self.computerID)
		self.dumpFlag = getDeviceInfo(self.redNetDumpID,self.computerID)
		end
	
		if getDeviceInfo(self.redNetFillID,self.computerID) == true and getDeviceInfo(self.redNetDumpID,self.computerID) == false then -- Fill State
		sendCommand(self.redNetFillID,"off",self.computerID)
		sendCommand(self.redNetDumpID,"on",self.computerID)
		self.fillFlag = getDeviceInfo(self.redNetFillID,self.computerID)
		self.dumpFlag = getDeviceInfo(self.redNetDumpID,self.computerID)
		end
	end
end

function Tank.off( self )
	if self.computerID ~= nil then
		if getDeviceInfo(self.redNetFillID,self.computerID) == true then -- Fill State
		sendCommand(self.redNetFillID,"off",self.computerID)
		self.fillFlag = getDeviceInfo(self.redNetFillID,self.computerID)
		end
	
		if getDeviceInfo(self.redNetDumpID,self.computerID) == true then -- Dump State
		sendCommand(self.redNetDumpID,"off",self.computerID)
		self.dumpFlag = getDeviceInfo(self.redNetDumpID,self.computerID)
		end
	end
end

-----------------------------------------------------------------------------------------------------------------------
-- Main Program Logic

function run(	)
	bootLoader() -- Not just for show, give redNet time to reset
	mainProgram()

end

function mainProgram( ... )
	local startOnceFlag = true -- Should only be true on the first loop
	while true do
		if debugMenuFlag then  debugMenu() break end -- Kicks in from menuInput command
		-- Lets us break out of the main program to do other things
		if editDevicesMenuFlag then editDevicesMenu() break end -- Kicks in from menuInput command
		if editSettingsMenuFlag then editSettingsMenu() break end -- Kicks in from menuInput command
		
		termRedraw() -- PASSIVE OUTPUT
		if monitorPresentFlag then  monitorRedraw() end -- PASSIVE OUTPUT

		if settings.startDeviceOnBoot and pocket ~= true and startOnceFlag then setStartupState() startOnceFlag = false end -- Sets startup state only once
		-- parallel.waitForAny(menuInput, clickMonitor,clickTerminal,netCommands) -- Getting  unable to create new native thread
		parallel.waitForAny(menuInput,clickTerminal,clickMonitor) -- ACTIVE INPUT Working fine
	end
end

function bootLoader( ... )
	term.clear()
	if fs.exists (settingsFilePath) then loadSettings() end -- Loads settings
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
	-- Setup Network
	term.setCursorPos(1,3)
	term.write("Initalizing network")

	if peripheral.isPresent("top") and peripheral.getType("top") == "modem" then modemSide = "top" modemPresentFlag = true end
	if peripheral.isPresent("bottom") and peripheral.getType("bottom") == "modem" then modemSide = "bottom" modemPresentFlag = true end
	if peripheral.isPresent("left") and peripheral.getType("left") == "modem" then modemSide = "left" modemPresentFlag = true end
	if peripheral.isPresent("right") and peripheral.getType("right") == "modem" then modemSide = "right" modemPresentFlag = true end
	if peripheral.isPresent("back") and peripheral.getType("back") == "modem" then modemSide = "back" modemPresentFlag = true end
	
	if modemPresentFlag then term.write(" - Located Modem: ".. modemSide)  end
	if modemPresentFlag == false then term.write(" - NO MODEM FOUND") os.sleep(10) os.shutdown() end

	term.setCursorPos(1,terminalHeight)
	term.setTextColor(settings.progressBarColor)
	term.write("....................")
	term.setTextColor(settings.bootLoaderColor)
	-- rednet.broadcast("reboot",settings.networkProtocol) --  Resets Switch Network
	os.sleep(.25)

	---------------------------------------------------------------------------------------------------------
	-- Create objects
	term.setCursorPos(1,4)
	term.write("Initalizing devices")
	term.setCursorPos(1,terminalHeight)
	term.setTextColor(settings.progressBarColor)
	term.write("..............................")
	term.setTextColor(settings.bootLoaderColor)
	setUpDevices() -- Sets up objects

	os.sleep(1)

	---------------------------------------------------------------------------------------------------------
	-- Startup physical system
	term.setCursorPos(1,5)
	term.write("Initalizing startup state")
	term.setCursorPos(1,terminalHeight)
	term.setTextColor(settings.progressBarColor)
	term.write("........................................")
	term.setTextColor(settings.bootLoaderColor)

	if settings.startDeviceOnBoot == false or pocket then os.sleep(2) end -- Wait for devices to be started by the "server" terminal
	os.sleep(.25)

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
	local terminalHeaderText = settings.terminalHeader .. " - "..settings.networkProtocol.." ["..tostring(os.getComputerID()).."]"
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

function confirmOnMenu( labelIn )
	local confirmOnFlagOut = false
	
	term.clear()
	term.setTextColor(colors.yellow)
	term.setCursorPos(10,8)	term.write("Are you sure you want to activate: ")
	term.setTextColor(colors.magenta)
	term.setCursorPos(20,10)	term.write(labelIn)

	term.setTextColor(colors.red)
	term.setCursorPos(1,terminalHeight)	term.write("Please type yes to confirm: ")
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

	if pocket then 
		term.setCursorPos(1,terminalHeight)
		term.write("On/oFf/Set/Ref/reB/Ed/U:")
	else
		term.setCursorPos(1,terminalHeight)
		term.write("Sel# (On/oF/Set/Ref/reBoot/Edt/ssetUp): ")
	end

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
	if menuChoice == "reboot" or menuChoice == "b" then rednet.broadcast("reboot",settings.networkProtocol) os.reboot() end
	if menuChoice == "switchsetup" or "u" then rednet.broadcast("enableSwitchSetup",settings.networkProtocol) end

	if menuChoice == "on" or menuChoice == "o" then activateAll() end
	if menuChoice == "off" or menuChoice == "f" then shutdownAll() end
	
	if pocket then
		-- Skip menu
	else
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
end

-----------------------------------------------------------------------------------------------------------------------
-- Device Actions
function setUpDevices( ... )
	deviceList = {} -- Master device list, stores all the devices, starts off empty.

	if fs.exists (devicesFilePath) then 
		loadDevicesFromFile()
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
				devIn.label,devIn.redNetSwitchID,devIn.confirmFlag,devIn.defaultState))
		end

		if devIn.type == "tank"  then 
			table.insert(deviceList, Tank.new(
				devIn.label,devIn.redNetFillID,devIn.redNetDumpID,devIn.defaultState))
		end
	end	
end

function setStartupState()
	for i=1,table.getn(deviceList) do -- Gets arraylist size
		local devIn = deviceList[i]
		if devIn.defaultState == "dump" then devIn:dump() end
		if devIn.defaultState == "fill" then devIn:fill() end
		if devIn.defaultState == "on" and devIn.confirmFlag == false then devIn:on() end
		os.sleep(.25)
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

function isIDinUseDevLst(redNetSwitchIDin) -- Looks at self
	local flag = false
	for i=1,table.getn(deviceList) do
		local devIn = deviceList[i] -- Sets device from arrayList to local object
		if devIn.type == "switch" then
			if redNetSwitchIDin == devIn.redNetSwitchID then flag = true  break end
		end
		if devIn.type == "tank" then
			if redNetSwitchIDin == devIn.redNetFillID or redNetSwitchIDin == devIn.redNetDumpID then flag = true break end
		end
	end
	return flag
end

function isIdOnNetwork( redNetSwitchIDin ) -- Looks on network
	local flag = false
	if getComputerAssignment(redNetSwitchIDin) ~= nil then flag = true end
	return flag
end

function isSwitchActive( switchId , computerID )
	local flag = false
	rednet.open(modemSide)
	rednet.send(computerID, "getSwitchStatus",settings.networkProtocol)
	rednet.send(computerID, switchId,settings.networkProtocol)
	local senderId, message, protocol = rednet.receive(settings.networkProtocol,settings.networkTimeout)
	if message == "true" or message == "false" then flag = true end
	rednet.close(modemSide)
	return flag
end

function getDeviceInfo( switchId , computerID)
	rednet.open(modemSide)
	rednet.send(computerID, "getSwitchStatus",settings.networkProtocol)
	rednet.send(computerID, switchId,settings.networkProtocol)
	local senderId, message, protocol = rednet.receive(settings.networkProtocol,settings.networkTimeout)
	local flag = false
	if message == "false" then flag = false end
	if message == "true" then flag = true end
	rednet.close(modemSide)
	return flag
end

function getComputerAssignment( redNetSwitchIDin )
	rednet.open(modemSide)
	rednet.broadcast("getSwitchStatus",settings.networkProtocol)
	rednet.broadcast(redNetSwitchIDin,settings.networkProtocol)
	local senderId, message, protocol = rednet.receive(settings.networkProtocol,settings.networkTimeout)
	if message == "true" or message == "false" then switchOwner = senderId	else switchOwner = nil end
	rednet.close(modemSide)
	return switchOwner
end

function sendCommand( switchIDin, commandIn, sendToComputer )
	local msgObj = {}
	msgObj.switchId = switchIDin
	msgObj.command = commandIn
	msgSend=jsonV2.encode(msgObj)
	rednet.open(modemSide)
	rednet.send(sendToComputer, "sendDeviceCommand",settings.networkProtocol)
	rednet.send(sendToComputer, msgSend,settings.networkProtocol)
	rednet.close(modemSide)
end

-----------------------------------------------------------------------------------------------------------------------
-- Device Menu
function addDevice( ... )
	print("Enter device name to be added: ")
	local deviceLabel = read()
	print("Enter device type to be added (Tank/[Switch]): ")
	local deviceType = read()

	if deviceType == "tank" or deviceType == "t" then 
		local startupState = "off" -- Default variables for creation
		print("Enter redNet FILL ID number: ")
		local colorCodeFill = tonumber(read())
		print("Enter redNet DUMP ID number: ")
		local colorCodeDump = tonumber(read())

		if pocket then else -- Pocket comps take the default state
			print("Enter startup state (fill/dump/[off]): ")
			local startupState = parseStartupState(read())
		end

		if colorCodeFill == nil or colorCodeDump == nil or deviceLabel == "" or 
			isIDinUseDevLst(colorCodeFill) == true or isIDinUseDevLst(colorCodeDump) == true or -- Checks local device list for conflicts
			isIdOnNetwork(colorCodeFill) == false or isIdOnNetwork(colorCodeDump) == false then -- Checks network for present device
			term.clear() print("INVALID SETTINGS") os.sleep(2) else -- Only pass if valid
		table.insert(deviceList, Tank.new(deviceLabel,colorCodeFill,colorCodeDump,startupState)) end

	else
		-- Fall through to switch creation
		local confirmFlag = false -- Default variables for creation
		local startupState = "off"

		print("Enter redNet ID number: ")
		local colorCodeOn = tonumber(read())
		local confirmFlag = false
		local startupState = "off"

		if pocket then 	else -- Pocket comps take the default state
			print("Enter confirm flag (true/[false]): ")
			confirmFlag = parseTrueFalse(read())
		end

		if pocket then 	else -- Pocket comps take the default state
			print("Enter startup state (on/[off]): ")
			startupState = parseStartupState(read())
		end

		if colorCodeOn == nil or startupState == "fill" or startupState == "dump" or deviceLabel == "" or 
			isIDinUseDevLst(colorCodeOn) == true  or isIdOnNetwork(colorCodeOn) == false then 
			term.clear() print("INVALID SETTINGS") os.sleep(2) -- Only pass if valid
		else
			if confirmFlag == true and startupState == "off" then 
				table.insert(deviceList, Switch.new(deviceLabel,colorCodeOn,confirmFlag,startupState)) end
			if confirmFlag == false then -- No confirm flag = startup state doesn't matter, it's all good man.
				table.insert(deviceList, Switch.new(deviceLabel,colorCodeOn,confirmFlag,startupState)) 	
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
				
				print("Enter new ID number ["..tostring(deviceList[i].redNetSwitchID).."] : ")
				local colorIn = read()
				local colorCodeOn = tonumber(colorIn)
				if colorIn ~= "" and colorCodeOn ~= nil and isIdOnNetwork(colorCodeOn) == true and isIDinUseDevLst(colorCodeOn) == false then 
					deviceList[i].redNetSwitchID = colorCodeOn 	end 
				-- Non blank AND correct color = set color, a incorrect color returns NOTHING, which blocks setter

				if pocket then 
					deviceList[i].defaultState = "off"
					deviceList[i].confirmFlag = false
				else
					print("Enter confirm flag (true/[false]) ["..tostring(deviceList[i].confirmFlag).."]: ")
					local confirmIn = read()
					local confirmFlagIn = parseTrueFalse(confirmIn)
					if confirmFlagIn == false  and confirmIn ~= "" then deviceList[i].confirmFlag = confirmFlagIn end
					if confirmFlagIn == true and startupState == "off" and confirmIn ~= "" then deviceList[i].confirmFlag = confirmFlagIn end

					print("Enter startup state (on/[off]) ["..deviceList[i].defaultState.."]: ")
					local startupIn = read()
					local startupState = parseStartupState(startupIn)

					if startupState == "fill" or startupState == "dump" then term.clear() print("INVALID SETTINGS") os.sleep(2)	break end

					if deviceList[i].confirmFlag == false and startupIn ~= "" then deviceList[i].defaultState = startupState end -- No confirm = AOK
					if confirmFlagIn == true and startupState == "off"  and startupIn ~= "" then deviceList[i].defaultState = startupState end -- Confim flag + Start off = AOK
				end	

			break
			end

			if deviceList[i].type == "tank" then 
				print("Enter new FILL ID number ["..tostring(deviceList[i].redNetFillID).."] : ")
				local colorFillIn = read()
				local colorCodeFill = tonumber(colorFillIn)

				print("Enter new DUMP ID number ["..tostring(deviceList[i].redNetDumpID).."] : ")
				local colorDumpIn = read()
				local colorCodeDump = tonumber(colorDumpIn)

				if colorFillIn ~= "" and colorCodeFill ~= nil and isIdOnNetwork(colorCodeFill) == true 
					and isIDinUseDevLst(colorCodeFill) == false then deviceList[i].redNetFillID = colorCodeFill end
				if colorDumpIn ~= "" and colorCodeDump ~= nil  and isIdOnNetwork(colorCodeDump) == true 
					and isIDinUseDevLst(colorCodeDump) == false then deviceList[i].redNetDumpID = colorCodeDump end
				-- Non blank AND correct color = set color, a incorrect color returns NOTHING, which blocks setter
				-- NOTE: You can only change one value at a time, to keep the user from steping on their own toes.

				if pocket then
					deviceList[i].defaultState = "off"
				else
					print("Enter startup state (fill/dump/[off]) ["..deviceList[i].defaultState.."]: ")
					local startupIn = read()
					local startupState = parseStartupState(startupIn)
	
					-- Entering nothing or invalid options will prevent changes from being made
					if startupState == "on" then term.clear() print("INVALID SETTINGS") os.sleep(2) break end
					if startupIn ~= "" then deviceList[i].defaultState = startupState end -- Parser default covers our ass from the user
				end

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
	term.setCursorPos(1,1)
	print("Device List")
	for i=1,table.getn(deviceList) do 
		if pocket then
			if deviceList[i].type == "tank" then print("Tank:   "..deviceList[i].label) end
			if deviceList[i].type == "switch" then print("Switch: "..deviceList[i].label) end
		else
			if deviceList[i].type == "tank" then print("Type: "..deviceList[i].type.."     Label: "..deviceList[i].label) end
			if deviceList[i].type == "switch" then print("Type: "..deviceList[i].type.."   Label: "..deviceList[i].label) end
		end
	end
end

function editDevicesMenu( ... )
	term.clear()

	while true do 
		listDevices()
		if pocket then
			term.setCursorPos(1,terminalHeight)	term.write("(Add/Edt/Rm/Clr/Def/eX: ")
		else
			term.setCursorPos(1,terminalHeight)	term.write("(Add / Edit / Remove / Clear / Default / eXit): ")
		end

		
		local menuChoice = read()
		
		if menuChoice == "add" or menuChoice == "a" then addDevice() end
		if menuChoice == "edit" or menuChoice == "e" then editDevice() end
		if menuChoice == "remove" or menuChoice == "r" then removeDevice() end
		if menuChoice == "clear" or menuChoice == "c" then clearList() end
		if menuChoice == "default" or menuChoice == "d" then loadDefaultDevices() end
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
	table.insert(deviceList, Tank.new("Roof Tank",1,2,"dump"))
	table.insert(deviceList, Tank.new("Backup Tank",3,4,"fill"))
	table.insert(deviceList, Switch.new("Basement Gens",5))
	table.insert(deviceList, Switch.new("Smeltery",6))
	table.insert(deviceList, Switch.new("1st Flr Gens + Lava",7))
	table.insert(deviceList, Switch.new("2nd Flr Gens + AE",8))
	table.insert(deviceList, Switch.new("Quarry Gens",9))
	table.insert(deviceList, Switch.new("Net Bridge + Gens",10))
	table.insert(deviceList, Switch.new("Player Lava",11))
	if pocket then else table.insert(deviceList, Switch.new("Purge Valve",9999,true)) end
	table.insert(deviceList, Switch.new("Recyclers",13))
end

run() --Runs main program