local MAX_ACTION_DISTANCE = 128
local RULES = {
	AccessIfStorageReceiver = function(inventory, action, context)
		-- Ensure correct storage entity and player.
		local client = context.client
		if (not IsValid(client)) then return end
		local storage = context.storage
		if (not IsValid(storage)) then return end
		if (storage:getInv() ~= inventory) then return end

		-- If the player is too far away from storage, then ignore.
		local distance = storage:GetPos():Distance(client:GetPos())
		if (distance > MAX_ACTION_DISTANCE) then return end

		-- Allow if the player is a receiver of the storage.
		if (storage.receivers[client] and isWithinRange) then
			return true
		end
	end
}

function PLUGIN:StorageInventorySet(storage, inventory)
	inventory:addAccessRule(RULES.AccessIfStorageReceiver)
end

return RULES
