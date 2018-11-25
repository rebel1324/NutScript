util.AddNetworkString("nutStringReq")

local playerMeta = FindMetaTable("Player")

-- Sends a Derma string request to the client.
function playerMeta:requestString(title, subTitle, callback, default)
	-- Overload with requestString(title, subTitle, default)
	local d
	if (type(callback) ~= "function" and default == nil) then
		default = callback
		d = deferred.new()
		callback = function(value)
			d:resolve(value)
		end
	end

	self.nutStrReqs = self.nutStrReqs or {}
	local id = table.insert(self.nutStrReqs, callback)

	net.Start("nutStringReq")
		net.WriteUInt(id, 32)
		net.WriteString(title)
		net.WriteString(subTitle)
		net.WriteString(default or "")
	net.Send(self)

	return d
end

net.Receive("nutStringReq", function(_, client)
	local id = net.ReadUInt(32)
	local value = net.ReadString()

	if (client.nutStrReqs and client.nutStrReqs[id]) then
		client.nutStrReqs[id](value)
		client.nutStrReqs[id] = nil
	end
end)
