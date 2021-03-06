-- Factory Control System v7
-- Author: Jesse

-- **RedNet Color Assignments**
-- white 		Top Tank Fill
-- orange		Top Tank Empty
-- magenta 		Smeltery
-- lightBlue	Basement generator (Inverted 0 = On 1 = Off)
-- yellow		Extra Base Lava
-- lime			backup Fill
-- pink			backup empty
-- gray			2st Floor Generators & Lava
-- lightGray 	Network Bridge
-- cyan			Quarry Generators
-- purple		1st Floor Generators and Lava
-- blue 		Recyclers
-- brown		**FREE**
-- green		**FREE**
-- red 			**FREE**
-- black		Purge Valve

os.loadAPI("/bb/api/jsonV2")

debugmode = false
debugEvents = false
rednetSide = "back" -- Where is the redNet cable

monitorDefaultColor = colors.white
terminalDefaultColor = colors.white
progressBarColor = colors.yellow
bootLoaderColor = colors.green
rednetIndicatorColor = colors.blue

fillColor = colors.yellow
dumpColor = colors.green
onColor = colors.green
offColor = colors.red

statusIndent = 20 -- Indent for Status (28 for 1x2 22 for 2x4 and bigger)
terminalIndent1 = 7 -- Determines dash location
terminalIndent2 = 36 -- Determines (On/Off ... etc location)
terminalHeaderOffset = 0

-----------------------------------------------------------------------------------------------------------------------
-- ReactorInfo Class
local ReactorInfo = {}  -- the table representing the class, which will double as the metatable for the instances
ReactorInfo.__index = ReactorInfo -- failed table lookups on the instances should fallback to the class table, to get methods

function ReactorInfo.new(labelIn, lineNumberIn)
	local self = setmetatable({},ReactorInfo) -- Lets class self refrence to create new objects based on the class
	
	self.type = "reactorInfo"
	self.label = labelIn
	self.lineNumber = lineNumberIn

	return self
end

function ReactorInfo.monitorStatus( self )
	monitor.setCursorPos(1, self.lineNumber)
	monitor.write(self.label)

	monitor.setCursorPos(statusIndent,self.lineNumber)
	monitor.write("OVER 9000 DEG")
	monitor.setTextColor(monitorDefaultColor)
end

function ReactorInfo.terminalWrite( self )
	term.setCursorPos(1,self.lineNumber+terminalHeaderOffset)
	term.write("self.type "..self.type.."self.label "..self.label)
	term.setCursorPos(terminalIndent2,self.lineNumber+terminalHeaderOffset)
	term.write(" MORE HERE")
end


-----------------------------------------------------------------------------------------------------------------------
-- Switch Class
local Switch = {}  -- the table representing the class, which will double as the metatable for the instances
Switch.__index = Switch -- failed table lookups on the instances should fallback to the class table, to get methods

function Switch.new(labelIn,terminalSwitchOnIn, terminalSwitchOffIn, lineNumberIn,redNetSwitchColorIn,confirmFlagIn)
	local self = setmetatable({},Switch) -- Lets class self refrence to create new objects based on the class
	
	self.type = "switch"
	self.label = labelIn

	self.terminalSwitchOn = terminalSwitchOnIn
	self.terminalSwitchOff = terminalSwitchOffIn

	self.statusFlag = false -- Default State
	self.lineNumber = lineNumberIn
	self.redNetSwitchColor = redNetSwitchColorIn
	self.confirmFlag = confirmFlagIn or false -- Default if not specificed
	return self
end

-- Getters
-- we don't need getters, you can just access values directly, I DO WHAT I WANT! (object.privateVariable)

-- Methods
function Switch.monitorStatus( self )
	monitor.setCursorPos(1, self.lineNumber)
	monitor.write(self.label)

	if self.statusFlag == false then	self.status = "OFFLINE"	monitor.setTextColor(offColor) end
	if self.statusFlag == true then	self.status = "ONLINE"	monitor.setTextColor(onColor) end

	monitor.setCursorPos(statusIndent,self.lineNumber)
	monitor.write(self.status)
	monitor.setTextColor(monitorDefaultColor)
end

function Switch.terminalWrite( self )
	term.setCursorPos(1,self.lineNumber+terminalHeaderOffset)
	term.write(self.terminalSwitchOn.."/"..self.terminalSwitchOff)
	term.setCursorPos(terminalIndent1,self.lineNumber+terminalHeaderOffset)
	term.write(" -   ")

	if self.statusFlag == false then term.setTextColor(offColor) end
	if self.statusFlag == true then	term.setTextColor(onColor) end
	term.write(self.label)
	term.setTextColor(terminalDefaultColor)

	term.setCursorPos(terminalIndent2+8,self.lineNumber+terminalHeaderOffset)  -- Extra indent to save space

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
-- Main Program Logic

