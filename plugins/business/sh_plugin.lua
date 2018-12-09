PLUGIN.name = "Business"
PLUGIN.author = "Cheesenut"
PLUGIN.desc = "Adds a menu where players can buy items."

if (SERVER) then
	function PLUGIN:OnPlayerUseBusiness(client, item)
		-- You can manipulate purchased items with this hook.
		-- does not requires any kind of return.
		-- ex) item:setData("businessItem", true)
		-- then every purchased item will be marked as Business Item.
	end
end

function PLUGIN:CanPlayerUseBusiness(client, uniqueID)
	local itemTable = nut.item.list[uniqueID]

	if (!client:getChar()) then
		return false
	end

	if (itemTable.noBusiness) then
		return false
	end
	
	if (itemTable.factions) then
		local allowed = false

		if (type(itemTable.factions) == "table") then
			for k, v in pairs(itemTable.factions) do
				if (client:Team() == v) then
					allowed = true

					break
				end
			end
		elseif (client:Team() != itemTable.factions) then
			allowed = false
		end

		if (!allowed) then
			return false
		end
	end

	if (itemTable.classes) then
		local allowed = false

		if (type(itemTable.classes) == "table") then
			for k, v in pairs(itemTable.classes) do
				if (client:getChar():getClass() == v) then
					allowed = true

					break
				end
			end
		elseif (client:getChar():getClass() == itemTable.classes) then
			allowed = true
		end

		if (!allowed) then
			return false
		end
	end

	if (itemTable.flag) then
		if (!client:getChar():hasFlags(itemTable.flag)) then
			return false
		end
	end
end
