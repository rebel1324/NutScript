PLUGIN.name = "NutScript Intro"
PLUGIN.author = "Cheesenut"
PLUGIN.desc = "NutScript and schema introduction shown when players first join."

nut.config.add("introEnabled", true, "Whether or not intro is enabled.", nil, {
	category = PLUGIN.name
})

if (CLIENT) then
	function PLUGIN:LoadFonts()
		-- Introduction fancy font.
		local font = "Cambria"

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
