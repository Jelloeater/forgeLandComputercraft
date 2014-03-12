-- Factory Control System v3.0
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

debugmode = false
monitor = peripheral.wrap("top") -- Monitor wrapper, default location, for easy access
rednetSide = "bottom" -- Where is the redNet cable

monitorDefaultColor = colors.white
terminalDefaultColor = colors.green
term.setTextColor(terminalDefaultColor)

monitor.setTextScale(1) -- Sets Text Size (.5 for 1x2 1 for 2x4 2.5 for 5x7 (MAX))
statusIndent = 22 -- Indent for Status (28 for 1x2 22 for 2x4 and bigger)
terminalIndent1 = 7 -- Determines dash location
terminalIndent2 = 36 -- Determines (On/Off ... etc location)

-----------------------------------------------------------------------------------------------------------------------
-- Switch Class
switch = {} -- Class wrapper

	switch.new = function (labelIn,terminalSwitchOnIn, terminalSwitchOffIn, lineNumberIn,redNetSwitchColorIn,invertFlagIn,confirmFlagIn) -- Constructor, but is technically one HUGE function
	-- #PRIVATE VARIABLES
	local self = {}
	local label = labelIn

	local terminalSwitchOn = terminalSwitchOnIn
	local terminalSwitchOff = terminalSwitchOffIn

	local statusFlag = false -- Default State
	local lineNumber = lineNumberIn
	local redNetSwitchColor = redNetSwitchColorIn
	local invertFlag = invertFlagIn or false -- Default if not specificed
	local confirmFlag = confirmFlagIn or false -- Default if not specificed

	-- Getters
	-- self.getLabel = function () return label end
	self.getTerminalSwitchOn = function () return terminalSwitchOn end
	self.getTerminalSwitchOff = function () return terminalSwitchOff end

	-- Methods
	self.monitorStatus = function()
		monitor.setCursorPos(1, lineNumber)
		monitor.write(label)
		-- monitor.write(" is: ")

		if statusFlag == false then	status = "OFFLINE"	end
		if statusFlag == true then	status = "ONLINE"	end

		if status == "OFFLINE" then monitor.setTextColor(colors.red) end
		if status == "ONLINE" then monitor.setTextColor(colors.green) end
		monitor.setCursorPos(statusIndent,lineNumber)
		monitor.write(status)
		monitor.setTextColor(monitorDefaultColor)
	end

	self.terminalWrite = function()
		term.setCursorPos(1,lineNumber)
		term.write(terminalSwitchOn.."/"..terminalSwitchOff)
		term.setCursorPos(terminalIndent1,lineNumber)
		term.write(" -   "..label)
		term.setCursorPos(terminalIndent2+8,lineNumber)  -- Extra indent to save space
		term.write("(On/Off)")
	end


	self.on = function()
		if confirmFlag == true then 
		local confirmInput = confirmOnMenu(label) -- Calls menu, returns flag
			if confirmInput == true then
				if invertFlag == false then
					if statusFlag == false then -- Off State
						redstone.setBundledOutput(rednetSide, redstone.getBundledOutput(rednetSide)+redNetSwitchColor)
						statusFlag = true
					end
				end

				if invertFlag == true then
					if statusFlag == false then -- Off State
						redstone.setBundledOutput(rednetSide, redstone.getBundledOutput(rednetSide)-redNetSwitchColor)
						statusFlag = true
					end
				end
			end
		end

		if confirmFlag == false then 
			if invertFlag == false then
				if statusFlag == false then -- Off State
					redstone.setBundledOutput(rednetSide, redstone.getBundledOutput(rednetSide)+redNetSwitchColor)
					statusFlag = true
				end
			end

			if invertFlag == true then
				if statusFlag == false then -- Off State
					redstone.setBundledOutput(rednetSide, redstone.getBundledOutput(rednetSide)-redNetSwitchColor)
					statusFlag = true
				end
			end
		end

	end 


	self.off = function()
		if invertFlag == false then
			if statusFlag == true then -- On State
				redstone.setBundledOutput(rednetSide, redstone.getBundledOutput(rednetSide)-redNetSwitchColor)
				statusFlag = false
			end
		end

		if invertFlag == true then
			if statusFlag == true then -- On State
				redstone.setBundledOutput(rednetSide, redstone.getBundledOutput(rednetSide)+redNetSwitchColor)
				statusFlag = false
			end
		end
	end

	self.invertStartup = function() -- SHOULD ONLY BE RUN ONCE AT STARTUP
		if invertFlag == true and statusFlag == false then
			redstone.setBundledOutput(rednetSide, redstone.getBundledOutput(rednetSide)+redNetSwitchColor)
		end
	end

	self.invertShutdown = function() -- SHOULD ONLY BE RUN ONCE AT STARTUP
		if invertFlag == true and statusFlag == true then
			redstone.setBundledOutput(rednetSide, redstone.getBundledOutput(rednetSide)-redNetSwitchColor)
		end
	end

	return self         --VERY IMPORTANT, RETURN ALL THE METHODS!
