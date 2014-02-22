-- Builder ant behavior.
-- The ant queen is a digging turtle.
os.loadAPI("/bb/ant/api/ant")

-- Doors: g = glas, x = sand stone, s = stone block (below or south)
-- Open  Closed
-- ggg   ggg
-- g g   gxg
-- g g   gxg
-- gsg   gsg

function checkFree()
  if ant.senseBlock(ant.SLOT_DOOR) then
    return "Door in the way!"
  end
  if ant.senseBlock(ant.SLOT_DOORSTEP) then
    return "Door step in the way!"
  end
  if ant.senseBlock(ant.SLOT_WALL) then
    return "Wall in the way!"
  end
  return nil
end

-- Builds a rectangular room from current position.
-- Block in front must be a closed door (wood planks)
function buildChamber()
  local radius = 2
  -- Open door
  if not ant.senseBlock(ant.SLOT_DOOR) then
    return "No door to open!"
  end
  ant.forward(true)
  if ant.senseBlockUp(ant.SLOT_DOOR) then
    ant.digUp()
  else
    if ant.senseBlockDown(ant.SLOT_DOOR) then
      ant.down(true)
    else
      return "Invalid door!"
    end
  end
  if checkFree() ~= nil then
    return "Way blocked!"
  end
  ant.forward(true)

  -- Build connection
  for i=1, 5 do
    ant.up(true)
    ant.digUp()
    ant.placeUp(ant.SLOT_WALL)
    ant.down()
    ant.digDown()
    ant.placeDown(ant.SLOT_WALL)

    ant.turnLeft()
    if checkFree() ~= nil then
      return "Way blocked!"
    end
    ant.forward(true)
    ant.up(true)
    ant.digUp()
    ant.placeUp(ant.SLOT_WALL)
    ant.down()
    ant.placeUp(ant.SLOT_WALL)
    ant.digDown()
    ant.placeDown(ant.SLOT_WALL)
    ant.back()
    ant.place(ant.SLOT_WALL)

    ant.turnRight()
    ant.turnRight()
    if checkFree() ~= nil then
      return "Way blocked!"
    end
    ant.forward(true)
    ant.up(true)
    ant.digUp()
    ant.placeUp(ant.SLOT_WALL)
    ant.down()
    ant.placeUp(ant.SLOT_WALL)
    ant.digDown()
    ant.placeDown(ant.SLOT_WALL)
    ant.back()
    ant.place(ant.SLOT_WALL)

    ant.turnLeft()
    if checkFree() ~= nil then
      return "Way blocked!"
    end
    ant.forward(true)
  end

  -- move to center
  ant.forward(true)
  ant.forward(true)
  ant.forward(true)

  ant.saveActPos("tmp_chamber_center")
  -- refill glas
  refillSlotWall()

  -- move to lower left corner
  ant.turnTo("w")
  for i=1, radius do
    ant.forward(true)
  end
  ant.turnTo("s")
  for i=1, radius do
    ant.forward(true)
  end
  for i=1, radius do
    ant.down(true)
  end
  -- place a chest to hold our inventory
  ant.turnTo("n")
  ant.forward(true)
  ant.turnTo("s")
  ant.place(ant.SLOT_CHEST)
  for i=1, 16 do
    if (i ~= ant.SLOT_FUEL) then
      ant.drop(i)
    end
  end
  ant.saveActPos("tmp_chamber_chest")

  ant.turnTo("n")
  local width = 2 * radius + 1
  for z=1, width do
    for y=1, width do
      if y > 1 then
        ant.turnTo("e")
        ant.forward(true)
      end
      if math.fmod(y, 2) == 0 then
        ant.turnTo("s")
      else
        ant.turnTo("n")
      end
      if (z == 1) and (y == 1) then
        for x=3, width do
          ant.forward(true)
        end
      else
        for x=2, width do
          ant.forward(true)
        end
      end
    end
    if z < width then
      -- move to left lower corner
      ant.turnTo("w")
      for x=2, width do
        ant.forward(true)
      end
      ant.turnTo("s")
      for x=3, width do
        ant.forward(true)
      end
      if z == 1 then
        ant.up(true)
        ant.forward(true)
      else
        ant.forward(true)
        ant.up(true)
      end
      ant.turnTo("n")
    end
  end
  -- Pick up inventory
  ant.goto("tmp_chamber_chest")
  while ant.suck() do
  end
  ant.forward(true)
  -- Done
  ant.goto("tmp_chamber_center")
end

print(buildChamber())
