os.loadAPI("/bb/ant/api/ant")

ant.setPosition("out1", {x = 26, y = -274, z = 72, f = 0})
ant.setPosition("field1", {x = 26, y = -274, z = 70, f = 2})
ant.setPosition("field2", {x = 31, y = -274, z = 70, f = 2})
ant.setPosition("workbench", {x = 25, y = -271, z = 71, f = 0})
ant.setPosition("sortbox", {x = 16, y = -272, z = 70, f = 0})
ant.setPosition("fuelbox", {x = 16, y = -272, z = 72, f = 0})
ant.setPosition("prepark", {x = 21, y = -272, z = 73, f = 2})
ant.setPosition("parkgardener", {x = 21, y = -271, z = 73, f = 2})

function init()
  print("calibrating...")
  ant.calibrate(19, -271, 71, "south")
  print("set home...")
  ant.saveActPos("home")
  print("refueling...")
  ant.refuel()
  print("leaving home...")
  ant.turnLeft()
  ant.turnLeft()
  harvestFields()
end

function refuel()
  print("fuel: "..ant.getFuelLevel())
  if (ant.getFuelLevel() < 6000) then
    print("refueling...")
    ant.goto("fuelbox")
    ant.refuel()
  end
end

function harvestField()
  ant.up()
  for x=1, 4 do
    for y=1, 4 do
     ant.dig()
     ant.suckDown()
     ant.forward()
    end
    ant.back(4)
    ant.turnRight()
    ant.forward()
    ant.turnLeft()
  end
end

function harvestFields()
  refuel()
  ant.goto("out1")
  ant.goto("field1")
  harvestField()
  ant.goto("field2")
  harvestField()
  ant.goto("out1")
  ant.goto("sortbox")
  ant.dropAll()
  ant.goto("prepark")
  ant.goto("parkgardener")
end

init()
