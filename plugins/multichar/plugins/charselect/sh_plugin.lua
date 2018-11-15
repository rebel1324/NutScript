PLUGIN.name = "NS Character Selection"
PLUGIN.author = "Cheesenut"
PLUGIN.desc = "The NutScript character selection screen."

nut.util.includeDir(PLUGIN.path.."/derma/steps", true)

if (CLIENT) then
	function PLUGIN:NutScriptLoaded()
		vgui.Create("nutCharacter")
	end

	function PLUGIN:KickedFromCharacter(id, isCurrentChar)
		if (isCurrentChar) then
			vgui.Create("nutCharacter")
		end
	end

	hook.Add("CreateMenuButtons", "nutCharacters", function(tabs)
		tabs["characters"] = function(panel)
			if (IsValid(nut.gui.menu)) then
				nut.gui.menu:Remove()
			end
			vgui.Create("nutCharacter")
		end
	end)
end
