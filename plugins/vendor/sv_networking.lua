local PLUGIN = PLUGIN
local EDITOR = nut.util.include("sv_editor.lua")

netstream.Hook("vendorExit", function(client)
	local entity = client.nutVendor

	if (IsValid(entity)) then
		for k, v in ipairs(entity.receivers) do
			if (v == client) then
				table.remove(entity.receivers, k)

				break
			end
		end

		nut.log.add(client, "vendorExit", entity:getNetVar("name"))

		client.nutVendor = nil
	end
end)

netstream.Hook("vendorEdit", function(client, key, data)
	if (not client:IsAdmin()) then
		return
	end
	local entity = client.nutVendor

	if (not IsValid(entity) or not EDITOR[key]) then
		return
	end

	local newData, feedback = EDITOR[key](entity, client, key, data) or data
	if (feedback == nil) then
		feedback = true
	end
	if (newData ~= nil) then
		data = newData
	end

	PLUGIN:saveVendors()
	nut.log.add(
		client,
		"vendorEdit",
		entity:getNetVar("name"), tostring(key),
		type(data) == "table"
		and "{"..table.concat(data, ", ").."}"
		or tostring(data)
	)

	if (not feedback) then
		return
	end
	local receivers = {}

	for k, v in ipairs(entity.receivers) do
		if (v:IsAdmin()) then
			receivers[#receivers + 1] = v
		end
	end

	netstream.Start(receivers, "vendorEditFinish", key, data)
end)

netstream.Hook("vendorTrade", function(client, uniqueID, isSellingToVendor)
	if ((client.nutVendorTry or 0) < CurTime()) then
		client.nutVendorTry = CurTime() + 0.33
	else
		return
	end

	local found
	local entity = client.nutVendor

	if (
		!IsValid(entity) or
		client:GetPos():Distance(entity:GetPos()) > 192
	) then
		return
	end

	local canTrade = hook.Run(
		"CanPlayerTradeWithVendor",
		client,
		entity,
		uniqueID,
		isSellingToVendor
	)
	if (not entity.items[uniqueID] or canTrade == false) then
		client:notifyLocalized("vendorNoTrade")
		return
	end

	local price = entity:getPrice(uniqueID, isSellingToVendor)

	if (isSellingToVendor) then
		local found = false
		local name
		local inv = client:getChar():getInv()
		local virtualInv = nut.item.inventories[0]

		for k, v in pairs(inv:getItems()) do
			if (v.uniqueID == uniqueID and v:getID() != 0 and istable(nut.item.instances[v:getID()])) then
				if (hook.Run("CanItemBeTransfered", v, inv, virtualInv) == false) then
					return false, "notAllowed"
				end

				if (!authorized and v.onCanBeTransfered and v:onCanBeTransfered(inv, virtualInv) == false) then
					return false, "notAllowed"
				end

				found = v
				name = L(v.name, client)
				break
			end
		end

		if (!found) then
			return client:notifyLocalized("noItem")
		end

		price = entity:getPrice(found, isSellingToVendor)

		if (!entity:hasMoney(price)) then
			return client:notifyLocalized("vendorNoMoney")
		end

		local invOkay = found:remove()

		if (!invOkay) then
			client:getChar():getInv():sync(client, true)
			return client:notifyLocalized("tellAdmin", "trd!iid")
		end

		client:getChar():giveMoney(price)
		client:notifyLocalized("businessSell", name, nut.currency.get(price))
		entity:takeMoney(price)
		entity:addStock(uniqueID)

		nut.log.add(client, "vendorSell", name, entity:getNetVar("name"))

		hook.Run("OnCharTradeVendor", client, entity, uniqueID, isSellingToVendor)
	else
		local stock = entity:getStock(uniqueID)

		if (stock and stock < 1) then
			return client:notifyLocalized("vendorNoStock")
		end

		if (!client:getChar():hasMoney(price)) then
			return client:notifyLocalized("canNotAfford")
		end

		local name = L(nut.item.list[uniqueID].name, client)

		client:getChar():takeMoney(price)
		client:notifyLocalized("businessPurchase", name, nut.currency.get(price))

		entity:giveMoney(price)

		client:getChar():getInv():add(uniqueID)
			:next(function(res)
				if (res.error) then
					nut.item.spawn(uniqueID, client:getItemDropPos())
				end
			end)
		entity:takeStock(uniqueID)

		nut.log.add(client, "vendorBuy", name, entity:getNetVar("name"))

		hook.Run("OnCharTradeVendor", client, entity, uniqueID, isSellingToVendor)
	end
end)
