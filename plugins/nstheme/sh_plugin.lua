PLUGIN.name = "NutScript Theme"
PLUGIN.author = "Cheesenut"
PLUGIN.desc = "Adds a dark Derma skin for NutScript."

if (CLIENT) then
	function PLUGIN:ForceDermaSkin()
		return "nutscript"
	end
end
