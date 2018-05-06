local PLUGIN = PLUGIN
PLUGIN.name = "Logging"
PLUGIN.author = "Black Tea"
PLUGIN.desc = "You can modfiy the logging text/lists on this plugin."
 
if (SERVER) then
	local L, type, IsValid = Format, type, IsValid
	
	nut.log.addType("chat", function(client, ...)
		local arg = {...}
		return (L("[%s] %s: %s", arg[1], client:Name(), arg[2]))
	end)
	nut.log.addType("command", function(client, ...)
		local arg = {...}
		return (L("%s used command '%s'", client:Name(), arg[1]))
	end)
	nut.log.addType("charLoad", function(client, ...)
		local arg = {...}
		return (L("%s loaded the character #%s (%s)", client:steamName(), arg[1], arg[2]))
	end)
	nut.log.addType("charDelete", function(client, ...)
		local arg = {...}
		return (L("%s(%s) deleted character (%s)", client:steamName(), client:SteamID(), arg[1]))
	end)
	nut.log.addType("itemUse", function(client, ...)
		local arg = {...}
		local item = arg[2]
		return (L("%s tried '%s' to item '%s'(#%s)", client:Name(), arg[1], item.name, item.id))
	end)
	nut.log.addType("shipment", function(client, ...)
		local arg = {...}
		return (L("%s took '%s' from the shipment", client:Name(), arg[1]))
	end)
	nut.log.addType("shipmentO", function(client, ...)
		local arg = {...}
		return (L("%s ordered a shipment", client:Name()))
	end)
	nut.log.addType("buy", function(client, ...)
		local arg = {...}
		return (L("%s purchased '%s' from the NPC", client:Name(), arg[1]))
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
