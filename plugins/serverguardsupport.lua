PLUGIN.name = "ServerGuard Support"
PLUGIN.author = "Sample Name"
PLUGIN.desc = "Disables ServerGuard's restrictions plugin"
PLUGIN.players = {}

-- ServerGuard's restrictions plugin was created to limit toolgun possibilies, but using it with NutScript
-- prevents any admins from using any of the tools, which is obviousbly a bug. NutScript utilizes flag system to limit toolgun usage,
-- so simply disabling this ServerGuard plugin will solve the problem.
if (serverguard) then
	serverguard.plugin:Toggle("restrictions", false)
end