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
		return net.ReadUInt(32), net.ReadString(), net.ReadTable()
	end

	for i = 1, expectedItems do
		local itemID, itemType, data = readItem()
		local item = nut.item.new(itemType, itemID)
		item.data = table.Merge(item.data, data)
		item.invID = id
		instance.items[itemID] = item
	end

	nut.inventory.instances[instance.id] = instance
end)
