local GridInv = nut.Inventory:extend("GridInv")

-- Useful access rules:
local function CanAccessInventoryIfCharacterIsOwner(inventory, action, context)
	local ownerID = inventory:getData("char")
	local client = context.client
	if (table.HasValue(client.nutCharList, ownerID)) then
		return true
	end
end

local function CanNotAddItemIfNoSpace(inventory, action, context)
	if (action ~= "add") then
		return
	end

	local x, y = context.x, context.y
	if (not x or not y) then return false, "noFit" end

	if (not inventory:doesItemFitAtPos(context.item, x, y)) then
		return false, "noFit"
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
			return false
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
	local items = self.BaseClass.getItems(self)
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
	function GridInv:add(itemTypeOrItem, x, y)
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
			return d:resolve({error = "invalid item type"})
		end

		if (not x or not y) then
			x, y = self:findFreePosition(item)
		end

		-- Permission check adding the item.
		local context = {item = item, x = x, y = y}
		local canAccess, reason = self:canAccess("add", context)
		if (not canAccess) then
			return d:resolve({error = reason or "noAccess"})
		end

		-- If given an item instance, there's no need for a new instance.
		if (justAddDirectly) then
			item:setData("x", x)
			item:setData("y", y)
			self:addItem(item)
			return d:resolve({item})
		end

		-- Otherwise, make quantity number of instances.
		local data = {x = x, y = y}
		local itemType = item.uniqueID
		nut.item.instance(self:getID(), itemType, data, 0, 0, function(item)
			self:addItem(item)
			d:resolve(item)
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
		if (
			x < 1 or x > inventory:getWidth() or
			y < 1 or y > inventory:getHeight()
		) then
			return
		end

		local item = inventory.items[itemID]
		if (item and item:getData("x") == x and item:getData("y") == y) then
			return
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
