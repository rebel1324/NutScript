local GridInv = nut.Inventory:extend("GridInv")

-- Useful access rules:
local function CanAccessInventoryIfCharacterIsOwner(inventory, action, context)
	if (inventory.virtual) then return (action == "transfer") end 

	local ownerID = inventory:getData("char")
	local client = context.client
	if (table.HasValue(client.nutCharList or {}, ownerID)) then
		return true
	end
end

local function CanNotAddItemIfNoSpace(inventory, action, context)
	if (action ~= "add") then
		return
	end

	if (inventory.virtual) then return true end 

	local x, y = context.x, context.y
	if (not x or not y) then return false, "noFit" end

	local doesFit, item = inventory:doesItemFitAtPos(context.item, x, y)
	if (not doesFit) then
		return false, {item = item}
	end
	return true
end

-- Returns the width of this inverntory.
function GridInv:getWidth()
	return self:getData(
		"w",
		nut.config.get("invW", 1)
	)
end

-- Returns the height of this inventory.
function GridInv:getHeight()
	return self:getData(
		"h",
		nut.config.get("invH", 1)
	)
end

-- Returns the width and height of this inventory.
function GridInv:getSize()
	return self:getWidth(), self:getHeight()
end

-- Whether or not the item can fit in the rectangle of this inventory.
function GridInv:canItemFitInInventory(item, x, y)
	local invW, invH = self:getSize()
	local itemW, itemH = (item.width or 1) - 1, (item.height or 1) - 1
	return x >= 1 and y >= 1 and (x + itemW) <= invW and (y + itemH) <= invH
end

-- Whether or not the given item overlaps with some item in this inventory.
function GridInv:doesItemOverlapWithOther(testItem, x, y, item)
	local testX2, testY2 = x + (testItem.width or 1), y + (testItem.height or 1)
	local itemX, itemY = item:getData("x"), item:getData("y")
	if (not itemX or not itemY) then return false end
	local itemX2, itemY2 = itemX + (item.width or 1), itemY + (item.height or 1)

	if (x >= itemX2 or itemX >= testX2) then return false end
	if (y >= itemY2 or itemY >= testY2) then return false end
	return true
end

function GridInv:doesItemFitAtPos(testItem, x, y)
	-- Make sure the inventory can contain the item.
	if (not self:canItemFitInInventory(testItem, x, y)) then
		return false
	end

	-- Make sure no current items overlap if we were to put item at (x, y).
	for _, item in pairs(self.items) do
		if (self:doesItemOverlapWithOther(testItem, x, y, item)) then
			return false, item
		end
	end

	-- Make sure it won't overlap with an allocated spot.
	if (self.occupied) then
		for x2 = 0, (testItem.width or 1) - 1 do
			for y2 = 0, (testItem.height or 1) - 1 do
				if (self.occupied[(x + x2)..(y + y2)]) then
					return false
				end
			end
		end
	end

	-- If no overlap and we can hold the item, it fits.
	return true
end

-- Returns a coordinate where an item can be placed without overlap.
function GridInv:findFreePosition(item)
	local width, height = self:getSize()
	for x = 1, width do
		for y = 1, height do
			if (self:doesItemFitAtPos(item, x, y)) then
				return x, y
			end
		end
	end
end

function GridInv:configure()
	if (SERVER) then
		self:addAccessRule(CanNotAddItemIfNoSpace)
		self:addAccessRule(CanAccessInventoryIfCharacterIsOwner)
	end
end

function GridInv:getItems(noRecurse)
	local items = self.items
	if (noRecurse) then return items end

	-- If recursive, then add the items within bags to the items list.
	local allItems = {}
	for id, item in pairs(items) do
		allItems[id] = item
		if (item.getInv and item:getInv()) then
			allItems = table.Merge(allItems, item:getInv():getItems())
		end
	end
	return allItems
end

