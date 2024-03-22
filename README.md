# Steam Game Server Auto Update
### A Powershell Script for automatically checking steam for game server updates, installing them, and restarting the game server

## How to use:
1) Change the game appID in the ```gameExecuteUpdate.bat``` script, and the ```gameServerUpdate.ps1``` on line 13 to match the game server you are installing and keeping up to date.
2) Change the location of SteamCMD on line 14 in ```gameServerUpdate.ps1```
3) Run the script by right-clicking the file, and click "Run with Powershell"
   - This will automatically install the game server under ```C:\Users\$user\Documents\steamcmd\steamapps\common```
   - A file will be created where the script was run called ```lastUpdateTime.txt```. **Delete this file for now**.
   - When this is complete, the script may pause, just close it out after the install is complete.
4) Get the location of the exe of the game server, and add it to line 19 for ```$exePath```.
5) Add the name of the exe of the game server you will be executing on line 17 for ```$exeName```.
6) Add any commands that you will be using to start the server on line 37 for ```$arguments```
7) After the install is complete, un-comment ```KillProcess``` and ```StartServer``` lines  
   - ```KillProcess``` is on line 48
   - ```StartServer``` is on lines 49 and 101
8) Run the Powershell file again, and it should check for updates, verify install, and start the server.

## How it works:
Simply put, it checks every hour with SteamCMD app info to see if the public branch has been updated since last install/update.  This does not require a developer account or anything fancy, but it is using SteamCMD app_info to check, which sometimes has a delay, and the script will have to attempt to check again. I've only ever seen it fail up to 5 times before getting the information and moving on.

This script will actively be running, with timestamps for each action that happens in the log.  If you would like to modify it to be better, have fun!

#### NOTE: This script is setup to install ARK: Survival Evolved.  I also have this script working to keep my Palworld server up to date, and it works amazingly.  The only caveat is that, as is, you probably shouldn't make this a Task.  

