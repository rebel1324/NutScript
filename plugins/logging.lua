local PLUGIN = PLUGIN
PLUGIN.name = "Logging"
PLUGIN.author = "Black Tea"
PLUGIN.desc = "You can modfiy the logging text/lists on this plugin."
 
if (SERVER) then
	local L, type, IsValid = Format, type, IsValid
	
	nut.log.addType("playerHurt", function(client, attacker, damage, health)
		attacker = tostring(attacker)
		damage = damage or 0
		health = health or 0
		return string.format("%s has taken %d damage from %s, leaving them at %d health.", client:Name(), damage, attacker, health)
	end)

	nut.log.addType("playerDeath", function(client, ...)
		local data = {...}
		local attacker = data[1] or "unknown"

		return string.format("%s has killed %s.", attacker, client:Name())
	end)

	nut.log.addType("playerConnected", function(client, ...)
		local data = {...}
		local steamID = data[1]

		return string.format("%s[%s] has connected to the server.", client:Name(), steamID or client:SteamID())
	end)

	nut.log.addType("playerDisconnected", function(client, ...)
		return string.format("%s has disconnected from the server.", client:Name())
	end)

	nut.log.addType("itemTake", function(client, ...)
		local data = {...}
		local itemName = data[1] or "unknown"
		local itemCount = data[2] or 1

		return string.format("%s has picked up %dx%s.", client:Name(), itemCount, itemName)
	end)

	nut.log.addType("itemDrop", function(client, ...)
		local data = {...}
		local itemName = data[1] or "unknown"
		local itemCount = data[2] or 1

		return string.format("%s has lost %dx%s.", client:Name(), itemCount, itemName)
	end)

	nut.log.addType("money", function(client, ...)
		local data = {...}
		local amount = data[1] or 0

		return string.format("%s's money has changed by %d.", client:Name(), amount)
	end)

	nut.log.addType("chat", function(client, ...)
		local arg = {...}
		return (L("[%s] %s: %s", arg[1], client:Name(), arg[2]))
	end)

	nut.log.addType("command", function(client, ...)
		local arg = {...}
		return (L("%s used '%s'", client:Name(), arg[1]))
	end)

	nut.log.addType("charLoad", function(client, ...)
		local arg = {...}
		return (L("%s loaded the character #%s(%s)", client:steamName(), arg[1], arg[2]))
	end)

	nut.log.addType("charDelete", function(client, ...)
		local arg = {...}
		return (L("%s(%s) deleted character (%s)", client:steamName(), client:SteamID(), arg[1]))
	end)

	nut.log.addType("itemUse", function(client, ...)
		local arg = {...}
		local item = arg[2]
		return (L("%s tried '%s' on item '%s'(#%s)", client:Name(), arg[1], item.name, item.id))
	end)

	nut.log.addType("shipment", function(client, ...)
		local arg = {...}
		return (L("%s took '%s' from a shipment", client:Name(), arg[1]))
	end)

	nut.log.addType("shipmentO", function(client, ...)
		local arg = {...}
		return (L("%s ordered a shipment", client:Name()))
	end)

	nut.log.addType("buy", function(client, ...)
		local arg = {...}
		return (L("%s purchased '%s' from an NPC", client:Name(), arg[1]))
	end)

	nut.log.addType("buydoor", function(client, ...)
		local arg = {...}
		return (L("%s purchased the door", client:Name()))
	end)

	function PLUGIN:CharacterLoaded(id)
		local character = nut.char.loaded[id]
		local client = character:getPlayer()
		nut.log.add(client, "charLoad", id, character:getName())
	end

	function PLUGIN:OnCharDelete(client, id)
		nut.log.add(client, "charDelete", id)
	end
	
	function PLUGIN:OnTakeShipmentItem(client, itemClass, amount)
		local itemTable = nut.item.list[itemClass]
		nut.log.add(client, "shipment", itemTable.name)
	end

	function PLUGIN:OnCreateShipment(client, shipmentEntity)
		nut.log.add(client, "shipmentO")
	end

	function PLUGIN:OnCharTradeVendor(client, vendor, x, y, invID, price, isSell)
	end

	function PLUGIN:OnPlayerInteractItem(client, action, item)
		if (type(item) == "Entity") then
			if (IsValid(item)) then
				local itemID = item.nutItemID
				item = nut.item.instances[itemID]
			else
				return
			end
		elseif (type(item) == "number") then
			item = nut.item.instances[item]
		end

		if (!item) then
			return
		end

		nut.log.add(client, "itemUse", action, item)
	end
end
