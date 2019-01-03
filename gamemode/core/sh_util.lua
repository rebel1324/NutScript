-- This file includes utility functions that are pretty isolated.

-- Includes a file from the prefix.
function nut.util.include(fileName, state)
	if (!fileName) then
		error("[NutScript] No file name specified for including.")
	end

	-- Only include server-side if we're on the server.
	if ((state == "server" or fileName:find("sv_")) and SERVER) then
		return include(fileName)
	-- Shared is included by both server and client.
	elseif (state == "shared" or fileName:find("sh_")) then
		if (SERVER) then
			-- Send the file to the client if shared so they can run it.
			AddCSLuaFile(fileName)
		end

		return include(fileName)
	-- File is sent to client, included on client.
	elseif (state == "client" or fileName:find("cl_")) then
		if (SERVER) then
			AddCSLuaFile(fileName)
		else
			return include(fileName)
		end
	end
end

-- Include files based off the prefix within a directory.
function nut.util.includeDir(directory, fromLua, recursive)
	-- By default, we include relatively to NutScript.
	local baseDir = "nutscript"

	-- If we're in a schema, include relative to the schema.
	if (SCHEMA and SCHEMA.folder and SCHEMA.loading) then
		baseDir = SCHEMA.folder.."/schema/"
	else
		baseDir = baseDir.."/gamemode/"
	end 
	
	if recursive then
		local function AddRecursive(folder)
			local files, folders = file.Find(folder.."/*", "LUA")

			if (!files) then
				MsgN("Warning! This folder is empty!")
				return
			end

			for k, v in pairs(files) do
				nut.util.include(folder .. "/" .. v)
			end

			for k, v in pairs(folders) do
				AddRecursive(folder .. "/" .. v)
			end
		end
		AddRecursive((fromLua and "" or baseDir)..directory)
	else
		-- Find all of the files within the directory.
		for k, v in ipairs(
			file.Find((fromLua and "" or baseDir)..directory.."/*.lua", "LUA")
		) do
			-- Include the file from the prefix.
			nut.util.include(directory.."/"..v)
		end
	end
end

-- Returns the address:port of the server.
function nut.util.getAddress()
	ErrorNoHalt(
		"nut.util.getAddress() is deprecated, use game.GetIPAddress()\n"
	)
	return game.GetIPAddress()
end

-- Returns a table of admin players
function nut.util.getAdmins(isSuper)
	local admins = {}

	for k, v in ipairs(player.GetAll()) do
		if (isSuper) then
			if (v:IsSuperAdmin()) then
				admins[#admins + 1] = v
			end
		else
			if (v:IsAdmin()) then
				admins[#admins + 1] = v
			end
		end
	end

	return admins
end

-- Returns true if a string is a 32-bit SteamID.
function nut.util.isSteamID(value)
	if (string.match(value, "STEAM_(%d+):(%d+):(%d+)")) then
		return true
	end
	return false
end

-- Finds a player by matching their name or steam id.
function nut.util.findPlayer(identifier, allowPatterns)
	if (nut.util.isSteamID(identifier)) then
		return player.GetBySteamID(identifier)
	end

	if (!allowPatterns) then
		identifier = string.PatternSafe(identifier)
	end

	for k, v in ipairs(player.GetAll()) do
		if (nut.util.stringMatches(v:Name(), identifier)) then
			return v
		end
	end
end

function nut.util.gridVector(vec, gridSize)
	if (gridSize <= 0) then
		gridSize = 1
	end

	for i = 1, 3 do
		vec[i] = vec[i] / gridSize
		vec[i] = math.Round(vec[i])
		vec[i] = vec[i] * gridSize
	end

	return vec
end


function nut.util.getAllChar()
	local charTable = {}

	for k, v in ipairs(player.GetAll()) do
		if (v:getChar()) then
			table.insert(charTable, v:getChar():getID())
		end
	end

	return charTable
end

-- Misc. player stuff.
do
	local playerMeta = FindMetaTable("Player")

	-- Default list of weapons that are always raised.
	ALWAYS_RAISED = ALWAYS_RAISED or {}
	ALWAYS_RAISED["weapon_physgun"] = true
	ALWAYS_RAISED["gmod_tool"] = true
	ALWAYS_RAISED["nut_poshelper"] = true

	-- Returns how many seconds the player has played on the server in total.

	if (SERVER) then
		function playerMeta:getPlayTime()
			local diff = os.time(nut.util.dateToNumber(self.lastJoin))
				- os.time(nut.util.dateToNumber(self.firstJoin))
			return diff + (RealTime() - (self.nutJoinTime or RealTime()))
		end
	else
		function playerMeta:getPlayTime()
			local diff = os.time(nut.util.dateToNumber(nut.lastJoin))
				- os.time(nut.util.dateToNumber(nut.firstJoin))
			return diff + (RealTime() - nut.joinTime or 0)
		end
	end

	-- Returns true if the player is moving at least the running speed.
	local vectorLength2D = FindMetaTable("Vector").Length2D

	function playerMeta:isRunning()
		return vectorLength2D(self.GetVelocity(self)) > (self.GetWalkSpeed(self) + 10)
	end

	-- Checks if the player has a female model.
	function playerMeta:isFemale()
		local model = self:GetModel():lower()

		return model:find("female")
			or model:find("alyx")
			or model:find("mossman")
			or nut.anim.getModelClass(model) == "citizen_female"
	end

	-- Returns a good position in front of the player for an entity.
	function playerMeta:getItemDropPos()
		-- Start a trace.
		local data = {}
			data.start = self:GetShootPos()
			data.endpos = self:GetShootPos() + self:GetAimVector()*86
			data.filter = self
		local trace = util.TraceLine(data)
			data.start = trace.HitPos
			data.endpos = data.start + trace.HitNormal*46
			data.filter = {}
		trace = util.TraceLine(data)

		return trace.HitPos
	end

	if (SERVER) then
		-- Removes a player's weapon and restricts interactivity.
		function playerMeta:setRestricted(state, noMessage)
			if (state) then
				self:setNetVar("restricted", true)

				if (noMessage) then
					self:setLocalVar("restrictNoMsg", true)
				end

				self.nutRestrictWeps = self.nutRestrictWeps or {}

				for k, v in ipairs(self:GetWeapons()) do
					self.nutRestrictWeps[k] = v:GetClass()
				end
				timer.Simple(0, function()
					self:StripWeapons()
				end)
				hook.Run("OnPlayerRestricted", self)
			else
				self:setNetVar("restricted")

				if (self:getLocalVar("restrictNoMsg")) then
					self:setLocalVar("restrictNoMsg")
				end

				if (self.nutRestrictWeps) then
					for k, v in ipairs(self.nutRestrictWeps) do
						self:Give(v)
					end

					self.nutRestrictWeps = nil
				end

				hook.Run("OnPlayerUnRestricted", self)
			end
		end
	end
end

nut.util.cachedMaterials = nut.util.cachedMaterials or {}

-- Returns a single cached copy of a material or creates it if it doesn't exist.
function nut.util.getMaterial(materialPath)
	-- Cache the material.
	nut.util.cachedMaterials[materialPath] =
		nut.util.cachedMaterials[materialPath]
		or Material(materialPath)
	return nut.util.cachedMaterials[materialPath]
end

nut.util.includeDir("nutscript/gamemode/core/util", true)
