-- Determines whether or not a player can use a vendor.
function PLUGIN:CanPlayerAccessVendor(client, vendor)
	if (client:IsAdmin()) then
		return true
	end

	local character = client:getChar()
	if (vendor:isClassAllowed(character:getClass())) then
		return true
	end

	if (vendor:isFactionAllowed(client:Team())) then
		return true
	end
end

-- Determines whether or not a player can trade an item with a vendor.
function PLUGIN:CanPlayerTradeWithVendor(
	client,
	vendor,
	itemType,
	isSellingToVendor
)
	-- Check if the item can be traded at all.
	if (not vendor.items[itemType]) then
		return false
	end

	-- Make sure the trade mode agrees with the trade.
	local state = vendor:getTradeMode(itemType)
	if (isSellingToVendor and state == VENDOR_SELLONLY) then
		return false
	end
	if (not isSellingToVendor and state == VENDOR_BUYONLY) then
		return false
	end

	-- Make sure whoever is selling actually has an item to sell.
	if (
		isSellingToVendor and
		not client:getChar():getInv():hasItem(itemType)
	) then
		return false
	elseif (not isSellingToVendor) then
		local stock = vendor:getStock(itemType)
		if (stock and stock <= 0) then
			return false, "vendorNoStock"
		end
	end

	-- Make sure the either side can afford the trade.
	local price = vendor:getPrice(itemType, isSellingToVendor)
	local money
	if (isSellingToVendor) then
		money = vendor:getMoney()
	else
		money = client:getChar():getMoney()
	end
	if (money and money < price) then
		return false, isSellingToVendor and "vendorNoMoney" or "canNotAfford"
	end
end

if (not VENDOR_INVENTORY_MEASURE) then
	VENDOR_INVENTORY_MEASURE = nut.inventory.types["grid"]:new()
	VENDOR_INVENTORY_MEASURE.data = {w = 8, h = 8}
	VENDOR_INVENTORY_MEASURE.virtual = true
	VENDOR_INVENTORY_MEASURE:onInstanced()
end

function PLUGIN:VendorTradeAttempt(
	client,
	vendor,
	itemType,
	isSellingToVendor
)
	-- Make sure the trade is allowed.
	local canAccess, reason = hook.Run(
		"CanPlayerTradeWithVendor",
		client,
		vendor,
		itemType,
		isSellingToVendor
	)
	if (canAccess == false) then
		if (isstring(reason)) then
			client:notifyLocalized(reason)
		end
		return
	end

	local character = client:getChar()
	local price = vendor:getPrice(itemType, isSellingToVendor)

	if (client.vendorTransaction and client.vendorTimeout > RealTime()) then
		return
	end

	client.vendorTransaction = true 
	client.vendorTimeout = RealTime() + .1

	-- Then, transfer the money and item.
	if (isSellingToVendor) then
		local inventory = character:getInv()
		local item = inventory:getFirstItemOfType(itemType)
		
		if (item) then
			local context = {
				client = client,
				item = item,
				from = inventory,
				to = VENDOR_INVENTORY_MEASURE
			}
			local canTransfer, reason = VENDOR_INVENTORY_MEASURE:canAccess("transfer", context)
			if (not canTransfer) then
				client:notifyLocalized(reason or "vendorError")

				return
			end

			local canTransferItem, reason = hook.Run("CanItemBeTransfered", item, inventory, VENDOR_INVENTORY_MEASURE)
			if (canTransferItem == false) then
				client:notifyLocalized(reason or "vendorError")
			
				return
			end

			vendor:takeMoney(price)
			character:giveMoney(price)

			item:remove()
				:next(function()
					client.vendorTransaction = nil
				end)
				:catch(function()
					client.vendorTransaction = nil
				end)
			vendor:addStock(itemType)
		end

		nut.log.add(client, "vendorSell", itemType, vendor:getNetVar("name"))
	else
		vendor:giveMoney(price)
		character:takeMoney(price)

		vendor:takeStock(itemType)

		local position = client:getItemDropPos()
		character:getInv():add(itemType)
			:next(function()
				client.vendorTransaction = nil
			end)
			:catch(function(err)
				if (IsValid(client)) then
					client:notifyLocalized("itemOnGround")
				end
				client.vendorTransaction = nil
				return nut.item.spawn(itemType, position)
			end)
			:catch(function(err)
				client:notifyLocalized(err)
				client.vendorTransaction = nil
			end)

		nut.log.add(client, "vendorBuy", itemType, vendor:getNetVar("name"))
	end

	hook.Run("OnCharTradeVendor", client, vendor, itemType, isSellingToVendor)
end

-- Called when the vendor menu should open for the vendor.
function PLUGIN:PlayerAccessVendor(client, vendor)
	-- Sync the vendor with the player.
	vendor:addReceiver(client)

	-- Then, open the vendor menu.
	net.Start("nutVendorOpen")
		net.WriteEntity(vendor)
	net.Send(client)
end
