-- Factory Control System v2.0
-- Author: Jesse

-- **RedNet Color Assignments**
-- white 		Top Tank Fill
-- orange		Top Tank Empty
-- magenta 		Smeltery
-- lightBlue	Basement generator (Inverted 0 = On 1 = Off)
-- yellow		Extra Base Lava
-- lime			backup Fill
-- pink			backup empty
-- grey			1st Floor Generators & Lava
-- lightGrey 	Network Bridge
-- cyan			Quarry Generators
-- purple		**FREE**
-- blue 		**FREE**
-- brown		**FREE**
-- green		**FREE**
-- red 			**FREE**
-- black		**FREE**

debugmode = false

monitor = peripheral.wrap("top") -- Monitor wrapper, default location, for easy access
rednetSide = "bottom" -- Where is the redNet cable

monitorDefaultColor = colors.white
term.setTextColor(colors.green)

monitor.setTextScale(.5) -- Sets Text Size (.5 for 1x2 1 for 2x4 2.5 for 5x7 (MAX))
statusIndent = 28 -- Indent for Status (28 for 1x2 22 for 2x4 and bigger)
terminalIndent1 = 7 -- Determines dash location
terminalIndent2 = 36 -- Determines (On/Off ... etc location)

-----------------------------------------------------------------------------------------------------------------------
-- Switch Class
switch = {} -- Class wrapper

	switch.new = function (labelIn,terminalSwitchOnIn, terminalSwitchOffIn, lineNumberIn,redNetSwitchColorIn,invertFlagIn) -- Constructor, but is technically one HUGE function
	-- #PRIVATE VARIABLES
	local self = {}
	local label = labelIn

	local terminalSwitchOn = terminalSwitchOnIn
	local terminalSwitchOff = terminalSwitchOffIn

	local statusFlag = false -- Default State
	local lineNumber = lineNumberIn
	local redNetSwitchColor = redNetSwitchColorIn
	local invertFlag = invertFlagIn

	-- Getters
	-- self.getLabel = function () return label end
	self.getTerminalSwitchOn = function () return terminalSwitchOn end
	self.getTerminalSwitchOff = function () return terminalSwitchOff end

	-- Methods
	self.monitorStatus = function()
		monitor.setCursorPos(1, lineNumber)
		monitor.write(label.." is: ")

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
		term.write(" -  "..label)
		term.setCursorPos(terminalIndent2,lineNumber)
		term.write("(On/Off)")

	end


	self.on = function()
		if invertFlag == false then
			if statusFlag == false then -- Off State
				redstone.setBundledOutput(rednetSide, redstone.getBundledOutput(rednetSide)+redNetSwitchColor)
				statusFlag = true
			end
		end

		if self.invertFlag == true then
			if statusFlag == false then -- Off State
				redstone.setBundledOutput(rednetSide, redstone.getBundledOutput(rednetSide)-redNetSwitchColor)
				statusFlag = true
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
		monitor.write(label.." is: ")

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
		term.write(" -  "..label)
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
function monitorRedraw( ... ) -- Status Monitor Display
	monitor.clear()

	monitor.setCursorPos(1, 1)
	monitor.write("Factory Status")

	mainRoofTank.monitorStatus()
	smeltrery.monitorStatus()

end

function termRedraw( ... ) -- Terminal Display
	term.clear()

	term.setCursorPos(1,1)
	term.write("           Factory Control System v2.0")

	mainRoofTank.terminalWrite()
	smeltrery.terminalWrite()






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

function menuOption( menuChoice ) -- Menu Options for Terminal
	if menuChoice == "debugon" then debugmode = true end
	if menuChoice == "debugoff" then debugmode = false end
	if menuChoice == "on" then activateAll() end
	if menuChoice == "off" then shutdownAll() end

	if menuChoice == mainRoofTank.getTerminalFill() then mainRoofTank.fill() end
	if menuChoice == mainRoofTank.getTerminalDump() then mainRoofTank.dump() end
	if menuChoice == mainRoofTank.getTerminalOff() then mainRoofTank.off() end

	if menuChoice == smeltrery.getTerminalSwitchOn() then smeltrery.on() end
	if menuChoice == smeltrery.getTerminalSwitchOff() then smeltrery.off() end


end


function setStartupState( ... )
	-- All systems are logically off at start, except basementGenerator
	-- ****NOTE**** Inverted switches must be forced into an off state at program start (they add a value to the system)

	-- Line 1 is the Title Row
	-- tankName = tank.new(labelIn, terminalFillIn, terminalDumpIn, terminalOffIn, lineNumberIn,redNetFillColorIn,redNetDumpColorIn)
	-- switchName = switch.new("labelIn",terminalSwitchOnIn, terminalswitchOffIn, lineNumberIn,redNetSwitchColorIn,invertFlagIn)

	mainRoofTank = tank.new("Roof Tank","1","2","3",2,colors.white,colors.orange)


	smeltrery = switch.new("Smeltery","9","10", 5,colors.magenta,false)

	
	-- basementGenerator:invertStartup()
	

end

function shutdownAll( ... )

end

function activateAll( ... )

end

function run(	) -- Main Program Logic
setStartupState() 
	while true do
		monitorRedraw() -- PASSIVE OUTPUT
		termRedraw()	-- ACTIVE INPUT
	end
end

run() --Runs main program
