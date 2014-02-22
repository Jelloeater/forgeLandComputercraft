-- Excavates an area using Turtle Teleporters to reach the mining site.
-- Usage bb/ant/house/miner <width> [<up> <height>]
-- Default is mining down to until bedrock is hit.
--
-- Place a turtle like following (top view):
-- .CT
-- D.x
--
-- C: Charge Station
-- D: Chest to drop mined items into
-- T: Turtle Teleporter
-- x: Mining Turtle facing the teleporter
--
-- The turtle will start mining on the other side of the teleporter, mining to the left of the teleporter face.
-- Top view
-- ......
-- .mmmm.
-- .mmmm.
-- .mmmm.
-- Tmmmm.
-- ......

os.loadAPI("/bb/ant/api/ant")

local arg ={...}
local numArgs = #arg

if (arg[1] == "continue") then
  numArgs = numArgs - 1
  for i=1, numArgs do
    arg[i] = arg[i+1]
  end
  ant.goto("teleporter")
  ant.dropAll()
end
if (numArgs ~= 1) and (numArgs ~= 3) then
  error("Wrong arguments! Usage bb/ant/house/miner <width> <y-length> [<up> <height>]")
end
-- make shure we get numbers as first two parameters
local maxX = arg[1] + 0
local down = true
local init = true

if (numArgs == 4) then
  if (arg[2] ~= "up") then
    error("Wrong arguments! Usage bb/ant/house/miner <width> [<up> <height>]")
  end
  down = false
  local maxHeight = arg[3] + 0
  local actHeight = 0
end
local m = peripheral.wrap("front")
local START_FUEL = 2000
local RETURN_FUEL = 1000

function dropInv()
  turtle.turnLeft()
  turtle.forward()
  ant.dropAll()
  turtle.back()
  turtle.turnRight()
end

function returnHome()
  print("returning to teleporter...")
  ant.saveActPos("lastpos")
  if down == true then
    ant.up()
  else
    ant.down()
  end
  ant.goto("teleporter")
  if m.teleport() == false then
    if ant.getFuelLevel() < RETURN_FUEL then
      print("Unexpectedly run out of fuel!")
      ant.waitAndRefuel(RETURN_FUEL)
      if m.teleport() == false then
        error("Teleporter misfunction. Not enough fuel after refueling?")
      end
    else
      error("Teleporter misfunction")
    end
  end
  dropInv()
end

function refill()
  print("refueling...")
  turtle.turnLeft()
  turtle.forward()
  while turtle.getFuelLevel() < START_FUEL do
    print("refueling: " .. turtle.getFuelLevel())
    sleep(1)
  end
  print("back to mining...")
  turtle.back()
  turtle.turnRight()
  if m.teleport() == false then
    error("Teleporter misfunction")
  end
  ant.saveActPos("teleporter")
  -- no "lastpos" after initial teleporter jump.
  if init == false then
    ant.goto("lastpos")
  else
    init = false
  end
end

function done()
  returnHome()
  error("Done.")
end

function isFull()
  for i = 1, 16 do
    if ant.getItemCount(i) == 0 then
      return false
    end
  end
  return true
end

function digForward()
  local digged = ant.dig()
  -- something in the way...
  while ant.forward() == false do
    -- out of fuel. should not happen!
    if ant.getFuelLevel() == 0 then
      print("Unexpectedly run out of fuel!")
      ant.waitAndRefuel(START_FUEL)
    end
    -- unbreakable block = bedrock --> done mining
    if ant.detect() and (digged == false) then
      done()
    end
    -- kill that monster
    ant.dig()
  end
  if isFull() then
    returnHome()
    refill()
  end
end

function digDown()
  local digged = ant.digDown()
  -- something in the way...
  while ant.down() == false do
    if ant.getFuelLevel() == 0 then
      print("Unexpectedly run out of fuel!")
      ant.waitAndRefuel(START_FUEL)
    end
    -- unbreakable block = bedrock --> done mining
    if ant.detect() and (digged == false) then
      done()
    end
    -- kill that monster
    ant.digDown()
  end
  if isFull() then
    returnHome()
    refill()
  end
end

function digUp()
  local digged = ant.digUp()
  -- something in the way...
  while ant.up() == false do
    if ant.getFuelLevel() == 0 then
      print("Unexpectedly run out of fuel!")
      ant.waitAndRefuel(START_FUEL)
    end
    -- unbreakable block = bedrock --> done mining
    if ant.detect() and (digged == false) then
      done()
    end
    -- kill that monster
    ant.digUp()
  end
  if isFull() then
    returnHome()
    refill()
  end
end

function mineLevel()
  cont = false
  for x = 1, maxX do
    for y = 1, maxX-1 do
      digForward()
    end

    if x < maxX then
      if x % 2 ~= 0 then
        ant.turnRight()
      else
        ant.turnLeft()
      end
      digForward()
      if x % 2 ~= 0 then
        ant.turnRight()
      else
        ant.turnLeft()
      end
    end
  end

--  if maxX % 2 == 0 then
--    ant.turnRight()
--  else
--    ant.turnLeft()
--  end
--  for i = 1, maxX do
--    digForward()
--  end
--  if maxX % 2 ~= 0 then
--    ant.turnLeft()
--    for i = 1, maxX-1 do
--      digForward()
--    end
--    ant.turnRight()
--  end
--  if maxX % 2 ~= 0 then
--    ant.turnRight()
--  else
--    ant.turnLeft()
--  end
end

function mine()
  while true do
    mineLevel()
    ant.turnRight()
    if maxX % 2 ~= 0 then
      ant.turnRight()
    end
    if ant.getFuelLevel() < RETURN_FUEL then
      print("returning for refueling...")
      returnHome()
      refill()
      print("continuing mining...")
    end
    if down == true then
      digDown()
    else
      if actHeight >= maxHeight then
        done()
      end
      digUp()
      actHeight = actHeight + 1
    end
  end
end


ant.waitAndRefuel(1)
refill()
ant.turnRight()
--digForward()
mine()
print("done.")