end

-----------------------------------------------------------------------------------------------------------------------
-- Tank Class
tank = {}
tank.new = function (labelIn, terminalFillIn, terminalDumpIn, terminalOffIn, lineNumberIn,redNetFillColorIn,redNetDumpColorIn) -- Constructor, but is technically one HUGE function
	-- #PRIVATE VARIABLES
	local self = {}
	local label = labelIn

	local terminalFill = terminalFillIn
	local terminalDump = terminalDumpIn
	local terminalOff = terminalOffIn

	local fillFlag = false -- Default state
	local dumpFlag = false -- Default state

	local lineNumber = lineNumberIn
	local redNetFillColor = redNetFillColorIn
	local redNetDumpColor = redNetDumpColorIn

	-- Getters
	-- self.getLabel = function () return label end
	self.getTerminalFill = function () return terminalFill end
	self.getTerminalDump = function () return terminalDump end
	self.getTerminalOff = function () return terminalOff end


	-- Methods
	self.monitorStatus = function()
		monitor.setCursorPos(1, lineNumber)
		monitor.write(label)
		-- monitor.write(" is: ")

		if fillFlag == false and dumpFlag == false then	status = "OFFLINE"	end
		if fillFlag == true and dumpFlag == false then	status = "FILLING"	end
		if fillFlag == false and dumpFlag == true then	status = "EMPTYING"	end

		if status == "OFFLINE" then monitor.setTextColor(colors.red) end
		if status == "FILLING" then monitor.setTextColor(colors.yellow) end
		if status == "EMPTYING" then monitor.setTextColor(colors.green) end
		
		monitor.setCursorPos(statusIndent,lineNumber)
		monitor.write(status)
		monitor.setTextColor(monitorDefaultColor)
	end

	self.terminalWrite = function()
		term.setCursorPos(1,lineNumber)
		term.write(terminalFill.."/"..terminalDump.."/"..terminalOff)
		term.setCursorPos(terminalIndent1,lineNumber)
		term.write(" -   "..label)
		term.setCursorPos(terminalIndent2,lineNumber)
		term.write("(Fill/Empty/Off)")

	end


	self.fill = function() -- We should NEVER have both flags set to true, that would be silly
		if fillFlag == false and dumpFlag == false then -- Off State
		redstone.setBundledOutput(rednetSide, redstone.getBundledOutput(rednetSide)+redNetFillColor)
		fillFlag = true
		dumpFlag = false
		end

		if fillFlag == false and dumpFlag == true then -- Dump State
		redstone.setBundledOutput(rednetSide, redstone.getBundledOutput(rednetSide)+redNetFillColor)
		redstone.setBundledOutput(rednetSide, redstone.getBundledOutput(rednetSide)-redNetDumpColor)
		fillFlag = true
		dumpFlag = false
		end
	end

	self.dump = function ()
		if fillFlag == false and dumpFlag == false then -- Off State
		redstone.setBundledOutput(rednetSide, redstone.getBundledOutput(rednetSide)+redNetDumpColor)
		fillFlag = false
		dumpFlag = true
		end

		if fillFlag == true and dumpFlag == false then -- Fill State
		redstone.setBundledOutput(rednetSide, redstone.getBundledOutput(rednetSide)-redNetFillColor)
		redstone.setBundledOutput(rednetSide, redstone.getBundledOutput(rednetSide)+redNetDumpColor)
		fillFlag = false
		dumpFlag = true
		end
	end

	self.off = function ()
		if fillFlag == true then -- Fill State
		redstone.setBundledOutput(rednetSide, redstone.getBundledOutput(rednetSide)-redNetFillColor)
		fillFlag = false
		end

		if dumpFlag == true then -- Dump State
		redstone.setBundledOutput(rednetSide, redstone.getBundledOutput(rednetSide)-redNetDumpColor)
		dumpFlag = false
		end
	end

	return self         --VERY IMPORTANT, RETURN ALL THE METHODS!
