local Inventory = nut.Inventory

-- Given an item type string, creates an instance of that item type
-- and adds it to this inventory. A promise is returned containing
-- the newly created item after it has been added to the inventory.
function Inventory:add(...)
	error(self.className..":add() should be overwritten")
end

-- Called to handle the logic for creating the data storage for this.
-- Returns a promise that is resolved after the storing is done.
function Inventory:initializeStorage(initialData)
	local d = deferred.new()

	nut.db.insertTable({
		_invType = self.typeID,
	}, function(results, lastID)
		local count = 0
		local expected = table.Count(initialData)

		for key, value in pairs(initialData) do
			nut.db.insertTable({
				_invID = lastID,
				_key = key,
				_value = {value}
			}, function()
				count = count + 1
				if (count == expected) then
					d:resolve(lastID)
				end
			end, INV_DATA_TABLE_NAME)
		end
	end, INV_TABLE_NAME)

	return d
end

-- Called when some inventory with a certain ID needs to be loaded.
-- If this type is responsible for loading that inventory ID in particular,
-- then a promise that resolves to an inventory should be returned.
-- This allows for custom data storage of inventories.
function Inventory:restoreFromStorage(id)
end

-- Given an ID of a valid item, the item is added to this inventory.
function Inventory:addItem(itemID)
	-- TODO: add a specific item to this inventory
	return self
end

-- Removes an item of a certain type from this inventory. A promise is
-- returned which is resolved after the item has been removed.
function Inventory:remove(...)
	error(self.className..":remove() should be overwritten")
end

-- Removes an item corresponding to the given item ID if it is in this
-- inventory. If the item belongs to this inventory, it is then deleted.
-- A promise is returned which is resolved after removal from this.
function Inventory:removeItem(itemID)
	-- TODO: remove a specific item from this inventory
	return self
end

-- Stores arbitrary data that can later be looked up using the given key.
function Inventory:setData(key, value)
	self.data[key] = value
	-- TODO: add replication and persistent storage
	return self
end

-- Whether or not a client can interact with this inventory.
function Inventory:canPlayerAccess(client, action)
	local result
	for _, rule in ipairs(self.rules) do
		result = rule(self, client, action)
		if (result ~= nil) then
			return result
		end
	end
	return false
end

-- Changes the canPlayerAccess method to also return the result of the rule
-- where the rule of a function of (inventory, player, action) -> boolean.
function Inventory:addAccessRule(rule)
	self.config.accessRules[#self.config.accessRules + 1] = rule
	return self
end

-- Returns a list of players who can interact with this inventory.
function Inventory:getRecipients()
	local recipients = {}
	for _, client in ipairs(player.GetAll()) do
		if (self:canBeAccessedByPlayer(client, INV_REPLICATE)) then
			recipients[#recipients + 1] = client
		end
	end
	return recipients
end

-- Called after this inventory has first been created and loaded.
function Inventory:onInstanced()
end

-- Called after this inventory has first been loaded, not including right
-- after it has been created.
function Inventory:onLoaded()
end

-- Loads the items contained in this inventory.
function Inventory:loadItems()
	local ITEM_TABLE = "items"
	local ITEM_FIELDS = {"_itemID", "_uniqueID", "_data"}

	return nut.db.select(ITEM_FIELDS, ITEM_TABLE, "_invID = "..self.id)
		:next(function(res)
			local items = {}
			for _, result in ipairs(res.results) do
				local itemID = tonumber(result._itemID)
				local uniqueID = result._uniqueID
				local itemTable = nut.item.list[uniqueID]
				if (not itemTable) then
					ErrorNoHalt(
						"Inventory "..self.id.." contains bad invalid item "
						..uniqueID.." ("..itemID..")"
					)
					continue
				end

				local item = nut.item.new(uniqueID, itemID)
				if (result._data) then
					item.data = util.JSONToTable(result._data)
				end

				items[itemID] = item.data
				if (item.onRestored) then
					item:onRestored(self)
				end
			end
			return items
		end)
end
