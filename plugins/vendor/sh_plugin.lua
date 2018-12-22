PLUGIN.name = "Vendors"
PLUGIN.author = "Chessnut"
PLUGIN.desc = "Adds NPC vendors that can sell things."

if (SERVER) then
	AddCSLuaFile("cl_editor.lua")
end

nut.util.include("sv_logging.lua")
nut.util.include("sh_enums.lua")
nut.util.include("sv_networking.lua")
nut.util.include("cl_networking.lua")
nut.util.include("sv_data.lua")
nut.util.include("sv_hooks.lua")
nut.util.include("cl_hooks.lua")
