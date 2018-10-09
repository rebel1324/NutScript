netstream.Hook("charChoose", function(client, id)
	if (client:getChar() and client:getChar():getID() == id) then
		netstream.Start(client, "charLoaded")
		
		return client:notifyLocalized("usingChar")
	end

	local character = nut.char.loaded[id]

	if (character and character:getPlayer() == client) then
		local status, result = hook.Run("CanPlayerUseChar", client, character)

		if (status == false) then
			if (result) then
				if (result:sub(1, 1) == "@") then
					client:notifyLocalized(result:sub(2))
				else
					client:notify(result)
				end
			end

			netstream.Start(client, "charMenu")

			return
		end

		local currentChar = client:getChar()

		if (currentChar) then
			currentChar:save()
		end

		hook.Run("PrePlayerLoadedChar", client, character, currentChar)
		character:setup()
		client:Spawn()

		hook.Run("PlayerLoadedChar", client, character, currentChar)
	else
		ErrorNoHalt("[NutScript] Attempt to load invalid character '"..id.."'\n")
	end
end)

netstream.Hook("charCreate", function(client, data)
	local newData = {}
	
	local maxChars = hook.Run("GetMaxPlayerCharacter", client) or nut.config.get("maxChars", 5)
	local charList = client.nutCharList
	local charCount = table.Count(charList)

	if (charCount >= maxChars) then
		return netstream.Start(client, "charAuthed", "maxCharacters")
	end

	for k, v in pairs(data) do
		local info = nut.char.vars[k]

		if (!info or (!info.onValidate and info.noDisplay)) then
			data[k] = nil
		end
	end

	for k, v in SortedPairsByMemberValue(nut.char.vars, "index") do
		local value = data[k]

		if (v.onValidate) then
			local result = {v.onValidate(value, data, client)}

			if (result[1] == false) then
				return netstream.Start(client, "charAuthed", unpack(result, 2))
			else
				if (result[1] != nil) then
					data[k] = result[1]
				end

				if (v.onAdjust) then
					v.onAdjust(client, data, value, newData)
				end
			end
		end
	end

	data.steamID = client:SteamID64()
		hook.Run("AdjustCreationData", client, data, newData)
	data = table.Merge(data, newData)

	nut.char.create(data, function(id)
		if (IsValid(client)) then
			nut.char.loaded[id]:sync(client)

			netstream.Start(client, "charAuthed", client.nutCharList)
			MsgN("Created character '"..id.."' for "..client:steamName()..".")
			hook.Run("OnCharCreated", client, nut.char.loaded[id])
		end
	end)
	
end)

netstream.Hook("charDel", function(client, id)
	local character = nut.char.loaded[id]
	local steamID = client:SteamID64()
	local isCurrentChar = client:getChar() and client:getChar():getID() == id

	if (character and character.steamID == steamID) then
		for k, v in ipairs(client.nutCharList or {}) do
			if (v == id) then
				table.remove(client.nutCharList, k)
			end
		end

		hook.Run("PreCharDelete", client, character)
		nut.char.loaded[id] = nil
		netstream.Start(nil, "charDel", id)
		nut.db.query("DELETE FROM nut_characters WHERE _id = "..id.." AND _steamID = "..client:SteamID64())
		nut.db.query("SELECT _invID FROM nut_inventories WHERE _charID = "..id, function(data)
			if (data) then
				for k, v in ipairs(data) do
					nut.db.query("DELETE FROM nut_items WHERE _invID = "..v._invID)
					nut.item.inventories[tonumber(v._invID)] = nil
				end
			end

			nut.db.query("DELETE FROM nut_inventories WHERE _charID = "..id)
		end)

		-- other plugins might need to deal with deleted characters.
		hook.Run("OnCharDelete", client, id, isCurrentChar)
		
		if (isCurrentChar) then
			client:setNetVar("char", nil)
			client:Spawn()
		end
	end
end)
