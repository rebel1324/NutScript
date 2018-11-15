PLUGIN.name = "NS Character Selection"
PLUGIN.author = "Cheesenut"
PLUGIN.desc = "The NutScript character selection screen."

nut.util.includeDir(PLUGIN.path.."/derma/steps", true)

if (SERVER) then return end

function PLUGIN:LoadFonts(font)
	surface.CreateFont("nutTitle2Font", {
		font = font,
		weight = 200,
		size = 96,
		additive = true
	})
	surface.CreateFont("nutTitle3Font", {
		font = font,
		weight = 200,
		size = 24,
		additive = true
	})
	surface.CreateFont("nutCharButtonFont", {
		font = font,
		weight = 200,
		size = 36,
		additive = true
	})
	surface.CreateFont("nutCharSmallButtonFont", {
		font = font,
		weight = 200,
		size = 22,
		additive = true
	})
end

function PLUGIN:NutScriptLoaded()
	vgui.Create("nutCharacter")
end

function PLUGIN:KickedFromCharacter(id, isCurrentChar)
	if (isCurrentChar) then
		vgui.Create("nutCharacter")
	end
end

function PLUGIN:CreateMenuButtons(tabs)
	tabs["characters"] = function(panel)
		if (IsValid(nut.gui.menu)) then
			nut.gui.menu:Remove()
		end
		vgui.Create("nutCharacter")
	end
end
