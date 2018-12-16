net.Receive("nutStorageUnlock", function()
	local entity = net.ReadEntity()
	hook.Run("StorageUnlockPrompt", entity)
end)

net.Receive("nutStorageOpen", function()
	local entity = net.ReadEntity()
	hook.Run("StorageOpen", entity)
end)

function PLUGIN:exitStorage()
	net.Start("nutStorageExit")
	net.SendToServer()
end
