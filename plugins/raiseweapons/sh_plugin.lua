PLUGIN.name = "Raise Weapons"
PLUGIN.author = "Cheesenut"
PLUGIN.desc = "Allows players to raise/lower weapons by holding R (reload)."

nut.config.add(
	"wepAlwaysRaised",
	false,
	"Whether or not weapons are always raised.",
	nil,
	{category = "server"}
)

nut.util.include("sh_player_extensions.lua")
nut.util.include("sv_hooks.lua")
nut.util.include("cl_hooks.lua")
nut.util.include("sh_hooks.lua")

nut.command.add("toggleraise", {
	onRun = function(client, arguments)
		if ((client.nutNextToggle or 0) < CurTime()) then
			client:toggleWepRaised()
			client.nutNextToggle = CurTime() + 0.5
		end
	end
})
