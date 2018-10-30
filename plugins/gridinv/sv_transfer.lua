util.AddNetworkString("nutTransferItem")

local TRANSFER = "transfer"

net.Receive("nutTransferItem", function(_, client)
	local itemID = net.ReadUInt(32)
	local x = net.ReadUInt(32)
	local y = net.ReadUInt(32)
	local invID = net.ReadType()

	-- Get the item that should be moved, its inventory, and the destination.
	local inventory = nut.inventory.instances[invID]
	if (not inventory) then return end
	local item = nut.item.instances[itemID]
	if (not item) then return end
	local oldInventory = nut.inventory.instances[item.invID]
	if (not oldInventory or not oldInventory.items[item:getID()]) then
		return
	end

	-- Make sure the item is permitted to move between the two inventories.
	if (
		hook.Run("CanItemBeTransfered", item, oldInventory, inventory) == false
	) then
		return
	end
	local context = {
		client = client,
		item = item,
		from = oldInventory,
		to = inventory
	}
	if (
		not oldInventory:canAccess(TRANSFER, context) or
		not inventory:canAccess(TRANSFER, context)
	) then
		return
	end

	-- If valid, remove the item from its current inventory and put it in
	-- the other inventory. If something fails, just drop the item in the world.
	local oldX, oldY = item:getData("x"), item:getData("y")
	local failItemDropPos = client:getItemDropPos()
	oldInventory:removeItem(itemID, true)
		:next(function()
			return inventory:add(item, x, y)
		end)
		:next(function(res)
			if (res and res.error) then
				return oldInventory:add(item, oldX, oldY)
			end
		end)
		:next(function(res)
			if (res and res.error) then
				item:spawn(failItemDropPos)
			end
		end)
end)
