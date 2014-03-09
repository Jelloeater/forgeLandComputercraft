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
monitor = peripheral.wrap("top") -- Where is the monitor
rednetSide = "bottom" -- Where is the redNet cable

monitorDefaultColor = colors.white
term.setTextColor(colors.green)
monitor.setTextScale(1) -- Sets Text Size
-- .5 for 1x2 1 for 2x4


-- GLOBAL FLAGS **DO NOT FUCK WITH**
topTankFillFlag = false
topTankDumpFlag = false
backupTankFillFlag = false
backupTankDumpFlag = false
basementGeneratorFlag = false
smelteryFlag = false
firstFloorGeneratorsFlag = false
quarryGeneratorsFlag = false
networkBridgeFlag = false
playerLavaFlag = false



function getStatus( device ) -- Checks what the system is doing, used in monitorStatus
	if device == "topTank" then
		if topTankFillFlag == false and topTankDumpFlag == false then
		status = "OFFLINE"
		end
		if topTankFillFlag == true and topTankDumpFlag == false then
		status = "FILLING"
		end
		if topTankFillFlag == false and topTankDumpFlag == true then
		status = "EMPTYING"
		end
	end

	if device == "backupTank" then
		if backupTankFillFlag == false and backupTankDumpFlag == false then
		status = "OFFLINE"
		end
		if backupTankFillFlag == true and backupTankDumpFlag == false then
		status = "FILLING"
		end
		if backupTankFillFlag == false and backupTankDumpFlag == true then
		status = "EMPTYING"
		end
	end

	if device == "basementGenerator" then
		if basementGeneratorFlag == false then
		status = "OFFLINE"
		end
		if basementGeneratorFlag == true then
		status = "ONLINE"
		end
	end

	if device == "smeltery" then
		if smelteryFlag == false then
		status = "OFFLINE"
		end
		if smelteryFlag == true then
		status = "ONLINE"
		end
	end

	if device == "firstFloorGenerators" then
		if firstFloorGeneratorsFlag == false then
		status = "OFFLINE"
		end
		if firstFloorGeneratorsFlag == true then
		status = "ONLINE"
		end
	end

	if device == "quarryGenerators" then
		if quarryGeneratorsFlag == false then
		status = "OFFLINE"
		end
		if quarryGeneratorsFlag == true then
		status = "ONLINE"
		end
	end

	if device == "networkBridge" then
		if networkBridgeFlag == false then
		status = "OFFLINE"
		end
		if networkBridgeFlag == true then
		status = "ONLINE"
		end
	end

	if device == "playerLava" then
		if playerLavaFlag == false then
		status = "OFFLINE"
		end
		if playerLavaFlag == true then
		status = "ONLINE"
		end
	end

	return status
end

