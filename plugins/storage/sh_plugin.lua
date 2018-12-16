local PLUGIN = PLUGIN

PLUGIN.name = "Storage Base"
PLUGIN.author = "Cheesenut"
PLUGIN.desc = "Useful things for storage plugins."

STORAGE_DEFINITIONS = STORAGE_DEFINITIONS or {}
PLUGIN.definitions = STORAGE_DEFINITIONS

nut.util.include("sv_storage.lua")
nut.util.include("sv_networking.lua")
nut.util.include("sv_access_rules.lua")
nut.util.include("cl_networking.lua")
nut.util.include("cl_password.lua")

nutStorageBase = PLUGIN

if (CLIENT) then
	function PLUGIN:transferItem(itemID)
		if (not nut.item.instances[itemID]) then return end
		net.Start("nutStorageTransfer")
			net.WriteUInt(itemID, 32)
		net.SendToServer()
	end
end

nut.command.add("storagelock", {
	adminOnly = true,
	syntax = "[string password]",
	onRun = function(client, arguments)
		local trace = client:GetEyeTraceNoCursor()
		local ent = trace.Entity

		if (ent and ent:IsValid()) then
			local password = table.concat(arguments, " ")

			if (password != "") then
				ent:setNetVar("locked", true)
				ent.password = password
				client:notifyLocalized("storPass", password)
			else
				ent:setNetVar("locked", nil)
				ent.password = nil
				client:notifyLocalized("storPassRmv")
			end

			PLUGIN:saveStorage()
		else
			client:notifyLocalized("invalid", "Entity")
		end
	end
})
