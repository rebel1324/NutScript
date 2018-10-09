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
	local base = debug.getregistry()[className] or {}
	table.Empty(base) -- Allow updated base methods to update in instances.
	base.className = className
	local subClass = table.Inherit(base, self)
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

	self.config = {data = {}}

	if (SERVER) then
		self.config.persistent = true
		self.config.accessRules = {}
	end

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

-- Called when a data value has been changed for this inventory.
function Inventory:onDataChanged(key, oldValue, newValue)
	local keyData = self.config.data[key]
	if (keyData and keyData.proxies) then
		for _, proxy in pairs(keyData.proxies) do
			proxy(oldValue, newValue)
		end
	end
end

function Inventory:getItems()
	return self.items
end

if (SERVER) then
	include("inventory/sv_base_inventory.lua")
	AddCSLuaFile("inventory/cl_base_inventory.lua")
else
	include("inventory/cl_base_inventory.lua")
end
