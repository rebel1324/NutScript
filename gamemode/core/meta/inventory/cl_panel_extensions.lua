local PANEL = FindMetaTable("Panel")

-- Make it so the panel hooks below run when the inventory hooks do.
function PANEL:nutListenForInventoryChanges(inventory)
	assert(inventory, "No inventory has been set!")
	local id = inventory:getID()

	-- Clean up old hooks
	self:nutDeleteInventoryHooks(id)

	_NUT_INV_PANEL_ID = (_NUT_INV_PANEL_ID or 0) + 1
	local hookID = "nutInventoryListener".._NUT_INV_PANEL_ID
	self.nutHookID = self.nutHookID or {}
	self.nutHookID[id] = hookID
	self.nutToRemoveHooks = self.nutToRemoveHooks or {}
	self.nutToRemoveHooks[id] = {}

	-- For each relevant inventory/item hook, add a listener that will
	-- trigger the associated panel hook.
	local function listenForInventoryChange(name, panelHook)
		panelHook = panelHook or name
		hook.Add(name, hookID, function(inventory, ...)
			if (not IsValid(self)) then
				return
			end
			if (not isfunction(self[panelHook])) then
				return
			end

			local args = {...}
			args[#args + 1] = inventory
			self[panelHook](self, unpack(args))

			if (name == "InventoryDeleted" and self.deleteInventoryHooks) then
				self:deleteInventoryHooks(id)
			end
		end)
		table.insert(self.nutToRemoveHooks[id], name)
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
			if (not IsValid(self) or not inventory.items[item:getID()]) then
				return
			end
			if (not isfunction(self.InventoryItemDataChanged)) then return end
			self:InventoryItemDataChanged(
				item,
				key,
				oldValue,
				newValue,
				inventory
			)
		end
	)
	table.insert(self.nutToRemoveHooks[id], "ItemDataChanged")
end

-- Cleans up all the hooks created by listenForInventoryChanges()
function PANEL:nutDeleteInventoryHooks(id)
	-- If there are no hooks added, do nothing.
	if (not self.nutHookID) then
		return
	end

	-- If id is not set, delete all hooks.
	if (id == nil) then
		for invID, hookIDs in pairs(self.nutToRemoveHooks) do
			for i = 1, #hookIDs do
				if (IsValid(self.nutHookID)) then
					hook.Remove(hookIDs[i], self.nutHookID)
				end
			end
			self.nutToRemoveHooks[invID] = nil
		end
		return
	end

	-- If id is set, delete the hooks corresponding to that ID.
	if (not self.nutHookID[id]) then
		return
	end
	for i = 1, #self.nutToRemoveHooks[id] do
		hook.Remove(self.nutToRemoveHooks[id][i], self.nutHookID[id])
	end
	self.nutToRemoveHooks[id] = nil
end
