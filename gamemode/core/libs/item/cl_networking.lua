netstream.Hook("item", function(uniqueID, id, data, invID)
	local item = nut.item.new(uniqueID, id)

	item.data = {}
	if (data) then
		item.data = data
	end

	item.invID = invID or 0
	hook.Run("ItemInitialized", item)
end)

netstream.Hook("invData", function(id, key, value)
	local item = nut.item.instances[id]

	if (item) then
		item.data = item.data or {}
		local oldValue = item.data[key]
		item.data[key] = value
		hook.Run("ItemDataChanged", item, key, oldValue, value)
	end
end)

netstream.Hook("invQuantity", function(id, quantity)
	local item = nut.item.instances[id]

	if (item) then
		local oldValue = item:getQuantity()
		item.quantity = quantity

		hook.Run("ItemQuantityChanged", item, oldValue, quantity)
	end
end)

net.Receive("nutItemInstance", function()
	local itemID = net.ReadUInt(32)
	local itemType = net.ReadString()
	local data = net.ReadTable()
	local item = nut.item.new(itemType, itemID)
	local invID = net.ReadType()
	local quantity = net.ReadUInt(32)

	item.data = table.Merge(item.data or {}, data)
	item.invID = invID
	item.quantity = quantity

	nut.item.instances[itemID] = item
	hook.Run("ItemInitialized", item)
end)

net.Receive("nutCharacterInvList", function()
	local charID = net.ReadUInt(32)
	local length = net.ReadUInt(32)
	local inventories = {}

	for i = 1, length do
		inventories[i] = nut.inventory.instances[net.ReadType()]
	end

	local character = nut.char.loaded[charID]
	if (character) then
		character.vars.inv = inventories
	end
end)

net.Receive("nutItemDelete", function()
	local id = net.ReadUInt(32)
	local instance = nut.item.instances[id]
	if (instance and instance.invID) then
		local inventory = nut.inventory.instances[instance.invID]
		if (not inventory or not inventory.items[id]) then return end

		inventory.items[id] = nil
		instance.invID = 0
		hook.Run("InventoryItemRemoved", inventory, instance)
	end

	nut.item.instances[id] = nil
	hook.Run("ItemDeleted", instance)
end)
