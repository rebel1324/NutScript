nut.item = nut.item or {}
nut.item.list = nut.item.list or {}
nut.item.base = nut.item.base or {}
nut.item.instances = nut.item.instances or {}
nut.item.inventories = nut.item.inventories or {
	[0] = {}
}
nut.item.inventoryTypes = nut.item.inventoryTypes or {}

nut.util.include("nutscript/gamemode/core/meta/sh_item.lua")

function nut.item.get(identifier)
	return nut.item.base[identifier] or nut.item.list[identifier]
end

function nut.item.load(path, baseID, isBaseItem)
	local uniqueID = path:match("sh_([_%w]+)%.lua")

	if (uniqueID) then
		uniqueID = (isBaseItem and "base_" or "")..uniqueID
		nut.item.register(uniqueID, baseID, isBaseItem, path)
	elseif (!path:find(".txt")) then
		ErrorNoHalt(
			"[NutScript] Item at '"..path.."' follows invalid "..
			"naming convention!\n"
		)
	end
end

function nut.item.isItem(object)
	return istable(object) and object.isItem == true
end

function nut.item.register(uniqueID, baseID, isBaseItem, path, luaGenerated)
	assert(isstring(uniqueID), "uniqueID must be a string")

	local baseTable = nut.item.base[baseID] or nut.meta.item
	if (baseID) then
		assert(baseTable, "Item "..uniqueID.." has a non-existent base "..baseID)
	end
	local targetTable = (isBaseItem and nut.item.base or nut.item.list)

	if luaGenerated then
		ITEM = setmetatable({
			hooks = table.Copy(baseTable.hooks or {}),
			postHooks = table.Copy(baseTable.postHooks or {}),
			BaseClass = baseTable,
			__tostring = baseTable.__tostring,
		}, {
			__eq = baseTable.__eq,
			__tostring = baseTable.__tostring,
			__index = baseTable
		})

		ITEM.__tostring = baseTable.__tostring
		ITEM.desc = "noDesc"
		ITEM.uniqueID = uniqueID
		ITEM.base = baseID
		ITEM.isBase = isBaseItem
		ITEM.category = ITEM.category or "misc"
		ITEM.functions = ITEM.functions or table.Copy(
			baseTable.functions or NUT_ITEM_DEFAULT_FUNCTIONS
		)
	else
		ITEM = targetTable[uniqueID] or setmetatable({
			hooks = table.Copy(baseTable.hooks or {}),
			postHooks = table.Copy(baseTable.postHooks or {}),
			BaseClass = baseTable,
			__tostring = baseTable.__tostring,
		}, {
			__eq = baseTable.__eq,
			__tostring = baseTable.__tostring,
			__index = baseTable
		})

		ITEM.__tostring = baseTable.__tostring
		ITEM.desc = "noDesc"
		ITEM.uniqueID = uniqueID
		ITEM.base = baseID
		ITEM.isBase = isBaseItem
		ITEM.category = ITEM.category or "misc"
		ITEM.functions = ITEM.functions or table.Copy(
			baseTable.functions or NUT_ITEM_DEFAULT_FUNCTIONS
		)
	end

	if (not luaGenerated and path) then
		nut.util.include(path)
	end

	ITEM:onRegistered()

	local itemType = ITEM.uniqueID
	targetTable[itemType] = ITEM
	ITEM = nil

	return targetTable[itemType]
end

function nut.item.loadFromDir(directory)
	local files, folders

	files = file.Find(directory.."/base/*.lua", "LUA")

	for k, v in ipairs(files) do
		nut.item.load(directory.."/base/"..v, nil, true)
	end

	files, folders = file.Find(directory.."/*", "LUA")

	for k, v in ipairs(folders) do
		if (v == "base") then
			continue
		end

		for k2, v2 in ipairs(file.Find(directory.."/"..v.."/*.lua", "LUA")) do
			nut.item.load(directory.."/"..v .. "/".. v2, "base_"..v)
		end
	end

	for k, v in ipairs(files) do
		nut.item.load(directory.."/"..v)
	end
end

function nut.item.new(uniqueID, id)
	id = id and tonumber(id) or id
	assert(isnumber(id), "non-number ID given to nut.item.new")

	if (
		nut.item.instances[id] and
		nut.item.instances[id].uniqueID == uniqueID
	) then
		return nut.item.instances[id]
	end

	local stockItem = nut.item.list[uniqueID]

	if (stockItem) then
		local item = setmetatable({
			id = id,
			data = {}
		}, {
			__eq = stockItem.__eq,
			__tostring = stockItem.__tostring,
			__index = stockItem
		})

		nut.item.instances[id] = item

		return item
	else
		error(
			"[NutScript] Attempt to create unknown item '"
			..tostring(uniqueID).."'\n"
		)
	end
end

nut.char.registerVar("inv", {
	noNetworking = true,
	noDisplay = true,
	onGet = function(character, index)
		if (index and type(index) != "number") then
			return character.vars.inv or {}
		end

		return character.vars.inv and character.vars.inv[index or 1]
	end,
	onSync = function(character, recipient)
		net.Start("nutCharacterInvList")
			net.WriteUInt(character:getID(), 32)
			net.WriteUInt(#character.vars.inv, 32)

			for i = 1, #character.vars.inv do
				net.WriteType(character.vars.inv[i].id)
			end
		if (recipient == nil) then
			net.Broadcast()
		else
			net.Send(recipient)
		end
	end
})

nut.util.include("item/sv_item.lua")
nut.util.include("item/sh_item_functions.lua")
nut.util.include("item/sv_networking.lua")
nut.util.include("item/cl_networking.lua")