function monitorStatus( deviceName, linenumber ) -- Writes Status to Monitor, uses colors
	local statusIndent = 30 -- Indent for Status

	if 	deviceName == "topTank" then
		monitor.setCursorPos(1,linenumber)
		monitor.write("Top Tank is: ")
		if getStatus(deviceName) == "OFFLINE" then monitor.setTextColor(colors.red) end
		if getStatus(deviceName) == "FILLING" then monitor.setTextColor(colors.yellow) end
		if getStatus(deviceName) == "EMPTYING" then monitor.setTextColor(colors.green) end
		monitor.setCursorPos(statusIndent,linenumber)
		monitor.write(getStatus(deviceName))
	end

	if 	deviceName == "backupTank" then
		monitor.setCursorPos(1,linenumber)
		monitor.write("Backup Tank is: ")
		if getStatus(deviceName) == "OFFLINE" then monitor.setTextColor(colors.red) end
		if getStatus(deviceName) == "FILLING" then monitor.setTextColor(colors.yellow) end
		if getStatus(deviceName) == "EMPTYING" then monitor.setTextColor(colors.green) end
		monitor.setCursorPos(statusIndent,linenumber)
		monitor.write(getStatus(deviceName))
	end

	if 	deviceName == "basementGenerator" then
		monitor.setCursorPos(1,linenumber)
		monitor.write("Basement Generator is: ")
		if getStatus(deviceName) == "OFFLINE" then monitor.setTextColor(colors.red) end
		if getStatus(deviceName) == "ONLINE" then monitor.setTextColor(colors.green) end
		monitor.setCursorPos(statusIndent,linenumber)
		monitor.write(getStatus(deviceName))
	end

	if 	deviceName == "smeltery" then
		monitor.setCursorPos(1,linenumber)
		monitor.write("Smeltery is: ")
		if getStatus(deviceName) == "OFFLINE" then monitor.setTextColor(colors.red) end
		if getStatus(deviceName) == "ONLINE" then monitor.setTextColor(colors.green) end
		monitor.setCursorPos(statusIndent,linenumber)
		monitor.write(getStatus(deviceName))
	end

	if 	deviceName == "firstFloorGenerators" then
		monitor.setCursorPos(1,linenumber)
		monitor.write("Main Generators are: ")
		if getStatus(deviceName) == "OFFLINE" then monitor.setTextColor(colors.red) end
		if getStatus(deviceName) == "ONLINE" then monitor.setTextColor(colors.green) end
		monitor.setCursorPos(statusIndent,linenumber)
		monitor.write(getStatus(deviceName))
	end

	if 	deviceName == "quarryGenerators" then
		monitor.setCursorPos(1,linenumber)
		monitor.write("Quarry Generators are: ")
		if getStatus(deviceName) == "OFFLINE" then monitor.setTextColor(colors.red) end
		if getStatus(deviceName) == "ONLINE" then monitor.setTextColor(colors.green) end
		monitor.setCursorPos(statusIndent,linenumber)
		monitor.write(getStatus(deviceName))
	end

	if 	deviceName == "networkBridge" then
		monitor.setCursorPos(1,linenumber)
		monitor.write("Network Bridge is: ")
		if getStatus(deviceName) == "OFFLINE" then monitor.setTextColor(colors.red) end
		if getStatus(deviceName) == "ONLINE" then monitor.setTextColor(colors.green) end
		monitor.setCursorPos(statusIndent,linenumber)
		monitor.write(getStatus(deviceName))
	end

	if 	deviceName == "playerLava" then
		monitor.setCursorPos(1,linenumber)
		monitor.write("Player Lava is: ")
		if getStatus(deviceName) == "OFFLINE" then monitor.setTextColor(colors.red) end
		if getStatus(deviceName) == "ONLINE" then monitor.setTextColor(colors.green) end
		monitor.setCursorPos(statusIndent,linenumber)
		monitor.write(getStatus(deviceName))
	end

	monitor.setTextColor(monitorDefaultColor) -- Sets color back to normal when done
end

function topTank( command ) -- Top Tank Control Logic

	if command == "fill" then -- We should NEVER have both flags set to true, that would be silly
		if topTankFillFlag == false and topTankDumpFlag == false then -- Off State
		redstone.setBundledOutput(rednetSide, redstone.getBundledOutput(rednetSide)+colors.white)
		topTankFillFlag = true
		topTankDumpFlag = false
		end

		if topTankFillFlag == false and topTankDumpFlag == true then -- Dump State
		redstone.setBundledOutput(rednetSide, redstone.getBundledOutput(rednetSide)+colors.white)
		redstone.setBundledOutput(rednetSide, redstone.getBundledOutput(rednetSide)-colors.orange)
		topTankFillFlag = true
		topTankDumpFlag = false
		end
	end

	if command == "dump" then
		if topTankFillFlag == false and topTankDumpFlag == false then -- Off State
		redstone.setBundledOutput(rednetSide, redstone.getBundledOutput(rednetSide)+colors.orange)
		topTankFillFlag = false
		topTankDumpFlag = true
		end

		if topTankFillFlag == true and topTankDumpFlag == false then -- Fill State
		redstone.setBundledOutput(rednetSide, redstone.getBundledOutput(rednetSide)+colors.orange)
		redstone.setBundledOutput(rednetSide, redstone.getBundledOutput(rednetSide)-colors.white)
		topTankFillFlag = false
		topTankDumpFlag = true
		end
	end

	if command == "off" then
		if topTankFillFlag == true then -- Fill State
		redstone.setBundledOutput(rednetSide, redstone.getBundledOutput(rednetSide)-colors.white)
		topTankFillFlag = false
		end

		if topTankDumpFlag == true then -- Dump State
		redstone.setBundledOutput(rednetSide, redstone.getBundledOutput(rednetSide)-colors.orange)
		topTankDumpFlag = false
		end
	end
end

