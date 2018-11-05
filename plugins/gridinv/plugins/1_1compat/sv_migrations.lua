local INV_DATA_TABLE = "invdata"
local INV_TABLE = "inventories"

local COLOR = Color(255, 0, 255)

function PLUGIN:print(message)
	MsgC(COLOR, "[1.1 INV MIGRATION] "..message.."\n")
end

function PLUGIN:NutScriptTablesLoaded()
	print(CurTime())
end

function PLUGIN:whereSameID(res)
	return "_invID = "..nut.db.escape(res._invID)
end

function PLUGIN:getMigrationFilter()
	local typeIDs = table.GetKeys(nut.inventory.types)
	local escapedTypeIDs = {}
	for i, typeID in ipairs(typeIDs) do
		escapedTypeIDs[i] = "'"..nut.db.escape(typeID).."'"
	end
	return "_invType NOT IN ("..table.concat(escapedTypeIDs, ",")..")"
end

function PLUGIN:addInventoryData(res, key, value)
	if (value == nil) then
		local d = deferred.new()
		d:resolve()
		return d
	end
	return nut.db.insertTable({
		_invID = res._invID,
		_key = key,
		_value = {value}
	}, nil, INV_DATA_TABLE)
end

function PLUGIN:migrateStorageSize(res)
	STORAGE_DEFINITIONS = STORAGE_DEFINITIONS or {}

	local storage
	for _, storageInfo in pairs(STORAGE_DEFINITIONS) do
		if (storageInfo.invType == res._invType) then
			storage = storageInfo
			break
		end
	end
	if (not storage or not storage.invData) then return end

	local w, h = storage.invData.w, storage.invData.h
	if (isnumber(w) and isnumber(h)) then
		local addW = self:addInventoryData(res, "w", w)
		local addH = self:addInventoryData(res, "h", h)
		return deferred.all({addW, addH}):next(function()
			self:print(
				"\tMigrated storage inventory "..res._invID.." with"..
				" (w,h) = ("..tostring(w)..","..tostring(h)..")"
			)
		end)
	end
end

function PLUGIN:migrateBagSize(res)
	local invID = res._invID
	local ITEMS_TABLE = "items"
	local ITEM_FIELDS = {"_itemID", "_uniqueID"}
	local ID_MATCH = "%\""..util.TableToJSON({id = invID}):sub(2, -2).."\"%"
	local CONDITION = "_data LIKE '"..ID_MATCH.."'"

	return nut.db.select(ITEM_FIELDS, ITEMS_TABLE, CONDITION, 1)
		:next(function(queryResults)
			if (not queryResults or not queryResults.results) then
				return
			end

			local uniqueID = queryResults.results._uniqueID
			local itemTable = nut.item.list[uniqueID]
			if (not itemTable) then return end
			local itemID = tonumber(queryResults.results._itemID)
			if (not itemID) then return end

			local w, h = itemTable.invWidth, itemTable.invHeight
			self:addInventoryData(res, "item", itemID)
			self:addInventoryData(res, "w", w)
			self:addInventoryData(res, "h", h)

			self:print(
				"\tMigrated bag inventory for item "..itemID..
				" with (w,h) = ("..tostring(w)..","..tostring(h)..")"
			)
		end)
end

function PLUGIN:migrateSize(res)
	return self:migrateStorageSize(res) or self:migrateBagSize(res)
end

function PLUGIN:migrateInvType(res)
	local invID = nut.db.escape(res._invID)
	local d = deferred.new()

	nut.db.updateTable({
		_invType = "grid"
	}, function()
		d:resolve()
	end, INV_TABLE, self:whereSameID(res))

	return d:next(function()
		self:print("\tChanged type to grid for "..invID)
	end)
end


function PLUGIN:migrateInventory(res)
	local migrateSize = self:migrateSize(res)
	local migrateInvType = self:migrateInvType(res)
	return deferred.all({migrateSize, migrateInvType})
end

function PLUGIN:migrateInventories()
    self:print("STARTING MIGRATIONS")
	local FIELDS = {"_invID", "_invType"}
	nut.db.select(FIELDS, INV_TABLE, self:getMigrationFilter())
		:next(function(res)
			local migrations = {}
			for i, res in ipairs(res.results or {}) do
				migrations[i] = self:migrateInventory(res)
			end

			return deferred.all(migrations)
		end)
		:next(function()
			self:print("FINISHED MIGRATIONS")
		end)
end

local PLUGIN = PLUGIN
concommand.Add("nut_migrateinv", function(client)
	if (IsValid(client)) then return end
	PLUGIN:migrateInventories()	
end)
