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
	[FLAG_SERVER] = Color(200, 200, 220),
	[FLAG_DEV] = Color(200, 200, 220),
}
local consoleColor = Color(50, 200, 50)

-- TODO: Creating MYSQL/SQLLite Query for the logging.
-- SUGG: Do I have to get Seperated Database? For ChatLog, For EventLog.

if (SERVER) then
	if (!nut.db) then
		include("sv_database.lua")
	end

	function nut.log.loadTables()
		file.CreateDir("nutscript/logs")
	end

	function nut.log.resetTables()
	end

	nut.log.types = nut.log.types or {}

	function nut.log.addType(logType, func)
		nut.log.types[logType] = func
	end

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

	function nut.log.addRaw(logString, shouldNotify)		
		if (shouldNotify) then
			nut.log.send(nut.util.getAdmins(), logString)
		end

		Msg("[LOG] ", logString.."\n")

		if (!noSave) then
			file.Append("nutscript/logs/"..os.date("%x"):gsub("/", "-")..".txt", "["..os.date("%X").."]\t"..logString.."\r\n")
		end
	end

	function nut.log.add(client, logType, ...)
		local logString = nut.log.getString(client, logType, ...)
		if (logString == -1) then return end

		hook.Run("OnServerLog", client, logType, ...)

		Msg("[LOG] ", logString.."\n")

		if (!noSave) then
			file.Append("nutscript/logs/"..os.date("%x"):gsub("/", "-")..".txt", "["..os.date("%X").."]\t"..logString.."\r\n")
		end
	end

	function nut.log.open(client)
		local logData = {}

		netstream.Hook(client, "nutLogView", logData)
	end

	function nut.log.send(client, logString, flag)
		netstream.Start(client, "nutLogStream", logString, flag)
	end

	-- Log Types
	nut.log.addType("playerHurt", function(client, ...)
		local data = {...}
		local attacker = data[1] or "unknown"
		local damage = data[2] or 0
		local remainingHealth = data[3] or 0

		return string.format("%s has taken %d damage from %s, leaving them at %d health.", client:Name(), damage, attacker, remaingingHealth)
	end

	nut.log.addType("playerDeath", function(client, ...)
		local data = {...}
		local attacker = data[1] or "unknown"

		return string.format("%s has killed %s.", attacker, client:Name())
	end)

	nut.log.addType("playerConnected", function(client, ...)
		local data = {...}
		local steamID = data[1]

		return string.format("%s[%s] has connected to the server.", client:Name(), steamID or client:SteamID())
	end)

	nut.log.addType("playerDisconnected", function(client, ...)
		return string.format("%s has disconnected from the server.", client:Name())
	end)

	nut.log.addType("itemTake", function(client, ...)
		local data = {...}
		local itemName = data[1] or "unknown"
		local itemCount = data[2] or 1

		return string.format("%s has picked up %dx%s.", client:Name(), itemCount, itemName)
	end)

	nut.log.addType("itemDrop", function(client, ...)
		local data = {...}
		local itemName = data[1] or "unknown"
		local itemCount = data[2] or 1

		return string.format("%s has lost %dx%s.", client:Name(), itemCount, itemName)
	end)

	nut.log.addType("command", function(client, ...)
		local data = {...}
		local text = data[1] or ""
		local args = data[2] or ""

		return string.format("%s has used \"%s\" with arguments: %s.", client:Name(), text, args)
	end)

	nut.log.addType("chat", function(client, ...)
		local data = {...}
		local chatType = data[1] or "IC"
		local message = data[2] or ""

		return string.format("[%s]%s has said: \"%s\".", chatType, client:Name(), message)
	end)

	nut.log.addType("money", function(client, ...)
		local data = {...}
		local amount = data[1] or 0

		return string.format("%s's money has changed by %d.", client:Name(), amount)
	end)
else
	netstream.Hook("nutLogStream", function(logString, flag)
		MsgC(consoleColor, "[SERVER] ", color_white, logString.."\n")
	end)
end