function backupTank( command ) -- Backup Tank Control Logic

	if command == "fill" then -- We should NEVER have both flags set to true, that would be silly
		if backupTankFillFlag == false and backupTankDumpFlag == false then -- Off State
		redstone.setBundledOutput(rednetSide, redstone.getBundledOutput(rednetSide)+colors.lime)
		backupTankFillFlag = true
		backupTankDumpFlag = false
		end

		if backupTankFillFlag == false and backupTankDumpFlag == true then -- Dump State
		redstone.setBundledOutput(rednetSide, redstone.getBundledOutput(rednetSide)+colors.lime)
		redstone.setBundledOutput(rednetSide, redstone.getBundledOutput(rednetSide)-colors.pink)
		backupTankFillFlag = true
		backupTankDumpFlag = false
		end
	end

	if command == "dump" then
		if backupTankFillFlag == false and backupTankDumpFlag == false then -- Off State
		redstone.setBundledOutput(rednetSide, redstone.getBundledOutput(rednetSide)+colors.pink)
		backupTankFillFlag = false
		backupTankDumpFlag = true
		end

		if backupTankFillFlag == true and backupTankDumpFlag == false then -- Fill State
		redstone.setBundledOutput(rednetSide, redstone.getBundledOutput(rednetSide)+colors.pink)
		redstone.setBundledOutput(rednetSide, redstone.getBundledOutput(rednetSide)-colors.lime)
		backupTankFillFlag = false
		backupTankDumpFlag = true
		end
	end

	if command == "off" then
		if backupTankFillFlag == true then -- Fill State
		redstone.setBundledOutput(rednetSide, redstone.getBundledOutput(rednetSide)-colors.lime)
		backupTankFillFlag = false
		end

		if backupTankDumpFlag == true then -- Dump State
		redstone.setBundledOutput(rednetSide, redstone.getBundledOutput(rednetSide)-colors.pink)
		backupTankDumpFlag = false
		end
	end
end

function basementGenerator( command ) -- Backup Generator Control Logic
	-- ** NOTE!!! This is wired backwards because I'm too lazy to make a inter gate**

	if command == "on" then
		if basementGeneratorFlag == false  then -- Off State
		redstone.setBundledOutput(rednetSide, redstone.getBundledOutput(rednetSide)-colors.lightBlue)
		basementGeneratorFlag = true
		end
	end

	if command == "off" then
		if basementGeneratorFlag == true  then -- On State
		redstone.setBundledOutput(rednetSide, redstone.getBundledOutput(rednetSide)+colors.lightBlue)
		basementGeneratorFlag = false
		end
	end

	if command == "startup" then 
	-- Because the basementGenerator flag is already false, we need to force it to be in the off state
		redstone.setBundledOutput(rednetSide, redstone.getBundledOutput(rednetSide)+colors.lightBlue)
	end
end

function smeltery( command ) -- Smeltery Control Logic

	if command == "on" then
		if smelteryFlag == false  then -- On State
		redstone.setBundledOutput(rednetSide, redstone.getBundledOutput(rednetSide)+colors.magenta)
		smelteryFlag = true
		end
	end

	if command == "off" then
		if smelteryFlag == true  then -- Off State
		redstone.setBundledOutput(rednetSide, redstone.getBundledOutput(rednetSide)-colors.magenta)
		smelteryFlag = false
		end
	end
end

function firstFloorGenerators( command ) -- Smeltery Control Logic

	if command == "on" then
		if firstFloorGeneratorsFlag == false  then -- On State
		redstone.setBundledOutput(rednetSide, redstone.getBundledOutput(rednetSide)+colors.gray)
		firstFloorGeneratorsFlag = true
		end
	end

	if command == "off" then
		if firstFloorGeneratorsFlag == true  then -- Off State
		redstone.setBundledOutput(rednetSide, redstone.getBundledOutput(rednetSide)-colors.gray)
		firstFloorGeneratorsFlag = false
		end
	end
end

function quarryGenerators( command ) -- Smeltery Control Logic

	if command == "on" then
		if quarryGeneratorsFlag == false  then -- Off State
		redstone.setBundledOutput(rednetSide, redstone.getBundledOutput(rednetSide)+colors.cyan)
		quarryGeneratorsFlag = true
		end
	end

	if command == "off" then
		if quarryGeneratorsFlag == true  then -- On State
		redstone.setBundledOutput(rednetSide, redstone.getBundledOutput(rednetSide)-colors.cyan)
		quarryGeneratorsFlag = false
		end
	end
end

function networkBridge( command ) -- Smeltery Control Logic

	if command == "on" then
		if networkBridgeFlag == false  then -- On State
		redstone.setBundledOutput(rednetSide, redstone.getBundledOutput(rednetSide)+colors.lightGray)
		networkBridgeFlag = true
		end
	end

	if command == "off" then
		if networkBridgeFlag == true  then -- Off State
		redstone.setBundledOutput(rednetSide, redstone.getBundledOutput(rednetSide)-colors.lightGray)
		networkBridgeFlag = false
		end
	end
