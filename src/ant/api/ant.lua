-- Duplicate of the turtle API to not mix up turtle and ant use. ONLY use ant API!
os.loadAPI("/bb/ant/api/serial")

-- Global vars
local pos = {x = 0, y = 0, z = 0, f = 0}
local f = {"south", "west", "north", "east"}
local positions = nil
local vars = nil

SLOT_TRASH = 1
SLOT_DOORSTEP = 4 -- sandstone
SLOT_DOOR = 8     -- wood planks = closed doors
SLOT_WALL = 12    -- glas
SLOT_CHEST = 15   -- chest
SLOT_FUEL = 16    -- coal

--
-- initialize
--
function init()
  positions = getPositions()
  pos = getPosition("current")
  vars = getVars()
end

--
-- Helper functions
--

function str(var)
  if (var == nil) then
    return "<nil>"
  else
    if (type(var) == "table") then
      local tmp = "("
      for k,v in pairs(var) do
        tmp = tmp .. k .. ": " .. str(v) .. ", "
      end
      tmp = tmp.sub(1, -3) .. ")"
      return tmp
    else
      return ""..var
    end
  end
end

function toString()
  return "x: "..str(pos.x)..", y: "..str(pos.y)..", z: "..str(pos.z).." f: "..str(f[pos.f + 1]).." ("..str(pos.f)..")"
end

function getDirectionName(direction)
  return f[direction + 1]
end

function getDirection(directionName)
  if directionName == nil then
    error("Illegal argument: DirectionName is nil.")
  end
  local d = 0
  if directionName == "south" or directionName == "s" then
    d = 0
  elseif directionName == "west" or directionName == "w"  then
    d = 1
  elseif directionName == "north" or directionName == "n"  then
    d = 2
  elseif directionName == "east" or directionName == "e"  then
    d = 3
  else
    error("Unknown direction <"..directionName..">")
  end
  return d
end

function checkFuel()
  if turtle.getFuelLevel() < 5 then
    print("refueling...")
    if turtle.getItemCount(SLOT_FUEL) == 0 then
      error("Out of fuel!")
    else
      turtle.refuel(1)
    end
  end
end

function waitAndRefuel(minFuel)
  print("Waiting for fuel in slot " .. SLOT_FUEL .. "...")
  while (turtle.getFuelLevel() < minFuel) do
    while (turtle.getItemCount(SLOT_FUEL) == 0) do
      sleep(0.1)
    end
    if ant.refuel() == false then
      local fnum = turtle.getItemCount(SLOT_FUEL)
      ant.drop(SLOT_FUEL, fnum)
      error("Wrong fuel type!")
    end
    print("Need more fuel.")
  end
end

--
-- Duplicate turtle API to not mix up turtle and ant use. ONLY use ant API!
--
function craft()
  return turtle.craft()
end

function dig()
  turtle.select(SLOT_TRASH)
  return turtle.dig()
end

function digUp()
  turtle.select(SLOT_TRASH)
  return turtle.digUp()
end

function digDown()
  turtle.select(SLOT_TRASH)
  return turtle.digDown()
end

function forward(digToMove, steps)
  if (steps == nil) then
    return _forward(digToMove)
  else
    for i=1, steps do
      if _forward(digToMove) == false then
        return false
      end
    end
    return true
  end
end

function _goForward()
  -- something in the way...
  while turtle.forward() == false do
    -- out of fuel. should not happen!
    if getFuelLevel() == 0 then
      print("Unexpectedly run out of fuel!")
      waitAndRefuel(START_FUEL)
    end
    -- block in the way
    if detect() then
      print("Forward movement blocked. Block in the way.")
      return false
    end
    -- wait for monster to move or die
    turtle.attack()
    sleep(0.5)
  end
  return true
end

function _digForward()
  local digged = dig()
  -- something in the way...
  while turtle.forward() == false do
    -- out of fuel. should not happen!
    if getFuelLevel() == 0 then
      print("Unexpectedly run out of fuel!")
      waitAndRefuel(START_FUEL)
    end
    -- unbreakable block = bedrock --> done mining
    if detect() and (digged == false) then
      print("Forward movement blocked. Can't break block.")
      return false
    end
    -- wait for monster to move or die
    turtle.attack()
    sleep(0.5)
  end
  return true
end

function _forward(digToMove)
  checkFuel()
  local success = false
  if digToMove then
    success = _digForward()
  else
    success = _goForward()
  end
  if success then
--    print("Moved forward facing: " .. str(pos.f).. " " .. str(getDirectionName(pos.f)))
    if pos.f == 0 then
      pos.y = pos.y + 1
    elseif pos.f == 1 then
      pos.x = pos.x - 1
    elseif pos.f == 2 then
      pos.y = pos.y - 1
    elseif pos.f == 3 then
      pos.x = pos.x + 1
    end
    saveActPos("current")
    return true
  else
    return false
  end
end

