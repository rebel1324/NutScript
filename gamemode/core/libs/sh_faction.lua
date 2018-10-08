--[[-- 
This module contains all the functions that handle factions.

All functions that handle factions are inside this module, nut.faction. However,
each faction's data (everything you set on each faction file) is stored in a table 
which is then stored in two global tables:
`nut.faction.teams` and `nut.faction.indices`.

Each function inside this module uses one or both of those tables.
]]
-- @module nut.faction


nut.faction = nut.faction or {}
nut.faction.teams = nut.faction.teams or {}
nut.faction.indices = nut.faction.indices or {}

local CITIZEN_MODELS = {
	"models/humans/group01/male_01.mdl",
	"models/humans/group01/male_02.mdl",
	"models/humans/group01/male_04.mdl",
	"models/humans/group01/male_05.mdl",
	"models/humans/group01/male_06.mdl",
	"models/humans/group01/male_07.mdl",
	"models/humans/group01/male_08.mdl",
	"models/humans/group01/male_09.mdl",
	"models/humans/group02/male_01.mdl",
	"models/humans/group02/male_03.mdl",
	"models/humans/group02/male_05.mdl",
	"models/humans/group02/male_07.mdl",
	"models/humans/group02/male_09.mdl",
	"models/humans/group01/female_01.mdl",
	"models/humans/group01/female_02.mdl",
	"models/humans/group01/female_03.mdl",
	"models/humans/group01/female_06.mdl",
	"models/humans/group01/female_07.mdl",
	"models/humans/group02/female_01.mdl",
	"models/humans/group02/female_03.mdl",
	"models/humans/group02/female_06.mdl",
	"models/humans/group01/female_04.mdl"
}

--- Loads data from the factions directory.
-- Loads all factions' data from the 'factions' directory inside your schema folder.
-- @string directory the path to the factions directory.
-- @return nothing.

function nut.faction.loadFromDir(directory)
	for k, v in ipairs(file.Find(directory.."/*.lua", "LUA")) do
		local niceName = v:sub(4, -5)

		FACTION = nut.faction.teams[niceName] or {index = table.Count(nut.faction.teams) + 1, isDefault = true}
			if (PLUGIN) then
				FACTION.plugin = PLUGIN.uniqueID
			end

			nut.util.include(directory.."/"..v, "shared")

			if (!FACTION.name) then
				FACTION.name = "Unknown"
				ErrorNoHalt("Faction '"..niceName.."' is missing a name. You need to add a FACTION.name = \"Name\"\n")
			end

			if (!FACTION.desc) then
				FACTION.desc = "noDesc"
				ErrorNoHalt("Faction '"..niceName.."' is missing a description. You need to add a FACTION.desc = \"Description\"\n")
			end

			if (!FACTION.color) then
				FACTION.color = Color(150, 150, 150)
				ErrorNoHalt("Faction '"..niceName.."' is missing a color. You need to add FACTION.color = Color(1, 2, 3)\n")
			end

			team.SetUp(FACTION.index, FACTION.name or "Unknown", FACTION.color or Color(125, 125, 125))
			
			FACTION.models = FACTION.models or CITIZEN_MODELS
			FACTION.uniqueID = FACTION.uniqueID or niceName

			for k, v in pairs(FACTION.models) do
				if (type(v) == "string") then
					util.PrecacheModel(v)
				elseif (type(v) == "table") then
					util.PrecacheModel(v[1])
				end
			end

			nut.faction.indices[FACTION.index] = FACTION
			nut.faction.teams[niceName] = FACTION
		FACTION = nil
	end
end

--- Gets the faction with the given identifier.
-- The function returns the table of a specific faction. This table is inside nut.faction.indices.
-- @param identifier a number or string.
-- @return the faction table.

function nut.faction.get(identifier)
	return nut.faction.indices[identifier] or nut.faction.teams[identifier]
end

--- Returns an indice from the factions table.
-- The function returns the indice from the nut.faction.indices, when the uniqueID matches
-- the function`s paramenter.
-- @param uniqueID a number.
-- @return the indice, a number.

function nut.faction.getIndex(uniqueID)
	for k, v in ipairs(nut.faction.indices) do
		if (v.uniqueID == uniqueID) then
			return k
		end
	end
end

if (CLIENT) then
	
	--- Checks if faction requires whitelist.
	-- If the specified faction exists, the function checks whether FACTION.isDefault
	-- is true or false.
	-- @param faction indice, a number.
	-- @return a boolean value.
	
	function nut.faction.hasWhitelist(faction)
		local data = nut.faction.indices[faction]

		if (data) then
			if (data.isDefault) then
				return true
			end

			local nutData = nut.localData and nut.localData.whitelists or {}

			return nutData[SCHEMA.folder] and nutData[SCHEMA.folder][data.uniqueID] == true or false
		end

		return false
	end
end
