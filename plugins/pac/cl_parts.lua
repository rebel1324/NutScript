local PLUGIN = PLUGIN
local playerMeta = FindMetaTable("Entity")

function PLUGIN:AdjustPACPartData(wearer, id, data)
	local item = nut.item.list[id]
	if (item and isfunction(item.pacAdjust)) then
		local result = item:pacAdjust(data, wearer)
		if (result ~= nil) then
			return result
		end
	end
end

function PLUGIN:getAdjustedPartData(wearer, id)
	if (not PLUGIN.partData[id]) then return end
	local data = table.Copy(PLUGIN.partData[id])
	return hook.Run("AdjustPACPartData", wearer, id, data) or data
end

function PLUGIN:attachPart(client, id)
	if (not pac) then return end
	
	local part = self:getAdjustedPartData(client, id)
	if (not part) then return end

	if (not client.AttachPACPart) then
		pac.SetupENT(client)
	end
	client:AttachPACPart(part, client)

	client.nutPACParts = client.nutPACParts or {}
	client.nutPACParts[id] = part
end

function PLUGIN:removePart(client, id)
	if (not client.RemovePACPart or not client.nutPACParts) then return end

	local part = client.nutPACParts[id]
	if (part) then
		client:RemovePACPart(part)
		client.nutPACParts[id] = nil
	end
end

function playerMeta:getParts()
	return self:getNetVar("parts", {})
end

net.Receive("nutPACSync", function()
	if (not pac) then return end

	for _, client in ipairs(player.GetAll()) do
		for id in pairs(client:getParts()) do
			PLUGIN:attachPart(client, id)
		end
	end
end)

net.Receive("nutPACPartAdd", function()
	local client = net.ReadEntity()
	local id = net.ReadString()
	if (not IsValid(client)) then return end

	PLUGIN:attachPart(client, id)
end)

net.Receive("nutPACPartRemove", function()
	local client = net.ReadEntity()
	local id = net.ReadString()
	if (not IsValid(client)) then return end

	PLUGIN:removePart(client, id)
end)

net.Receive("nutPACPartReset", function()
	local client = net.ReadEntity()
	if (not IsValid(client) or not client.RemovePACPart) then return end
	if (client.nutPACParts) then
		for _, part in pairs(client.nutPACParts) do
			client:RemovePACPart(part)
		end
		client.nutPACParts = nil
	end
end)
