local INV_DATA_TABLE = "invdata"
local INV_TABLE = "inventories"

local COLOR = Color(255, 0, 255)

function PLUGIN:print(message)
	MsgC(COLOR, "[1.1 INV MIGRATION] "..message.."\n")
end

function PLUGIN:whereSameID(res)
	return "_invID = "..nut.db.escape(tostring(res._invID))
end

function PLUGIN:getMigrationFilter()
	local typeIDs = table.GetKeys(nut.inventory.types)
	local escapedTypeIDs = {}
	for i, typeID in ipairs(typeIDs) do
		escapedTypeIDs[i] = "'"..nut.db.escape(typeID).."'"
	end
	return "_invType NOT IN ("..table.concat(escapedTypeIDs, ",")..")"
		.." or _invType IS NULL"
end

function PLUGIN:addInventoryData(res, key, value)
	local d = deferred.new()
	if (value == nil) then
		d:resolve()
		return d
	end
	nut.db.insertTable({
		_invID = res._invID,
		_key = key,
		_value = {value}
	}, function() d:resolve() end, INV_DATA_TABLE)
	return d
end

function PLUGIN:migrateStorageSize(res)
	STORAGE_DEFINITIONS = STORAGE_DEFINITIONS or {}

	local storage
	for _, storageInfo in pairs(STORAGE_DEFINITIONS) do
		if (
			storageInfo.invType == res._invType or
			storageInfo.legacyInvType == res._invType
		) then
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

function PLUGIN:deleteCharID(res)
	-- TODO: add promise support for nut.db.*Table
	local d = deferred.new()
	nut.db.updateTable({
		_charID = NULL
	}, function() d:resolve() end, INV_TABLE, "_invID = "..res._invID)
	return d
end

function PLUGIN:migrateBagSize(res)
	local invID = tonumber(res._invID)
	if (not invID) then return end
	local ITEMS_TABLE = "items"
	local ITEM_FIELDS = {"_itemID", "_uniqueID"}
	local ID_MATCH = nut.db.escape(util.TableToJSON({id = invID}):sub(2, -2))
	local CONDITION = "_data LIKE '%"..ID_MATCH.."%'"
	return nut.db.select(ITEM_FIELDS, ITEMS_TABLE, CONDITION, 1)
		:next(function(queryResults)
			if (not queryResults or not queryResults.results) then
				return
			end

			local uniqueID = queryResults.results[1]._uniqueID
			local itemTable = nut.item.list[uniqueID]
			if (not itemTable) then return print("no itemtable") end
			local itemID = tonumber(queryResults.results[1]._itemID)
			if (not itemID) then return print("bad item id") end

			local w, h = itemTable.invWidth, itemTable.invHeight

			return deferred.all({
				self:addInventoryData(res, "item", itemID),
				self:addInventoryData(res, "w", w),
				self:addInventoryData(res, "h", h),
				self:deleteCharID(res)
			}):next(function()
				self:print(
					"\tMigrated bag inventory for item "..itemID..
					" with (w,h) = ("..tostring(w)..","..tostring(h)..")"
				)
			end)
		end)
end

function PLUGIN:migrateInventorySize(res)
	local w, h = nut.config.get("invW"), nut.config.get("invH")
	if (isnumber(w) and isnumber(h)) then
		local addW = self:addInventoryData(res, "w", w)
		local addH = self:addInventoryData(res, "h", h)
		return deferred.all({addW, addH}):next(function()
			self:print(
				"\tMigrated player inventory "..res._invID.." with"..
				" (w,h) = ("..tostring(w)..","..tostring(h)..")"
			)
		end)
	end
end

function PLUGIN:migrateSize(res)
	return (res._charID ~= 0 and self:migrateInventorySize(res)) or self:migrateStorageSize(res) or self:migrateBagSize(res)
end

function PLUGIN:migrateInvType(res)
	local invID = nut.db.escape(tostring(res._invID))
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
	nut.shuttingDown = true
	self:setData({}, true, true)
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
			-- Store last migration time.
			self:setData({
				lastMigration = os.time()
			}, true, true)

			hook.Add("ShouldDataBeSaved", "nutTemporarySession", function()
				return false
			end)

			self:print("FINISHED MIGRATIONS")
			local hibernationBool = nut.data.get("currentHibernationBool", 0, true, true)
			game.ConsoleCommand("sv_hibernate_think "..tostring(hibernationBool).."\n")
			RunConsoleCommand("changelevel", game.GetMap())
		end)
end

local PLUGIN = PLUGIN
concommand.Add("nut_migrateinv", function(client)
	if (IsValid(client)) then return end
	PLUGIN:migrateInventories()	
end)
