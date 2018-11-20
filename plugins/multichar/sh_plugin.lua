PLUGIN.name = "Multiple Characters"
PLUGIN.author = "Cheesenut"
PLUGIN.desc = "Allows players to have multiple characters."

nutMultiChar = PLUGIN

if (SERVER) then
	function PLUGIN:syncCharList(client)
		if (not client.nutCharList) then return end
		net.Start("nutCharList")
			net.WriteUInt(#client.nutCharList, 32)
			for i = 1, #client.nutCharList do
				net.WriteUInt(client.nutCharList[i], 32)
			end
		net.Send(client)
	end

	function PLUGIN:CanPlayerCreateCharacter(client)
		local count = #client.nutCharList
		local maxChars = hook.Run("GetMaxPlayerCharacter", client)
			or nut.config.get("maxChars", 5)
		if (count >= maxChars) then
			return false
		end
	end
else
	--- Requests to change to the character corresponding to the ID.
	-- @param id A numeric character ID
	-- @return A promise that resolves after the character has been chosen
	function PLUGIN:chooseCharacter(id)
		assert(isnumber(id), "id must be a number")
		local d = deferred.new()
		net.Receive("nutCharChoose", function()
			local message = net.ReadString()
			if (message == "") then
				d:resolve()
				hook.Run("CharacterLoaded", nut.char.loaded[id])
			else
				d:reject(message)
			end
		end)
		net.Start("nutCharChoose")
			net.WriteUInt(id, 32)
		net.SendToServer()
		return d
	end

	--- Requests a character to be created with the given data.
	-- @param data A table with character variable names as keys and values
	-- @return A promise that is resolves to the created character's ID
	function PLUGIN:createCharacter(data)
		assert(istable(data), "data must be a table")
		local d = deferred.new()

		-- Quick client-side validation before sending.
		local payload = {}
		for key, charVar in pairs(nut.char.vars) do
			if (charVar.noDisplay) then continue end

			local value = data[key]
			if (isfunction(charVar.onValidate)) then
				local results = {charVar.onValidate(value, data, LocalPlayer())}
				if (results[1] == false) then
					return d:reject(L(unpack(results, 2)))
				end
			end
			payload[key] = value
		end

		-- Resolve promise after character is created.
		net.Receive("nutCharCreate", function()
			local id = net.ReadUInt(32)
			local reason = net.ReadString()
			if (id > 0) then
				d:resolve(id)
			else
				d:reject(reason)
			end
		end)

		-- Request a character to be created with the given data.
		net.Start("nutCharCreate")
			net.WriteUInt(table.Count(payload), 32)
			for key, value in pairs(payload) do
				net.WriteString(key)
				net.WriteType(value)
			end
		net.SendToServer()
		return d
	end

	--- Requests for a character to be deleted
	-- @param id The numeric ID of the desired character
	function PLUGIN:deleteCharacter(id)
		assert(isnumber(id), "id must be a number")
		net.Start("nutCharDelete")
			net.WriteUInt(id, 32)
		net.SendToServer()
	end
end

nut.util.include("sv_hooks.lua")
nut.util.include("cl_networking.lua")
nut.util.include("sv_networking.lua")
