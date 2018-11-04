PLUGIN.name = "Scoreboard"
PLUGIN.author = "Cheesenut"
PLUGIN.desc = "A simple scoreboard that supports recognition."

if (CLIENT) then
	function PLUGIN:ScoreboardHide()
		if (IsValid(nut.gui.score)) then
			nut.gui.score:SetVisible(false)
			CloseDermaMenus()
		end

		gui.EnableScreenClicker(false)
	end

	function PLUGIN:ScoreboardShow()
		if (IsValid(nut.gui.score)) then
			nut.gui.score:SetVisible(false)
			CloseDermaMenus()
		end

		gui.EnableScreenClicker(false)
	end

	function PLUGIN:OnReloaded()
		-- Reload the scoreboard.
		if (IsValid(nut.gui.score)) then
			nut.gui.score:Remove()
		end
	end
end

nut.config.add(
	"sbWidth",
	0.325,
	"Scoreboard's width within percent of screen width.",
	function(oldValue, newValue)
		if (CLIENT and IsValid(nut.gui.score)) then
			nut.gui.score:Remove()
		end
	end,
	{
		form = "Float",
		category = "visual",
		data = {min = 0.2, max = 1}
	}
)

nut.config.add(
	"sbHeight",
	0.825,
	"Scoreboard's height within percent of screen height.",
	function(oldValue, newValue)
		if (CLIENT and IsValid(nut.gui.score)) then
			nut.gui.score:Remove()
		end
	end,
	{
		form = "Float",
		category = "visual",
		data = {min = 0.3, max = 1}
	}
)

nut.config.add(
	"sbTitle",
	GetHostName(),
	"The title of the scoreboard.",
	function(oldValue, newValue)
		if (CLIENT and IsValid(nut.gui.score)) then
			nut.gui.score:Remove()
		end
	end,
	{
		category = "visual"
	}
)

nut.config.add(
	"sbRecog",
	false,
	"Whether or not recognition is used in the scoreboard.",
	nil,
	{
		category = "characters"
	}
)
