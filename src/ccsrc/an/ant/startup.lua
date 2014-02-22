-- This startup script resides on the disk drive of the turtle creation point.
-- On placing a turtle next to this drive and powering on the turtle this startup
-- overrides the startup of the turtle if any.
-- It simply starts the install script which installs all needed files to the local
-- hard drive of the turtle.
shell.run("/disk/prog/install")
shell.run("/prog/boot")