--Usage: bb/ant/setpos <name> <x> <y> <z> <direction>
-- Saves the position under this name.

os.loadAPI("/bb/ant/api/ant")

local arg ={...}

if (#arg ~= 5) then
  error("Wrong arguments! Usage bb/ant/setpos <name> <x> <y> <z> <direction>")
end

ant.calibrate(arg[2], arg[3], arg[4], arg[5])
ant.saveActPos(arg[1])