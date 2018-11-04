if (SERVER) then
	netstream.Hook("bizBuy", function(client, items)
		if (client.nextBiz and client.nextBiz > CurTime()) then
			client:notifyLocalized("tooFast")
			return
		end

		local char = client:getChar()

		if (!char) then
			return
		end

		if (table.Count(items) < 1) then
			return
		end

		local cost = 0

		for k, v in pairs(items) do
			local itemTable = nut.item.list[k]

			if (itemTable and hook.Run("CanPlayerUseBusiness", client, k) != false) then
				local amount = math.Clamp(tonumber(v) or 0, 0, 10)

				if (amount == 0) then
					items[k] = nil
				else
					cost = cost + (amount * (itemTable:getPrice()))
				end
			else
				items[k] = nil
			end
		end

		if (table.Count(items) < 1) then
			return
		end

		if (char:hasMoney(cost)) then
			char:takeMoney(cost)

			local entity = ents.Create("nut_shipment")
			entity:SetPos(client:getItemDropPos())
			entity:Spawn()
			entity:setItems(items)
			entity:setNetVar("owner", char:getID())

			local shipments = char:getVar("charEnts") or {}
			table.insert(shipments, entity)
			char:setVar("charEnts", shipments, true)

			netstream.Start(client, "bizResp")
			hook.Run("OnCreateShipment", client, entity)
			client.nextBiz = CurTime() + 0.5
		end
	end)

	netstream.Hook("shpUse", function(client, uniqueID, drop)
		local entity = client.nutShipment
		local itemTable = nut.item.list[uniqueID]

		if (itemTable and IsValid(entity)) then
			if (entity:GetPos():Distance(client:GetPos()) > 128) then
				client.nutShipment = nil

				return
			end

			local amount = entity.items[uniqueID]

			if (amount and amount > 0) then
				if (entity.items[uniqueID] <= 0) then
					entity.items[uniqueID] = nil
				end

				local function itemTaken()
					if (IsValid(client)) then
						hook.Run("OnTakeShipmentItem", client, uniqueID, amount)
					end
					
					entity.items[uniqueID] = entity.items[uniqueID] - 1

					if (entity:getItemCount() < 1) then
						entity:GibBreakServer(Vector(0, 0, 0.5))
						entity:Remove()
					end
				end

				if (drop) then
					nut.item.spawn(uniqueID, entity:GetPos() + Vector(0, 0, 16))
					itemTaken()
				else
					client:getChar():getInv():add(uniqueID, amount)
						:next(function(res)
							if (IsValid(client) and res.error) then
								client:notifyLocalized(res.error)
							elseif (not res.error) then
								itemTaken()
							end
						end)
				end
			end
		end
	end)
else
	netstream.Hook("openShp", function(entity, items)
		nut.gui.shipment = vgui.Create("nutShipment")
		nut.gui.shipment:setItems(entity, items)
	end)

	netstream.Hook("updtShp", function(entity, items)
		if (nut.gui.shipment and nut.gui.shipment:IsVisible()) then
		end
	end)

	netstream.Hook("takeShp", function(name, amount)
		if (nut.gui.shipment and nut.gui.shipment:IsVisible()) then
			local item = nut.gui.shipment.itemPanel[name]

			if (item) then
				item.amount = item.amount - 1
				item:Update(item.amount)

				if (item.amount <= 0) then
					item:Remove()
				end
			end
		end
	end)
end
