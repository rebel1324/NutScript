local ITEM = nut.meta.item or {}
debug.getregistry().Item = nut.meta.item -- for FindMetaTable.

ITEM.__index = ITEM
ITEM.name = "INVALID ITEM"
ITEM.desc = ITEM.desc or "[[INVALID ITEM]]"
ITEM.id = ITEM.id or 0
ITEM.uniqueID = "undefined"
ITEM.isItem = true
ITEM.isStackable = false
ITEM.quantity = 1
ITEM.maxQuantity = 1
ITEM.canSplit = true

function ITEM:getQuantity()
	if (self.id == 0) then
		return self.maxQuantity -- for display purpose.
	end

	return self.quantity
end

function ITEM:__eq(other)
	return self:getID() == other:getID()
end

function ITEM:__tostring()
	return "item["..self.uniqueID.."]["..self.id.."]"
end

function ITEM:getID()
	return self.id
end

if (SERVER) then
	function ITEM:getName()
		return self.name
	end

	function ITEM:getDesc()
		return self.desc
	end
else
	function ITEM:getName()
		return L(self.name)
	end

	function ITEM:getDesc()
		return L(self.desc)
	end
end

function ITEM:getPrice()
	local price = self.price

	if (self.calcPrice) then
		price = self:calcPrice(self.price)
	end

	return price or 0
end

function ITEM:call(method, client, entity, ...)
	local oldPlayer, oldEntity = self.player, self.entity

	self.player = client or self.player
	self.entity = entity or self.entity

	if (type(self[method]) == "function") then
		local results = {self[method](self, ...)}

		self.player = oldPlayer
		self.entity = oldEntity

		return unpack(results)
	end

	self.player = oldPlayer
	self.entity = oldEntity
end

function ITEM:getOwner()
	local inventory = nut.inventory.instances[self.invID]

	if (inventory) then
		return inventory:getRecipients()[1]
	end

	local id = self:getID()
	for _, v in ipairs(player.GetAll()) do
		local character = v:getChar()
		if (character and character:getInv().items[id]) then
			return v
		end
	end
end

function ITEM:getData(key, default)
	self.data = self.data or {}

	-- Overload that allows the user to get all the data.
	if (key == true) then
		return self.data
	end

	-- Try to get the data stored in the item.
	local value = self.data[key]
	if (value != nil) then return value end

	-- If that didn't work, back up to getting the data from its entity.
	if (IsValid(self.entity)) then
		local data = self.entity:getNetVar("data", {})
		local value = data[key]
		if (value ~= nil) then return value end
	end

	-- All no data was found, return the default (nil if not set).
	return default
end

function ITEM:hook(name, func)
	if (name) then
		self.hooks[name] = func
	end
end

function ITEM:postHook(name, func)
	if (name) then
		self.postHooks[name] = func
	end
end

-- Called after NutScript has stored this item into the list of valid items.
function ITEM:onRegistered()
end

nut.meta.item = ITEM

nut.util.include("item/sv_item.lua")
nut.util.include("item/sh_item_debug.lua")
