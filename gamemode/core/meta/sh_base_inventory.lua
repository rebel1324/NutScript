local INV_TABLE_NAME = "inventories2"
local INV_DATA_TABLE_NAME = "invdata"

local Inventory = nut.Inventory or {}
Inventory.__index = Inventory

-- Arbitrary data for this particular inventory.
Inventory.data = {}

-- A map from item ID to an item instance of items within this inventory.
Inventory.items = {}

-- A unique identifier for an instance of this inventory.
Inventory.id = -1

-- Constants for inventory actions.
INV_REPLICATE = "repl" -- Replicate data about the inventory to a player.

Inventory.config = {
	persistent = true,
	data = {},
	accessRules = {},
}

-- Returns the value of the stored key if it exists, the default otherwise.
-- If no default is given, then nil is returned.
function Inventory:getData(key, default)
	local value = self.data[key]

	if (value == nil) then
		return default
	end
	return value
end

-- Used to create sub-classes for the Inventory class.
function Inventory:extend(className)
	local subClass = table.Inherit({className = className}, self)
	subClass.__index = subClass
	return subClass
end

-- Configure how the inventory works.
function Inventory:configure(config)
end

function Inventory:addDataProxy(key, onChange)
	local dataConfig = self.config.data[key] or {}
	dataConfig.proxies[#dataConfig.proxies + 1] = onChange
	self.config.data[key] = dataConfig
end

-- Sets the type ID for this inventory class and registers it as a valid type.
function Inventory:register(typeID)
	assert(
		type(typeID) == "string",
		"Expected argument #1 of "..self.className..".register to be a string"
	)
	self.typeID = typeID
	self:configure(self.config)
	nut.inventory.newType(self.typeID, self)
end

-- Creates an instance of this inventory type.
function Inventory:new()
	return nut.inventory.new(self.typeID)
end

-- A string representation of this inventory.
function Inventory:__tostring()
	return self.className.."["..tostring(self.id).."]"
end

-- Returns the inventory type of this inventory.
function Inventory:getType()
	return nut.inventory.types[self.typeID]
end

if (SERVER) then
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
end

nut.Inventory = Inventory
