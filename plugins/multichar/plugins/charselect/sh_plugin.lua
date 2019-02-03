PLUGIN.name = "NS Character Selection"
PLUGIN.author = "Cheesenut"
PLUGIN.desc = "The NutScript character selection screen."

nut.util.includeDir(PLUGIN.path.."/derma/steps", true)

nut.config.add(
	"music",
	"music/hl2_song2.mp3",
	"The default music played in the character menu.",
	nil,
	{category = PLUGIN.name}
)
nut.config.add(
	"musicvolume",
	"0.25",
	"The Volume for the music played in the character menu.",
	nil,
	{
		form = "Float",
		data = {min = 0, max = 1},
		category = PLUGIN.name
	}
)
nut.config.add(
	"backgroundURL",
	"",
	"The URL or HTML for the background of the character menu.",
	nil,
	{category = PLUGIN.name}
)

nut.config.add(
	"charMenuBGInputDisabled",
	true,
	"Whether or not KB/mouse input is disabled in the character background.",
	nil,
	{category = PLUGIN.name}
)

if (SERVER) then return end

local function ScreenScale(size)
	return size * (ScrH() / 900) + 10
end

function PLUGIN:LoadFonts(font)
	surface.CreateFont("nutCharTitleFont", {
		font = font,
		weight = 200,
		size = ScreenScale(70),
		additive = true
	})
	surface.CreateFont("nutCharDescFont", {
		font = font,
		weight = 200,
		size = ScreenScale(24),
		additive = true
	})
	surface.CreateFont("nutCharSubTitleFont", {
		font = font,
		weight = 200,
		size = ScreenScale(12),
		additive = true
	})
	surface.CreateFont("nutCharButtonFont", {
		font = font,
		weight = 200,
		size = ScreenScale(24),
		additive = true
	})
	surface.CreateFont("nutCharSmallButtonFont", {
		font = font,
		weight = 200,
		size = ScreenScale(22),
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
