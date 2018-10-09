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
	}, function(data2, charID)
		nut.db.query("INSERT INTO nut_inventories (_charID) VALUES ("..charID..")", function(_, invID)
			local client

			for k, v in ipairs(player.GetAll()) do
				if (v:SteamID64() == data.steamID) then
					client = v
					break
				end
			end

			local w, h = nut.config.get("invW"), nut.config.get("invH")
			local character = nut.char.new(data, charID, client, data.steamID)
			local inventory = nut.item.createInv(w, h, invID)

			character.vars.inv = {inventory}
			inventory:setOwner(charID)

			nut.char.loaded[charID] = character
			table.insert(nut.char.cache[data.steamID], charID)

			if (callback) then
				callback(charID)
			end
		end)
	end)
end

function nut.char.restore(client, callback, noCache, id)
	local steamID64 = client:SteamID64()
	local cache = nut.char.cache[steamID64]

	if (cache and !noCache) then
		for k, v in ipairs(cache) do
			local character = nut.char.loaded[v]

			if (character and !IsValid(character.client)) then
				character.player = client
			end
		end

		if (callback) then
			callback(cache)
		end

		return
	end

	local fields = "_id, _name, _desc, _model, _attribs, _data, _money, _faction"
	local condition = "_schema = '"..nut.db.escape(SCHEMA.folder).."' AND _steamID = "..steamID64

	if (id) then
		condition = condition.." AND _id = "..id
	end

	nut.db.query("SELECT "..fields.." FROM nut_characters WHERE "..condition, function(data)
		local characters = {}

		for k, v in ipairs(data or {}) do
			local id = tonumber(v._id)

			if (id) then
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
					character.vars.inv = {
						[1] = -1,
					}

					nut.inventory.loadAllFromCharID(id)
						:next(function(inventories)
							
						end)

					nut.db.query("SELECT _invID, _invType FROM nut_inventories WHERE _charID = "..id, function(data)
						if (data and #data > 0) then
							for k, v in pairs(data) do
								local inventoryType = v._invType
								if (inventoryType and isstring(inventoryType) and inventoryType == "NULL") then
									inventoryType = nil
								end

								local w, h = nut.config.get("invW"), nut.config.get("invH")

								local invType 
								if (inventoryType) then
									invType = nut.item.inventoryTypes[inventoryType]

									if (invType) then
										w, h = invType.w, invType.h
									end
								else
									local newW, newH = hook.Run("GetCharacterInventorySize", client, character:getID())
									if (newW and newH) then
										w, h = newW, newH
									end
								end

								nut.item.restoreInv(tonumber(v._invID), w, h, function(inventory)
									if (inventoryType) then
										inventory.vars.invType = inventoryType
										table.insert(character.vars.inv, inventory)
									else
										character.vars.inv[1] = inventory
									end

									inventory:setOwner(id)
								end, true)
							end
						else
							nut.db.insertTable({
								_charID = id
							}, function(_, invID)
								local w, h = nut.config.get("invW"), nut.config.get("invH")
								local inventory = nut.item.createInv(w, h, invID)
								inventory:setOwner(id)

								character.vars.inv = {
									inventory
								}
							end, "inventories")
						end
					end)
				nut.char.loaded[id] = character
			else
				ErrorNoHalt("[NutScript] Attempt to load character '"..(data._name or "nil").."' with invalid ID!")
			end
		end

		if (callback) then
			callback(characters)
		end

		nut.char.cache[steamID64] = characters
	end)
end

function nut.char.loadChar(callback, noCache, id)
	local fields = "_id, _name, _desc, _model, _attribs, _data, _money, _faction"
	local condition = "_schema = '"..nut.db.escape(SCHEMA.folder)

	if (id) then
		condition = condition.."' AND _id = "..id
	else
		ErrorNoHalt("Tried to load invalid character with nut.char.loadChar")

		return
	end

	nut.db.query("SELECT "..fields.." FROM nut_characters WHERE "..condition, function(data)
		for k, v in ipairs(data or {}) do
			local id = tonumber(v._id)

			if (id) then
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

				local character = nut.char.new(data, id)
					hook.Run("CharacterRestored", character)
					character.vars.inv = {
						[1] = -1,
					}

					nut.db.query("SELECT _invID, _invType FROM nut_inventories WHERE _charID = "..id, function(data)
						if (data and #data > 0) then
							for k, v in pairs(data) do
								if (v._invType and isstring(v._invType) and v._invType == "NULL") then
									v._invType = nil
								end

								local w, h = nut.config.get("invW"), nut.config.get("invH")

								local invType 
								if (v._invType) then
									invType = nut.item.inventoryTypes[v._invType]

									if (invType) then
										w, h = invType.w, invType.h
									end
								end

								nut.item.restoreInv(tonumber(v._invID), w, h, function(inventory)
									if (v._invType) then
										inventory.vars.invType = v._invType
										table.insert(character.vars.inv, inventory)
									else
										character.vars.inv[1] = inventory
									end

									inventory:setOwner(id)
								end, true)
							end
						else
							nut.db.insertTable({
								_charID = id
							}, function(_, invID)
								local w, h = nut.config.get("invW"), nut.config.get("invH")
								local inventory = nut.item.createInv(w, h, invID)
								inventory:setOwner(id)

								character.vars.inv = {
									inventory
								}
							end, "inventories")
						end
					end)
				nut.char.loaded[id] = character
			else
				ErrorNoHalt("[NutScript] Attempt to load character '"..(data._name or "nil").."' with invalid ID!")
			end
		end

		if (callback) then
			print("hello")
			callback(character)
		end
	end)
end
