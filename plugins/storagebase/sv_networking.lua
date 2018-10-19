util.AddNetworkString("nutStorageOpen")
util.AddNetworkString("nutStorageLock")
util.AddNetworkString("nutStorageExit")

net.Receive("nutStorageExit", function(_, client)
	local storage = client.nutStorageEntity
	if (IsValid(storage)) then
		storage.receivers[client] = nil
	end
	client.nutStorageEntity = nil
end)

net.Receive("nutStorageUnlock", function(_, client)
	local password = net.ReadString()

	local storage = client.nutStorageEntity
	if (not IsValid(storage)) then return end
	if (client:GetPos():Distance(storage:GetPos()) > 128) then return end

	if (storage.password == password) then
		storage:openInv(client)
	else
		client:notifyLocalized("wrongPassword")
	end
end)
