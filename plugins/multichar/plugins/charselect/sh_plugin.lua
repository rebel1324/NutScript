PLUGIN.name = "NS Character Selection"
PLUGIN.author = "Cheesenut"
PLUGIN.desc = "The NutScript character selection screen."

if (CLIENT) then
	function PLUGIN:NutScriptLoaded()
		vgui.Create("nutCharacter")
	end
end
