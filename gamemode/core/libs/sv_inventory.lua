if (not nut.inventory) then
	include("sh_inventory.lua")
end

local INV_FIELDS = {"_invID", "_invType"}
local INV_TABLE = "inventories2"
local DATA_FIELDS = {"_key", "_value"}
local DATA_TABLE = "invdata"

function nut.inventory.loadByID(id, noCache)
	local instance = nut.inventory.instances[invID]

	-- Do not reload inventories unless necessary.
	if (instance and not noCache) then
		local d = deferred.new()
		d:resolve(instance)

		return d
	end

	-- Allow for custom ways of loading inventories.
	for typeID, invType in pairs(nut.inventory.types) do
		local loadFunction = rawget(invType, "loadFromStorage")
		if (loadFunction) then
			local d = loadFunction(invType, id)
			if (d) then
				return d
			end
		end
	end

	-- If there were no custom loaders and the id is a normal one, load from
	-- the default database table.
	assert(
		type(id) == "number" and id >= 0,
		"No inventories implement loadFromStorage for ID "..tostring(id)
	)
	return nut.inventory.loadFromDefaultStorage(id)
end

function nut.inventory.loadFromDefaultStorage(id)
	return deferred.all({
		nut.db.select(INV_FIELDS, INV_TABLE, "_invID = "..id, 1),
		nut.db.select(DATA_FIELDS, DATA_TABLE, "_invID = "..id)
	})
	:next(function(res)
		local results = res[1].results and res[1].results[1] or nil
		if (not results) then
			return
		end

		local typeID = results._invType
		local invType = nut.inventory.types[typeID]
		if (not invType) then
			ErrorNoHalt("Inventory "..id.." has invalid type "..typeID.."\n")
			return
		end

		instance = invType:new()
		instance.id = id
		instance.data = {}
		for _, row in ipairs(res[2].results or {}) do
			instance.data[row._key] = util.JSONToTable(row._value)[1]
		end

		nut.inventory.instances[id] = instance
		instance:onLoaded()
		return instance:loadItems():next(function() return instance end, error)
	end, error)
end

function nut.inventory.instance(typeID, initialData)
	local invType = nut.inventory.types[typeID]
	assert(type(invType) == "table", "invalid inventory type "..typeID)
	assert(
		not data or type(initialData) == "table",
		"initialData must be a table for nut.inventory.instance"
	)
	initialData = initialData or {}

	return invType:initializeStorage(initialData)
		:next(function(id)
			local instance = invType:new()
			instance.id = id
			instance.data = initialData

			nut.inventory.instances[id] = instance
			instance:onInstanced()
			return instance
		end)
end

function nut.inventory.loadAllFromCharID(charID)
	local sameCharCondition =
		"_key = 'char' AND _value = '"..util.TableToJSON({charID}).."'"
	return nut.db.select({"_invID"}, DATA_TABLE, sameCharCondition)
		:next(function(res)
			return deferred.map(res.results or {}, function(result)
				return nut.inventory.loadByID(tonumber(result._invID))
			end)
		end)
end

function nut.inventory.deleteByID(id)
	nut.db.delete("invdata", "_invID = "..id)
	nut.db.delete("inventories2", "_invID = "..id)
	nut.db.delete("items", "_invID = "..id)
	nut.inventory.instances[id] = nil
	net.Start("nutInventoryDelete")
		net.WriteType(id)
	net.Broadcast()
end
