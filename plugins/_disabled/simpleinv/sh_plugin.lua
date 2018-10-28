PLUGIN.name = "Simple Inv"
PLUGIN.author = "Cheesenut"
PLUGIN.desc = "Adds a simple inventory type."

nut.util.include("sh_simple_inv.lua")

local INVENTORY_TYPE_ID = "simple"
PLUGIN.INVENTORY_TYPE_ID = INVENTORY_TYPE_ID

function PLUGIN:GetDefaultInventoryType(character)
	return INVENTORY_TYPE_ID
end
