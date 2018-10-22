util.AddNetworkString("nutStorageOpen")
util.AddNetworkString("nutStorageLock")
util.AddNetworkString("nutStorageExit")
util.AddNetworkString("nutStorageTransfer")

local TRANSFER = "storageTransfer"

local function getValidStorage(client)
	local storage = client.nutStorageEntity
	if (not IsValid(storage)) then return end
	if (client:GetPos():Distance(storage:GetPos()) > 128) then return end
	return storage
end

net.Receive("nutStorageExit", function(_, client)
	local storage = client.nutStorageEntity
	if (IsValid(storage)) then
		storage.receivers[client] = nil
	end
	client.nutStorageEntity = nil
end)

net.Receive("nutStorageUnlock", function(_, client)
	local password = net.ReadString()
	local storage = getValidStorage(client)
	if (not storage) then return end

	if (storage.password == password) then
		storage:openInv(client)
	else
		client:notifyLocalized("wrongPassword")
		client.nutStorageEntity = nil
	end
end)

net.Receive("nutStorageTransfer", function(_, client)
	-- Get the item that the player is swapping.
	local itemID = net.ReadUInt(32)

	-- Get the storage that the player opened.
	if (not client:getChar()) then return end
	local storage = getValidStorage(client)
	if (not storage or not storage.receivers[client]) then return end

	-- Get the inventory that we are transfering to and from.
	local clientInv = client:getChar():getInv()
	local storageInv = storage:getInv()
	if (not clientInv or not storageInv) then return end
	local item = clientInv.items[itemID] or storageInv.items[itemID]
	if (not item) then return end
	local toInv = clientInv:getID() == item.invID and storageInv or clientInv
	local fromInv = toInv == clientInv and storageInv or clientInv

	-- Permission check before moving the item around.
	if (hook.Run("StorageCanTransferItem", client, storage, item) == false) then
		return
	end
	local context = {
		client = client,
		item = item,
		storage = storage,
		from = fromInv,
		to = toInv
	}
	if (
		clientInv:canAccess(TRANSFER, context) == false or
		storageInv:canAccess(TRANSFER, context) == false
	) then
		return
	end

	-- Swap the item between the storage inventory and character's inventory.
	local failItemDropPos = client:getItemDropPos()
	fromInv:removeItem(itemID, true)
		:next(function()
			return toInv:add(item)
		end)
		:next(function(res)
			-- If something went wrong, move the item back to its old inventory.
			if (res.error and IsValid(client)) then
				client:notifyLocalized(res.error)
				return fromInv:add(item)
			end
		end)
		:next(function(res)
			-- And if that doesn't work, just spawn it in the world.
			if (res and res.error) then
				item:spawn(failItemDropPos)
			end
		end)
end)
