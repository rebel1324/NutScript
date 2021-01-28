local INV_TABLE_NAME = "inventories"
local INV_DATA_TABLE_NAME = "invdata"

local Inventory = nut.Inventory or {}
Inventory.__index = Inventory
nut.Inventory = Inventory

-- Arbitrary data for this particular inventory.
Inventory.data = {}

-- A map from item ID to an item instance of items within this inventory.
Inventory.items = {}

-- A unique identifier for an instance of this inventory.
Inventory.id = -1

--- Returns the value of the stored key if it exists, the default otherwise.
-- If no default is given, then nil is returned.
-- @param key The key to look up data  with
-- @param default The value that should be returned if no such data was found. By default this is nil
-- @return A value corresponding to the key
function Inventory:getData(key, default)
	local value = self.data[key]

	if (value == nil) then
		return default
	end
	return value
end

--- Creates an inventory object whose base class is the callee.
-- Use this to create subclasses of a specific inventory type.
-- A starting point is to extend the nut.Inventory class.
function Inventory:extend(className)
	local base = debug.getregistry()[className] or {}
	table.Empty(base) -- Allow updated base methods to update in instances.
	base.className = className
	local subClass = table.Inherit(base, self)
	subClass.__index = subClass
	return subClass
end

--- Called when the inventory can first be configured.
-- You can call edit the inventory configuration in here.
-- @param config A reference to the inventory configuration table
function Inventory:configure(config)
end

--- Adds a callback function for data changes whose key matches the given one.
-- This allows you to add additional behavior when data is changed. Note that
-- this only runs if the default behavior for Inventory:onDataChanged has
-- not been modified.
-- @param key A string containing the data key that needs to be changed for the callback to run
-- @param onChange A function with oldValue and newValue as parameters that is called when the data is changed
function Inventory:addDataProxy(key, onChange)
	local dataConfig = self.config.data[key] or {}
	dataConfig.proxies[#dataConfig.proxies + 1] = onChange
	self.config.data[key] = dataConfig
end

--- Sets the type ID for this inventory class and registers it as a valid type.
-- This basically sets up configurations for this inventory and registers
-- the type.
-- @param typeID A string containing a key to later access the type
-- @see nut.inventory.newType
function Inventory:register(typeID)
	assert(
		isstring(typeID),
		"Expected argument #1 of "..self.className..".register to be a string"
	)
	self.typeID = typeID

	self.config = {data = {}}

	if (SERVER) then
		self.config.persistent = true
		self.config.accessRules = {}
	end

	self:configure(self.config)
	nut.inventory.newType(self.typeID, self)
end

--- Creates an instance of this inventory type.
-- @return An inventory instance
-- @see nut.inventory.new
function Inventory:new()
	return nut.inventory.new(self.typeID)
end

--- A string representation of this inventory.
-- @return A string containing a nice representation of this inventory
function Inventory:__tostring()
	return self.className.."["..tostring(self.id).."]"
end

--- Returns the inventory type of this inventory.
-- @return An inventory object
function Inventory:getType()
	return nut.inventory.types[self.typeID]
end

--- Called when a data value has been changed for this inventory.
-- You can use this to add different behaviors for certain keys changing.
-- @param key The key whose value was changed
-- @param oldValue The previous value corresponding to the key
-- @param newValue The value the key is being set to
function Inventory:onDataChanged(key, oldValue, newValue)
	local keyData = self.config.data[key]
	if (keyData and keyData.proxies) then
		for _, proxy in pairs(keyData.proxies) do
			proxy(oldValue, newValue)
		end
	end
end

--- Returns a list of all the items in this inventory
-- @return A table containing items
function Inventory:getItems()
	return self.items
end

--- Returns a list of items in this inventory with matching item type.
-- @param itemType A string containing the desired type of item
-- @return A table containing items whose type matches
function Inventory:getItemsOfType(itemType)
	local items = {}
	for _, item in pairs(self:getItems()) do
		if (item.uniqueID == itemType) then
			items[#items + 1] = item
		end
	end
	return items
end

--- Returns an item in this inventory of a specific type, or nil if not found.
-- @param itemType A string containing the desired type of item
-- @return An item instance if one was found, nil otherwise.
function Inventory:getFirstItemOfType(itemType)
	for _, item in pairs(self:getItems()) do
		if (item.uniqueID == itemType) then
			return item
		end
	end
end

function Inventory:getItemsByUniqueID(itemType)
	ErrorNoHalt(
		"Inventory:getItemsByUniqueID is deprecated.\n"..
		"Use Inventory:getItemsOfType instead.\n"
	)
	return self:getItemsOfType(itemType)
end

--- Returns whether or not this inventory contains at least one item of the given type.
-- @param itemType A string containing the desired type of item
-- @return True if there is such an item, false otherwise
function Inventory:hasItem(itemType)
	for _, item in pairs(self:getItems()) do
		if (item.uniqueID == itemType) then
			return true
		end
	end
	return false
end

function Inventory:getItemCount(itemType)
	local count = 0
	for _, item in pairs(self:getItems()) do
		if (item.uniqueID == itemType) then
			count = count + item:getQuantity()
		end
	end
	return count
end

function Inventory:getID()
	return self.id
end

function Inventory:__eq(other)
	return self:getID() == other:getID()
end

nut.util.include("inventory/sv_base_inventory.lua")
nut.util.include("inventory/cl_base_inventory.lua")
nut.util.include("inventory/cl_panel_extensions.lua")
