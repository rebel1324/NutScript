PLUGIN.name = "Vignette"
PLUGIN.author = "Cheesenut"
PLUGIN.desc = "Adds a subtle dark border around the screen."

nut.config.add("vignette", true, "Whether or not the vignette is shown.", nil, {
	category = "appearance"
})

if (SERVER) then return end

local vignette = nut.util.getMaterial("nutscript/gui/vignette.png")
local vignetteAlphaGoal = 0
local vignetteAlphaDelta = 0
local hasVignetteMaterial = vignette != "___error"
local mathApproach = math.Approach

timer.Create("nutVignetteChecker", 1, 0, function()
	local client = LocalPlayer()

	if (IsValid(client)) then
		local data = {}
			data.start = client:GetPos()
			data.endpos = data.start + Vector(0, 0, 768)
			data.filter = client
		local trace = util.TraceLine(data)

		if trace and (trace.Hit) then
			vignetteAlphaGoal = 80
		else
			vignetteAlphaGoal = 0
		end
	end
end)

function PLUGIN:HUDPaintBackground()
	local frameTime = FrameTime()
	local scrW, scrH = surface.ScreenWidth(), surface.ScreenHeight()

	if (hasVignetteMaterial and nut.config.get("vignette")) then
		vignetteAlphaDelta =
			mathApproach(vignetteAlphaDelta, vignetteAlphaGoal, frameTime * 30)

		surface.SetDrawColor(0, 0, 0, 175 + vignetteAlphaDelta)
		surface.SetMaterial(vignette)
		surface.DrawTexturedRect(0, 0, scrW, scrH)
	end
end
