if (nut.config.useListInventory == true) then return end

local META = nut.meta.inventory or {}
META.__index = META
META.slots = META.slots or {}
META.w = META.w or 4
META.h = META.h or 4
META.vars = META.vars or {}
debug.getregistry().Inventory = nut.meta.inventory -- hi mark

-- Declare some supports for logic inventory
local zeroInv = nut.item.inventories[0]
function zeroInv:getID()
	return 0
end

-- WARNING: You have to manually sync the data to client if you're trying to use item in the logical inventory in the vgui.
function zeroInv:add(uniqueID, quantity, data, callback)
	quantity = quantity or 1

	if (quantity > 0) then
		if (!isnumber(uniqueID)) then
			local itemTable = nut.item.list[uniqueID]
			local maxQuantity = itemTable:getMaxQuantity()
			local numInstance = math.floor(quantity/maxQuantity)
			local leftQuantity = (quantity%maxQuantity)

			if (!itemTable) then
				return false, "invalidItem"
			end

			for i = 0, numInstance do
				nut.item.instance(0, uniqueID, data, x, y, function(item)
					if (item.isStackable) then
						item:setQuantity(item:getMaxQuantity())
					end

					self[item:getID()] = item

					if (callback) then
						callback(item, item:getID())
					end
				end)
			end

			if (leftQuantity > 0) then
				nut.item.instance(0, uniqueID, data, x, y, function(item)
					if (item.isStackable) then
						item:setQuantity(leftQuantity)
					end

					self[item:getID()] = item

					if (callback) then
						callback(item, item:getID())
					end
				end)
			end

			return nil, nil, 0
		end
	else
		return false, "notValid"
	end
end

function META:getID()
	return self.id or 0
end

function META:setSize(w, h)
	self.w = w
	self.h = h
end

function META:__tostring()
	return "inventory["..(self.id or 0).."]"
end

function META:getSize()
	return self.w, self.h
end

-- this is pretty good to debug/develop function to use.
function META:print(printPos, noQuantity)
	for k, v in pairs(self:getItems()) do
		local str = k .. ": " .. v.name

		if (printPos) then
			str = str .. " (" .. v.gridX .. ", " .. v.gridY .. ")"
		end

		if (!noQuantity) then
			str = str .. " x" .. v:getQuantity()
		end

		print(str)
	end
end

-- find out stacked shit
function META:findError()
	for k, v in pairs(self:getItems()) do
		if (v.width == 1 and v.height == 1) then
			continue
		end

		print("Finding error: " .. v.name )
		print("Item Position: " .. v.gridX, v.gridY )
		local x, y;
		for x = v.gridX, v.gridX + v.width - 1 do
			for y = v.gridY, v.gridY + v.height - 1 do
				local item = self.slots[x][y]
				if (item and item.id != v.id) then
					print("Error Found: ".. item.name)
				end
			end
		end
	end
end

-- For the debug/item creation purpose
function META:printAll()
	print("------------------------")
		print("INVID", self:getID())
		print("INVSIZE", self:getSize())

		if (self.slots) then
			for x = 1, self.w do
				for y = 1, self.h do
					local item = self.slots[x] and self.slots[x][y]
					if (item and item.id) then
						print(item.name .. "(" .. item.id .. ")", x, y)
					end
				end
			end
		end

		print("INVVARS")
		PrintTable(self.vars or {})
	print("------------------------")
end

function META:setOwner(owner, fullUpdate)
	if (type(owner) == "Player" and owner:getNetVar("char")) then
		owner = owner:getNetVar("char")
	elseif (type(owner) != "number") then
		return
	end

	if (SERVER) then
		if (fullUpdate) then
			for k, v in ipairs(player.GetAll()) do
				if (v:getNetVar("char") == owner) then
					self:sync(v, true)

					break
				end
			end
		end

		nut.db.query("UPDATE nut_inventories SET _charID = "..owner.." WHERE _invID = "..self:getID())
	end

	self.owner = owner
end

function META:canItemFit(x, y, w, h, item2)
	local canFit = true

	for x2 = 0, w - 1 do
		for y2 = 0, h - 1 do
			local item = (self.slots[x + x2] or {})[y + y2]
			if ((x + x2) > self.w or item) then
				if (item2) then
					if (item and item.id == item2.id) then
						continue
					end
				end

				canFit = false
				break
			end
		end

		if (!canFit) then
			break
		end
	end

	return canFit
