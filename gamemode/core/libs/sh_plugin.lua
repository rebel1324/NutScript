nut.plugin = nut.plugin or {}
nut.plugin.list = nut.plugin.list or {}
nut.plugin.unloaded = nut.plugin.unloaded or {}

function nut.plugin.load(uniqueID, path, isSingleFile, variable)
	variable = uniqueID == "schema" and "SCHEMA" or variable or "PLUGIN"
	if (hook.Run("PluginShouldLoad", uniqueID) == false) then return end

	-- Do not load non-existent plugins.
	if (
		not isSingleFile and
		not file.Exists(path.."/sh_"..variable:lower()..".lua", "LUA")
	) then
		return
	end

	-- Create a table to store plugin information.
	local oldPlugin = PLUGIN
	local PLUGIN = {
		folder = path,
		plugin = oldPlugin,
		uniqueID = uniqueID,
		name = "Unknown",
		desc = "Description not available",
		author = "Anonymous",
		IsValid = function(plugin) return true end
	}

	if (uniqueID == "schema") then
		-- If the plugin is actually the schema, overwrite delevant variables.
		if (SCHEMA) then
			PLUGIN = SCHEMA
		end
		variable = "SCHEMA"
		PLUGIN.folder = engine.ActiveGamemode()
	elseif (nut.plugin.list[uniqueID]) then
		-- Handle auto-reload.
		PLUGIN = nut.plugin.list[uniqueID]
	end

	-- Expose PLUGIN as a global so the plugin files can access the table.
	_G[variable] = PLUGIN

	-- Then include all of the plugin files so they run.
	PLUGIN.loading = true
	PLUGIN.path = path

	if (not isSingleFile) then
		nut.plugin.loadExtras(path)
	end
	nut.util.include(
		isSingleFile and path or path.."/sh_"..variable:lower()..".lua",
		"shared"
	)
	PLUGIN.loading = false

	-- Add helper methods for persistent data.
	local uniqueID2 = uniqueID
	if (uniqueID2 == "schema") then
		uniqueID2 = PLUGIN.name
	end

	function PLUGIN:setData(value, global, ignoreMap)
		nut.data.set(uniqueID2, value, global, ignoreMap)
	end

	function PLUGIN:getData(default, global, ignoreMap, refresh)
		return nut.data.get(uniqueID2, default, global, ignoreMap, refresh)
			or {}
	end

	-- Add listeners for the plugin hooks so they run.
	for k, v in pairs(PLUGIN) do
		if (type(v) == "function") then
			hook.Add(k, PLUGIN, v)
		end
	end

	-- Store a reference to the plugin for later access.
	if (uniqueID == "schema") then
		function PLUGIN:IsValid() return true end
	else
		nut.plugin.list[uniqueID] = PLUGIN
		_G[variable] = oldPlugin
	end

	-- Signal that a plugin has finished loading.
	hook.Run("PluginLoaded", uniqueID, PLUGIN)
	if (PLUGIN.OnLoaded) then
		PLUGIN:OnLoaded()
	end
end

function nut.plugin.loadExtras(path)
	nut.util.includeDir(path.."/libs", true, true)
	nut.faction.loadFromDir(path.."/factions")
	nut.class.loadFromDir(path.."/classes")
	nut.util.includeDir(path.."/derma", true)
	nut.plugin.loadEntities(path.."/entities")
	nut.lang.loadFromDir(path.."/languages")
	nut.plugin.loadFromDir(path.."/plugins")

	hook.Run("DoPluginIncludes", path, PLUGIN)

	local hookID = "nutItems"..path
	hook.Add("InitializedPlugins", hookID, function()
		nut.item.loadFromDir(path.."/items")
		hook.Remove("InitializedPlugins", hookID)
	end)
end

function nut.plugin.loadEntities(path)
	local files, folders

	local function IncludeFiles(path2, clientOnly)
		if ((SERVER and file.Exists(path2.."init.lua", "LUA")) or (CLIENT and file.Exists(path2.."cl_init.lua", "LUA"))) then
			nut.util.include(
				path2.."init.lua",
				clientOnly and "client" or "server"
			)

			if (file.Exists(path2.."cl_init.lua", "LUA")) then
				nut.util.include(path2.."cl_init.lua", "client")
			end

			return true
		elseif (file.Exists(path2.."shared.lua", "LUA")) then
			nut.util.include(path2.."shared.lua", "shared")

			return true
		end

		return false
	end

	local function HandleEntityInclusion(
		folder, variable, register, default, clientOnly
	)
		files, folders = file.Find(path.."/"..folder.."/*", "LUA")
		default = default or {}

		for k, v in ipairs(folders) do
			local path2 = path.."/"..folder.."/"..v.."/"

			_G[variable] = table.Copy(default)
				_G[variable].ClassName = v

				if (IncludeFiles(path2, clientOnly) and not client) then
					if (clientOnly) then
						if (CLIENT) then
							register(_G[variable], v)
						end
					else
						register(_G[variable], v)
					end
				end
			_G[variable] = nil
		end

		for k, v in ipairs(files) do
			local niceName = string.StripExtension(v)

			_G[variable] = table.Copy(default)
				_G[variable].ClassName = niceName
				nut.util.include(
					path.."/"..folder.."/"..v,
					clientOnly and "client" or "shared"
				)

				if (clientOnly) then
					if (CLIENT) then
						register(_G[variable], niceName)
					end
				else
					register(_G[variable], niceName)
				end
			_G[variable] = nil
		end
	end

	-- Include entities.
	HandleEntityInclusion("entities", "ENT", scripted_ents.Register, {
		Type = "anim",
		Base = "base_gmodentity",
		Spawnable = true
	})

	-- Include weapons.
	HandleEntityInclusion("weapons", "SWEP", weapons.Register, {
		Primary = {},
		Secondary = {},
		Base = "weapon_base"
	})

	-- Include effects.
	HandleEntityInclusion(
		"effects", "EFFECT", effects and effects.Register, nil, true
	)
end

function nut.plugin.initialize()
	nut.plugin.loadFromDir(engine.ActiveGamemode().."/preload")

	nut.plugin.load("schema", engine.ActiveGamemode().."/schema")
	hook.Run("InitializedSchema")

	nut.plugin.loadFromDir("nutscript/plugins")
	nut.plugin.loadFromDir(engine.ActiveGamemode().."/plugins")
	hook.Run("InitializedPlugins")
	hook.Run("InitializedItems")
end

function nut.plugin.loadFromDir(directory)
	local files, folders = file.Find(directory.."/*", "LUA")

	for k, v in ipairs(folders) do
		nut.plugin.load(v, directory.."/"..v)
	end

	for k, v in ipairs(files) do
		nut.plugin.load(string.StripExtension(v), directory.."/"..v, true)
	end
end

function nut.plugin.setDisabled(uniqueID, disabled)
	disabled = tobool(disabled)

	local oldData = table.Copy(nut.data.get("unloaded", {}, false, true))
	oldData[uniqueID] = disabled
	nut.data.set("unloaded", oldData, false, true, true)
end

function nut.plugin.isDisabled(uniqueID)
	if (istable(DISABLED_PLUGINS) and DISABLED_PLUGINS[uniqueID]) then
		return true
	end

	return nut.data.get("unloaded", {}, false, true)[uniqueID] == true
end
