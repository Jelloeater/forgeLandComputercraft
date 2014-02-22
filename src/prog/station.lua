sides = {"left", "right", "top", "bottom", "front", "back"}
destination = {
  spawn = {name = "Spawn", boarding = {b1, b2}, switchOn = {colors.lightGray, colors.lightBlue, colors.magenta, colors.yellow}
      , switchOff = {}}
  , turm = {name=   "Turm des Troglodyten", boarding = {b1, b2}, switchOn = {colors.lightBlue, colors.magenta, colors.yellow}
      , switchOff = {colors.lightGray}}
  , arboretum = {name = "Arboretum / Mine", boarding = {b1, b3}, switchOn = {colors.red, colors.lightBlue}
      , switchOff = {colors.magenta}}
  , labor = {name = "Labor des Troglodyten", boarding = {b1, b3}, switchOn = {}
      , switchOff = {colors.lightBlue, colors.pink, colors.orange, colors.magenta, colors.red}}
  , venedig = {name = "Venedig", boarding = {b1, b3}, switchOn = {colors.orange, colors.green}
      , switchOff = {colors.lightBlue, colors.pink, colors.magenta, colors.red}}
  , moritzburg = {name = "Moritzburg", boarding = {b1, b3}, switchOn = {colors.orange}
      , switchOff = {colors.lightBlue, colors.pink, colors.magenta, colors.red, colors.green, colors.blue}}
  , zeppelin = {name = "Zeppelin", boarding = {b1, b2}, switchOn = {colors.blue, colors.magenta}
      , switchOff = {colors.yellow, colors.lime, colors.cyan}}
  , zeerix = {name = "Zeerix", boarding = {b1, b2}, switchOn = {colors.blue, colors.magenta, colors.cyan, colors.gray}
      , switchOff = {colors.yellow, colors.lime}}
  , herzhaus = {name = "Herzhaus", boarding = {b1, b2}, switchOn = {colors.blue, colors.magenta, colors.cyan}
      , switchOff = {colors.yellow, colors.lime, colors.gray}}
}
dest = ""

-- Find the side on which a modem is present.
function getSide()
  for key, side in pairs(sides) do
    if (peripheral.isPresent(side) and (peripheral.getType(side) == "modem")) then
      return side
    end
  end
  return nil
end

function init()
  rs.setBundledOutput("back", 0xffff)
  rs.setBundledOutput("back", 0)
end

function switch(color, state)
  c = rs.getBundledOutput("back")
  print(color..": "..tostring(state).." "..c)
  if state then
    c = bit.bor(c, color)
  else
    c = bit.band(c, bit.bnot(color))
  end
  print(c)
  rs.setBundledOutput("back", c)
end

function switchAll(dest)
  for i=1, #dest.switchOn do
    switch(dest.switchOn[i], true)
  end
  for i=1, #dest.switchOff do
    switch(dest.switchOff[i], false)
  end
end

function signal(color)
  c = rs.getBundledInput("bottom")
  return (bit.band(c, color) ~= 0)
end

function isIncoming()
  return signal(colors.black)
end

function isLeaving()
  return signal(colors.white)
end

function isRefilling()
  return signal(colors.magenta)
end

function printDest(clientId)
  monSend("CLS", clientId)
  monSend("Nächster Halt: ", clientId)
  monSend(dest.name, clientId)
end

function monSend(message, clientId)
  if clientId then
    print(clientId.." >> "..message)
    rednet.send(clientId, message)
  else
    for i, client in pairs(clients) do
      print(client.." >> "..message)
      rednet.send(client, message)
    end
  end
end

-- Initialize switches
init()
dest = destination.turm
switchAll(dest)

-- Eventloop
clients = {}
rednet.open(getSide(2))
while true do
  event, arg1, arg2 = os.pullEvent()
  if event == "rednet_message" then
    if arg2 == "displayclient" then
      table.remove(clients, arg1)
      table.insert(clients, arg1, arg1)
      rednet.send(arg1, "connection accepted")
      print("Client connected: "..arg1)
      printDest(arg1)
    elseif arg2 == "displayclient_disconnect" then
      print("Client disonnect: "..arg1)
      table.remove(clients, arg1)
    end
  elseif event == "char" then
    if arg1 == "q" or arg1 == "Q" then
      break
    end
  end
end
monSend("SERVER_SHUTDOWN")
rednet.close(getSide())