end

function META:findEmptySlot(w, h, onlyMain)
	w = w or 1
	h = h or 1

	if (w > self.w or h > self.h) then
		return
	end

	local canFit = false

	for y = 1, self.h - (h - 1) do
		for x = 1, self.w - (w - 1) do
			if (self:canItemFit(x, y, w, h)) then
				return x, y
			end
		end
	end

	if (onlyMain != true) then
		local bags = self:getBags()

		if (#bags > 0) then
			for _, invID in ipairs(bags) do
				local bagInv = nut.item.inventories[invID]

				if (bagInv) then
					local x, y = bagInv:findEmptySlot(w, h)

					if (x and y) then
						return x, y, bagInv
					end
				end
			end
		end
	end
end

function META:getItemAt(x, y)
	if (self.slots and self.slots[x]) then
		return self.slots[x][y]
	end
end

function META:remove(id, noReplication, noDelete)
	local x2, y2

	for x = 1, self.w do
		if (self.slots[x]) then
			for y = 1, self.h do
				local item = self.slots[x][y]

				if (item and item.id == id) then
					self.slots[x][y] = nil

					x2 = x2 or x
					y2 = y2 or y
				end
			end
		end
	end

	if (SERVER and !noReplication) then
		local receiver = self:getReceiver()

		if (type(receiver) == "Player" and IsValid(receiver)) then
			netstream.Start(receiver, "invRm", id, self:getID())
		else
			netstream.Start(receiver, "invRm", id, self:getID(), self.owner)
		end

		if (!noDelete) then
			local item = nut.item.instances[id]

			if (item and item.onRemoved) then
				item:onRemoved()
			end

			nut.db.query("DELETE FROM nut_items WHERE _itemID = "..id)
			nut.item.instances[id] = nil
		end
	end

	return x2, y2
end

-- For the debug/item creation purpose
function META:removeAll()
	for k, v in pairs(self:getItems()) do
		v:remove()
	end
end

function META:getReceiver()
	for k, v in ipairs(player.GetAll()) do
		if (v:getChar() and v:getChar().id == self.owner) then
			return v
		end
	end
end

function META:getItemCount(uniqueID, onlyMain)
	local i = 0

	for k, v in pairs(self:getItems(onlyMain)) do
		if (v.uniqueID == uniqueID) then
			i = i + v:getQuantity()
		end
	end

	return i
end

function META:getItemsByUniqueID(uniqueID, onlyMain)
	local items = {}

	for k, v in pairs(self:getItems(onlyMain)) do
		if (v.uniqueID == uniqueID) then
			table.insert(items, v)
		end
	end

	return items
end

function META:getItemByID(id, onlyMain)
	for k, v in pairs(self:getItems(onlyMain)) do
		if (v.id == id) then
			return v
		end
	end
end

function META:getItemsByID(id, onlyMain)
	local items = {}

	for k, v in pairs(self:getItems(onlyMain)) do
		if (v.id == id) then
			table.insert(items, v)
		end
	end

	return items
end

-- This function may pretty heavy.
function META:getItems(onlyMain)
	local items = {}

	for k, v in pairs(self.slots) do
		for k2, v2 in pairs(v) do
			if (v2 and type(v2) == "table" and !items[v2.id]) then
				items[v2.id] = v2

				v2.data = v2.data or {}
				local isBag = v2.data.id
				if (isBag and isBag != self:getID() and onlyMain != true) then
					local bagInv = nut.item.inventories[isBag]

					if (bagInv) then
						local bagItems = bagInv:getItems()

						table.Merge(items, bagItems)
					end
				end
			end
		end
	end

	return items
end

function META:getItemsCount(onlyMain)
	local items = {}

	for k, v in ipairs(self:getItems(onlyMain)) do
		items[v.uniqueID] = items[v.uniqueID] or 0
		items[v.uniqueID] = items[v.uniqueID] + v:getQuantity()
	end

	return items
end

-- This function may pretty heavy.
function META:getItemsByClass(onlyMain)
	local items = {}

	for k, v in pairs(self.slots) do
		for k2, v2 in pairs(v) do
			if (v2 and type(v2) == "table" and !items[v2.id]) then
				if (items[v2.uniqueID]) then
					table.insert(items[v2.uniqueID], v2)
				else
					items[v2.uniqueID] = {v2}
				end

				v2.data = v2.data or {}
				local isBag = v2.data.id
				if (isBag and isBag != self:getID() and onlyMain != true) then
					local bagInv = nut.item.inventories[isBag]

					if (bagInv) then
						local bagItems = bagInv:getItemsByClass()

						for uID, itemList in pairs(bagItems) do
							if (items[uID]) then
								for _, itemObject in pairs(itemList) do
									table.insert(items[uID], itemObject)
								end
							else
								items[uID] = itemList
							end
						end
					end
				end
			end
		end
	end

	return items
end

function META:getBags()
	local invs = {}

	for k, v in pairs(self.slots) do
		for k2, v2 in pairs(v) do
			if (v2 and type(v2) == "table" and v2.data) then
				local isBag = v2.data.id

				if (!table.HasValue(invs, isBag)) then
					if (isBag and isBag != self:getID()) then
						table.insert(invs, isBag)
					end
				end
			end
		end
	end

	return invs
end

function META:matchData(id, matchData)
	local item = self:getItemByID(id)

	if (item) then
		for dataKey, dataVal in pairs(data) do
			if (itemData[dataKey] != dataVal) then
				return false
			end
		end

		return true
	end
end

function META:hasItem(targetID, data)
	local items = self:getItems()

	for k, v in pairs(items) do
		if (v.uniqueID == targetID) then
			if (data) then
				local itemData = v.data

				for dataKey, dataVal in pairs(data) do
					if (itemData[dataKey] != dataVal) then
						return false
					end
				end
			end

			return v
		end
	end

	return false
end

if (SERVER) then
	function META:sendSlot(x, y, item, receiver)
		receiver = receiver or self:getReceiver()
		local sendData = item and item.data and table.Count(item.data) > 0 and item.data or nil

		if (type(receiver) == "Player" and IsValid(receiver)) then
			netstream.Start(receiver, "invSet", self:getID(), x, y, item and item.uniqueID or nil, item and item.id or nil, nil, sendData, item and item:getQuantity() or nil)
		else
			netstream.Start(receiver, "invSet", self:getID(), x, y, item and item.uniqueID or nil, item and item.id or nil, self.owner, sendData, item and item:getQuantity() or nil)
		end

		if (item) then
			if (type(receiver) == "table") then
				for k, v in pairs(receiver) do
					item:call("onSendData", v)
				end
			elseif (IsValid(receiver)) then
				item:call("onSendData", receiver)
			end
		end
	end

	-- this is for the debugging purpose. if you don't have idea what you're dealing with, don't even try to look at this
	local suppressCreation = false
	function META:add(uniqueID, quantity, data, x, y, noReplication, forceSplit)
		quantity = quantity or 1

		local inputType = type(uniqueID)
		local targetInv = self
		local bagInv

		if (inputType == "number") then
			local item = nut.item.instances[uniqueID]

			if (item) then
				if (!x and !y) then
					x, y, bagInv = self:findEmptySlot(item.width, item.height)
				end

				if (bagInv) then
					targetInv = bagInv
				end

				if (hook.Run("CanItemBeTransfered", item, nut.item.inventories[0], targetInv) == false) then
					return false, "notAllowed"
				end

				if (x and y) then
					targetInv.slots[x] = targetInv.slots[x] or {}
					targetInv.slots[x][y] = true

					item.gridX = x
					item.gridY = y
					item.invID = targetInv:getID()

					for x2 = 0, item.width - 1 do
						for y2 = 0, item.height - 1 do
							targetInv.slots[x + x2] = targetInv.slots[x + x2] or {}
							targetInv.slots[x + x2][y + y2] = item
						end
					end

					if (!noReplication) then
						targetInv:sendSlot(x, y, item)
					end

					if (!self.noSave) then
						nut.db.query("UPDATE nut_items SET _invID = "..targetInv:getID()..", _x = "..x..", _y = "..y.." WHERE _itemID = "..item.id)
					end

					return x, y, targetInv:getID()
				else
					return false, "noSpace"
				end
			else
				return false, "invalidIndex"
			end
		elseif (inputType == "string") then
			local itemTable = nut.item.list[uniqueID]

			if (itemTable) then
				local itemList = self:getItemsByUniqueID(uniqueID)
				local maxQuantity = itemTable:getMaxQuantity()
				local numInstances, leftOver = 0
				local canFill = (itemTable.isStackable and itemTable.canSplit == true and forceSplit != true)
				local fillTargets = {}
				local targetCoords = {}

				if (canFill) then
					for _, item in pairs(itemList) do
						if (quantity <= 0) then
							break
						end

						local itemMaxQuantity = item:getMaxQuantity()
						local itemQuantity = item.quantity
						local dataAmount = table.Count(item.data) -- i don't want it

						if (data or dataAmount > 0) then
							continue
						end

						if (itemQuantity >= itemMaxQuantity) then 
							continue
						end

						local stockQuantity = itemMaxQuantity - itemQuantity
						local leftOver = quantity - stockQuantity

						if (leftOver <= 0) then
							fillTargets[item] = itemQuantity + quantity
							quantity = 0
							break
						else
							quantity = quantity - stockQuantity
							fillTargets[item] = itemMaxQuantity
						end
					end
				end

				if (quantity > 0) then
					local numInstance = math.floor(quantity/maxQuantity)
					local leftQuantity = (quantity%maxQuantity)
					local w, h = itemTable.width, itemTable.height

					if (itemTable.isStackable != true) then
						numInstance = quantity
						leftQuantity = 0
					end

					local function pushCoord(requestQuantity)
						x, y, bagInv = self:findEmptySlot(w, h)

						if (bagInv) then
							targetInv = bagInv
						end

						if (x and y) then
							for x2 = x, (x + (w - 1)) do
								for y2= y, (y + (h - 1)) do
									targetInv.slots[x2] = targetInv.slots[x2] or {}
									targetInv.slots[x2][y2] = true
								end
							end

							table.insert(targetCoords, {x, y, requestQuantity, targetInv:getID()})
							
							return false
						else
							return true
						end
					end

					local function removeCoords()
						for _, coord in ipairs(targetCoords) do
							local targetInv = nut.item.inventories[coord[4]]

							for x2 = coord[1], (coord[1] + (w - 1)) do
								for y2= coord[2], (coord[2] + (h - 1)) do
									targetInv.slots[x2] = targetInv.slots[x2] or {}
									targetInv.slots[x2][y2] = nil
								end
							end
						end
					end

					if (hook.Run("CanItemBeTransfered", itemTable, nut.item.inventories[0], targetInv) == false) then
						return false, "notAllowed"
					end

					for i = 1, numInstance do
						local halt = pushCoord(maxQuantity) 

						if (halt) then
							removeCoords()

							return false, "noSpace"
						end
						-- create request maxQuantity
					end

					if (leftQuantity > 0) then
						-- create request leftQuantity
						local halt = pushCoord(leftQuantity) 

						if (halt) then
							removeCoords()

							return false, "noSpace"
						end
					end

					removeCoords()

					-- this is for the debugging purpose. if you don't have idea what you're dealing with, don't even try to look at this
					if (!suppressCreation) then
						for _, coord in ipairs(targetCoords) do
							local x, y, quantity = coord[1], coord[2], coord[3]

							nut.item.instance(targetInv:getID(), uniqueID, data, x, y, function(item)
								item.gridX = x
								item.gridY = y
								item:setQuantity(quantity)

								for x2 = 0, item.width - 1 do
									for y2 = 0, item.height - 1 do
										targetInv.slots[x + x2] = targetInv.slots[x + x2] or {}
										targetInv.slots[x + x2][y + y2] = item
									end
								end

								if (!noReplication) then
									targetInv:sendSlot(x, y, item)
								end
							end)
						end
					end
				end

				-- this is for the debugging purpose. if you don't have idea what you're dealing with, don't even try to look at this
				if (!suppressCreation and canFill) then
					for item, quantity in pairs(fillTargets) do
						item:setQuantity(quantity)
					end
				end

				return true, targetCoords
			else
				return false, "invalidItem"
			end
		else
			return false, "invalid"
		end
	end

	function META:sync(receiver, fullUpdate)
		local slots = {}

		for x, items in pairs(self.slots) do
			for y, item in pairs(items) do
				if (item.gridX == x and item.gridY == y) then
					slots[#slots + 1] = {x, y, item.uniqueID, item.id, item.data, item.quantity}
				end
			end
		end
		
		netstream.Start(receiver, "inv", slots, self:getID(), self.w, self.h, (receiver == nil or fullUpdate) and self.owner or nil, self.vars or {})

		for k, v in pairs(self:getItems()) do
			v:call("onSendData", receiver)
		end
	end
end

nut.meta.inventory = META