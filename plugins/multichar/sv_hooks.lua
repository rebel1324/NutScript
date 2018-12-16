function PLUGIN:PlayerNutDataLoaded(client)
	nut.char.restore(client, function(charList)
		if (!IsValid(client)) then return end

		MsgN(
			"Loaded ("..table.concat(charList, ", ")..") for "
			..client:Name()
		)

		for k, v in ipairs(charList) do
			if (nut.char.loaded[v]) then
				nut.char.loaded[v]:sync(client)
			end
		end

		for k, v in ipairs(player.GetAll()) do
			if (v:getChar()) then
				v:getChar():sync(client)
			end
		end

		client.nutCharList = charList
		self:syncCharList(client)
		client.nutLoaded = true

		client:setNutData("intro", true)
	end)
end

function PLUGIN:PostPlayerInitialSpawn(client)
	client:SetNoDraw(true)
	client:SetNotSolid(true)
	client:Lock()

	timer.Simple(1, function()
		if (!IsValid(client)) then return end

		client:KillSilent()
		client:StripAmmo()
	end)
end

function PLUGIN:CanPlayerUseChar(client, character, oldCharacter)
	if (client:getChar() and client:getChar():getID() == character:getID()) then
		return false, "@usingChar"
	end
end

function PLUGIN:PlayerLoadedChar(client, character, oldCharacter)
	client:Spawn()
end

function PLUGIN:OnCharCreated(client, character)
	local id = character:getID()
	MsgN("Created character '"..id.."' for "..client:steamName()..".")
end
