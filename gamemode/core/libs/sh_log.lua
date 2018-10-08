--[[--
This module contains all the functions that handle logging.

NutScript has a logging system. It logs core related actions and custom actions
that you wish to be logged. The framework seperates all logs into different
categories.

<b>Enumerations:</b>

FLAG_NORMAL = 0 </br>
FLAG_SUCCESS = 1 </br>
FLAG_WARNING = 2 </br>
FLAG_DANGER = 3 </br>
FLAG_SERVER = 4 </br>
FLAG_DEV = 5 </br>


Whenever you wish to log a command or something else, you use nut.log.add function.

]]
-- @module nut.log

FLAG_NORMAL = 0
FLAG_SUCCESS = 1
FLAG_WARNING = 2
FLAG_DANGER = 3
FLAG_SERVER = 4
FLAG_DEV = 5

nut.log = nut.log or {}
nut.log.color = {
	[FLAG_NORMAL] = Color(200, 200, 200),
	[FLAG_SUCCESS] = Color(50, 200, 50),
	[FLAG_WARNING] = Color(255, 255, 0),
	[FLAG_DANGER] = Color(255, 50, 50),
	[FLAG_SERVER] = Color(120, 0, 255),
	[FLAG_DEV] = Color(0, 160, 255),
}
local consoleColor = Color(50, 200, 50)

-- TODO: Creating MYSQL/SQLLite Query for the logging.
-- SUGG: Do I have to get Seperated Database? For ChatLog, For EventLog.

if (SERVER) then
	if (!nut.db) then
		include("sv_database.lua")
	end
	
	--- Creates the nutscript logs directory under DATA.
	-- @return nothing.

	function nut.log.loadTables()
		file.CreateDir("nutscript/logs")
	end

	nut.log.types = nut.log.types or {}
	
	--- Allows you to add a different logs section.
	-- Adds the new logs category to `nut.log.types`.
	-- @string logType a log's category.
	-- @param func a function.
	-- @return nothing.
	
	function nut.log.addType(logType, func)
		nut.log.types[logType] = func
	end
	
	--- Gets a specific log.
	-- If there is no logType in `nut.log.types` table, the function return "-1"
	-- value.
	-- @player client a player.
	-- @string logType a log's category.
	-- @return a string.

	function nut.log.getString(client, logType, ...)
		local text = nut.log.types[logType]
		
		if (text) then
			if (isfunction(text)) then
				text = text(client, ...)
			end
		else
			text = -1
		end

		return text
	end

	--- Sends a log to all the staff members online with a specific flag.
	-- The function also appends the log to a logfile, under the logs directory.
	-- @string logString a log entry.
	-- @param flag a number.
	-- @return nothing.

	function nut.log.addRaw(logString, flag)		
		nut.log.send(nut.util.getAdmins(), logString, flag)
		
		MsgC(consoleColor, "[LOG] ", nut.log.color[flag] or color_white, logString .. "\n")
		
		if (!noSave) then
			file.Append("nutscript/logs/"..os.date("%x"):gsub("/", "-")..".txt", "["..os.date("%X").."]\t"..logString.."\r\n")
		end
	end
	
	--- Sends a log to all the staff members online.
	-- The function also appends the log to a logfile, under the logs directory.
	-- @player client a player.
	-- @string logType a log's category.
	-- @return nothing.

	function nut.log.add(client, logType, ...)
		local logString = nut.log.getString(client, logType, ...)
		if (logString == -1) then return end

		nut.log.send(nut.util.getAdmins(), logString)
		
		MsgC(consoleColor, "[LOG] ", color_white, logString .. "\n")
		
		if (!noSave) then
			file.Append("nutscript/logs/"..os.date("%x"):gsub("/", "-")..".txt", "["..os.date("%X").."]\t"..logString.."\r\n")
		end
	end

	function nut.log.open(client)
		local logData = {}

		netstream.Hook(client, "nutLogView", logData)
	end
	
	--- Shows a log to the specified recipient.
	-- @player client a player.
	-- @string logString a log entry.
	-- @param flag a number.

	function nut.log.send(client, logString, flag)
		netstream.Start(client, "nutLogStream", logString, flag)
	end
else
	netstream.Hook("nutLogStream", function(logString, flag)
		MsgC(consoleColor, "[SERVER] ", nut.log.color[flag] or color_white, logString .. "\n")
	end)
end
