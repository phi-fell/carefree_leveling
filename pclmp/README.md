# Phi's Carefree Leveling Multiplayer
Optimal Vanilla Leveling for TES3MP 0.8.1

## Differences from the OpenMW version
There's no status menu. For comprehensive info about skill ups and attribute points use the chat command `/pclmp`, or for a more concisely formatted version use `/pcl`

Honestly you don't need it as much because TES3MP exposes the ability for scripts to modify attribute multipliers, so those are correct now, unlike in the OpenMW version. (though there isn't a way to tell apart a x0 from a x1 multiplier so you'll need to use the chat command for that)

## Installation
 - move this folder to `server/scripts/custom` so that the path to `main.lua` is `server/scripts/custom/pclmp/main.lua`
  - in `server/scripts/customScripts.lua` add the following:
  ```
  require("custom/pclmp/main")
  ```
  - Don't forget to edit the settings in main.lua if needed!

## Settings
Same settings as the main mod (except status UI) can be found near the top of the main.lua script.  Edit the script before use.