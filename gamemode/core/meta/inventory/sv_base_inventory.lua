local Inventory = nut.Inventory

-- Constants for inventory actions.
INV_REPLICATE = "repl" -- Replicate data about the inventory to a player.

local INV_TABLE_NAME = "inventories"
local INV_DATA_TABLE_NAME = "invdata"

util.AddNetworkString("nutInventoryInit")
util.AddNetworkString("nutInventoryData")
util.AddNetworkString("nutInventoryDelete")
util.AddNetworkString("nutInventoryAdd")
util.AddNetworkString("nutInventoryRemove")

-- Given an item type string, creates an instance of that item type
-- and adds it to this inventory. A promise is returned containing
-- the newly created item after it has been added to the inventory.
function Inventory:addItem(item)
	self.items[item:getID()] = item
	item.invID = self:getID()

	local id = self.id
	if (not isnumber(id)) then
		id = NULL
	end
	nut.db.updateTable({
		_invID = id
	}, nil, "items", "_itemID = "..item:getID())

	-- Replicate adding the item to this inventory client-side
	self:syncItemAdded(item)

	return self
end

-- Sample implementation of Inventory:add - delegates to addItem
function Inventory:add(item)
	return self:addItem(item)
end

function Inventory:syncItemAdded(item)
	assert(istable(item) and item.getID, "cannot sync non-item")
	assert(
		self.items[item:getID()],
		"Item "..item:getID().." does not belong to "..self.id
	)
	local recipients = self:getRecipients()
	item:sync(recipients)
	net.Start("nutInventoryAdd")
		net.WriteUInt(item:getID(), 32)
		net.WriteType(self.id)
	net.Send(recipients)
end

