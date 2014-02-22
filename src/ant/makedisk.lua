print("installing turtle files to disk...")

print("copy /startup...")
shell.run("rm", "/disk/startup")
shell.run("cp", "/bb/turtledisk/startup", "/disk/startup")

print("copy /turtle_startup...")
shell.run("rm", "/disk/turtle_startup")
shell.run("cp", "/bb/turtledisk/turtle_startup", "/disk/turtle_startup")

print("copy /api...")
shell.run("rm", "/disk/api")
shell.run("cp", "/bb/turtledisk/api", "/disk/api")

print("copy /prog...")
shell.run("rm", "/disk/prog")
shell.run("cp", "/bb/turtledisk/prog", "/disk/prog")

print("install finished")