local EDITOR = {}

local function addEditor(name, callback)
	EDITOR[name] = function(...)
		net.Start("nutVendorEdit")
			net.WriteString(name)

			if (isfunction(callback)) then
				callback(...)
			end
		net.SendToServer()
	end
end

addEditor("name", function(name)
	net.WriteString(name)
end)

addEditor("desc", function(desc)
	net.WriteString(desc)
end)

addEditor("bubble", function(show)
	net.WriteBool(show)
end)

addEditor("mode", function(itemType, mode)
	if (not isnumber(mode)) then mode = nil end
	net.WriteString(itemType)
	net.WriteInt(mode or -1, 8)
end)

addEditor("price", function(itemType, price)
	net.WriteString(itemType)
	net.WriteInt(price or -1, 32)
end)

addEditor("stockDisable", function(itemType)
	net.WriteString(itemType)
	net.WriteUInt(0, 32)
end)

addEditor("stockMax", function(itemType, value)
	if (not isnumber(value)) then return end
	net.WriteString(itemType)
	net.WriteUInt(math.max(value, 1), 32)
end)

addEditor("stock", function(itemType, value)
	net.WriteString(itemType)
	net.WriteUInt(value, 32)
end)

addEditor("faction", function(factionID, allowed)
	net.WriteUInt(factionID, 8)
	net.WriteBool(allowed)
end)

addEditor("class", function(classID, allowed)
	net.WriteUInt(classID, 8)
	net.WriteBool(allowed)
end)

addEditor("model", function(model)
	net.WriteString(model)
end)

addEditor("useMoney", function(useMoney)
	net.WriteBool(useMoney)
end)

addEditor("money", function(value)
	if (isnumber(value)) then
		value = math.max(math.Round(value), 0)
	else
		value = nil
	end

	net.WriteInt(value or -1, 32)
end)

addEditor("scale", function(scale)
	net.WriteFloat(scale)
end)

return EDITOR
