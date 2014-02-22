print("installing to local machine...")

print("copy /startup...")
shell.run("rm", "/startup")
shell.run("cp", "/disk/startup", "/startup")

print("copy /init...")
shell.run("rm", "/init")
shell.run("cp", "/disk/init", "/init")

print("copy /bb...")
shell.run("rm", "/bb")
shell.run("cp", "/disk/bb", "/bb")
print("install finished")