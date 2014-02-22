-- Usage: broom |<times>|
-- Put an empty bucket into slot 1. Put some fuel in slot 16.
-- Set the positions "source" and "tank" by placing the turtle and "bb/ant/setpos <name>" first.
-- Walks from positions "source" to "tank" carrying any liquid.

os.loadAPI("/bb/ant/api/ant")

local arg ={...}

if (#arg > 1)then
  error("Wrong arguments! Usage bb/ant/setpos <name>")
end

local times = -1
if (#arg > 0)then
  times = arg[1] + 0
end

ant.waitAndRefuel(50)

while (times == -1) or (times > 0) do
  print("Fetching liquid from source " .. ant.str(ant.getPosition("source")) .. "...")
  ant.goto("source")
  ant.place(1)
  print("Placing liquid in tank" .. ant.str(ant.getPosition("source")) .. "...")
  ant.goto("tank")
  ant.place(1)
  if (times ~= -1) then
    times = times - 1
    print("Walks left: " .. times)
  end
end

print("Done.")