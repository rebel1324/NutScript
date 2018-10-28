PLUGIN.name = "Simple Inv UI"
PLUGIN.author = "Cheesenut"
PLUGIN.desc = "Adds a simple interface for list inventories."

local INVENTORY_TYPE_ID = "simple"

if (CLIENT) then
	function PLUGIN:CreateInventoryPanel(inventory, parent)
		if (inventory.typeID ~= INVENTORY_TYPE_ID) then
			return
		end

		local panel = parent:Add("nutListInventory")
		panel:setInventory(inventory)
		panel:Center()
		
		return panel
	end

	function PLUGIN:getItemStackKey(item)
		local elements = {}
		for key, value in SortedPairs(item.data) do
			elements[#elements + 1] = key
			elements[#elements + 1] = value
		end
		return item.uniqueID..pon.encode(elements)
	end

	function PLUGIN:getItemStacks(inventory)
		local stacks = {}
		local stack, key
		for _, item in SortedPairs(inventory:getItems()) do
			key = self:getItemStackKey(item)
			stack = stacks[key] or {}
			stack[#stack + 1] = item
			stacks[key] = stack
		end
		return stacks
	end
end