end




-----------------------------------------------------------------------------------------------------------------------
-- Main Program Logic

function run(	)
	term.clear()
	monitor.clear()
	
	bootLoader() -- Not just for show, give redNet time to reset

		while true do
			monitorRedraw() -- PASSIVE OUTPUT
			termRedraw()	-- ACTIVE INPUT
		end
end

function bootLoader( ... )
	monitor.setCursorPos(5, 5)
	monitor.write("SYSTEM BOOT IN PROGRESS")

	term.setCursorPos(1,2)
	term.write("SYSTEM BOOTING")
	term.setCursorPos(1,19)
	term.write("..........")
	os.sleep(1)

	term.setCursorPos(1,3)
	term.write("Initalizing network")
	term.setCursorPos(1,19)
	term.write("....................")
	redstone.setBundledOutput(rednetSide,0) -- Resets Network
	os.sleep(1)

	term.setCursorPos(1,4)
	term.write("Initalizing devices")
	term.setCursorPos(1,19)
	term.write("..............................")
	setUpDevices() -- Sets up objects
	os.sleep(1)

	term.setCursorPos(1,5)
	term.write("Initalizing startup state")
	term.setCursorPos(1,19)
	term.write("........................................")
	setStartupState() -- Sets startup state
	os.sleep(1)

	term.setCursorPos(1,6)
	term.write("Please wait")
	os.sleep(1)
	term.setCursorPos(1,19)
	term.write("..................................................")
	os.sleep(1)
end
-----------------------------------------------------------------------------------------------------------------------
-- Termainl & Monitor Output
function writeMenuSelection( ... )
	term.setCursorPos(1,19)
	if debugmode == true then
		term.write("DEBUG RedNet: ")
		term.write(redstone.getBundledOutput(rednetSide))
		term.write(" ")
	end
	term.write("Select a menu option (on/off): ")
	local inputOption = read()
	menuOption(inputOption)
end

function writeMenuHeader( ... )
	term.clear()
	term.setCursorPos(1,1)
	term.write("           Factory Control System v3.0")
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
-----------------------------------------------------------------------------------------------------------------------
-- **DONT EDIT ANYTHING ABOVE HERE**

function setUpDevices( ... )
	-- tankName = tank.new(labelIn, terminalFillIn, terminalDumpIn, terminalOffIn, lineNumberIn,redNetFillColorIn,redNetDumpColorIn)
	-- switchName = switch.new("labelIn",terminalSwitchOnIn, terminalswitchOffIn, lineNumberIn,redNetSwitchColorIn,invertFlagIn,confirmFlagIn)
	
	-- Line 1 is the Title Row
	mainRoofTank = tank.new("Roof Tank","1","2","3",2,colors.white,colors.orange)
	backupTank = tank.new("Backup Tank","4","5","6",3,colors.lime,colors.pink)
	basementGenerator = switch.new("Basement Gens","7","8", 4,colors.lightBlue)
	smeltrery = switch.new("Smeltery","9","10", 5,colors.magenta)
	firstFloorGenerators = switch.new("1st Flr Gens + Lava","11","12",6,colors.purple)
	secondFloorGenerators = switch.new("2nd Flr Gens + AE","13","14", 7,colors.gray)
	quarryGenerators = switch.new("Quarry Gens","15","16", 8,colors.cyan)
	networkBridge = switch.new("Net Bridge + Gens","17","18", 9,colors.lightGray)
	playerLava = switch.new("Player Lava","19","20", 10,colors.yellow)
	purgeValve = switch.new("Purge Valve","21","22",11,colors.black,false,true)
	recyclers = switch.new("Recyclers","23","24", 12,colors.blue)


end

function monitorRedraw( ... ) -- Status Monitor Display
	writeMonitorHeader()

	mainRoofTank.monitorStatus()
	backupTank.monitorStatus()
	basementGenerator.monitorStatus()
	smeltrery.monitorStatus()
	secondFloorGenerators.monitorStatus()
	quarryGenerators.monitorStatus()
	networkBridge.monitorStatus()
	playerLava.monitorStatus()
	purgeValve.monitorStatus()
	firstFloorGenerators.monitorStatus()
	recyclers.monitorStatus()

end

