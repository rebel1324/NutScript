local PLUGIN = PLUGIN
PLUGIN.name = "NutScript Intro"
PLUGIN.author = "Cheesenut"
PLUGIN.desc = "NutScript and schema introduction shown when players first join."

nut.config.add("introEnabled", true, "Whether or not intro is enabled.", nil, {
	category = PLUGIN.name
})

nut.config.add("playIntroOnlyOnce", true, "Whether the intro, if enabled, should play every time, or only on first join", nil, {
	category = PLUGIN.name
})

nut.config.add("introFont", "Cambria", "Font of the intro screen", function(_, newFont)
	if CLIENT then
		PLUGIN:LoadFonts(newFont)
	end
end, {
	category = PLUGIN.name
})

if (CLIENT) then
	function PLUGIN:LoadFonts(newFont)
		-- Introduction fancy font.
		local font = newFont or nut.config.get("introFont", "Cambria")

		surface.CreateFont("nutIntroTitleFont", {
			font = font,
			size = 200,
			extended = true,
			weight = 1000
		})

		surface.CreateFont("nutIntroBigFont", {
			font = font,
			size = 48,
			extended = true,
			weight = 1000
		})

		surface.CreateFont("nutIntroMediumFont", {
			font = font,
			size = 28,
			extended = true,
			weight = 1000
		})

		surface.CreateFont("nutIntroSmallFont", {
			font = font,
			size = 22,
			extended = true,
			weight = 1000
		})
	end

	function PLUGIN:CreateIntroduction()
		if (nut.config.get("introEnabled")) then
			return vgui.Create("nutIntro")
		end
	end
end
