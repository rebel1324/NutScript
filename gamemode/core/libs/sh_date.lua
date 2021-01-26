nut.date = nut.date or {}
nut.date.lib = nut.date.lib or include("thirdparty/sh_date.lua")
nut.date.timeScale = nut.date.timeScale or nut.config.get("secondsPerMinute", 60)
nut.date.current = nut.date.current or nut.date.lib()
nut.date.start = nut.date.start or CurTime()

if (!nut.config) then
	include("nutscript/gamemode/core/sh_config.lua")
end

nut.config.add("year", 2015, "The starting year of the schema.", function(oldValue, newValue)
	if (SERVER and !nut.date.bSaving) then
		nut.date.resolveOffset()
		nut.date.current:setyear(newValue)
		nut.date.send()
	end
end, {
	data = {min = 0, max = 4000},
	category = "date"
})

nut.config.add("month", 1, "The starting month of the schema.", function(oldValue, newValue)
	if (SERVER and !nut.date.bSaving) then
		nut.date.resolveOffset()
		nut.date.current:setmonth(newValue)
		nut.date.send()
	end
end, {
	data = {min = 1, max = 12},
	category = "date"
})

nut.config.add("day", 1, "The starting day of the schema.", function(oldValue, newValue)
	if (SERVER and !nut.date.bSaving) then
		nut.date.resolveOffset()
		nut.date.current:setday(newValue)
		nut.date.send()
	end
end, {
	data = {min = 1, max = 31},
	category = "date"
})

nut.config.add("secondsPerMinute", 60, "How many seconds it takes for a minute to pass in-game.", function(oldValue, newValue)
	if (SERVER and !nut.date.bSaving) then
		nut.date.updateTimescale(newValue)
		nut.date.send()
	end
end, {
	data = {min = 0.01, max = 120},
	category = "date"
})

nut.config.add("yearAppendix", "", "Add a custom appendix to your date, if you use a non-conventional calender", nil, {
	data = {form = "Generic"},
	category = "date"
})

if (SERVER) then
	util.AddNetworkString("nutDateSync")

	--- Loads the date from disk.

	function nut.date.initialize()
		local currentDate = nut.data.get("date", nil, false, true)

		-- construct new starting date if we don't have it saved already
		if (!currentDate) then
			currentDate = {
				year = nut.config.get("year"),
				month = nut.config.get("month"),
				day = nut.config.get("day"),
				hour = tonumber(os.date("%H")) or 0,
				min = tonumber(os.date("%M")) or 0,
				sec = tonumber(os.date("%S")) or 0
			}

			currentDate = nut.date.lib.serialize(nut.date.lib(currentDate))
			nut.data.set("date", currentDate, false, true)
		end

		nut.date.timeScale = nut.config.get("secondsPerMinute", 60)
		nut.date.current = nut.date.lib.construct(currentDate)
	end

	--- Updates the internal in-game date/time representation and resets the offset.
	function nut.date.resolveOffset()
		nut.date.current = nut.date.get()
		nut.date.start = CurTime()
	end

	--- Updates the time scale of the in-game date/time. The time scale is given in seconds per minute (i.e how many real life
	-- seconds it takes for an in-game minute to pass). You should avoid using this function and use the in-game config menu to
	-- change the time scale instead.
	function nut.date.updateTimescale(secondsPerMinute)
		nut.date.resolveOffset()
		nut.date.timeScale = secondsPerMinute
	end

	--- Sends the current date to a player. This is done automatically when the player joins the server.
	function nut.date.send(client)
		net.Start("nutDateSync")
		print(nut.date.current)
		print(nut.date.start)
		net.WriteFloat(nut.date.timeScale)
		net.WriteTable(nut.date.current)
		net.WriteFloat(nut.date.start)

		if (client) then
			net.Send(client)
		else
			net.Broadcast()
		end
	end

	--- saves the current in-game date to disk.
	function nut.date.save()
		nut.date.bSaving = true

		nut.date.resolveOffset() -- resolve offset so we save the actual time to disk
		nut.data.set("date", nut.date.lib.serialize(nut.date.current), false, true)

		-- update config to reflect current saved date
		nut.config.set("year", nut.date.current:getyear())
		nut.config.set("month", nut.date.current:getmonth())
		nut.config.set("day", nut.date.current:getday())

		nut.date.bSaving = nil
	end
else
	net.Receive("nutDateSync", function()
		local timeScale = net.ReadFloat()
		local currentDate = nut.date.lib.construct(net.ReadTable())
		local startTime = net.ReadFloat()

		nut.date.timeScale = timeScale
		nut.date.current = currentDate
		nut.date.start = startTime
	end)
end

--- Returns the currently set date.
function nut.date.get()
	local minutesSinceStart = (CurTime() - nut.date.start) / nut.date.timeScale

	return nut.date.current:copy():addminutes(minutesSinceStart)
end

--- Returns a string formatted version of a date.
function nut.date.getFormatted(format, currentDate)
	return (currentDate or nut.date.get()):fmt(format)
end

--- Returns a serialized version of a date. This is useful when you need to network a date to clients, or save a date to disk.
function nut.date.getSerialized(currentDate)
	return nut.date.lib.serialize(currentDate or nut.date.get())
end

--- Returns a date object from a table or serialized date.
function nut.date.construct(currentDate)
	return nut.date.lib.construct(currentDate)
end

if SERVER then
	hook.Add("InitializedConfigs", "nutInitializeTime", function()
		nut.date.initialize()
	end)

	hook.Add("PlayerInitialSpawn", "nutDateSend", function()
		nut.date.send()
	end)

	hook.Add("SaveData", "nutDateSave", function()
		nut.date.save()
	end)
end