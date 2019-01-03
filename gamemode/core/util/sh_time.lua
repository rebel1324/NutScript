-- Gets the current time in the UTC time-zone.
function nut.util.getUTCTime()
	local date = os.date("!*t")
	local localDate = os.date("*t")
	localDate.isdst = false

	return os.difftime(os.time(date), os.time(localDate))
end

-- Setup for time strings.
local TIME_UNITS = {}
TIME_UNITS["s"] = 1						-- Seconds
TIME_UNITS["m"] = 60					-- Minutes
TIME_UNITS["h"] = 3600					-- Hours
TIME_UNITS["d"] = TIME_UNITS["h"] * 24	-- Days
TIME_UNITS["w"] = TIME_UNITS["d"] * 7	-- Weeks
TIME_UNITS["mo"] = TIME_UNITS["d"] * 30	-- Months
TIME_UNITS["y"] = TIME_UNITS["d"] * 365	-- Years

-- Gets the amount of seconds from a given formatted string.
-- Example: 5y2d7w = 5 years, 2 days, and 7 weeks.
-- If just given a minute, it is assumed minutes.
function nut.util.getStringTime(text)
	local minutes = tonumber(text)

	if (minutes) then
		return math.abs(minutes * 60)
	end

	local time = 0

	for amount, unit in text:lower():gmatch("(%d+)(%a+)") do
		amount = tonumber(amount)

		if (amount and TIME_UNITS[unit]) then
			time = time + math.abs(amount * TIME_UNITS[unit])
		end
	end

	return time
end

function nut.util.dateToNumber(str)
	str = str or os.date("%Y-%m-%d %H:%M:%S", os.time())

	return {
		year = tonumber(str:sub(1, 4)),
		month = tonumber(str:sub(6, 7)),
		day = tonumber(str:sub(9, 10)),
		hour = tonumber(str:sub(12, 13)),
		min = tonumber(str:sub(15, 16)),
		sec = tonumber(str:sub(18, 19)),
	}
end
