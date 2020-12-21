if (!nut.char) then include("sh_character.lua") end

nut.attribs = nut.attribs or {}
nut.attribs.list = nut.attribs.list or {}

function nut.attribs.loadFromDir(directory)
	for k, v in ipairs(file.Find(directory.."/*.lua", "LUA")) do
		local niceName = v:sub(4, -5)

		ATTRIBUTE = nut.attribs.list[niceName] or {}
			if (PLUGIN) then
				ATTRIBUTE.plugin = PLUGIN.uniqueID
			end

			nut.util.include(directory.."/"..v)

			ATTRIBUTE.name = ATTRIBUTE.name or "Unknown"
			ATTRIBUTE.desc = ATTRIBUTE.desc or "No description availalble."

			nut.attribs.list[niceName] = ATTRIBUTE
		ATTRIBUTE = nil
	end
end
nut.attribs.LoadFromDir = nut.attribs.loadFromDir

function nut.attribs.setup(client)
	local character = client:getChar()

	if (character) then
		for k, v in pairs(nut.attribs.list) do
			if (v.onSetup) then
				v:onSetup(client, character:getAttrib(k, 0))
			end
		end
	end
end
nut.attribs.Setup = nut.attribs.setup

-- Add updating of attributes to the character metatable.
do
	local charMeta = nut.meta.character
	
	if (SERVER) then
		function charMeta:updateAttrib(key, value)
			local attribute = nut.attribs.list[key]

			if (attribute) then
				local attrib = self:getAttribs()
				local client = self:getPlayer()

				attrib[key] = math.min((attrib[key] or 0) + value, attribute.maxValue or nut.config.get("maxAttribs", 30))

				if (IsValid(client)) then
					netstream.Start(client, "attrib", self:getID(), key, attrib[key])

					if (attribute.setup) then
						attribute.setup(attrib[key])
					end
				end
			end

			hook.Run("OnCharAttribUpdated", client, self, key, value)
		end
		charMeta.UpdateAttrib = charMeta.updateAttrib

		function charMeta:setAttrib(key, value)
			local attribute = nut.attribs.list[key]

			if (attribute) then
				local attrib = self:getAttribs()
				local client = self:getPlayer()

				attrib[key] = value

				if (IsValid(client)) then
					netstream.Start(client, "attrib", self:getID(), key, attrib[key])

					if (attribute.setup) then
						attribute.setup(attrib[key])
					end
				end
			end
			
			hook.Run("OnCharAttribUpdated", client, self, key, value)
		end
		charMeta.SetAttrib = charMeta.setAttrib

		function charMeta:addBoost(boostID, attribID, boostAmount)
			local boosts = self:getVar("boosts", {})

			boosts[attribID] = boosts[attribID] or {}
			boosts[attribID][boostID] = boostAmount

			hook.Run("OnCharAttribBoosted", self:getPlayer(), self, attribID, boostID, boostAmount)

			return self:setVar("boosts", boosts, nil, self:getPlayer())
		end
		charMeta.AddBoost = charMeta.addBoost
		
		function charMeta:removeBoost(boostID, attribID)
			local boosts = self:getVar("boosts", {})

			boosts[attribID] = boosts[attribID] or {}
			boosts[attribID][boostID] = nil

			hook.Run("OnCharAttribBoosted", self:getPlayer(), self, attribID, boostID, true)

			return self:setVar("boosts", boosts, nil, self:getPlayer())
		end
		charMeta.RemoveBoost = charMeta.removeBoost
	else
		netstream.Hook("attrib", function(id, key, value)
			local character = nut.char.loaded[id]

			if (character) then
				character:getAttribs()[key] = value
			end
		end)
	end

	function charMeta:getBoost(attribID)
		local boosts = self:getBoosts()

		return boosts[attribID]
	end
	charMeta.GetBoost = charMeta.getBoost

	function charMeta:getBoosts()
		return self:getVar("boosts", {})
	end
	charMeta.GetBoosts = charMeta.getBoosts

	function charMeta:getAttrib(key, default)
		local att = self:getAttribs()[key] or default
		local boosts = self:getBoosts()[key]

		if (boosts) then
			for k, v in pairs(boosts) do
				att = att + v
			end
		end 
	
		return att
	end
	charMeta.GetAttrib = charMeta.getAttrib
end
