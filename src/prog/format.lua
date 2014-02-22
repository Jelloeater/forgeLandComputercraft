print("intializing disk...")

print("copy /startup...")
shell.run("rm", "/disk/startup")
shell.run("cp", "/startup", "/disk/startup")

print("copy /init...")
shell.run("rm", "/disk/init")
shell.run("cp", "/init", "/disk/init")

print("copy /bb/*...")
shell.run("rm", "/disk/bb")
shell.run("cp", "/bb/", "/disk/bb/")

print("format finished")