local SimpleInv = nut.Inventory:extend("SimpleInv")

local MAX_WEIGHT = 10

-- Useful access rules:
local function CanAccessInventoryIfCharacterIsOwner(inventory, action, context)
	local ownerID = inventory:getData("char")
	local client = context.client
	if (table.HasValue(client.nutCharList, ownerID)) then
		return true
	end
end

local function CanAddItemIfNotWeightRestricted(inventory, action, context)
	if (action ~= "add") then
		return
	end

	if (context.forced) then
		return true
	end

	local weight = inventory:getWeight()
	local maxWeight = inventory:getMaxWeight()
	if (weight + (context.item.weight or 1) > maxWeight) then
		return false, "noFit"
	end
	return true
end

function SimpleInv:configure()
	if (SERVER) then
		self:addAccessRule(CanAddItemIfNotWeightRestricted)
		self:addAccessRule(CanAccessInventoryIfCharacterIsOwner)
	end
end

if (SERVER) then
	function SimpleInv:add(itemTypeOrItem, quantity, forced)
		-- Validate that quantity is positive and itemType is valid.
		quantity = quantity or 1
		assert(isnumber(quantity), "quantity must be a number")
		local d = deferred.new()
		if (quantity <= 0) then
			return d:reject("quantity must be positive")
		end

		-- Get the table for the item type.
		local item, justAddDirectly
		if (nut.item.isItem(itemTypeOrItem)) then
			item = itemTypeOrItem
			quantity = 1
			justAddDirectly = true
		else
			item = nut.item.list[itemTypeOrItem]
		end
		if (not item) then
			return d:resolve({error = "invalid item type"})
		end

		-- Permission check adding the item(s).
		local context = {item = item, forced = forced, quantity = quantity}
		local canAccess, reason = self:canAccess("add", context)
		if (not canAccess) then
			return d:reject(reason or "noAccess")
		end

		-- If given an item instance, there's no need for a new instance.
		if (justAddDirectly) then
			self:addItem(item)
			return d:resolve(item)
		end

		-- Otherwise, make quantity number of instances.
		local items = {}
		local itemType = item.uniqueID
		for i = 1, quantity do
			nut.item.instance(self:getID(), itemType, nil, 0, 0, function(item)
				self:addItem(item)
				items[#items + 1] = item
				if (#items == quantity) then
					d:resolve(quantity == 1 and items[1] or items)
				end
			end)
		end

		return d
	end

	function SimpleInv:remove(itemTypeOrID, quantity)
		-- Validate that the itemType is valid and quantity is positive.
		quantity = quantity or 1
		assert(isnumber(quantity), "quantity must be a number")
		local d = deferred.new()
		if (quantity <= 0) then
			return d:reject("quantity must be positive")
		end

		if (isnumber(itemTypeOrID)) then
			self:removeItem(itemTypeOrID)
		else
			local items = self:getItemsOfType(itemTypeOrID)
			for i = 1, math.min(quantity, #items) do
				self:removeItem(items[i]:getID())
			end
		end

		d:resolve()
		return d
	end
end

function SimpleInv:getItemsOfType(itemType)
	local items = {}
	for _, item in pairs(self.items) do
		if (item.uniqueID == itemType) then
			items[#items + 1] = item
		end
	end
	return items
end

function SimpleInv:getWeight()
	local weight = 0
	for _, item in pairs(self.items) do
		weight = weight + math.max(item.weight or 1, 0)
	end
	return weight
end

function SimpleInv:getMaxWeight()
	local maxWeight =
		self:getData("maxWeight", nut.config.get("invMaxWeight", MAX_WEIGHT))
	for _, item in pairs(self.items) do
		if (item.weight and item.weight < 0) then
			maxWeight = maxWeight - item.weight
		end
	end
	return maxWeight
end

SimpleInv:register("simple")