if (SERVER) then
	function GridInv:setSize(w, h)
		self:setData("w", w)
		self:setData("h", h)
	end

	function GridInv:setOwner(owner, fullUpdate)
		if (type(owner) == "Player" and owner:getChar()) then
			owner = owner:getChar():getID()
		elseif (type(owner) ~= "number") then
			return
		end

		if (SERVER) then
			if (fullUpdate) then
				for _, client in ipairs(player.GetAll()) do
					if (client:getChar():getID() == owner) then
						self:sync(client)
						break
					end
				end
			end
			self:setData("char", owner)
		end

		self.owner = owner
	end

	function GridInv:add(itemTypeOrItem, xOrQuantity, yOrData)
		local x, y, quantity, data
		local isStackCommand = type(itemTypeOrItem) == "string" && type(xOrQuantity) == "number"

		-- Overload of GridInv:add(itemTypeOrItem, quantity, data)
		if (type(yOrData) == "table") then
			quantity = tonumber(quantity) or 1
			data = yOrData

			if (quantity > 1) then
				local items = {}
				for i = 1, quantity do
					items[i] = self:add(itemTypeOrItem, 1, data)
				end
				return deferred.all(items)
			end
		else
			x = tonumber(xOrQuantity)
			y = tonumber(yOrData)
		end

		local d = deferred.new()

		-- Get the table for the item type.
		local item, justAddDirectly
		if (nut.item.isItem(itemTypeOrItem)) then
			item = itemTypeOrItem
			justAddDirectly = true
		else
			item = nut.item.list[itemTypeOrItem]
		end
		if (not item) then
			return d:reject("invalid item type")
		end

		if (not x or not y) then
			x, y = self:findFreePosition(item)
		end

		if (isStackCommand and item.isStackable != true) then
			isStackCommand = false
		end

		local targetAssignments = {}
		local remainingQuantity = xOrQuantity

		if (isStackCommand) then
			local items = self:getItemsOfType(itemTypeOrItem)
			
			if (items) then
				for _, targetItem in pairs(items) do
					if (remainingQuantity == 0) then -- nothing to fill. 
						break 
					end

					local freeSpace = targetItem.maxQuantity - targetItem:getQuantity()
					
					if (freeSpace > 0) then
						local filler = freeSpace - remainingQuantity

						if (filler > 0) then
							targetAssignments[targetItem] = remainingQuantity	
							remainingQuantity = 0
						else
							targetAssignments[targetItem] = freeSpace		
							remainingQuantity = math.abs(filler)
						end
					end
				end
			end
		end

		if (isStackCommand and remainingQuantity == 0) then
			local resultItems = {}

			for targetItem, assignedQuantity in pairs(targetAssignments) do
				targetItem:addQuantity(assignedQuantity)
				table.insert(resultItems, targetItem)
			end

			return d:resolve(resultItems)
		end

		-- Permission check adding the item.
		local context = {item = item, x = x, y = y}
		local canAccess, reason = self:canAccess("add", context)
		if (not canAccess) then
			if (istable(reason)) then
				return d:resolve({error = reason})
			else
				return d:reject(tostring(reason or "noAccess"))
			end
		end

		-- If given an item instance, there's no need for a new instance.
		if (not isStackCommand && justAddDirectly) then
			item:setData("x", x)
			item:setData("y", y)
			self:addItem(item)
			return d:resolve(item)
		end

		-- Allocate space for the item.
		self.occupied = self.occupied or {}
		for x2 = 0, (item.width or 1) - 1 do
			for y2 = 0, (item.height or 1) - 1 do
				self.occupied[(x + x2)..(y + y2)] = true
			end
		end

		-- Otherwise, make quantity number of instances.
		data = table.Merge({x = x, y = y}, data or {})
		local itemType = item.uniqueID
		nut.item.instance(self:getID(), itemType, data, 0, 0, function(item)
			if (self.occupied) then
				for x2 = 0, (item.width or 1) - 1 do
					for y2 = 0, (item.height or 1) - 1 do
						self.occupied[(x + x2)..(y + y2)] = nil
					end
				end
			end

			self:addItem(item)
			d:resolve(item)
		end):next(function(item)
			if (isStackCommand and remainingQuantity > 0) then
				for targetItem, assignedQuantity in pairs(targetAssignments) do
					targetItem:addQuantity(assignedQuantity)
				end
				
				local overStacks = math.ceil(remainingQuantity/item.maxQuantity) - 1

				if (overStacks > 0) then
					local items = {}
					for i = 1, overStacks do
						items[i] = self:add(itemTypeOrItem)
					end
					deferred.all(items):next(nil, function(error)
						hook.Run("OnPlayerLostStackItem", itemTypeOrItem) -- TODO: yes. just in case. maybe drop or something.
					end)

					item:setQuantity(remainingQuantity - (item.maxQuantity * overStacks))
					self:addItem(item)
					
					return d:resolve(items)
				else
					item:setQuantity(remainingQuantity)
				end
			end
		end)

		return d
	end

	function GridInv:remove(itemTypeOrID, quantity)
		-- Validate that the itemType is valid and quantity is positive.
		quantity = quantity or 1
		assert(type(quantity) == "number", "quantity must be a number")
		local d = deferred.new()
		if (quantity <= 0) then
			return d:reject("quantity must be positive")
		end

		if (type(itemTypeOrID) == "number") then
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
else
	function GridInv:requestTransfer(itemID, destinationID, x, y)
		local inventory = nut.inventory.instances[destinationID]
		if (not inventory) then return end

		local item = inventory.items[itemID]
		if (item and item:getData("x") == x and item:getData("y") == y) then
			return
		end

		if (
			item and
			(x > inventory:getWidth() or y > inventory:getHeight() or
			(x + (item.width or 1) - 1) < 1 or (y + (item.height or 1) - 1) < 1)
		) then
			destinationID = nil
		end
		
		net.Start("nutTransferItem")
			net.WriteUInt(itemID, 32)
			net.WriteUInt(x, 32)
			net.WriteUInt(y, 32)
			net.WriteType(destinationID)
		net.SendToServer()
	end
end

GridInv:register(PLUGIN.INVENTORY_TYPE_ID)
