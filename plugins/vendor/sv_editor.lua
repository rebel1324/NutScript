local EDITOR = {}

EDITOR.name = function(vendor, client, key, data)
	vendor:setNetVar("name", data)
end

EDITOR.desc = function(vendor, client, key, data)
	vendor:setNetVar("desc", data)
end

EDITOR.bubble = function(vendor, client, key, data)
	vendor:setNetVar("noBubble", data)
end

EDITOR.mode = function(vendor, client, key, data)
	local uniqueID = data[1]

	vendor.items[uniqueID] = vendor.items[uniqueID] or {}
	vendor.items[uniqueID][VENDOR_MODE] = data[2]

	netstream.Start(vendor.receivers, "vendorEdit", key, data)
end

EDITOR.price = function(vendor, client, key, data)
	local uniqueID = data[1]
	data[2] = tonumber(data[2])

	if (data[2]) then
		data[2] = math.Round(data[2])
	end

	vendor.items[uniqueID] = vendor.items[uniqueID] or {}
	vendor.items[uniqueID][VENDOR_PRICE] = data[2]

	netstream.Start(vendor.receivers, "vendorEdit", key, data)
	return uniqueID
end

EDITOR.stockDisable = function(vendor, client, key, data)
	vendor.items[data] = vendor.items[uniqueID] or {}
	vendor.items[data][VENDOR_MAXSTOCK] = nil

	netstream.Start(vendor.receivers, "vendorEdit", key, data)
end

EDITOR.stockMax = function(vendor, client, key, data)
	local uniqueID = data[1]
	data[2] = math.max(math.Round(tonumber(data[2]) or 1), 1)

	vendor.items[uniqueID] = vendor.items[uniqueID] or {}
	vendor.items[uniqueID][VENDOR_MAXSTOCK] = data[2]
	vendor.items[uniqueID][VENDOR_STOCK] = math.Clamp(vendor.items[uniqueID][VENDOR_STOCK] or data[2], 1, data[2])

	data[3] = vendor.items[uniqueID][VENDOR_STOCK]

	netstream.Start(vendor.receivers, "vendorEdit", key, data)
	return uniqueID
end

EDITOR.stock = function(vendor, client, key, data)
	local uniqueID = data[1]

	vendor.items[uniqueID] = vendor.items[uniqueID] or {}

	if (not vendor.items[uniqueID][VENDOR_MAXSTOCK]) then
		data[2] = math.max(math.Round(tonumber(data[2]) or 0), 0)
		vendor.items[uniqueID][VENDOR_MAXSTOCK] = data[2]
	end

	data[2] = math.Clamp(math.Round(tonumber(data[2]) or 0), 0, vendor.items[uniqueID][VENDOR_MAXSTOCK])
	vendor.items[uniqueID][VENDOR_STOCK] = data[2]

	netstream.Start(vendor.receivers, "vendorEdit", key, data)
	return uniqueID
end

EDITOR.faction = function(vendor, client, key, factionID)
	local faction = nut.faction.teams[factionID]

	if (faction) then
		vendor.factions[factionID] = not vendor.factions[factionID]

		if (not vendor.factions[factionID]) then
			vendor.factions[factionID] = nil
		end
	end

	return {factionID, vendor.factions[factionID]}
end

EDITOR.class = function(vendor, client, key, uniqueID)
	local class

	for k, v in ipairs(nut.class.list) do
		if (v.uniqueID == uniqueID) then
			class = v

			break
		end
	end

	if (class) then
		vendor.classes[data] = not vendor.classes[data]

		if (not vendor.classes[data]) then
			vendor.classes[data] = nil
		end
	end

	return {uniqueID, vendor.classes[uniqueID]}
end

EDITOR.model = function(vendor, client, key, data)
	vendor:SetModel(data)
	vendor:setAnim()
end

EDITOR.useMoney = function(vendor, client, key, data)
	if (vendor.money) then
		vendor:setMoney()
	else
		vendor:setMoney(0)
	end
end

EDITOR.money = function(vendor, client, key, data)
	data = math.Round(math.abs(tonumber(data) or 0))

	vendor:setMoney(data)
	return nil, false
end

EDITOR.scale = function(vendor, client, key, data)
	data = tonumber(data) or 0.5

	vendor:setNetVar("scale", data)
	netstream.Start(vendor.receivers, "vendorEdit", key, data)
end

return EDITOR
