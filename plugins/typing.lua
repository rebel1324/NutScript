PLUGIN.name = "Typing Indicator"
PLUGIN.desc = "Shows some text when someone types."
PLUGIN.author = "Chessnut"

if (CLIENT) then
	local TYPE_OFFSET = Vector(0, 0, 80)
	local TYPE_OFFSET_CROUCHED = Vector(0, 0, 48)
	local TYPE_COLOR = Color(250, 250, 250)

	function PLUGIN:StartChat()
		net.Start("nutTypeStatus")
			net.WriteBool(true)
		net.SendToServer()
	end

	function PLUGIN:FinishChat()
		net.Start("nutTypeStatus")
			net.WriteBool(false)
		net.SendToServer()
	end

	local data = {}
	local offset1, offset2, offset3, alpha, y

	function PLUGIN:HUDPaint()
		local ourPos = LocalPlayer():GetPos()
		local localPlayer = LocalPlayer()
		local time = RealTime() * 5

		data.start = localPlayer:EyePos()
		data.filter = localPlayer

		for k, v in ipairs(player.GetAll()) do
			if (
				v ~= localPlayer and
				v:getNetVar("typing") and
				v:GetMoveType() == MOVETYPE_WALK
			) then
				data.endpos = v:EyePos()
				if (util.TraceLine(data).Entity ~= v) then continue end
				local position = v:GetPos()
				alpha = (1 - (ourPos:DistToSqr(position) / 65536)) * 255
				if (alpha <= 0) then continue end

				local screen = (
					position +
					(v:Crouching() and TYPE_OFFSET_CROUCHED or TYPE_OFFSET)
				):ToScreen()
				offset1 = math.sin(time + 2) * alpha
				offset2 = math.sin(time + 1) * alpha
				offset3 = math.sin(time) * alpha
				y = screen.y - 20

				nut.util.drawText("•", screen.x - 8, y, ColorAlpha(TYPE_COLOR, offset1), 1, 1, "nutChatFont", offset1)
				nut.util.drawText("•", screen.x, y, ColorAlpha(TYPE_COLOR, offset2), 1, 1, "nutChatFont", offset2)
				nut.util.drawText("•", screen.x + 8, y, ColorAlpha(TYPE_COLOR, offset3), 1, 1, "nutChatFont", offset3)
			end
		end
	end
else
	util.AddNetworkString("nutTypeStatus")

	net.Receive("nutTypeStatus", function(_, client)
		client:setNetVar("typing", net.ReadBool())
	end)
end
