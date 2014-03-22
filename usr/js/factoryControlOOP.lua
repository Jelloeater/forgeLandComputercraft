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
debugEventFlag = false
rednetSide = "bottom" -- Where is the redNet cable

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
-- Tank Class
local Tank = {}
Tank.__index = Tank -- failed table lookups on the instances should fallback to the class table, to get methods

-- Tank Constructor
function Tank.new(labelIn, terminalFillIn, terminalDumpIn, terminalOffIn, lineNumberIn,redNetFillColorIn,redNetDumpColorIn) -- Constructor, but is technically one HUGE function
	local self = setmetatable({},Tank) -- Lets class self refrence to create new objects based on the class

	-- Instance Variables
	self.type = "tank"
	self.label = labelIn
	self.terminalFill = terminalFillIn
	self.terminalDump = terminalDumpIn
	self.terminalOff = terminalOffIn

	self.fillFlag = false -- Default state
	self.dumpFlag = false -- Default state

	self.lineNumber = lineNumberIn
	self.redNetFillColor = redNetFillColorIn
	self.redNetDumpColor = redNetDumpColorIn
	return self
end

function Tank.monitorStatus( self )
	monitor.setCursorPos(1, self.lineNumber)
	monitor.write(self.label)

	if self.fillFlag == false and self.dumpFlag == false then	self.status = "OFFLINE"	monitor.setTextColor(offColor) end
	if self.fillFlag == true and self.dumpFlag == false then	self.status = "FILLING"	monitor.setTextColor(fillColor) end
	if self.fillFlag == false and self.dumpFlag == true then	self.status = "EMPTYING"	monitor.setTextColor(dumpColor) end

	monitor.setCursorPos(statusIndent,self.lineNumber)
	monitor.write(self.status)
	monitor.setTextColor(monitorDefaultColor)
end

function Tank.terminalWrite( self )
	term.setCursorPos(1,self.lineNumber+terminalHeaderOffset)
	term.write(self.terminalFill.."/"..self.terminalDump.."/"..self.terminalOff)
	term.setCursorPos(terminalIndent1,self.lineNumber+terminalHeaderOffset)
	term.write(" -   ")

	if self.fillFlag == false and self.dumpFlag == false then term.setTextColor(offColor) end
	if self.fillFlag == true and self.dumpFlag == false then term.setTextColor(fillColor) end
	if self.fillFlag == false and self.dumpFlag == true then term.setTextColor(dumpColor) end
	term.write(self.label)
	
	term.setCursorPos(terminalIndent2,self.lineNumber+terminalHeaderOffset)

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
		if debugEventFlag then print("To escape, press tilde twice")  debugEvent() break end -- Kicks in from menuInput command
		-- Lets us break out of the main program to do other things

		if monitorPresentFlag then 	 monitorRedraw() end -- PASSIVE OUTPUT
		termRedraw() -- PASSIVE OUTPUT
		parallel.waitForAny(menuInput, clickMonitor,clickTerminal) -- ACTIVE INPUT
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
function writeMenuSelection( ... )
	term.setCursorPos(1,19)
	if debugmode == true then
		term.write("DEBUG RN:")
		term.write(redstone.getBundledOutput(rednetSide))
		term.write("-")
		term.write(rednetSide)
		term.write("-")
	end
	term.write("Select a menu option (on/off/craft): ")
	
end

function writeMenuHeader( ... )
	term.clear()
	term.setCursorPos(13,1)
	term.write("Factory Control System v7")
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
	monitor.write("       Factory Status")
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
	writeMenuSelection()
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
	if menuChoice == "on" then activateAll() end
	if menuChoice == "off" then shutdownAll() end
	if menuChoice == "L" then rednetSide = "left" end
	if menuChoice == "R" then rednetSide = "right" end
	if menuChoice == "T" then rednetSide = "top" end
	if menuChoice == "B" then rednetSide = "bottom" end

	for i=1,table.getn(deviceList) do -- Gets arraylist size
		if deviceList[i].type == "switch" then 
			if menuChoice == deviceList[i].terminalSwitchOn then deviceList[i]:on() end
			if menuChoice == deviceList[i].terminalSwitchOff then deviceList[i]:off() end
		end

		if deviceList[i].type == "tank" then 
			if menuChoice == deviceList[i].terminalFill then deviceList[i]:fill() end
			if menuChoice == deviceList[i].terminalDump then deviceList[i]:dump() end
			if menuChoice == deviceList[i].terminalOff then deviceList[i]:off() end
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
	--switch.new("labelIn",terminalSwitchOnIn, terminalswitchOffIn, lineNumberIn,redNetSwitchColorIn,invertFlagIn,confirmFlagIn)
	
	deviceList = {} -- Master device list, stores all the devices.

	table.insert(deviceList, Tank.new("Roof Tank","1","2","3",2,colors.white,colors.orange))
	table.insert(deviceList, Tank.new("Backup Tank","4","5","6",3,colors.lime,colors.pink))
	table.insert(deviceList, Switch.new("Basement Gens","7","8", 4,colors.lightBlue))
	table.insert(deviceList, Switch.new("Smeltery","9","10", 5,colors.magenta))
	table.insert(deviceList, Switch.new("1st Flr Gens + Lava","11","12",6,colors.purple))
	table.insert(deviceList, Switch.new("2nd Flr Gens + AE","13","14", 7,colors.gray))
	table.insert(deviceList, Switch.new("Quarry Gens","15","16", 8,colors.cyan))
	table.insert(deviceList, Switch.new("Net Bridge + Gens","17","18", 9,colors.lightGray))
	table.insert(deviceList, Switch.new("Player Lava","19","20", 10,colors.yellow))
	table.insert(deviceList, Switch.new("Purge Valve","21","22",11,colors.black,true))
	table.insert(deviceList, Switch.new("Recyclers","23","24", 12,colors.blue))

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

	if menuChoice == "craft" then craft() end
	if menuChoice == "debugevent" then debugEventFlag = true end -- Sets flag to true so we break out of main program

end

function craft(  )
	shutdownAll()
	for i=1,table.getn(deviceList) do -- Gets arraylist size
		if deviceList[i].label == "Roof Tank" then deviceList[i]:dump() end
		if deviceList[i].label == "Backup Tank" then deviceList[i]:fill() end
		if deviceList[i].label == "2nd Flr Gens + AE" then deviceList[i]:on() end
	end	
end

function setStartupState()
	for i=1,table.getn(deviceList) do -- Gets arraylist size
		if deviceList[i].label == "Roof Tank" then deviceList[i]:dump() end
		if deviceList[i].label == "Backup Tank" then deviceList[i]:fill() end
	end	
end

function activateAll()
	for i=1,table.getn(deviceList) do
		if deviceList[i].type == "switch" and deviceList[i].confirmFlag == false then deviceList[i]:on() end

		if deviceList[i].type == "tank" then 
			if deviceList[i].label == "Roof Tank" then deviceList[i]:dump() end
			if deviceList[i].label == "Backup Tank" then deviceList[i]:fill() end
		end
	end
end

function debugEvent()
	while true do 
		print(os.pullEvent())
		event,key = os.pullEvent()
		if key == 41 then 
			debugEventFlag = false -- Disables break in main program
			mainProgram() -- Returns to main program
		end
	end 
end

run() --Runs main program