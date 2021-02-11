---------------------------------------------------------------------------------------
-- Module for date and time calculations
--
-- Version 2.1.2
-- Copyright (C) 2006, by Jas Latrix (jastejada@yahoo.com)
-- Copyright (C) 2013-2014, by Thijs Schreijer
-- Licensed under MIT, http://opensource.org/licenses/MIT
-- https://github.com/Tieske/date
-- The MIT License (MIT) http://opensource.org/licenses/MIT

-- Copyright (c) 2013-2017 Thijs Schreijer
-- Copyright (c) 2018 Alexander Grist-Hucker, Igor Radovanovic

-- lib based on Helix by Alexander Grist-Hucker, Igor Radovanovic 2018

-- due to UNIX time, normal os.time() cannnot be set before 1970, as 1st Jan 1970 is 0
-- the library fixes said issue. 


nut.date = nut.date or {}
nut.date.lib = nut.date.lib or include("thirdparty/sh_date.lua")
nut.date.timeScale = nut.date.timeScale or nut.config.get("secondsPerMinute", 60)
nut.date.dateObj = nut.date.dateObj or nut.date.lib()
nut.date.start = nut.date.start or CurTime()

if (not nut.config) then
	include("nutscript/gamemode/core/sh_config.lua")
end

nut.config.add("year", 2021, "The starting year of the schema.", function(oldValue, newValue)
	if (SERVER and not nut.date.saving) then
		nut.date.update()
		nut.date.dateObj:setyear(newValue)
		nut.date.sync()
	end
end, {
	data = {min = 0, max = 4000},
	category = "date"
})

nut.config.add("month", 1, "The starting month of the schema.", function(oldValue, newValue)
	if (SERVER and not nut.date.saving) then
		nut.date.update()
		nut.date.dateObj:setmonth(newValue)
		nut.date.sync()
	end
end, {
	data = {min = 1, max = 12},
	category = "date"
})

nut.config.add("day", 1, "The starting day of the schema.", function(oldValue, newValue)
	if (SERVER and not nut.date.saving) then
		nut.date.update()
		nut.date.dateObj:setday(newValue)
		nut.date.sync()
	end
end, {
	data = {min = 1, max = 31},
	category = "date"
})

nut.config.add("secondsPerMinute", 60, "How many real life seconds it takes for a minute to pass in-game.", function(oldValue, newValue)
	if (SERVER and not nut.date.saving) then
		nut.date.updateTimescale(newValue)
		nut.date.sync()
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

	-- called upon server startup. Grabs the saved date data, or creates a new date instance, and sets it as the date object
	function nut.date.initialize()
		local currentDate = nut.data.get("date", nil, false, true)
		-- If we don't have date data already, use current defaults to create a new date data table
		if (not currentDate) then
			currentDate = {
				year = nut.config.get("year"),
				month = nut.config.get("month"),
				day = nut.config.get("day"),
				hour = tonumber(os.date("%H")) or 0,
				min = tonumber(os.date("%M")) or 0,
				sec = tonumber(os.date("%S")) or 0,
			}

			currentDate = nut.date.lib.serialize(nut.date.lib(currentDate))

			nut.data.set("date", currentDate, false, true) -- save the new data
		end

		nut.date.timeScale = nut.config.get("secondsPerMinute", 60)
		nut.date.dateObj = nut.date.lib.construct(currentDate) -- update the date object with the initialized data
	end

	-- Called when date values have been manually changed, updating the date object.
	function nut.date.update()
		nut.date.dateObj = nut.date.get()
		nut.date.start = CurTime()
	end

	-- This is an internal function that sets the amount of real life seconds in an ingame minute. While you can use this function,
	--you probably shouldn't, and rather use the ingame config.
	function nut.date.updateTimescale(secondsPerMinute)
		nut.date.update()
		nut.date.timeScale = secondsPerMinute
	end

	--Syncs the current date with the client/s. This allows the players to have proper date representation, such as in the F1menu.
	function nut.date.sync(client)
		net.Start("nutDateSync")
		net.WriteFloat(nut.date.timeScale)
		net.WriteTable(nut.date.dateObj)
		net.WriteFloat(nut.date.start)

		if (client) then
			net.Send(client)
		else
			net.Broadcast()
		end
	end

	-- saves the current in-game date data.
	function nut.date.save()
		nut.date.saving = true -- prevents from the function from being called before it finishes.

		nut.date.update()

		nut.data.set("date", nut.date.lib.serialize(nut.date.dateObj), false, true) -- saves the current data object

		-- update config to reflect current saved date
		nut.config.set("year", nut.date.dateObj:getyear())
		nut.config.set("month", nut.date.dateObj:getmonth())
		nut.config.set("day", nut.date.dateObj:getday())

		nut.date.saving = nil -- allows the date to be saved again
	end
else
	net.Receive("nutDateSync", function() -- set the clientside values to the updated serverside date values 
		nut.date.timeScale = net.ReadFloat()
		nut.date.dateObj = nut.date.lib.construct(net.ReadTable())
		nut.date.start = net.ReadFloat()
		print("synced")
		PrintTable(nut.date.dateObj)
	end)
end

--- Returns the currently set date.
function nut.date.get()
	-- CurTime increases in value by 1 every second. By getting the difference in seconds between now and the date object initialization,
	local minutesSinceStart = (CurTime() - nut.date.start) / nut.date.timeScale --and divide it by the timescale, we get the minutes elapsed to add to the date start

	return nut.date.dateObj:copy():addminutes(minutesSinceStart)
end

--- Returns a string formatted version of a date.
function nut.date.getFormatted(format, currentDate)
	return (currentDate or nut.date.get()):fmt(format)
end

if SERVER then
	hook.Add("InitializedSchema", "nutInitializeTime", function()
		nut.date.initialize()
	end)

	hook.Add("PlayerInitialSpawn", "nutDateSync", function(client)
		nut.date.sync(client)
	end)

	hook.Add("SaveData", "nutDateSave", function()
		nut.date.save()
	end)
end