function back(steps)
  if (steps == nil) then
    return _back()
  else
    for i=1, steps do
      if _back() == false then
        return false
      end
    end
    return true
  end
end

function _goBack()
  -- something in the way...
  while turtle.back() == false do
    -- out of fuel. should not happen!
    if getFuelLevel() == 0 then
      print("Unexpectedly run out of fuel!")
      waitAndRefuel(START_FUEL)
    end
    -- block in the way
    turtle.turnLeft()
    turtle.turnLeft()
    local blocked = detect()
    turtle.turnLeft()
    turtle.turnLeft()
    if blocked then
      print("Forward movement blocked. Block in the way.")
      return false
    end
    -- wait for monster to move
    sleep(1)
  end
  return true
end

function _back()
  checkFuel()
  if _goBack() then
--    print("Moved back facing: " .. pos.f .. " " .. getDirectionName(pos.f))
    if pos.f == 0 then
      pos.y = pos.y - 1
    elseif pos.f == 1 then
      pos.x = pos.x + 1
    elseif pos.f == 2 then
      pos.y = pos.y + 1
    elseif pos.f == 3 then
      pos.x = pos.x - 1
    end
    saveActPos("current")
    return true
  else
    return false
  end
end

function _goUp()
  -- something in the way...
  while turtle.up() == false do
    -- out of fuel. should not happen!
    if getFuelLevel() == 0 then
      print("Unexpectedly run out of fuel!")
      waitAndRefuel(START_FUEL)
    end
    -- block in the way
    if detectUp() then
      print("Upward movement blocked. Block in the way.")
      return false
    end
    -- wait for monster to move or die
    turtle.attack()
    sleep(0.5)
  end
  return true
end

function up(digToMove)
  checkFuel()
  if digToMove then
    if digUp() == false then
      print("Upward movement blocked. Can't break block.")
      return false
    end
  end
  if _goUp() then
    pos.z = pos.z + 1
    saveActPos("current")
    return true
  else
    return false
  end
end

function _goDown()
  -- something in the way...
  while turtle.down() == false do
    -- out of fuel. should not happen!
    if getFuelLevel() == 0 then
      print("Unexpectedly run out of fuel!")
      waitAndRefuel(START_FUEL)
    end
    -- block in the way
    if detectDown() then
      print("Downward movement blocked. Block in the way.")
      return false
    end
    -- wait for monster to move or die
    turtle.attack()
    sleep(0.5)
  end
  return true
end

function down(digToMove)
  checkFuel()
  if digToMove then
    if digDown() == false then
      print("Downward movement blocked. Can't break block.")
      return false
    end
  end
  if _goDown() then
    pos.z = pos.z - 1
    saveActPos("current")
    return true
  else
    print("Downward movement blocked.")
    return false
  end
end

function turnLeft()
  turtle.turnLeft()
  pos.f = pos.f - 1
  if pos.f < 0 then
    pos.f = 3
  end
  saveActPos("current")
end

function turnRight()
  turtle.turnRight()
  pos.f = pos.f + 1
  if pos.f > 3 then
    pos.f = 0
  end
  saveActPos("current")
end

function select(slotNum)
  return turtle.select(slotNum)
end

function getItemCount(slotNum)
  return turtle.getItemCount(slotNum)
end

function getItemSpace(slotNum)
  return turtle.getItemSpace(slotNum)
end

function attack()
  return turtle.attack()
end

function attackUp()
  return turtle.attackUp()
end

function attackDown()
  return turtle.attackDown()
end

function place(slotNum, signText)
  if (slotNum ~= nil) then
    turtle.select(slotNum)
  end
  if signText == nil then
    return turtle.place()
  else
    return turtle.place(signText)
  end
end

function placeUp(slotNum)
  if (slotNum ~= nil) then
    turtle.select(slotNum)
  end
  return turtle.placeUp()
end

function placeDown(slotNum)
  if (slotNum ~= nil) then
    turtle.select(slotNum)
  end
  return turtle.placeDown()
end

function detect()
  return turtle.detect()
end

function detectUp()
  return turtle.detectUp()
end

function detectDown()
  return turtle.detectDown()
end

function compare()
  return turtle.compare()
end

function compareUp()
  return turtle.compareUp()
end

function compareDown()
  return turtle.compareDown()
end

function compareTo(slotNum)
  if slotNum == nil then
    return turtle.compareTo()
  else
    return turtle.compareTo(slotNum)
  end
end

function dropAll()
  for i=1, 15 do
    turtle.select(i)
    turtle.drop()
  end
end

function drop(slotNum, count)
  turtle.select(slotNum)
  if count == nil then
    return turtle.drop()
  else
    return turtle.drop(count)
  end
end

function dropUp(slotNum, count)
  turtle.select(slotNum)
  if count == nil then
    return turtle.dropUp()
  else
    return turtle.dropUp(count)
  end
end