end

function playerLava( command ) -- Smeltery Control Logic

	if command == "on" then
		if playerLavaFlag == false  then -- Off State
		redstone.setBundledOutput(rednetSide, redstone.getBundledOutput(rednetSide)+colors.yellow)
		playerLavaFlag = true
		end
	end

	if command == "off" then
		if playerLavaFlag == true  then -- On State
		redstone.setBundledOutput(rednetSide, redstone.getBundledOutput(rednetSide)-colors.yellow)
		playerLavaFlag = false
		end
	end
end

function monitorRedraw( ... ) -- Status Monitor Display
	monitor.clear()
	monitorStatus("topTank",1)		--(deviceName,lineNumberOnMonitor)
	monitorStatus("backupTank",2)
	monitorStatus("basementGenerator",3)
	monitorStatus("smeltery",4)
	monitorStatus("firstFloorGenerators",5)
	monitorStatus("quarryGenerators",6)
	monitorStatus("networkBridge",7)
	monitorStatus("playerLava",8)

end

function termRedraw( ... ) -- Terminal Display
	term.clear()

	term.setCursorPos(1,1)
	term.write("           Factory Control System v1.0")

	term.setCursorPos(1,2)
	term.write("1     - Main Roof Tank Fill")
	term.setCursorPos(1,3)
	term.write("2     - Main Roof Tank Dump")
	term.setCursorPos(1,4)
	term.write("3     - Main Roof Tank Off")

	term.setCursorPos(1,5)
	term.write("4     - Backup Tank Fill")
	term.setCursorPos(1,6)
	term.write("5     - Backup Tank Dump")
	term.setCursorPos(1,7)
	term.write("6     - Backup Tank Off")

	term.setCursorPos(1,8)
	term.write("7/8   - Basement Generator On/Off")

	term.setCursorPos(1,9)
	term.write("9/10  - Smeltery On/Off")

	term.setCursorPos(1,10)
	term.write("11/12 - Main Generators On/Off")

	term.setCursorPos(1,11)
	term.write("13/14 - Quarry Generators On/Off")

	term.setCursorPos(1,12)
	term.write("15/16 - Connect/Disconnect Netowrk Bridge")

	term.setCursorPos(1,13)
	term.write("17/18 - Player Lava On/Off")


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
	if menuChoice == "1" then topTank("fill") end
	if menuChoice == "2" then topTank("dump") end
	if menuChoice == "3" then topTank("off") end
	if menuChoice == "4" then backupTank("fill") end
	if menuChoice == "5" then backupTank("dump") end
	if menuChoice == "6" then backupTank("off") end
	if menuChoice == "7" then basementGenerator("on") end
	if menuChoice == "8" then basementGenerator("off") end
	if menuChoice == "9" then smeltery("on") end
	if menuChoice == "10" then smeltery("off") end
	if menuChoice == "11" then firstFloorGenerators("on") end
	if menuChoice == "12" then firstFloorGenerators("off") end
	if menuChoice == "13" then quarryGenerators("on") end
	if menuChoice == "14" then quarryGenerators("off") end
	if menuChoice == "15" then networkBridge("on") end
	if menuChoice == "16" then networkBridge("off") end
	if menuChoice == "17" then playerLava("on") end
	if menuChoice == "18" then playerLava("off") end

end


function setStartupState( ... )
	-- All systems are logically off at start, except basementGenerator
	basementGenerator("startup")
	topTank("dump")
	backupTank("fill")
end

function shutdownAll( ... )
	topTank("off")
	backupTank("off")
	basementGenerator("off")
	smeltery("off")
	firstFloorGenerators("off")
	quarryGenerators("off")
	networkBridge("off")
	playerLava("off")
end

function activateAll( ... )
	topTank("dump")
	backupTank("fill")
	basementGenerator("on")
	smeltery("on")
	firstFloorGenerators("on")
	quarryGenerators("on")
	networkBridge("on")
	playerLava("on")
end

function run(	) -- Main Program Logic
setStartupState() --TODO find bug
-- w/ setStartupState disabled, system starts in off state
-- basementGenerator("startup")

	while true do
		monitorRedraw() -- PASSIVE OUTPUT
		termRedraw()	-- ACTIVE INPUT
	end
end

run() --Runs main program