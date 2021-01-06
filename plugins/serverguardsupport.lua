PLUGIN.name = "ServerGuard Support"
PLUGIN.author = "Sample Name"
PLUGIN.desc = "Proper ServerGuard support"

-- We don't want the code below to run when ServerGuard isn't installed
if (!serverguard) then return end

-- ServerGuard's restrictions plugin was created to limit toolgun possibilies, but using it with NutScript
-- prevents any admins from using any of the tools, which is obviousbly a bug. NutScript utilizes flag system to limit toolgun usage,
-- so simply disabling this ServerGuard plugin will solve the problem.
serverguard.plugin:Toggle("restrictions", false)