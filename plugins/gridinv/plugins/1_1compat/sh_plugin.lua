PLUGIN.name = "1.1 Inventory Compatibility"
PLUGIN.author = "Cheesenut"
PLUGIN.desc = "Adds compatibility for the old 1.1 inventory."

nut.util.include("sv_migrations.lua")

if (SERVER) then
	function PLUGIN:NutScriptTablesLoaded()
		-- Only migrate data on dedicated servers.
		if (not game.IsDedicated()) then return end
		
		-- If the migration has not started before, start it.
		local data = self:getData(nil, true, true)
		if (data and data.lastMigration) then return end
		local currentHibernationBool = GetConVar("sv_hibernate_think"):GetBool()
		nut.data.set("currentHibernationBool", currentHibernationBool, true, true)
		game.ConsoleCommand("sv_hibernate_think 1\n")
		local WAIT = 10

		-- Add a bot to start timers.
		game.ConsoleCommand("bot\n")
		print("Waiting 10 seconds for inventory migration...")

		-- Do not let players interfere with data migration.
		game.ConsoleCommand("kickall\n")

		hook.Add("CheckPassword", "nutInvDBMigration", function()
			return false, "NutScript inventory data migration in progress"
		end)
			
		timer.Simple(WAIT, function()
			game.ConsoleCommand("nut_migrateinv\n")
		end)
	end
end
