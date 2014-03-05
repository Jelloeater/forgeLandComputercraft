-- Title: TurtleFillZigZag
-- Author: Jesse

itemSlot = 1

function run() --Main program
	setItemSlot(1)

	checkGasLevel()

	if turtle.detectDown() == true then
		turtle.up()
	end
	print("Going up")

	gotoRightCorner()
	print("Going to right corner")
	moveCheckDrop() -- Drop a block in the corner

	turtle.turnLeft()

	fillLoop()
end

function fillLoop(  )
	local fillDistance = 0
	local spacesMoved = 0

	while turtle.detect() == false do -- Search for top wall
			moveCheckDrop()
			fillDistance = fillDistance + 1
		end

	fillDistance = fillDistance - 1 -- Take 1 off the top

	while true do 
		print("Going Up")
		countSteps(fillDistance)
		print ("Hit Top Wall")
		-- Hit top wall
		
		moveCheckDrop() -- Drop a block
		checkIfAtEnd() -- Might be at top left corner
		leftUturn()

		print("Going Down")
		countSteps(fillDistance)
		print("Hit Bottom Wall")

		-- hit bottom wall
		moveCheckDrop() -- Drop a block
		rightUturn()
		-- Now at bottom facing top wall

	end
end

function checkIfAtEnd(  )
	turtle.turnLeft()
		if turtle.detect() == true then -- Should trigger at end
			os.shutdown() -- STOP THE PROGRAM
		end
	turtle.turnRight()
end

function countSteps( numberToMove )
	for i=1,numberToMove,1 do
		moveCheckDrop()
	end
	
end

function leftUturn(  )
	turtle.turnLeft()
	moveCheckDrop()
	turtle.turnLeft()
end

function rightUturn(  )
	turtle.turnRight()
	moveCheckDrop()
	turtle.turnRight()
end

function moveCheckDrop(  )
	checkGasLevel()
	
	turtle.forward()

	checkInventory()

	turtle.placeDown() --Drops block
end

function checkInventory(  )
	if isSlotEmpty() == true then
		print("Out of items, searching...")
		while searchForItems() == true do -- Are we out of items?
			os.sleep(3) -- wait 3 seconds
			searchForItems()
			print("Still got nothing...")
		end
	end
end

function searchForItems(  )
	-- Look for next full slot, starts at 1
	local outOfItemsFlag = false

	for i=1,15,1 do
		setItemSlot(i)

		if isSlotEmpty() == false then
			break
		end

		if i == 15 and isSlotEmpty() == true then
			outOfItemsFlag = true
		end
	end
	return outOfItemsFlag
end

function getItemSlot(  )
	return itemSlot
end

function setItemSlot( slotSel )
	if slotSel >=1 and slotSel <=16 then
	itemSlot = slotSel
	turtle.select(slotSel)
else
	print("ERROR: Invalid Slot Selection")
	end
end

function isSlotEmpty(  )
	local slotEmptyFlag = false

	if turtle.getItemCount(getItemSlot()) == 0 then
		slotEmptyFlag = true
	else
		slotEmptyFlag = false
	end

	return slotEmptyFlag
end

function checkGasLevel(  )
	if isOutOfGas() == true then
		print ("Waiting for fuel in Slot 16")
		local tempSlotNumber = getItemSlot()

		setItemSlot(16)
		while isOutOfGas() == true do -- YAY recrusion
			if turtle.refuel() == true then
				print("YAY FUEL!")
				break
			end
			os.sleep(3) -- Wait 3 seconds
			print("Still no gas...")
			isOutOfGas() -- Check the gas level
		end
		setItemSlot(tempSlotNumber)
	end
end

function isOutOfGas(  )
	if turtle.getFuelLevel() == 0 then
		outOfGasFlag = true
	else
		outOfGasFlag = false
	end
	return outOfGasFlag
end

function gotoRightCorner(  )
	turnAround()
	while turtle.detect() == false do
		turtle.forward()
	end
	turnAround()

	turtle.turnRight()
	while turtle.detect() == false do
		turtle.forward()
	end
end

function turnAround(  )
	turtle.turnRight()
	turtle.turnRight()
end

print("Program Started")
run() --Runs main program
os.shutdown()