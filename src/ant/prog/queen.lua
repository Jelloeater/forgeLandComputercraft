-- Ant queen behavior.
-- The ant queen is a crafting turtle which gives birth to new turtles.
os.loadAPI("/bb/ant/api/ant")
os.loadAPI("/bb/ant/prog/builder")

-- Global vars
-- Start config
local SLOT_CHILD = 1  -- digger turtle
local SLOT_DISKDRIVE = 2  -- disk drive
local SLOT_DISK = 3  -- floppy disk

local currentAction = nil

--
-- initialize
--
function init()
  if ant.getVar("hive_id") == nil then
    ant.setVar("hive_id", os.computerID())
    print("calibrating...")
    ant.calibrate(0, 0, 0, "north")
    print("set home...")
    ant.saveActPos("home")
    placeCreche()
  else
    buildChamber(1)
  end
end

-- Places a disk drive west and a chest with fuel north.
-- This spot marks the "home" position of all ants since they are born here.
function placeCreche()
  ant.goto("home")
-- Build the birthing chamber for the queen
  ant.turnTo("n")
  ant.dig()
  ant.place(ant.SLOT_DOOR)
  buildChamber()
-- Disk drive with boot program
  ant.turnTo("west")
  ant.place(SLOT_DISKDRIVE)
-- Insert disk
  ant.drop(SLOT_DISK)
-- Chest for fuel
  ant.turnTo("north")
  ant.place(SLOT_CHEST)
-- Chest for unborn childs
  ant.turnTo("south")
  ant.forward()
  ant.saveActPos("creche")
  ant.place(SLOT_CHEST)
end

function placeNewBorn()
  ant.goto("creche")
  ant.turnTo("north")

-- Fill fuel chest to be shure child can start.
  ant.drop(ant.SLOT_FUEL)

  ant.place(SLOT_CHILD)
  peripheral.call("front", "turnOn")
end

init()