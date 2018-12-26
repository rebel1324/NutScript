local function addNetHandler(name, handler)
	assert(isfunction(handler), "handler is not a function")
	net.Receive("nutVendor"..name, function()
		if (not IsValid(nutVendorEnt)) then return end
		handler(nutVendorEnt)
	end)
end

net.Receive("nutVendorSync", function()
	local vendor = net.ReadEntity()
	if (not IsValid(vendor)) then return end

	vendor.money = net.ReadInt(32)
	if (vendor.money < 0) then
		vendor.money = nil
	end

	local count = net.ReadUInt(16)
	for i = 1, count do
		local itemType = net.ReadString()
		local price = net.ReadInt(32)
		local stock = net.ReadInt(32)
		local maxStock = net.ReadInt(32)
		local mode = net.ReadInt(8)

		if (price < 0) then price = nil end
		if (stock < 0) then stock = nil end
		if (maxStock <= 0) then maxStock = nil end
		if (mode < 0) then mode = nil end

		vendor.items[itemType] = {
			[VENDOR_PRICE] = price,
			[VENDOR_STOCK] = stock,
			[VENDOR_MAXSTOCK] = maxStock,
			[VENDOR_MODE] = mode
		}
	end

	hook.Run("VendorSynchronized", vendor)
end)

net.Receive("nutVendorOpen", function()
	local vendor = net.ReadEntity()
	if (IsValid(vendor)) then
		nutVendorEnt = vendor
		hook.Run("VendorOpened", vendor)
	end
end)

net.Receive("nutVendorExit", function()
	nutVendorEnt = nil
	hook.Run("VendorExited")
end)

addNetHandler("Money", function(vendor)
	local money = net.ReadInt(32)
	if (money < 0) then money = nil end
	vendor.money = money
	hook.Run("VendorMoneyUpdated", vendor, money, vendor.money)
end)

addNetHandler("Price", function(vendor)
	local itemType = net.ReadString()
	local value = net.ReadInt(32)
	if (value < 0) then value = nil end

	vendor.items[itemType] = vendor.items[itemType] or {}
	vendor.items[itemType][VENDOR_PRICE] = value

	hook.Run("VendorItemPriceUpdated", vendor, itemType, value)
end)

addNetHandler("Mode", function(vendor)
	local itemType = net.ReadString()
	local value = net.ReadInt(8)
	if (value < 0) then value = nil end

	vendor.items[itemType] = vendor.items[itemType] or {}
	vendor.items[itemType][VENDOR_MODE] = value

	hook.Run("VendorItemModeUpdated", vendor, itemType, value)
end)

addNetHandler("Stock", function(vendor)
	local itemType = net.ReadString()
	local value = net.ReadUInt(32)

	vendor.items[itemType] = vendor.items[itemType] or {}
	vendor.items[itemType][VENDOR_STOCK] = value

	hook.Run("VendorItemStockUpdated", vendor, itemType, value)
end)

addNetHandler("MaxStock", function(vendor)
	local itemType = net.ReadString()
	local value = net.ReadUInt(32)
	if (value == 0) then value = nil end

	vendor.items[itemType] = vendor.items[itemType] or {}
	vendor.items[itemType][VENDOR_MAXSTOCK] = value

	hook.Run("VendorItemMaxStockUpdated", vendor, itemType, value)
end)

addNetHandler("AllowFaction", function(vendor)
	local id = net.ReadUInt(8)
	local allowed = net.ReadBool()

	if (allowed) then
		vendor.factions[id] = true
	else
		vendor.factions[id] = nil
	end

	hook.Run("VendorFactionUpdated", vendor, id, allowed)
end)

addNetHandler("AllowClass", function(vendor)
	local id = net.ReadUInt(8)
	local allowed = net.ReadBool()

	if (allowed) then
		vendor.classes[id] = true
	else
		vendor.classes[id] = nil
	end

	hook.Run("VendorClassUpdated", vendor, id, allowed)
end)

net.Receive("nutVendorEdit", function()
	local key = net.ReadString()
	-- Give some time to receive the update.
	timer.Simple(0.25, function()
		if (not IsValid(nutVendorEnt)) then return end
		hook.Run("VendorEdited", nutVendorEnt, key)
	end)
end)

net.Receive("nutVendorFaction", function()
	local factionID = net.ReadUInt(8)
	if (IsValid(nutVendorEnt)) then
		nutVendorEnt.factions[factionID] = true
	end
end)
