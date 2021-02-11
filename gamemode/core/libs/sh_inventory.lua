nut.inventory = nut.inventory or {}
nut.inventory.types = {}
nut.inventory.instances = nut.inventory.instances or {}

nut.util.include("nutscript/gamemode/core/meta/sh_base_inventory.lua")

local function serverOnly(value)
	return SERVER and value or nil
end

local InvTypeStructType = {
	__index = "table",
	add = serverOnly("function"),
	remove = serverOnly("function"),
	sync = serverOnly("function"),
	typeID = "string",
	className = "string"
}

local function checkType(typeID, struct, expected, prefix)
	prefix = prefix or ""
	for key, expectedType in pairs(expected) do
		local actualValue = struct[key]
		local expectedTypeString = isstring(expectedType)
			and expectedType or type(expectedType)
		assert(
			type(actualValue) == expectedTypeString,
			"expected type of "..prefix..key.." to be "..expectedTypeString..
			" for inventory type "..typeID..", got "..type(actualValue)
		)
		if (istable(expectedType)) then
			checkType(typeID, actualValue, expectedType, prefix..key..".")
		end
	end
end

-- Performs type checking for new inventory types then stores them into
-- nut.inventory.types if there are no errors.
function nut.inventory.newType(typeID, invTypeStruct)
	assert(not nut.inventory.types[typeID], "duplicate inventory type "..typeID)

	-- Type check the inventory type struct.
	assert(istable(invTypeStruct), "expected table for argument #2")
	checkType(typeID, invTypeStruct, InvTypeStructType)

	debug.getregistry()[invTypeStruct.className] = invTypeStruct
	nut.inventory.types[typeID] = invTypeStruct
end

-- Creates an instance of an inventory class whose type is the given type ID.
function nut.inventory.new(typeID)
	local class = nut.inventory.types[typeID]
	assert(class ~= nil, "bad inventory type "..typeID)

	return setmetatable({
		items = {},
		config = table.Copy(class.config)
	}, class)
end

if (CLIENT) then
	function nut.inventory.show(inventory, parent)
		local globalName = "inv"..inventory.id
		if (IsValid(nut.gui[globalName])) then
			nut.gui[globalName]:Remove()
		end
		local panel = hook.Run("CreateInventoryPanel", inventory, parent)
		nut.gui[globalName] = panel
		return panel
	end
end
