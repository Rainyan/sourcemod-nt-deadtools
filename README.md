# sourcemod-nt-deadtools
SourceMod base plugin for controlling Neotokyo players' death status. Adds the ability to bring "dead"/downed players back to life.

This plugin encapsulates the respawn code, and aims to provide a clean API for calling these methods from other plugins in a modular fashion.

## For server operators
If you just want to enable the respawns on your NT server, follow the installation instructions of this base plugin, and then install the desired respawns plugin from the list of example plugins.

## For plugin developers
Please see the [API reference here](https://github.com/Rainyan/sourcemod-nt-deadtools/blob/main/addons/sourcemod/scripting/include/nt_deadtools/nt_deadtools_natives.inc). If you need more example code, check out the example plugins list.

## Example plugins using this plugin
* [nt_respawns](https://github.com/Rainyan/sourcemod-nt-respawns) — Adds a simple respawn mechanic for the CTG game mode.
