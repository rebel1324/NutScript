util.AddNetworkString("nutNotify")
util.AddNetworkString("nutNotifyL")

-- Sends a notification to a specified recipient.
function nut.util.notify(message, recipient)
	net.Start("nutNotify")
		net.WriteString(message)
	if (recipient == nil) then
		net.Broadcast()
	else
		net.Send(recipient)
	end
end

-- Sends a translated notification.
function nut.util.notifyLocalized(message, recipient, ...)
	local args = {...}

	-- Allow 2nd argument to just be part of the varargs.
	if (
		recipient ~= nil and
		type(recipient) ~= "table" and
		type(recipient) ~= "Player"
	) then
		table.insert(args, 1, recipient)
		recipient = nil
	end

	net.Start("nutNotifyL")
		net.WriteString(message)
		net.WriteUInt(#args, 8)
		for i = 1, #args do
			net.WriteString(tostring(args[i]))
		end
	if (recipient == nil) then
		net.Broadcast()
	else
		net.Send(recipient)
	end
end

do
	local playerMeta = FindMetaTable("Player")

	-- Utility function to notify a player.
	function playerMeta:notify(message)
		nut.util.notify(message, self)
	end

	-- Utility function to notify a localized message to a player.
	function playerMeta:notifyLocalized(message, ...)
		nut.util.notifyLocalized(message, self, ...)
	end
end
