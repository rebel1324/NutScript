-- Drawing related utility functions.

-- Draw a text with a shadow.
function nut.util.drawText(text, x, y, color, alignX, alignY, font, alpha)
	color = color or color_white

	return draw.TextShadow({
		text = text,
		font = font or "nutGenericFont",
		pos = {x, y},
		color = color,
		xalign = alignX or 0,
		yalign = alignY or 0
	}, 1, alpha or (color.a * 0.575))
end

-- Wraps text so it does not pass a certain width.
function nut.util.wrapText(text, width, font)
	font = font or "nutChatFont"
	surface.SetFont(font)

	local exploded = string.Explode("%s", text, true)
	local line = ""
	local lines = {}
	local w = surface.GetTextSize(text)
	local maxW = 0

	if (w <= width) then
		return {(text:gsub("%s", " "))}, w
	end

	for i = 1, #exploded do
		local word = exploded[i]
		line = line.." "..word
		w = surface.GetTextSize(line)

		if (w > width) then
			lines[#lines + 1] = line
			line = ""

			if (w > maxW) then
				maxW = w
			end
		end
	end

	if (line != "") then
		lines[#lines + 1] = line
	end

	return lines, maxW
end

local LAST_WIDTH = ScrW()
local LAST_HEIGHT = ScrH()

timer.Create("nutResolutionMonitor", 1, 0, function()
	local scrW, scrH = ScrW(), ScrH()

	if (scrW != LAST_WIDTH or scrH != LAST_HEIGHT) then
		hook.Run("ScreenResolutionChanged", LAST_WIDTH, LAST_HEIGHT)

		LAST_WIDTH = scrW
		LAST_HEIGHT = scrH
	end
end)
