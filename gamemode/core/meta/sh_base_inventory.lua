nut.Inventory = nut.Inventory or {}
nut.Inventory.__index = nut.Inventory

-- Arbitrary data for this particular inventory.
nut.Inventory.data = {}

-- A map from item ID to an item instance of items within this inventory.
nut.Inventory.items = {}

-- Constants for inventory actions.
INV_REPLICATE = "repl" -- Replicate data about the inventory to a player.

nut.Inventory.config = {
	persistent = true,
	data = {},
	accessRules = {},
}

-- Returns the value of the stored key if it exists, the default otherwise.
-- If no default is given, then nil is returned.
function nut.Inventory:getData(key, default)
	local value = self.data[key]

	if (value == nil) then
		return default
	end
	return value
end

-- Used to create sub-classes for the Inventory class.
function nut.Inventory:extend(className)
	local oldClass = debug.getregistry()[className]
	return oldClass or setmetatable({
		className = className,
		super = self
	}, self)
end

-- Configurate the setting/getting of data.
function nut.Inventory:configure(config)
end

function nut.Inventory:addDataProxy(key, onChange)
	local dataConfig = self.config.data[key] or {}
	dataConfig.proxies[#dataConfig.proxies + 1] = onChange
	self.config.data[key] = dataConfig
end

-- Sets the type ID for this inventory class and registers it as a valid type.
function nut.Inventory:register(typeID)
	assert(
		type(typeID) == "string",
		"Expected argument #1 of "..self.className..".register to be a string"
	)
	self.typeID = typeID
	self:configure(self.config)
	nut.inventory.newType(self.typeID, self)
end

if (SERVER) then
	-- Given an item type string, creates an instance of that item type
	-- and adds it to this inventory. A promise is returned containing
	-- the newly created item after it has been added to the inventory.
	function nut.Inventory:add(...)
		error(self.className..":add() should be overwritten")
	end

	-- Given an ID of a valid item, the item is added to this inventory.
	function nut.Inventory:addItem(itemID)
		-- TODO: add a specific item to this inventory
	end

	-- Removes an item of a certain type from this inventory. A promise is
	-- returned which is resolved after the item has been removed.
	function nut.Inventory:remove(...)
		error(self.className..":remove() should be overwritten")
	end

	-- Removes an item corresponding to the given item ID if it is in this
	-- inventory. If the item belongs to this inventory, it is then deleted.
    -- A promise is returned which is resolved after removal from this.
	function nut.Inventory:removeItem(itemID)
		-- TODO: remove a specific item from this inventory
	end

	-- Stores arbitrary data that can later be looked up using the given key.
	function nut.Inventory:setData(key, value)
		self.data[key] = value
		-- TODO: add replication and persistent storage
	end

	-- Whether or not a client can interact with this inventory.
	function nut.Inventory:canPlayerAccess(client, action)
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
	function nut.Inventory:addAccessRule(rule)
		self.config.accessRules[#self.config.accessRules + 1] = rule
	end

	-- Returns a list of players who can interact with this inventory.
	function nut.Inventory:getRecipients()
		local recipients = {}
		for _, client in ipairs(player.GetAll()) do
			if (self:canBeAccessedByPlayer(client, INV_REPLICATE)) then
				recipients[#recipients + 1] = client
			end
		end
		return recipients
	end
end
