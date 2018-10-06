if (not nut.inventory) then
	include("sh_inventory.lua")
end

local INV_FIELDS = {"_invID", "_invType", "_data"}
local INV_TABLE = "inventories2"

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
		"No inventories implement loadFromStorage for ID "..id
	)
	return nut.inventory.loadFromDefaultStorage(id)
end

function nut.inventory.loadFromDefaultStorage(id)
	return nut.db.select(INV_FIELDS, INV_TABLE, "_invID = "..id, 1)
		:next(function(res)
			local results = res.results and res.results[1] or nil
			if (not results) then
				return
			end

			local typeID = results._invType
			local data = util.JSONToTable(results._data or "{}")
			local invType = nut.inventory.types[typeID]
			if (not invType) then
				ErrorNoHalt(
					"Inventory "..id.." has invalid type "..typeID.."\n"
				)
				return
			end

			instance = invType:new()
			instance.id = id
			instance.data = data

			nut.inventory.instances[id] = instance
			instance:onLoaded(false)
			return instance
		end)
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
