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

	-- ITEM.noBusiness = true means item cannot be sold via business.
	if (itemTable.noBusiness) then
		return false
	end

	-- Check if player has the flag ITEM.flag
	if (
		isstring(itemTable.flag) and
		client:getChar():hasFlags(itemTable.flag)
	) then
		return true
	end

	-- Check if allowed by class.
	local classID = itemTable.classes or itemTable.class
	local charClass = client:getChar():getClass()

	if (isnumber(classID) and charClass == classID) then
		return true
	elseif (istable(classID) and table.HasValue(classID, charClass)) then
		return true
	end

	-- Check if allowed by faction.
	local factions = itemTable.factions or itemTable.faction
	local faction = client:getChar():getFaction()
	if (isnumber(factions) and faction == factions) then
		return true
	elseif (istable(factions) and table.HasValue(factions, faction)) then
		return true
	end
end
