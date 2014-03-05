-- Title: TurtleFillZigZag
-- Author: Jesse

itemSlot

print("Program Started")
run() --Runs main program
print("Program Finished")

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
	while true do 
		
		while turtle.detect() == false do
			moveCheckDrop()
		end

		-- Hit top wall
		moveCheckDrop() -- Drop a block
		leftUturn()
			
		while turtle.detect() == false do
			moveCheckDrop()
		end

		-- hit bottom wall
		moveCheckDrop() -- Drop a block
		rightUturn()
		-- Now facing top wall

		if turtle.detectLeft() == true then
			break
		end

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
	print("Checking for Gas...")
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