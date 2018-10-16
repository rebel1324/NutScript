if (nut.config.useListInventory == true) then return end

local ITEM = {}
debug.getregistry().Item = nut.meta.item -- for FindMetaTable.

ITEM.__index = ITEM
ITEM.name = "INVALID ITEM"
ITEM.desc = ITEM.desc or "[[INVALID ITEM]]"
ITEM.id = ITEM.id or 0
ITEM.maxQuantity = 1
ITEM.defaultQuantity = 1
ITEM.isStackable = false
ITEM.uniqueID = "undefined"
ITEM.canSplit = true
ITEM.isItem = true

function ITEM:__eq(other)
	return self:getID() == other:getID()
end

function ITEM:__tostring()
	return "item["..self.uniqueID.."]["..self.id.."]"
end

function ITEM:getID()
	return tonumber(self.id)
end

function ITEM:getName()
	return (CLIENT and L(self.name) or self.name)
end

function ITEM:getQuantity()
	local quantity = self.quantity

	if (IsValid(self.entity)) then
		quantity = self.entity:getNetVar("quantity")
	end

	return tonumber(quantity or (self.id == 0 and self:getMaxQuantity() or 1))
end

function ITEM:getMaxQuantity()
	return tonumber(self.maxQuantity)
end

function ITEM:setQuantity(quantity, forced, receivers, noCheckEntity)
	self.quantity = (forced and quantity or math.Clamp(quantity, 1, self:getMaxQuantity()))
	
	if (SERVER) then
		if (!noCheckEntity) then
			local ent = self:getEntity()

			if (IsValid(ent)) then
				ent:setNetVar("quantity", quantity)
			end
		end

		if (receivers != false) then
			if (receivers or self:getOwner()) then
				netstream.Start(receivers or self:getOwner(), "invQuantity", self:getID(), quantity)
			end
		end

		if (!noSave) then
			if (nut.db) then
				if (MYSQLOO_PREPARED) then
					nut.db.preparedCall("itemQuantity", nil, quantity, self:getID())
				else
					nut.db.updateTable({_quantity = quantity}, nil, "items", "_itemID = "..self:getID())
				end
			end
		end
	end
end

function ITEM:addQuantity(amount, forced)
	local quantity = self:getQuantity()

	if (forced) then
		quantity = math.max(0, quantity + amount)
	else
		quantity = math.Clamp(quantity + amount, 0, self:getMaxQuantity())
	end

	self:setQuantity(quantity, quantity == 0 and true or forced)
	return (quantity <= 0)
end

function ITEM:getDesc()
	if (!self.desc) then return "ERROR" end
	
	return L(self.desc or "noDesc")
end

function ITEM:getPrice()
	local price = self.price

	if (self.calcPrice) then
		price = self:calcPrice(self.price)
	end

	if (self.isStackable) then
		return price and (price * math.Clamp(self:getQuantity() / self:getMaxQuantity(), 0, 1)) or 0 -- yeah..
	else
		return price or 0
	end
end

-- function ITEM:split(quantity) end -- need to separate split function for future developers.

-- Dev Buddy. You don't have to print the item data with PrintData();
function ITEM:print(detail)
	if (detail == true) then
		print(Format("%s[%s]: >> [%s](%s,%s)", self.uniqueID, self.id, self.owner, self.gridX, self.gridY))
	else
		print(Format("%s[%s]", self.uniqueID, self.id))
	end
end

-- Dev Buddy, You don't have to make another function to print the item Data.
function ITEM:printData()
	self:print(true)
	print("ITEM DATA:")
	for k, v in pairs(self.data) do
		print(Format("[%s] = %s", k, v))
	end
end

function ITEM:call(method, client, entity, ...)
	local oldPlayer, oldEntity = self.player, self.entity

	self.player = client or self.player
	self.entity = entity or self.entity

	if (type(self[method]) == "function") then
		local results = {self[method](self, ...)}

		self.player = nil
		self.entity = nil

		return unpack(results)
	end

	self.player = oldPlayer
	self.entity = oldEntity
