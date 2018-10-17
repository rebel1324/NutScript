local PANEL = FindMetaTable("Panel")

-- Make it so the panel hooks below run when the inventory hooks do.
function PANEL:nutListenForInventoryChanges(inventory)
	assert(inventory, "No inventory has been set!")
	local id = inventory:getID()

	-- Clean up old hooks
	self:nutDeleteInventoryHooks()

	_NUT_INV_PANEL_ID = (_NUT_INV_PANEL_ID or 0) + 1
	local hookID = "nutInventoryListener".._NUT_INV_PANEL_ID
	self.nutHookID = hookID
	self.nutToRemoveHooks = {}

	-- For each relevant inventory/item hook, add a listener that will
	-- trigger the associated panel hook.
	local function listenForInventoryChange(name, panelHook)
		panelHook = panelHook or name
		hook.Add(name, hookID, function(inventory, ...)
			if (not IsValid(self) or self.inventory ~= inventory) then
				return
			end
			if (not isfunction(self[panelHook])) then
				return
			end
			self[panelHook](self, ...)

			if (name == "InventoryDeleted") then
				self.inventory = nil
				self:deleteInventoryHooks()
			end
		end)
		self.nutToRemoveHooks[#self.nutToRemoveHooks + 1] = name
	end

	listenForInventoryChange("InventoryInitialized")
	listenForInventoryChange("InventoryDeleted")
	listenForInventoryChange("InventoryDataChanged")
	listenForInventoryChange("InventoryItemAdded")
	listenForInventoryChange("InventoryItemRemoved")

	hook.Add(
		"ItemDataChanged",
		hookID,
		function(item, key, oldValue, newValue)
			if (not IsValid(self) or not self.inventory) then return end
			if (not self.inventory.items[item:getID()]) then
				return
			end
			self:InventoryItemDataChanged(item, key, oldValue, newValue)
		end
	)
	self.nutToRemoveHooks[#self.nutToRemoveHooks + 1] = "ItemDataChanged"
end

-- Cleans up all the hooks created by listenForInventoryChanges()
function PANEL:nutDeleteInventoryHooks()
	if (not self.nutHookID) then
		return
	end
	for i = 1, #self.toRemoveHooks do
		hook.Remove(self.nutToRemoveHooks[i], self.nutHookID)
	end
	self.nutToRemoveHooks = {}
end
