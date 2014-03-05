-- Title: TurtleFill
-- Author: Jesse

movX = 0
movY = 0
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

	--First Leg (Up)
	xSearch() --How big is X?
	print("X is ".. movX .. " units big")
	turtle.turnLeft()

	--Second Leg (Across)
	ySearch()
	print("Y is ".. movY .. " units big")
	turtle.turnLeft()

	-- ThirdLeg (Down)
	legNoCount()	
	print("Leg NoCount")
	turtle.turnLeft()

	fillLoop()
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

function fillLoop(  )
	while true do 
		if movX < 0 then
			break
		end

		if movY < 0 then
			break
		end

	--Forth Leg (Across)
	yLeg()
	print("yLeg")
	turtle.turnLeft()
	--Firth Leg (Up), round and round we go
	xLeg()
	print("xLeg")
	turtle.turnLeft()
	--we should be back at the start minus at this line
	end
end

function xLeg()
	-- Move forward, drop a block, count down by one
	spacesToMove = 0
	movX = movX - 1
	while spacesToMove < movX do
		moveCheckDrop()
		spacesToMove = spacesToMove + 1
	end
	spacesToMove = 0
end

function yLeg()
	-- Move forward, drop a block, count down by one
	spacesToMove = 0
	movY = movY - 1
	while spacesToMove < movY do
		moveCheckDrop()
		spacesToMove = spacesToMove + 1
	end
	spacesToMove = 0
end

function gotoRightCorner(  )
	backup()
	turtle.turnRight()
	while turtle.detect() == false do
		turtle.forward()
	end
	moveCheckDrop()
end

function backup(  )
	turnAround()
	while turtle.detect() == false do
		turtle.forward()
	end
	turnAround()
end

function turnAround(  )
	turtle.turnLeft()
	turtle.turnLeft()
end

function legNoCount()
	-- Move forward, drop a block, count down by one
	spacesToMove = -1 -- Move one extra block at the end
	while spacesToMove <= movY do
		moveCheckDrop()
		spacesToMove = spacesToMove + 1
	end
	spacesToMove = 0
end

function xSearch()
	while turtle.detect() == false do
		moveCheckDrop()
		movX = movX + 1
	end
end

function ySearch()
	while turtle.detect() == false do
		moveCheckDrop()
		movY = movY + 1
	end
end

print("Program Started")
run() --Runs main program
print("Program Finished")