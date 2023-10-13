# sourcemod-nt-deadtools
SourceMod plugin for Neotokyo, for controlling the player dead/alive state. This plugin adds the ability to bring "dead"/downed players back to life during the same round, for custom things like respawning or reviving players.

This base plugin encapsulates the respawning functionality, and aims to provide a clean API for calling these methods from other plugins in a modular fashion, for easier creation of custom game modes.

*([YouTube link](https://www.youtube.com/watch?v=ncVmKLMM7bk&list=PLtWzsvsEHmmDjrtEOYeusjBBF3eWUPD59)) Example of a custom game mode using this plugin, from the ANP 2023 Summer Skirmish showmatch:*
<a target="_blank" href="https://www.youtube.com/watch?v=ncVmKLMM7bk&list=PLtWzsvsEHmmDjrtEOYeusjBBF3eWUPD59"><img alt="YouTube example video thumbnail" src="https://i.ytimg.com/vi/ncVmKLMM7bk/maxresdefault.jpg" width="480" /></a>

## Outline

### For server operators
If you just want to enable the basic respawns feature on your NT server, follow the installation instructions for this base plugin, and then install the desired respawns plugin from the [list of example plugins](#example-plugins-using-this-plugin).

### For plugin developers
Please see the [API reference here](https://github.com/Rainyan/sourcemod-nt-deadtools/blob/main/addons/sourcemod/scripting/include/nt_deadtools/nt_deadtools_natives.inc). If you need more example code, check out [the example plugins list](#example-plugins-using-this-plugin).

## Build requirements
* SourceMod 1.8 or newer <!-- TODO: SM 1.7.3 compiles successfully, but can we support it?? -->
  * **If using SourceMod older than 1.11**: you also need [the DHooks extension](https://forums.alliedmods.net/showpost.php?p=2588686). Download links are at the bottom of the opening post of the AlliedMods thread. Be sure to choose the correct one for your SM version! You don't need this if you're using SourceMod 1.11 or newer.
* [Neotokyo include](https://github.com/softashell/sourcemod-nt-include), version 1.0 or newer

## Installation
* Place [the gamedata file](addons/sourcemod/gamedata/neotokyo/) to the `addons/sourcemod/gamedata/neotokyo` folder (create the "neotokyo" folder if it doesn't exist).
> [!IMPORTANT]  
> Note that the DeadTools include folder structure should look like `<...>/include/nt_deadtools/nt_deadtools_<thing>.inc`, and **not** `<...>/include/nt_deadtools_<thing>.inc`, the incorrect path lacking the "nt_deadtools" folder inside "include".
* Compile [the plugin](addons/sourcemod/scripting), and place the .smx binary file to `addons/sourcemod/plugins`
  * You'll need to add [the include files folder](addons/sourcemod/scripting/include) to your SM compiler's include folder (typically the `include` directory inside your compiler directory), or specify the additional include directory using the `-i <path>` argument syntax.

## Example plugins using this plugin
* [nt_respawns](https://github.com/Rainyan/sourcemod-nt-respawns) — Adds a simple respawn mechanic for the CTG game mode.
* Your plugin here? :smile:
