-- This Library is just for PAC3 Integration.
-- You must install PAC3 to make this library works.

PLUGIN.name = "PAC3 Integration"
PLUGIN.author = "Black Tea"
PLUGIN.desc = "More Upgraded, More well organized PAC3 Integration made by Black Tea"
PLUGIN.partData = {}

if (not pac) then
	return
end

nut.util.include("sh_permissions.lua")
nut.util.include("sh_pacoutfit.lua")
nut.util.include("sv_parts.lua")
nut.util.include("cl_parts.lua")
nut.util.include("cl_ragdolls.lua")
