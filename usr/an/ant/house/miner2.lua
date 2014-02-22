-- Excavates an area.
-- Usage bb/ant/house/miner <width> [<up> <height>]
-- Default is mining down to until bedrock is hit.
--
-- Place a turtle like following (top view):
-- .C
-- Dx
--
-- C: Charge Station
-- D: Chest to drop mined items into
-- x: Mining Turtle facing the chest
--
-- The turtle will start mining to the left of the chest.
-- Top view
-- .C....
-- Dmmmm.
-- .mmmm.
-- .mmmm.
-- .mmmm.
-- ......

os.loadAPI("/bb/ant/api/ant")
os.loadAPI("/bb/ant/api/serial")

local arg ={...}
local numArgs = #arg
local m = peripheral.wrap("front")
local START_FUEL = 2000
local RETURN_FUEL = 1000

function recharge()
  while turtle.getFuelLevel() < START_FUEL do
    print("refueling: " .. turtle.getFuelLevel())
    sleep(1)
  end
end

function returnHome()
  print("returning to chest...")
  ant.saveActPos("lastpos")
  if down == true then
    ant.up()
  else
    ant.down()
  end
  ant.goto("chest")
  ant.dropAll()
  recharge()
  ant.goto("lastpos")
end

if (arg[1] == "continue") then
  numArgs = numArgs - 1
  for i=1, numArgs do
    arg[i] = arg[i+1]
  end
  returnHome()
end
if (numArgs ~= 1) and (numArgs ~= 3) then
  error("Wrong arguments! Usage bb/ant/house/miner2 <width> [<up> <height>]")
end
-- make shure we get numbers as first two parameters
local maxX = arg[1] + 0
local down = true

if (numArgs == 4) then
  if (arg[2] ~= "up") then
    error("Wrong arguments! Usage bb/ant/house/miner2 <width> [<up> <height>]")
  end
  down = false
  local maxHeight = arg[3] + 0
  local actHeight = 0
end

function done()
  print("We're done here...")
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
  if ant.forward(true) == false then
    -- unbreakable block = bedrock --> done mining
    done()
  end
  if isFull() then
    returnHome()
  end
end

function digDown()
  if ant.down(true) == false then
    -- unbreakable block = bedrock --> done mining
    done()
  end
  if isFull() then
    returnHome()
  end
end

function digUp()
  if ant.up(true) == false then
    -- unbreakable block = bedrock --> done mining
    done()
  end
  if isFull() then
    returnHome()
  end
end

function mineLevel()
  cont = false
  for x = 1, maxX do
    for y = 1, maxX-1 do
      digForward()
      if ant.getFuelLevel() < RETURN_FUEL then
        print("returning for refueling...")
        returnHome()
        print("continuing mining...")
      end
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


ant.saveActPos("chest")
--command to execute on reboot
local reboot = "bb/ant/house/miner2 continue " .. maxX
serial.varToFile("reboot_cmd", reboot)

recharge()
ant.turnRight()
ant.turnRight()

-- In case we are restarting after a crash: find the bottom / top
if down == true then
  while ant.down() do
  end
  digDown()
else
  while ant.up() do
  end
  digUp()
end

mine()
print("done.")
