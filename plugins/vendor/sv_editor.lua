local EDITOR = {}

EDITOR.name = function(vendor, client)
	local name = net.ReadString()
	vendor:setName(name)
end

EDITOR.desc = function(vendor, client)
	local desc = net.ReadString()
	vendor:setDesc(desc)
end

EDITOR.bubble = function(vendor, client)
	local noBubble = net.ReadBool()
	vendor:setNoBubble(noBubble)
end

EDITOR.mode = function(vendor, client)
	local itemType = net.ReadString()
	local mode = net.ReadInt(8)

	vendor:setTradeMode(itemType, mode)
end

EDITOR.price = function(vendor, client)
	local itemType = net.ReadString()
	local price = net.ReadInt(32)

	vendor:setItemPrice(itemType, price)
end

EDITOR.stockDisable = function(vendor, client)
	local itemType = net.ReadString()
	vendor:setMaxStock(itemType, nil)
end

EDITOR.stockMax = function(vendor, client)
	local itemType = net.ReadString()
	local value = net.ReadUInt(32)
	vendor:setMaxStock(itemType, value)
end

EDITOR.stock = function(vendor, client)
	local itemType = net.ReadString()
	local value = net.ReadUInt(32)
	vendor:setStock(itemType, value)
end

EDITOR.faction = function(vendor, client)
	local factionID = net.ReadUInt(8)
	local allowed = net.ReadBool()
	vendor:setFactionAllowed(factionID, allowed)
end

EDITOR.class = function(vendor, client)
	local classID = net.ReadUInt(8)
	local allowed = net.ReadBool()
	vendor:setClassAllowed(classID, allowed)
end

EDITOR.model = function(vendor, client)
	local model = net.ReadString()
	vendor:setModel(model)
end

EDITOR.useMoney = function(vendor, client)
	local useMoney = net.ReadBool()
	if (useMoney) then
		vendor:setMoney(nut.config.get("defMoney", 0))
	else
		vendor:setMoney(nil)
	end
end

EDITOR.money = function(vendor, client, key, data)
	local money = net.ReadUInt(32)
	vendor:setMoney(money)
end

EDITOR.scale = function(vendor, client)
	local scale = net.ReadFloat()
	vendor:setSellScale(scale)
end

return EDITOR