end

function ITEM:getOwner()
	local inventory = nut.item.inventories[self.invID]

	if (inventory) then
		return (inventory.getReceiver and inventory:getReceiver())
	end

	local id = self:getID()

	for k, v in ipairs(player.GetAll()) do
		local character = v:getChar()

		if (character and character:getInv().items[id]) then
			return v
		end
	end
end

function ITEM:setData(key, value, receivers, noSave, noCheckEntity)
	self.data = self.data or {}
	self.data[key] = value

	if (SERVER) then
		if (!noCheckEntity) then
			local ent = self:getEntity()

			if (IsValid(ent)) then
				local data = ent:getNetVar("data", {})
				data[key] = value

				ent:setNetVar("data", data)
			end
		end
	end

	if (receivers != false) then
		if (receivers or self:getOwner()) then
			netstream.Start(receivers or self:getOwner(), "invData", self:getID(), key, value)
		end
	end

	if (!noSave) then
		if (nut.db) then
			if (MYSQLOO_PREPARED) then
				nut.db.preparedCall("itemData", nil, self.data, self:getID())
			else
				nut.db.updateTable({_data = self.data}, nil, "items", "_itemID = "..self:getID())
			end
		end
	end	
end

function ITEM:getData(key, default)
	self.data = self.data or {}

	if (self.data) then
		if (key == true) then
			return self.data
		end

		local value = self.data[key]

		if (value != nil) then
			return value
		elseif (IsValid(self.entity)) then
			local data = self.entity:getNetVar("data", {})
			local value = data[key]

			if (value != nil) then
				return value
			end
		end
	else
		self.data = {}
	end

	if (default != nil) then
		return default
	end

	return
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

if (SERVER) then
	function ITEM:removeFromInventory(preserveItem)
		local inventory = nut.inventory.instances[self.invID]
		if (inventory) then
			return inventory:removeItem(self:getID(), preserveItem)
		end
		local d = deferred.new()
		d:resolve()
		return d
	end

	-- Removes the item from the inventory it is in and then itself
	function ITEM:remove()
		return self:removeFromInventory()
			:next(function() return self:delete() end)
	end

	-- Deletes the data for this item
	function ITEM:delete()
		self:destroy()
		return nut.db.delete("items", "_itemID = "..self:getID())
	end

	-- Deletes the in-memory data for this item
	function ITEM:destroy()
		net.Start("nutItemDelete")
			net.WriteUInt(self:getID(), 32)
		net.Broadcast()
		nut.item.instances[self:getID()] = nil
	end

	function ITEM:getEntity()
		local id = self:getID()

		for k, v in ipairs(ents.FindByClass("nut_item")) do
			if (v.nutItemID == id) then
				return v
			end
		end
	end
	-- Spawn an item entity based off the item table.
	function ITEM:spawn(position, angles)
		-- Check if the item has been created before.
		if (nut.item.instances[self.id]) then
			local client

			-- If the first argument is a player, then we will find a position to drop
			-- the item based off their aim.
			if (type(position) == "Player") then
				client = position
				position = position:getItemDropPos()
			end

			-- Spawn the actual item entity.
			local entity = ents.Create("nut_item")
			entity:Spawn()
			entity:SetPos(position)
			entity:SetAngles(angles or Angle(0, 0, 0))
			-- Make the item represent this item.
			entity:setItem(self.id)

			if (IsValid(client)) then
				entity.nutSteamID = client:SteamID()
				entity.nutCharID = client:getChar():getID()
			end

			-- Return the newly created entity.
			return entity
		end
	end

	function ITEM:sync(recipient)
		net.Start("nutItemInstance")
			net.WriteUInt(self:getID(), 32)
			net.WriteString(self.uniqueID)
			net.WriteTable(self.data)
			net.WriteType(self.invID)
		if (recipient == nil) then
			net.Broadcast()
		else
			net.Send(recipient)
		end
	end
end

nut.meta.item = ITEM
