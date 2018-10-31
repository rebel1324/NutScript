local ITEM = nut.meta.item

-- Removes the item from the inventory it is in and then itself
function ITEM:removeFromInventory(preserveItem)
	local inventory = nut.inventory.instances[self.invID]
	self.invID = 0
	if (inventory) then
		return inventory:removeItem(self:getID(), preserveItem)
	end
	local d = deferred.new()
	d:resolve()
	return d
end

-- Deletes the data for this item.
function ITEM:delete()
	self:destroy()
	return nut.db.delete("items", "_itemID = "..self:getID())
end

-- Permanently deletes this item instance and from the inventory it is in.
function ITEM:remove()
	return self:removeFromInventory()
		:next(function() return self:delete() end)
		:next(function() self:onRemoved() end)
end

-- Deletes the in-memory data for this item
function ITEM:destroy()
	net.Start("nutItemDelete")
		net.WriteUInt(self:getID(), 32)
	net.Broadcast()
	nut.item.instances[self:getID()] = nil
end

-- Returns the entity representing this item, if one exists.
function ITEM:getEntity()
	local id = self:getID()

	for k, v in ipairs(ents.FindByClass("nut_item")) do
		if (v:getNetVar("id") == id) then
			return v
		end
	end
end

-- Spawn an item entity based off the item table.
function ITEM:spawn(position, angles)
	local instance = nut.item.instances[self.id]

	-- Check if the item has been created before.
	if (instance) then
		if (IsValid(instance.entity)) then
			instance.entity.nutIsSafe = true
			instance.entity:Remove()
		end

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
		instance.entity = entity

		if (IsValid(client)) then
			entity.nutSteamID = client:SteamID()
			entity.nutCharID = client:getChar():getID()
		end

		-- Return the newly created entity.
		return entity
	end
end

-- Called when an instance of this item has been created.
function ITEM:onInstanced(id)
end

-- Called when data for this item should be replicated to the recipient.
function ITEM:onSync(recipient)
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
	self:onSync(recipient)
end

function ITEM:setData(key, value, receivers, noSave, noCheckEntity)
	self.data = self.data or {}
	self.data[key] = value

	if (!noCheckEntity) then
		local ent = self:getEntity()

		if (IsValid(ent)) then
			local data = ent:getNetVar("data", {})
			data[key] = value

			ent:setNetVar("data", data)
		end
	end

	if (receivers or self:getOwner()) then
		netstream.Start(
			receivers or self:getOwner(),
			"invData",
			self:getID(),
			key,
			value
		)
	end

	if (noSave or not nut.db) then return end
	if (MYSQLOO_PREPARED) then
		nut.db.preparedCall("itemData", nil, self.data, self:getID())
	else
		nut.db.updateTable({
			_data = self.data
		}, nil, "items", "_itemID = "..self:getID())
	end
end
