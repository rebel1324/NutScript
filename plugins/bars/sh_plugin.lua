PLUGIN.name = "Bars"
PLUGIN.author = "Cheesenut"
PLUGIN.desc = "Adds bars to display information."

if (SERVER) then return end

function PLUGIN:HUDPaint()
	nut.bar.drawAll()
end
