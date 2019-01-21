PLUGIN.name = "Grid Storage"
PLUGIN.author = "Cheesenut"
PLUGIN.desc = "Storage of items inside a grid."

local INV_TYPE_ID = "grid"

STORAGE_DEFINITIONS = STORAGE_DEFINITIONS or {}
STORAGE_DEFINITIONS["models/props_junk/wood_crate001a.mdl"] = {
	name = "Wood Crate",
	desc = "A crate made out of wood.",
	invType = INV_TYPE_ID,
	invData = {
		w = 4,
		h = 4
	}
}
STORAGE_DEFINITIONS["models/props_c17/lockers001a.mdl"] = {
	name = "Locker",
	desc = "A white locker.",
	invType = INV_TYPE_ID,
	invData = {
		w = 4,
		h = 6
	}
}
STORAGE_DEFINITIONS["models/props_wasteland/controlroom_storagecloset001a.mdl"] = {
	name = "Metal Closet",
	desc = "A green storage closet.",
	invType = INV_TYPE_ID,
	invData = {
		w = 5,
		h = 7
	}
}
STORAGE_DEFINITIONS["models/props_wasteland/controlroom_filecabinet002a.mdl"] = {
	name = "File Cabinet",
	desc = "A metal file cabinet.",
	invType = INV_TYPE_ID,
	invData = {
		w = 3,
		h = 6
	}
}
STORAGE_DEFINITIONS["models/props_c17/furniturefridge001a.mdl"] = {
	name = "Refrigerator",
	desc = "A metal box to keep food in",
	invType = INV_TYPE_ID,
	invData = {
		w = 3,
		h = 4
	}
}
STORAGE_DEFINITIONS["models/props_wasteland/kitchen_fridge001a.mdl"] = {
	name = "Large Refrigerator",
	desc = "A large metal box to keep even more food in.",
	invType = INV_TYPE_ID,
	invData = {
		w = 4,
		h = 5
	}
}
STORAGE_DEFINITIONS["models/props_junk/trashbin01a.mdl"] = {
	name = "Trash Bin",
	desc = "A container for junk.",
	invType = INV_TYPE_ID,
	invData = {
		w = 1,
		h = 3
	}
}
STORAGE_DEFINITIONS["models/items/ammocrate_smg1.mdl"] = {
	name = "Ammo Crate",
	desc = "A heavy crate for storing ammunition.",
	invType = INV_TYPE_ID,
	invData = {
		w = 5,
		h = 3
	},
	onOpen = function(entity, activator)
		entity:ResetSequence("Close")

		timer.Create("CloseLid"..entity:EntIndex(), 2, 1, function()
			if (IsValid(entity)) then
				entity:ResetSequence("Open")
			end
		end)
	end
}


if (CLIENT) then
	function PLUGIN:StorageOpen(storage)
		-- Number of pixels between the local inventory and storage inventory.
		local PADDING = 4

		if (
			not IsValid(storage) or
			storage:getStorageInfo().invType ~= INV_TYPE_ID
		) then
			return
		end

		-- Get the inventory for the player and storage.
		local localInv =
			LocalPlayer():getChar() and LocalPlayer():getChar():getInv()
		local storageInv = storage:getInv()
		if (not localInv or not storageInv) then
			return nutStorageBase:exitStorage()
		end

		-- Show both the storage and inventory.
		local localInvPanel = localInv:show()
		local storageInvPanel = storageInv:show()
		storageInvPanel:SetTitle(L(storage:getStorageInfo().name))

		-- Allow the inventory panels to close.
		localInvPanel:ShowCloseButton(true)
		storageInvPanel:ShowCloseButton(true)

		-- Put the two panels, side by side, in the middle.
		local extraWidth = (storageInvPanel:GetWide() + PADDING) / 2
		localInvPanel:Center()
		storageInvPanel:Center()
		localInvPanel.x = localInvPanel.x + extraWidth
		storageInvPanel:MoveLeftOf(localInvPanel, PADDING)

		-- Signal that the user left the inventory if either closes.
		local firstToRemove = true
		localInvPanel.oldOnRemove = localInvPanel.OnRemove
		storageInvPanel.oldOnRemove = storageInvPanel.OnRemove

		local function exitStorageOnRemove(panel)
			if (firstToRemove) then
				firstToRemove = false
				nutStorageBase:exitStorage()
				local otherPanel =
					panel == localInvPanel and storageInvPanel or localInvPanel
				if (IsValid(otherPanel)) then otherPanel:Remove() end
			end
			panel:oldOnRemove()
		end

		hook.Run("OnCreateStoragePanel", localInvPanel, storageInvPanel, storage)

		localInvPanel.OnRemove = exitStorageOnRemove
		storageInvPanel.OnRemove = exitStorageOnRemove
	end
end
