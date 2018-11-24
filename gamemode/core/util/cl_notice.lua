function nut.util.notify(message)
	chat.AddText(message)
end

-- Creates a translated notification.
function nut.util.notifyLocalized(message, ...)
	nut.util.notify(L(message, ...))
end

-- Receives a notification from the server.
net.Receive("nutNotify", function()
	nut.util.notify(net.ReadString())
end)

-- Receives a notification from the server.
net.Receive("nutNotifyL", function()
	local message = net.ReadString()
	local length = net.ReadUInt(8)

	if (length == 0) then
		return nut.util.notifyLocalized(message)
	end

	local args = {}
	for i = 1, length do
		args[i] = net.ReadString()
	end

	nut.util.notifyLocalized(message, unpack(args))
end)
