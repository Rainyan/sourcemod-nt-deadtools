# sourcemod-nt-deadtools
SourceMod base plugin for controlling Neotokyo players' death status. Adds the ability to bring "dead"/downed players back to life.

This plugin encapsulates the respawn code, and aims to provide a clean API for calling these methods from other plugins in a modular fashion.

## Outline

### For server operators
If you just want to enable the respawns on your NT server, follow the installation instructions of this base plugin, and then install the desired respawns plugin from the [list of example plugins](#example-plugins-using-this-plugin).

### For plugin developers
Please see the [API reference here](https://github.com/Rainyan/sourcemod-nt-deadtools/blob/main/addons/sourcemod/scripting/include/nt_deadtools/nt_deadtools_natives.inc). If you need more example code, check out [the example plugins list](#example-plugins-using-this-plugin).

## Build requirements
* SourceMod 1.8 or newer
  * **If using SourceMod older than 1.11**: you also need [the DHooks extension](https://forums.alliedmods.net/showpost.php?p=2588686). Download links are at the bottom of the opening post of the AlliedMods thread. Be sure to choose the correct one for your SM version! You don't need this if you're using SourceMod 1.11 or newer.
* [Neotokyo include](https://github.com/softashell/sourcemod-nt-include), version 1.0 or newer

## Installation
* Place [the gamedata file](addons/sourcemod/gamedata/neotokyo/) to the `addons/sourcemod/gamedata/neotokyo` folder (create the "neotokyo" folder if it doesn't exist).
* Compile [the plugin](addons/sourcemod/scripting), and place the .smx binary file to `addons/sourcemod/plugins`

## Example plugins using this plugin
* [nt_respawns](https://github.com/Rainyan/sourcemod-nt-respawns) — Adds a simple respawn mechanic for the CTG game mode.