function dropDown(slotNum, count)
  turtle.select(slotNum)
  if count == nil then
    return turtle.dropDown()
  else
    return turtle.dropDown(count)
  end
end

function suck(slotNum)
  if slotNum ~= nil then
    turtle.select(slotNum)
  end
  return turtle.suck()
end

function suckUp(slotNum)
  if slotNum ~= nil then
    turtle.select(slotNum)
  end
  return turtle.suckUp()
end

function suckDown(slotNum)
  if slotNum ~= nil then
    turtle.select(slotNum)
  end
  turtle.suckDown()
end

function refuel(quantity)
  turtle.select(SLOT_FUEL)
  ant.suck()
  if quantity == nil then
    return turtle.refuel()
  else
    return turtle.refuel(quantity)
  end
end

function getFuelLevel()
  return turtle.getFuelLevel()
end

function transferTo(slot, quantity)
  turtle.transferTo(slot, quantity)
end

--
-- New ant API functions
--

function distanceTo(target)
  local r = (pos.x - target.x) * (pos.x - target.x)
      + (pos.y - target.y) * (pos.y - target.y)
      + (pos.z - target.z) * (pos.z - target.z)
  return math.sqrt(r)
end

function calibrate(xPos, yPos, zPos, directionName)
  pos.x = xPos
  pos.y = yPos
  pos.z = zPos
  pos.f = getDirection(directionName)
  saveActPos("current")
end

function turnTo(directionName)
  local d = getDirection(directionName)
  while pos.f ~= d do
    local diff = pos.f - d
    if ((diff == 1) or (diff == -3)) then
      turnLeft()
    else
      turnRight()
    end
  end
  saveActPos("current")
end

function setPosition(name, position)
  if position == nil then
    error("Invalid argument: Position may not be nil!")
  end
--  print("X: " .. position.x .. "!")
  local p = {}
  p["x"] = position.x
  p["y"] = position.y
  p["z"] = position.z
  p["f"] = position.f
  positions[name] = p
  serial.varToFile("turtle_positions", positions)
end

function getPosition(name)
  return positions[name]
end

function getPositions()
  if positions == nil then
    positions = serial.varFromFile("turtle_positions", positions)
    if positions == nil then
      positions = {current = {x = 0, y = 0, z = 0, f = 0}}
    end
  end
  return positions
end

function saveActPos(name)
  setPosition(name, pos)
end

function setVar(name, value)
  if value == nil then
    error("Invalid argument: Value may not be nil!")
  end
--  print(name .. ": " .. value .. "!")
  vars[name] = value
  serial.varToFile("turtle_vars", vars)
end

function getVar(name)
  return vars[name]
end

function getVars()
  if vars == nil then
    vars = serial.varFromFile("turtle_vars", vars)
    if vars == nil then
      vars = {}
    end
  end
  return vars
end

function samePos(pos1)
  if (pos1.x == pos.x)
    and (pos1.y == pos.y)
    and (pos1.z == pos.z)
    and (pos1.f == pos.f)
      then
    return true
  end
  return false
end

function _goto(target)
  if pos.x < target.x then
    turnTo("east")
    while pos.x < target.x do
      if forward() == false then
        --error("Path blocked.")
        return false
      end
    end
  end
  if pos.x > target.x then
    turnTo("west")
    while pos.x > target.x do
      if forward() == false then
        --error("Path blocked.")
        return false
      end
    end
  end
  if pos.y < target.y then
    turnTo("south")
    while pos.y < target.y do
      if forward() == false then
        --error("Path blocked.")
        return false
      end
    end
  end
  if pos.y > target.y then
    turnTo("north")
    while pos.y > target.y do
      if forward() == false then
        --error("Path blocked.")
        return false
      end
    end
  end
  while pos.z < target.z do
    if up() == false then
      --error("Path blocked.")
      return false
    end
  end
  while pos.z > target.z do
    if down() == false then
      --error("Path blocked.")
      return false
    end
  end
end

function _findNewWay()
  if up() == false then
    error("Path blocked.")
  end
end

function goto(positionName)
  local target = getPosition(positionName)
  if target == nil then
    error("Position '" .. positionName .. "' not found!")
  end

  local maxR = distanceTo(target)
  local tries = 1
  while (_goto(target) == false) and (tries < maxR) do
    tries = tries + 1
    _findNewWay()
  end

  -- Destination coordinates reached. Turn to target direction.
  turnTo(getDirectionName(target.f))

  -- Just to be shure...
  if (pos.x == target.x) and (pos.y == target.y) and (pos.z == target.z) then
    return true
  end

  return false
end

function senseBlock(slotNum)
  turtle.select(slotNum)
  return turtle.compare()
end

function senseBlockUp(slotNum)
  turtle.select(slotNum)
  return turtle.compareUp()
end

function senseBlockDown(slotNum)
  turtle.select(slotNum)
  return turtle.compareDown()
end

init()
