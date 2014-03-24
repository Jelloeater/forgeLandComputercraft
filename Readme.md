If you go on ANY computer (on forgeLand) and type "init" it will pull the code from the repo. The boot strap file is located in ComputerCraft1.58.zip\assets\computercraft\lua\rom\programs in the mods folder on the server.

To pull latest code down, re-run init

Neat API's you can use
- jsonV2 (for neat JSON stuff)
- LANClient & router (for REAL networking) from http://pastebin.com/u/Tatantyler and https://github.com/Tatantyler

**NOTE** *All code goes in the usr folder, then in your personal folder. /src is strictly for API's and other global stuff, as it gets mapped to /bb/whatever*

Awesome Code from DerTroglodyt
http://www.computercraft.info/forums2/index.php?/topic/5134-recursive-download-from-bitbucket-repository/

ONLY WORKS WITH ComputerCraft 1.4 and higher!

This will download the two files necessary for the automated update and execute them.
You can edit the file "/bb/prog/bitbucket" to use your own BitBucket repository instead of mine.
Any time after this initial install just type "init" to download the latest version of your BitBucket repository.

For use of Lua syntax highlighting in Netbeans try "Netbeans luaSupport - plugin" (not associated)
http://plugins.netbeans.org/plugin/29607