-- Called to handle the logic for creating the data storage for this.
-- Returns a promise that is resolved after the storing is done.
function Inventory:initializeStorage(initialData)
	local d = deferred.new()
	local charID = initialData.char

	nut.db.insertTable({
		_invType = self.typeID,
		_charID = charID
	}, function(results, lastID)
		local count = 0
		local expected = table.Count(initialData)

		-- Ignore the char data since it is stored in the old charID column.
		if (initialData.char) then
			expected = expected - 1
		end

		if (expected == 0) then
			return d:resolve(lastID)
		end

		for key, value in pairs(initialData) do
			if (key == "char") then continue end
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

-- Removes an item corresponding to the given item ID if it is in this
-- inventory. If the item belongs to this inventory, it is then deleted.
-- A promise is returned which is resolved after removal from this.
function Inventory:removeItem(itemID, preserveItem)
	assert(isnumber(itemID), "itemID must be a number for remove")

	local d = deferred.new()
	local instance = self.items[itemID]

	if (instance) then
		instance.invID = 0
		self.items[itemID] = nil

		net.Start("nutInventoryRemove")
			net.WriteUInt(itemID, 32)
			net.WriteType(self:getID())
		net.Send(self:getRecipients())

		if (not preserveItem) then
			d:resolve(instance:delete())
		else
			nut.db.updateTable({_invID = NULL}, function()
				d:resolve()
			end, "items", "_itemID = "..itemID)
		end
	else
		d:resolve()
	end

	return d
end

-- Sample implementation of Inventory:remove() - delegate to removeItem
function Inventory:remove(itemID)
	return self:removeItem(itemID)
end

-- Stores arbitrary data that can later be looked up using the given key.
function Inventory:setData(key, value)
	local oldValue = self.data[key]
	self.data[key] = value

	local keyData = self.config.data[key]
	if (key == "char") then
		-- Compatibility with NS1.1 inventory
		nut.db.updateTable({
			_charID = value
		}, nil, INV_TABLE_NAME, "_invID = "..self:getID())
	elseif (not keyData or not keyData.notPersistent) then
		if (value == nil) then
			nut.db.delete(
				INV_DATA_TABLE_NAME,
				"_invID = "..self.id.." AND _key = '"..nut.db.escape(key).."'"
			)
		else
			nut.db.upsert(
				{_invID = self.id, _key = key, _value = {value}},
				INV_DATA_TABLE_NAME
			)
		end
	end

	self:syncData(key)
	self:onDataChanged(key, oldValue, value)
	return self
end

-- Whether or not a client can interact with this inventory.
function Inventory:canAccess(action, context)
	context = context or {}
	local result
	for _, rule in ipairs(self.config.accessRules) do
		result, reason = rule(self, action, context)
		if (result ~= nil) then
			return result, reason
		end
	end
end

-- Changes the canAccess method to also return the result of the rule
-- where the rule of a function of (inventory, player, action) -> boolean.
function Inventory:addAccessRule(rule, priority)
	if (isnumber(priority)) then
		table.insert(self.config.accessRules, priority, rule)
	else
		self.config.accessRules[#self.config.accessRules + 1] = rule
	end
	return self
end

-- Removes the first instance of a specific access rule from the inventory.
function Inventory:removeAccessRule(rule)
	table.RemoveByValue(self.config.accessRules, rule)
	return self
end

-- Returns a list of players who can interact with this inventory.
function Inventory:getRecipients()
	local recipients = {}
	for _, client in ipairs(player.GetAll()) do
		if (self:canAccess(INV_REPLICATE, {client = client})) then
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
	local ITEM_FIELDS = {"_itemID", "_uniqueID", "_data", "_x", "_y", "_quantity"}

	return nut.db.select(ITEM_FIELDS, ITEM_TABLE, "_invID = "..self.id)
		:next(function(res)
			local items = {}
			for _, result in ipairs(res.results or {}) do
				local itemID = tonumber(result._itemID)
				local uniqueID = result._uniqueID
				local itemTable = nut.item.list[uniqueID]
				if (not itemTable) then
					ErrorNoHalt(
						"Inventory "..self.id.." contains invalid item "
						..uniqueID.." ("..itemID..")\n"
					)
					continue
				end

				local item = nut.item.new(uniqueID, itemID)
				item.invID = self.id

				if (result._data) then
					item.data = table.Merge(
						item.data,
						util.JSONToTable(result._data) or {}
					)
				end

				-- Legacy support for x, y data
				item.data.x = tonumber(result._x)
				item.data.y = tonumber(result._y)

				item.quantity = tonumber(result._quantity)
				items[itemID] = item
				item:onRestored(self)
			end
			self.items = items
			self:onItemsLoaded(items)
			return items
		end)
end

function Inventory:onItemsLoaded(items)
end

function Inventory:instance(initialData)
	return nut.inventory.instance(self.typeID, initialData)
end

function Inventory:syncData(key, recipients)
	if (self.config.data[key] and self.config.data[key].noReplication) then
		return
	end

	net.Start("nutInventoryData")
		-- ID is not always a number.
		net.WriteType(self.id)
		net.WriteString(key)
		net.WriteType(self.data[key])
	net.Send(recipients or self:getRecipients())
end

function Inventory:sync(recipients)
	net.Start("nutInventoryInit")
		-- ID is not always a number.
		net.WriteType(self.id)
		net.WriteString(self.typeID)
		net.WriteTable(self.data)
		net.WriteUInt(table.Count(self.items), 32)		
		local function writeItem(item)
			net.WriteUInt(item:getID(), 32)
			net.WriteString(item.uniqueID)
			net.WriteTable(item.data)
			net.WriteUInt(item:getQuantity(), 32)
		end

		-- TODO:
		-- Roughly 150 bytes per item * n items - 325 bytes < 64000 bytes
		-- => n is roughly less than 428 items before net message limit reached.
		-- Is this safe to assume inventories have at most 400 items?
		for _, item in pairs(self.items) do
			writeItem(item)
		end
	local res = net.Send(recipients or self:getRecipients())

	for _, item in pairs(self.items) do
		item:onSync(recipients)
	end
end

function Inventory:delete()
	nut.inventory.deleteByID(self.id)
end

function Inventory:destroy()
	for _, item in pairs(self:getItems()) do
		item:destroy()
	end
	nut.inventory.instances[self:getID()] = nil
	net.Start("nutInventoryDelete")
		net.WriteType(id)
	net.Broadcast()
end
