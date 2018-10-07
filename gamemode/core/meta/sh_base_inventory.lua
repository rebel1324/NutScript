local INV_TABLE_NAME = "inventories2"
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
	include("inventory/sv_base_inventory.lua")
end
