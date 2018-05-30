nut.plugin = nut.plugin or {}
nut.plugin.list = nut.plugin.list or {}
nut.plugin.unloaded = nut.plugin.unloaded or {}

HOOKS_CACHE = {}

function nut.plugin.load(uniqueID, path, isSingleFile, variable)
	if (hook.Run("PluginShouldLoad", uniqueID) == false) then return end

	variable = variable or "PLUGIN"

	-- Plugins within plugins situation?
	local oldPlugin = PLUGIN
	local PLUGIN = {folder = path, plugin = oldPlugin, uniqueID = uniqueID, name = "Unknown", desc = "Description not available", author = "Anonymous"}

	if (uniqueID == "schema") then
		if (SCHEMA) then
			PLUGIN = SCHEMA
		end

		variable = "SCHEMA"
		PLUGIN.folder = engine.ActiveGamemode()
	elseif (nut.plugin.list[uniqueID]) then
		PLUGIN = nut.plugin.list[uniqueID]
	end

	_G[variable] = PLUGIN
	PLUGIN.loading = true

	if (!isSingleFile) then
		nut.util.includeDir(path.."/libs", true, true)
		nut.attribs.loadFromDir(path.."/attributes")
		nut.faction.loadFromDir(path.."/factions")
		nut.class.loadFromDir(path.."/classes")
		nut.item.loadFromDir(path.."/items")
		nut.util.includeDir(path.."/derma", true)
		nut.plugin.loadEntities(path.."/entities")
		nut.lang.loadFromDir(path.."/languages")
		nut.plugin.loadFromDir(path.."/plugins")

		hook.Run("DoPluginIncludes", path, PLUGIN)
	end
	
	nut.util.include(isSingleFile and path or path.."/sh_"..variable:lower()..".lua", "shared")
	
	PLUGIN.loading = false

	local uniqueID2 = uniqueID

	if (uniqueID2 == "schema") then
		uniqueID2 = PLUGIN.name
	end

	function PLUGIN:setData(value, global, ignoreMap)
		nut.data.set(uniqueID2, value, global, ignoreMap)
	end

	function PLUGIN:getData(default, global, ignoreMap, refresh)
		return nut.data.get(uniqueID2, default, global, ignoreMap, refresh) or {}
	end

	hook.Run("PluginLoaded", uniqueID, PLUGIN)

	if (uniqueID != "schema") then
		PLUGIN.name = PLUGIN.name or "Unknown"
		PLUGIN.desc = PLUGIN.desc or "No description available."
		
		if (!PLUGIN.IsValid) then
			function PLUGIN:IsValid()
				-- if you gonna return false of this, you should remove/make nil your PLUGIN table! 
				return true
			end
		end

		for k, v in pairs(PLUGIN) do
			if (type(v) == "function") then
				hook.Add(k, PLUGIN, v)
			end
		end

		nut.plugin.list[uniqueID] = PLUGIN
		_G[variable] = nil
	else
		-- no matter what you should be loaded.
		function PLUGIN:IsValid()
			return true
		end

		for k, v in pairs(PLUGIN) do
			if (type(v) == "function") then
				hook.Add(k, PLUGIN, v)
			end
		end
	end

	if (PLUGIN.OnLoaded) then
		PLUGIN:OnLoaded()
	end
end

function nut.plugin.loadEntities(path)
	local files, folders

	local function IncludeFiles(path2, clientOnly)
		if (SERVER and file.Exists(path2.."init.lua", "LUA") or CLIENT) then
			nut.util.include(path2.."init.lua", clientOnly and "client" or "server")

			if (file.Exists(path2.."cl_init.lua", "LUA")) then
				nut.util.include(path2.."cl_init.lua", "client")
			end

			return true
		elseif (file.Exists(path2.."shared.lua", "LUA")) then
			nut.util.include(path2.."shared.lua")

			return true
		end

		return false
	end

	local function HandleEntityInclusion(folder, variable, register, default, clientOnly)
		files, folders = file.Find(path.."/"..folder.."/*", "LUA")
		default = default or {}

		for k, v in ipairs(folders) do
			local path2 = path.."/"..folder.."/"..v.."/"

			_G[variable] = table.Copy(default)
				_G[variable].ClassName = v

				if (IncludeFiles(path2, clientOnly) and !client) then
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
				nut.util.include(path.."/"..folder.."/"..v, clientOnly and "client" or "shared")

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
	HandleEntityInclusion("effects", "EFFECT", effects and effects.Register, nil, true)
end

DATA_INIT = DATA_INIT or false
function nut.plugin.initialize()
	nut.plugin.load("schema", engine.ActiveGamemode().."/schema")
	hook.Run("InitializedSchema")

	nut.plugin.loadFromDir("nutscript/plugins")
	nut.plugin.loadFromDir(engine.ActiveGamemode().."/plugins")
	hook.Run("InitializedPlugins")
	
	if (SERVER) then
		if (!DATA_INIT) then
			hook.Run("LoadData")
		end

		DATA_INIT = true
		hook.Run("PostLoadData")
	end
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

function nut.plugin.setUnloaded(uniqueID, state, noSave)
	local plugin = nut.plugin.list[uniqueID]

	if (state) then
		if (plugin.onLoaded) then
			plugin:onLoaded()
		end

		if (nut.plugin.unloaded[uniqueID]) then
			nut.plugin.list[uniqueID] = nut.plugin.unloaded[uniqueID]
			nut.plugin.unloaded[uniqueID] = nil
		else
			return false
		end
	elseif (plugin) then
		if (plugin.onUnload) then
			plugin:onUnload()
		end

		nut.plugin.unloaded[uniqueID] = nut.plugin.list[uniqueID]
		nut.plugin.list[uniqueID] = nil
	else
		return false
	end

	if (SERVER and !noSave) then
		local status

		if (state) then
			status = true
		end

		local unloaded = nut.data.get("unloaded", {}, true, true)
			unloaded[uniqueID] = status
		nut.data.set("unloaded", unloaded, true, true)
	end

	hook.Run("PluginUnloaded", uniqueID)

	return true
end