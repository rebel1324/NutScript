PLUGIN.name = "Grid Inventory"
PLUGIN.author = "Cheesenut"
PLUGIN.desc = "Inventory system where items have a size and fit in a grid."

local INVENTORY_TYPE_ID = "grid"
PLUGIN.INVENTORY_TYPE_ID = INVENTORY_TYPE_ID

nut.util.include("sh_grid_inv.lua")
nut.util.include("sv_transfer.lua")
nut.util.include("sv_access_rules.lua")

function PLUGIN:GetDefaultInventoryType(character)
	return INVENTORY_TYPE_ID
end

if (SERVER) then
	-- Called when item has been dragged on top of target (also an item).
	function PLUGIN:ItemCombine(client, item, target)
		if (target.onCombine) then
			if (target:call("onCombine", client, nil, item)) then -- when other items dragged into the item.
				return
			end
		end

		if (item.onCombineTo) then
			if (item and item:call("onCombineTo", client, nil, target)) then -- when you drag the item on something
				return
			end
		end
	end

	-- Called when an item has been dragged out of its inventory.
	function PLUGIN:ItemDraggedOutOfInventory(client, item)
		item:interact("drop", client)
	end
end
