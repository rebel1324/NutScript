util.AddNetworkString("nutTransferItem")

local TRANSFER = "transfer"

function PLUGIN:HandleItemTransferRequest(client, itemID, x, y, invID)
	-- Get the item that should be moved, its inventory, and the destination.
	local inventory = nut.inventory.instances[invID]
	local item = nut.item.instances[itemID]
	if (not item) then return end
	local oldInventory = nut.inventory.instances[item.invID]
	if (not oldInventory or not oldInventory.items[itemID]) then
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
	local canTransfer, reason = oldInventory:canAccess(TRANSFER, context)
	if (not canTransfer) then
		return
	end

	if (not inventory) then
		return hook.Run("ItemDraggedOutOfInventory", client, item)
	end

	canTransfer, reason = inventory:canAccess(TRANSFER, context)
	if (not canTransfer) then
		if (reason) then
			client:notifyLocalized(reason)
		end
		return
	end

	-- If valid, remove the item from its current inventory and put it in
	-- the other inventory. If something fails, just drop the item in the world.
	local oldX, oldY = item:getData("x"), item:getData("y")
	local failItemDropPos = client:getItemDropPos()

	local function fail(err)
		if (err) then
			print(err)
			debug.Trace()
		end
		item:spawn(failItemDropPos)
	end

	local tryCombineWith
	local originalAddRes

	return oldInventory:removeItem(itemID, true)
		:next(function()
			return inventory:add(item, x, y)
		end, fail)
		:next(function(res)
			if (not res or not res.error) then return end

			-- If the item was dropped on another item, then "combine" them.
			-- This is subject to how the target item defines "combine".
			local conflictingItem = istable(res.error) and res.error.item
			if (conflictingItem) then
				tryCombineWith = conflictingItem
			end

			originalAddRes = res
			return oldInventory:add(item, oldX, oldY)
		end, fail)
		:next(function(res)
			if (res and res.error) then return res end
			if (tryCombineWith and IsValid(client)) then
				if (hook.Run("ItemCombine", client, item, tryCombineWith)) then
					return
				end
			end
		end)
		:next(function(res)
			if (res and res.error) then
				fail()
			end
			return originalAddRes
		end, fail)
end

net.Receive("nutTransferItem", function(_, client)
	local itemID = net.ReadUInt(32)
	local x = net.ReadUInt(32)
	local y = net.ReadUInt(32)
	local invID = net.ReadType()

	hook.Run("HandleItemTransferRequest", client, itemID, x, y, invID)
end)