function run(	)
	bootLoader() -- Not just for show, give redNet time to reset

	while true do
		if monitorPresentFlag then 	 monitorRedraw() end -- PASSIVE OUTPUT
		termRedraw() -- PASSIVE OUTPUT
		parallel.waitForAny(writeMenuSelection, clickMonitor,clickTerminal) -- ACTIVE INPUT
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
	term.setCursorPos(1,19)
	term.setTextColor(progressBarColor)
	term.write("....................")
	term.setTextColor(bootLoaderColor)
	redstone.setBundledOutput(rednetSide,0) -- Resets Network
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
	os.sleep(.25)
	term.setCursorPos(1,19)
	term.setTextColor(progressBarColor)
	term.write("..................................................")
	term.setTextColor(bootLoaderColor)
	os.sleep(1)

	term.setTextColor(terminalDefaultColor)
end

-----------------------------------------------------------------------------------------------------------------------
-- Termainl & Monitor Output
function writeMenuSelection( ... )
	term.setCursorPos(1,19)
	if debugmode == true then
		term.write("DEBUG RN:")
		term.write("-")
		term.write(redstone.getBundledOutput(rednetSide))
		term.write("-")
	else
		term.write("Select option: ")
	end

	local inputOption = read()
	menuOption(inputOption) -- Normal Options
	menuOptionCustom(inputOption) -- Custom Options at bottom
	term.clear()
end

function writeMenuHeader( ... )
	term.clear()
	term.setCursorPos(13,1)
	term.write("Reactor Control System v1b")
	term.setCursorPos(44,19)

	term.write("("..rednetSide..")")
end

function writeMonitorHeader( ... )
	monitor.clear()
	monitor.setCursorPos(1, 1)
	monitor.write("       Reactor Status")
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
		deviceList[i]:monitorStatus()
	end

end

function termRedraw( ... ) -- Terminal Display
	writeMenuHeader()

	for i=1,table.getn(deviceList) do -- Gets arraylist size
		deviceList[i]:terminalWrite()
	end


end

-----------------------------------------------------------------------------------------------------------------------
-- Menu Options

function clickMonitor()

  event, side, xPos, yPos = os.pullEvent("monitor_touch")
  print(event .. " => Side: " .. tostring(side) .. ", " ..
    "X: " .. tostring(xPos) .. ", " ..
    "Y: " .. tostring(yPos))
  os.sleep(4)
end

function clickTerminal()

  event, side, xPos, yPos = os.pullEvent("mouse_click")
  print(event .. " => Side: " .. tostring(side) .. ", " ..
    "X: " .. tostring(xPos) .. ", " ..
    "Y: " .. tostring(yPos))
  os.sleep(1)
end

function menuOption( menuChoice ) -- Menu Options for Terminal
	if menuChoice == "debugon" then debugmode = true end
	if menuChoice == "debugoff" then debugmode = false end
	if menuChoice == "debugevents" then debugEvents() end
	if menuChoice == "on" then activateAll() end
	if menuChoice == "off" then shutdownAll() end
	if menuChoice == "L" then rednetSide = "left" end
	if menuChoice == "R" then rednetSide = "right" end
	if menuChoice == "T" then rednetSide = "top" end
	if menuChoice == "B" then rednetSide = "bottom" end
	if menuChoice == "A" then rednetSide = "back" end


	for i=1,table.getn(deviceList) do -- Gets arraylist size
		if deviceList[i].type == "switch" then 
			if menuChoice == deviceList[i].terminalSwitchOn then deviceList[i]:on() end
			if menuChoice == deviceList[i].terminalSwitchOff then deviceList[i]:off() end
		end

	end
end

function debugEvents()
	print("To escape, press tilde twice")
	while true do 
		print(os.pullEvent())
		event,key = os.pullEvent()
		if key == 41 then 
			debugEvents = false
			break
		end
	end 
end

-- Device Actions
function shutdownAll()
	for i=1,table.getn(deviceList) do
		deviceList[i]:off()
	end
end
-----------------------------------------------------------------------------------------------------------------------
-- **DONT EDIT ANYTHING ABOVE HERE**

function setUpDevices( ... )
	--tank.new(labelIn, terminalFillIn, terminalDumpIn, terminalOffIn, lineNumberIn,redNetFillColorIn,redNetDumpColorIn)
	--switch.new("labelIn",terminalSwitchOnIn, terminalswitchOffIn, lineNumberIn,redNetSwitchColorIn,confirmFlagIn)
	
	deviceList = {} -- Master device list, stores all the devices.

	table.insert(deviceList, Switch.new("Reactor","1","2",2,colors.white,false))
	table.insert(deviceList, ReactorInfo.new("Temprature",3))
	table.insert(deviceList, ReactorInfo.new("Power Output",4))

end

function menuOptionCustom( menuChoice ) -- Custom Options for Terminal
	if menuChoice == "json" then 
		term.clear()
		prettystring = jsonV2.encodePretty(deviceList)
		print (prettystring)
		print("OUT:")
		print (jsonV2.encodePretty(deviceList[1]))
		print("Table Size: " .. table.getn(deviceList))

		os.sleep(5)
	end

end


function setStartupState()
	for i=1,table.getn(deviceList) do -- Gets arraylist size
	if deviceList[i].label == Reactor then deviceList[i]:on() end
	end	
end

function activateAll()
	for i=1,table.getn(deviceList) do
		print("")

	end
end

run() --Runs main program