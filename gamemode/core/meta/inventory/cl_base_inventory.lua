local Inventory = nut.Inventory

net.Receive("nutInventoryData", function()
	local id = net.ReadType()
	local key = net.ReadString()
	local value = net.ReadType()
	local instance = nut.inventory.instances[id]
	if (not instance) then
		ErrorNoHalt("Got data "..key.." for non-existent instance "..id)
		return
	end

	local oldValue = instance.data[key]
	instance.data[key] = value
	instance:onDataChanged(key, oldValue, value)

	hook.Run("InventoryDataChanged", instance, key, oldValue, value)
end)

net.Receive("nutInventoryInit", function()
	local id = net.ReadType()
	local typeID = net.ReadString()
	local data = net.ReadTable()
	local instance = nut.inventory.new(typeID)
	instance.id = id
	instance.data = data
	instance.items = {}

	local expectedItems = net.ReadUInt(32)
	local function readItem()
		return net.ReadUInt(32), net.ReadString(), net.ReadTable(), net.ReadUInt(32)
	end

	for i = 1, expectedItems do
		local itemID, itemType, data, quantity = readItem()
		local item = nut.item.new(itemType, itemID)
		item.data = table.Merge(item.data, data)
		item.invID = instance.id
		item.quantity = quantity
		instance.items[itemID] = item
		hook.Run("ItemInitialized", item)
	end

	nut.inventory.instances[instance.id] = instance
	hook.Run("InventoryInitialized", instance)

	for _, character in pairs(nut.char.loaded) do
		for index, inventory in pairs(character.vars.inv) do
			if (inventory:getID() == id) then
				character.vars.inv[index] = instance
			end
		end
	end
end)

net.Receive("nutInventoryAdd", function()
	local itemID = net.ReadUInt(32)
	local invID = net.ReadType()
	local item = nut.item.instances[itemID]
	local inventory = nut.inventory.instances[invID]
	if (item and inventory) then
		inventory.items[itemID] = item
		hook.Run("InventoryItemAdded", inventory, item)
	end
end)

net.Receive("nutInventoryRemove", function()
	local itemID = net.ReadUInt(32)
	local invID = net.ReadType()
	local item = nut.item.instances[itemID]
	local inventory = nut.inventory.instances[invID]
	if (item and inventory and inventory.items[itemID]) then
		inventory.items[itemID] = nil
		item.invID = 0
		hook.Run("InventoryItemRemoved", inventory, item)
	end
end)

net.Receive("nutInventoryDelete", function()
	local invID = net.ReadType()
	local instance = nut.inventory.instances[invID]
	if (instance) then
		hook.Run("InventoryDeleted", instance)
	end
	if (invID) then
		nut.inventory.instances[invID] = nil
	end
end)

function Inventory:show(parent)
	return nut.inventory.show(self, parent)
end