function termRedraw( ... ) -- Terminal Display
	writeMenuHeader()

	mainRoofTank.terminalWrite()
	backupTank.terminalWrite()
	basementGenerator.terminalWrite()
	smeltrery.terminalWrite()
	secondFloorGenerators.terminalWrite()
	quarryGenerators.terminalWrite()
	networkBridge.terminalWrite()
	playerLava.terminalWrite()
	purgeValve.terminalWrite()
	firstFloorGenerators.terminalWrite()
	recyclers.terminalWrite()

	writeMenuSelection()
end

function menuOption( menuChoice ) -- Menu Options for Terminal

	if menuChoice == "debugon" then debugmode = true end
	if menuChoice == "debugoff" then debugmode = false end
	if menuChoice == "on" then activateAll() end
	if menuChoice == "off" then shutdownAll() end

	if menuChoice == mainRoofTank.getTerminalFill() then mainRoofTank.fill() end
	if menuChoice == mainRoofTank.getTerminalDump() then mainRoofTank.dump() end
	if menuChoice == mainRoofTank.getTerminalOff() then mainRoofTank.off() end

	if menuChoice == backupTank.getTerminalFill() then backupTank.fill() end
	if menuChoice == backupTank.getTerminalDump() then backupTank.dump() end
	if menuChoice == backupTank.getTerminalOff() then backupTank.off() end

	if menuChoice == basementGenerator.getTerminalSwitchOn() then basementGenerator.on() end
	if menuChoice == basementGenerator.getTerminalSwitchOff() then basementGenerator.off() end

	if menuChoice == smeltrery.getTerminalSwitchOn() then smeltrery.on() end
	if menuChoice == smeltrery.getTerminalSwitchOff() then smeltrery.off() end

	if menuChoice == secondFloorGenerators.getTerminalSwitchOn() then secondFloorGenerators.on() end
	if menuChoice == secondFloorGenerators.getTerminalSwitchOff() then secondFloorGenerators.off() end

	if menuChoice == quarryGenerators.getTerminalSwitchOn() then quarryGenerators.on() end
	if menuChoice == quarryGenerators.getTerminalSwitchOff() then quarryGenerators.off() end

	if menuChoice == networkBridge.getTerminalSwitchOn() then networkBridge.on() end
	if menuChoice == networkBridge.getTerminalSwitchOff() then networkBridge.off() end

	if menuChoice == playerLava.getTerminalSwitchOn() then playerLava.on() end
	if menuChoice == playerLava.getTerminalSwitchOff() then playerLava.off() end

	if menuChoice == purgeValve.getTerminalSwitchOn() then mainRoofTank.off() backupTank.off() purgeValve.on() end
	if menuChoice == purgeValve.getTerminalSwitchOff() then purgeValve.off() end

	if menuChoice == firstFloorGenerators.getTerminalSwitchOn() then firstFloorGenerators.on() end
	if menuChoice == firstFloorGenerators.getTerminalSwitchOff() then firstFloorGenerators.off() end

	if menuChoice == recyclers.getTerminalSwitchOn() then recyclers.on() end
	if menuChoice == recyclers.getTerminalSwitchOff() then recyclers.off() end
end


function setStartupState( ... )
	-- All systems are logically off at start, except basementGenerator
	-- ****NOTE**** Inverted switches must be forced into an off state at program start (they add a value to the system)

	-- basementGenerator.invertStartup()
	-- recyclers.invertStartup()
	mainRoofTank.dump()
	backupTank.fill()
	
end

function shutdownAll( ... )
	-- ****NOTE**** Inverted switches must be forced into an OFF state BEFORE any normal switches
	-- basementGenerator.invertShutdown()
	basementGenerator.off()
	-- recyclers.invertShutdown()
	recyclers.off()

	mainRoofTank.off()
	backupTank.off()
	smeltrery.off()
	secondFloorGenerators.off()
	quarryGenerators.off()
	networkBridge.off()
	playerLava.off()
	purgeValve.off()
	firstFloorGenerators.off()
end

function activateAll( ... )
	-- ****NOTE**** Inverted switches must be forced into an ON state BEFORE any normal switches
	-- basementGenerator.invertStartup()
	basementGenerator.on()

	mainRoofTank.dump()
	backupTank.fill()
	smeltrery.on()
	secondFloorGenerators.on()
	quarryGenerators.on()
	networkBridge.on()
	playerLava.on()
	firstFloorGenerators.on()
end

run() --Runs main program