function nut.char.create(data, callback)
	local timeStamp = os.date("%Y-%m-%d %H:%M:%S", os.time())

	data.money = data.money or nut.config.get("defMoney", 0)

	nut.db.insertTable({
		_name = data.name or "",
		_desc = data.desc or "",
		_model = data.model or "models/error.mdl",
		_schema = SCHEMA and SCHEMA.folder or "nutscript",
		_createTime = timeStamp,
		_lastJoinTime = timeStamp,
		_steamID = data.steamID,
		_faction = data.faction or "Unknown",
		_money = data.money,
		_data = data.data
	}, function(_, charID)
		local client
		for k, v in ipairs(player.GetAll()) do
			if (v:SteamID64() == data.steamID) then
				client = v
				break
			end
		end

		local character = nut.char.new(data, charID, client, data.steamID)
		character.vars.inv = {}
		hook.Run("CreateDefaultInventory", character)

		nut.char.loaded[charID] = character
		if (callback) then
			callback(charID)
		end
	end)
end

function nut.char.restore(client, callback, noCache, id)
	local steamID64 = client:SteamID64()
	local fields =
		"_id, _name, _desc, _model, _attribs, _data, _money, _faction"
	local condition = "_schema = '"..nut.db.escape(SCHEMA.folder)
		.."' AND _steamID = "..steamID64

	if (id) then
		condition = condition.." AND _id = "..id
	end

	local query = "SELECT "..fields.." FROM nut_characters WHERE "..condition
	nut.db.query(query, function(data)
		local characters = {}

		for k, v in ipairs(data or {}) do
			local id = tonumber(v._id)

			if (not id) then
				ErrorNoHalt(
					"[NutScript] Attempt to load character '"
					..(data._name or "nil").."' with invalid ID!"
				)
				continue
			end
			local data = {}

			for k2, v2 in pairs(nut.char.vars) do
				if (v2.field and v[v2.field]) then
					local value = tostring(v[v2.field])

					if (type(v2.default) == "number") then
						value = tonumber(value) or v2.default
					elseif (type(v2.default) == "boolean") then
						value = tobool(vlaue)
					elseif (type(v2.default) == "table") then
						value = util.JSONToTable(value)
					end

					data[k2] = value
				end
			end

			characters[#characters + 1] = id

			local character = nut.char.new(data, id, client)
			hook.Run("CharacterRestored", character)
			character.vars.inv = {}

			nut.inventory.loadAllFromCharID(id)
				:next(function(inventories)
					if (#inventories == 0) then
						hook.Run("CreateDefaultInventory", character)
						return
					end
					for _, inventory in ipairs(inventories) do
						inventory:sync()
					end
				end)
			nut.char.loaded[id] = character
		end

		if (callback) then
			callback(characters)
		end
	end)
end
