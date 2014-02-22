-- Copy all needed files to the local hard drive.
print("installing to local machine...")

print("copy /startup...")
shell.run("rm", "/startup")
shell.run("cp", "/disk/turtle_startup", "/startup")

print("copy /api...")
shell.run("rm", "/api")
shell.run("cp", "/disk/api", "/api")

print("copy /prog...")
shell.run("rm", "/prog")
shell.run("cp", "/disk/prog", "/prog")
