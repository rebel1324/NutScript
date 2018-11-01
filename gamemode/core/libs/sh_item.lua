nut.item = nut.item or {}
nut.item.list = nut.item.list or {}
nut.item.base = nut.item.base or {}
nut.item.instances = nut.item.instances or {}
nut.item.inventories = nut.item.inventories or {
	[0] = {}
}
nut.item.inventoryTypes = nut.item.inventoryTypes or {}

nut.util.include("nutscript/gamemode/core/meta/sh_item.lua")

local function DEPRECATED()
	local warning = debug.getinfo(2, "n").name.." is deprecated"
	local output = debug.traceback(warning, 3)
	local lines = string.Explode("\n", output)
	ErrorNoHalt("\n"..lines[1].."\n"..lines[3].."\n\n")
end

function nut.item.instance(index, uniqueID, itemData, x, y, callback)
	local itemTable = nut.item.list[uniqueID]
	if (not itemTable) then
		error("Attempt to instantiate invalid item "..tostring(uniqueID))
	end

	if (not istable(itemData)) then
		itemData = {}
	end

	-- Legacy support for x, y data: have the x, y data save to the correct
	-- x, y column instead of the data column
	if (isnumber(itemData.x)) then
		x = itemData.x
		itemData.x = nil
	end
	if (isnumber(itemData.y)) then
		y = itemData.y
		itemData.y = nil
	end

	local function onItemCreated(data, itemID)
		local item = nut.item.new(uniqueID, itemID)

		if (item) then
			item.data = itemData
			item.invID = index

			-- Legacy support for x, y data: add it back to the data for use
			item.data.x = x
			item.data.y = y

			if (callback) then
				callback(item)
			end

			item:onInstanced(index, x, y, item)
		end
	end

	if (MYSQLOO_PREPARED) then
		nut.db.preparedCall(
			"itemInstance", onItemCreated, index, uniqueID, itemData, x, y
		)
	else
		nut.db.insertTable({
			_invID = index,
			_uniqueID = uniqueID,
			_data = itemData,
			_x = x,
			_y = y
		}, onItemCreated, "items")
	end
end

function nut.item.registerInv(invType, w, h, isBag)
	DEPRECATED()
	nut.item.inventoryTypes[invType] = {w = w, h = h}

	if (isBag) then
		nut.item.inventoryTypes[invType].invType = invType
	end

	return nut.item.inventoryTypes[invType]
end

function nut.item.newInv(owner, invType, callback)
	DEPRECATED()
	local invData = nut.item.inventoryTypes[invType] or {w = 1, h = 1}

	nut.db.insertTable({
		_invType = invType,
		_charID = owner
	}, function(data, invID)
		local inventory = nut.item.createInv(invData.w, invData.h, invID)

		if (invType) then
			inventory.vars.invType = invType
		end

		if (owner and owner > 0) then
			for k, v in ipairs(player.GetAll()) do
				if (v:getChar() and v:getChar():getID() == owner) then
					inventory:setOwner(owner)
					inventory:sync(v)

					break
				end
			end
		end

		if (callback) then
			callback(inventory)
		end
	end, "inventories")
end

function nut.item.get(identifier)
	return nut.item.base[identifier] or nut.item.list[identifier]
end

function nut.item.getInv(invID)
	DEPRECATED()
	return nut.item.inventories[invID]
end

function nut.item.load(path, baseID, isBaseItem)
	local uniqueID = path:match("sh_([_%w]+)%.lua")

	if (uniqueID) then
		uniqueID = (isBaseItem and "base_" or "")..uniqueID
		nut.item.register(uniqueID, baseID, isBaseItem, path)
	else
		if (!path:find(".txt")) then
			ErrorNoHalt("[NutScript] Item at '"..path.."' follows invalid naming convention!\n")
		end
	end
end

function nut.item.isItem(object)
	return type(object) == "table" and object.isItem == true
end

-- TODO: figure out if default functions should be implemented in plugins
-- instead of here.
NUT_ITEM_DEFAULT_FUNCTIONS = {
	drop = {
		tip = "dropTip",
		icon = "icon16/world.png",
		onRun = function(item)
			item:removeFromInventory(true)
				:next(function() item:spawn(item.player) end)
			nut.log.add(item.player, "itemDrop", item.name, 1)

			return false
		end,
		onCanRun = function(item)
			return (item.entity == nil and !IsValid(item.entity) and !item.noDrop)
		end
	},
	take = {
		tip = "takeTip",
		icon = "icon16/box.png",
		onRun = function(item)
			local client = item.player
			local inventory = client:getChar():getInv()
			local entity = item.entity

			if (not inventory) then return false end
			inventory:add(item)
				:next(function(res)
					if (res.error) then
						return client:notifyLocalized(res.error)
					end
					if (IsValid(entity)) then
						entity.nutIsSafe = true
						entity:Remove()
					end
					if (not IsValid(client)) then return end
					nut.log.add(client, "itemTake", item.name, 1)
				end)

			return false
		end,
		onCanRun = function(item)
			return IsValid(item.entity)
		end
	},
}

function nut.item.register(uniqueID, baseID, isBaseItem, path, luaGenerated)
	if (uniqueID) then
		local meta = nut.meta.item
		local baseTable = nut.item.base[baseID]

		if (baseID) then
			if (!baseTable) then
				ErrorNoHalt("[NutScript] Item '"..uniqueID.."' has a non-existent base! ("..baseID..")\n")
				return 
			end
		end

		ITEM = (baseTable and table.Copy(baseTable) or {})
			ITEM.desc = "noDesc"
			ITEM.uniqueID = uniqueID
			ITEM.base = baseID
			ITEM.isBase = isBaseItem
			ITEM.hooks = ITEM.hooks or {}
			ITEM.postHooks = ITEM.postHooks or {}
			ITEM.functions = ITEM.functions or table.Copy(NUT_ITEM_DEFAULT_FUNCTIONS)
			ITEM.width = ITEM.width or 1
			ITEM.height = ITEM.width or 1
			ITEM.category = ITEM.category or "misc"

			if (PLUGIN) then
				ITEM.plugin = PLUGIN.uniqueID
			end

			function ITEM:hook(k, f)
				ITEM.hooks[k] = f
			end

			function ITEM:postHook(k, f)
				ITEM.postHooks[k] = f
			end

			if (!luaGenerated and path) then
				nut.util.include(path)
			end

			if (ITEM.onRegistered) then
				ITEM:onRegistered()
			end

			local targetTable = (isBaseItem and nut.item.base or nut.item.list)
			targetTable[ITEM.uniqueID] = setmetatable(ITEM, nut.meta.item)
			
			if (luaGenerated) then
				return targetTable[ITEM.uniqueID]
			end
		ITEM = nil
	else
		ErrorNoHalt("[NutScript] You tried to register an item without uniqueID!\n")
	end
end


function nut.item.loadFromDir(directory)
	local files, folders

	files = file.Find(directory.."/base/*.lua", "LUA")

	for k, v in ipairs(files) do
		nut.item.load(directory.."/base/"..v, nil, true)
	end

	files, folders = file.Find(directory.."/*", "LUA")

	for k, v in ipairs(folders) do
		if (v == "base") then
			continue
		end

		for k2, v2 in ipairs(file.Find(directory.."/"..v.."/*.lua", "LUA")) do
			nut.item.load(directory.."/"..v .. "/".. v2, "base_"..v)
		end
	end

	for k, v in ipairs(files) do
		nut.item.load(directory.."/"..v)
	end
end

function nut.item.new(uniqueID, id)
	id = id and tonumber(id) or id
	assert(type(id) == "number", "non-number ID given to nut.item.new")

	if (nut.item.instances[id] and nut.item.instances[id].uniqueID == uniqueID) then
		return nut.item.instances[id]
	end

	local stockItem = nut.item.list[uniqueID]

	if (stockItem) then
		local item = setmetatable({
			id = id,
			data = {}
		}, {__index = stockItem})

		nut.item.instances[id] = item

		return item
	else
		error("[NutScript] Attempt to create unknown item '"..tostring(uniqueID).."'\n")
	end
end

do
	nut.util.include("nutscript/gamemode/core/meta/sh_inventory.lua")

	function nut.item.createInv(w, h, id)
		DEPRECATED()
		local inventory = setmetatable({w = w, h = h, id = id, slots = {}, vars = {}}, nut.meta.inventory)
		nut.item.inventories[id] = inventory

		return inventory
	end

	function nut.item.restoreInv(invID, w, h, callback)
		DEPRECATED()
		if (type(invID) != "number" or invID < 0) then
			error("Attempt to restore inventory with an invalid ID!")
		end

		local inventory = nut.item.createInv(w, h, invID)

		nut.db.query("SELECT _itemID, _uniqueID, _data, _x, _y FROM nut_items WHERE _invID = "..invID, function(data)
			local badItemsUniqueID = {}

			if (data) then
				local slots = {}
				local badItems = {}

				for _, item in ipairs(data) do
					local x, y = tonumber(item._x), tonumber(item._y)
					local itemID = tonumber(item._itemID)
					local data = util.JSONToTable(item._data or "[]")

					if (x and y and w and h and itemID) then
						if (x <= w and x > 0 and y <= h and y > 0) then
							local item2 = nut.item.new(item._uniqueID, itemID)

							if (item2) then
								if (x + (item2.width - 1) > w or y + (item2.height - 1) > h) then
									-- remove items that is overflowing the inventory.
									badItemsUniqueID[#badItemsUniqueID + 1] = item._uniqueID
									badItems[#badItems + 1] = itemID
								else
									item2.data = {}
									if (data) then
										item2.data = data
									end

									-- legacy support for x, y data
									item2.data.x = tonumber(x)
									item2.data.y = tonumber(y)

									item2.invID = invID

									for x2 = 0, item2.width - 1 do
										for y2 = 0, item2.height - 1 do
											slots[x + x2] = slots[x + x2] or {}
											slots[x + x2][y + y2] = item2
										end
									end

									if (item2.onRestored) then
										item2:onRestored(item2, invID)
									end
								end
							else
								-- remove items that is not valid.
								badItemsUniqueID[#badItemsUniqueID + 1] = item._uniqueID
								badItems[#badItems + 1] = itemID
							end
						else
							-- remove items that is not valid.
							badItemsUniqueID[#badItemsUniqueID + 1] = item._uniqueID
							badItems[#badItems + 1] = itemID
						end
					end
				end

				inventory.slots = slots

				if (table.Count(badItems) > 0) then
					nut.db.query("DELETE FROM nut_items WHERE _itemID IN ("..table.concat(badItems, ", ")..")")
				end
			end

			if (callback) then
				callback(inventory, badItemsUniqueID)
			end
		end)
	end

	if (CLIENT) then
		netstream.Hook("item", function(uniqueID, id, data, invID)
			local stockItem = nut.item.list[uniqueID]
			local item = nut.item.new(uniqueID, id)

			item.data = {}
			if (data) then
				item.data = data
			end

			item.invID = invID or 0
			hook.Run("ItemInitialized", item)
		end)

		netstream.Hook("invData", function(id, key, value)
			local item = nut.item.instances[id]

			if (item) then
				item.data = item.data or {}
				local oldValue = item.data[key]
				item.data[key] = value
				hook.Run("ItemDataChanged", item, key, oldValue, value)
			end
		end)

		net.Receive("nutItemInstance", function()
			local itemID = net.ReadUInt(32)
			local itemType = net.ReadString()
			local data = net.ReadTable()
			local item = nut.item.new(itemType, itemID)
			local invID = net.ReadType()

			item.data = table.Merge(item.data or {}, data)
			item.invID = invID

			nut.item.instances[itemID] = item
			hook.Run("ItemInitialized", item)
		end)

		net.Receive("nutCharacterInvList", function()
			local charID = net.ReadUInt(32)
			local length = net.ReadUInt(32)
			local inventories = {}

			for i = 1, length do
				inventories[i] = nut.inventory.instances[net.ReadType()]
			end

			local character = nut.char.loaded[charID]
			if (character) then
				character.vars.inv = inventories
			end
		end)

		net.Receive("nutItemDelete", function()
			local id = net.ReadUInt(32)
			local instance = nut.item.instances[id]
			if (instance and instance.invID) then
				local inventory = nut.inventory.instances[instance.invID]
				if (not inventory or not inventory.items[id]) then return end

				inventory.items[id] = nil
				instance.invID = 0
				hook.Run("InventoryItemRemoved", inventory, instance)
			end

			nut.item.instances[id] = nil
			hook.Run("ItemDeleted", instance)
		end)
	else
		util.AddNetworkString("nutCharacterInvList")
		util.AddNetworkString("nutItemDelete")
		util.AddNetworkString("nutItemInstance")

		function nut.item.deleteByID(id)
			if (nut.item.instances[id]) then
				nut.item.instances[id]:delete()
			else
				nut.db.delete("items", "_itemID = "..id)
			end
		end

		function nut.item.loadItemByID(itemIndex, recipientFilter)
			local range
			if (type(itemIndex) == "table") then
				range = "("..table.concat(itemIndex, ", ")..")"
			elseif (type(itemIndex) == "number") then
				range = "(".. itemIndex ..")"
			else
				return
			end

			nut.db.query("SELECT _itemID, _uniqueID, _data, _x, _y FROM nut_items WHERE _itemID IN "..range, function(data)
				if (data) then
					for k, v in ipairs(data) do
						local itemID = tonumber(v._itemID)
						local data = util.JSONToTable(v._data or "[]")
						local uniqueID = v._uniqueID
						local itemTable = nut.item.list[uniqueID]

						if (itemTable and itemID) then
							local item = nut.item.new(uniqueID, itemID)

							item.invID = 0
							item.data = data or {}

							-- Legacy support for x, y data
							item.data.x = tonumber(v._x)
							item.data.y = tonumber(v._y)

							item:onRestored()
						end
					end
				end
			end)
		end

		netstream.Hook("invMv", function(client, oldX, oldY, x, y, invID, newInvID)
			oldX, oldY, x, y, invID = tonumber(oldX), tonumber(oldY), tonumber(x), tonumber(y), tonumber(invID)
			if (!oldX or !oldY or !x or !y or !invID) then return end

			local character = client:getChar()

			if (character) then
				local inventory = nut.item.inventories[invID]

				if (!inventory or inventory == nil) then
					inventory:sync(client)
				end

				if ((!inventory.owner or (inventory.owner and inventory.owner == character:getID())) or (inventory.onCheckAccess and inventory:onCheckAccess(client))) then
					local item = inventory:getItemAt(oldX, oldY)

					if (item) then
						if (newInvID and invID != newInvID) then
							local inventory2 = nut.item.inventories[newInvID]

							if (inventory2) then
								item:transfer(newInvID, x, y, client)
							end

							return
						end

						if (inventory:canItemFit(x, y, item.width, item.height, item)) then
							item.gridX = x
							item.gridY = y

							for x2 = 0, item.width - 1 do
								for y2 = 0, item.height - 1 do
									local oldX = inventory.slots[oldX + x2]

									if (oldX) then
										oldX[oldY + y2] = nil
									end
								end
							end

							for x2 = 0, item.width - 1 do
								for y2 = 0, item.height - 1 do
									inventory.slots[x + x2] = inventory.slots[x + x2] or {}
									inventory.slots[x + x2][y + y2] = item
								end
							end

							local receiver = inventory:getReceiver()

							if (receiver and type(receiver) == "table") then
								for k, v in ipairs(receiver) do
									if (v != client) then
										netstream.Start(v, "invMv", invID, item:getID(), x, y)
									end
								end
							end

							if (!inventory.noSave) then
								nut.db.query("UPDATE nut_items SET _x = "..x..", _y = "..y.." WHERE _itemID = "..item.id)
							end
						end
					end
				end
			end
		end)

		netstream.Hook("invSplit", function(client, item, amount, invID)
			local character = client:getChar()

			if (!character) then
				-- print << invalid request
				return false
			end

			local inventory = nut.item.inventories[invID]

			if (!inventory or !inventory.owner or inventory.owner != character:getID()) then
				-- print << no inventory
				return false
			end

			if (hook.Run("CanPlayerInteractItem", client, action, item, data) == false) then
				-- print << cantuse
				return false
			end

			if (type(item) == "number") then
				item = nut.item.instances[item]

				if (!item) then
					-- print << invalid request 

					return false
				end

				item.player = client
			end

			if (!inventory:getItemByID(item.id)) then
				-- print << invalid request
				return false
			end 

			amount = math.Round(amount)
			local leftOver = itemQuantity - amount

			-- You VS The Guy Told You Not to Worry About
			if (leftOver > 0) then
				local result, msg = inventory:add(item.uniqueID, amount, item.data, nil, nil, nil, true)

				if (result != false) then
					item:setQuantity(leftOver)

					return true, item, msg
				else
					return result, msg
				end
			end
		end)

		netstream.Hook("invAct", function(client, action, item, invID, data)
			local character = client:getChar()
			if (!character) then
				return
			end

			-- Refine item into an instance
			local entity
			if (type(item) == "Entity") then
				if (not IsValid(item)) then
					return
				end
				if (item:GetPos():Distance(client:GetPos()) > 96) then
					return
				end
				if (not item.nutItemID) then
					return
				end
				entity = item
				item = nut.item.instances[item.nutItemID]
			else
				item = nut.item.instances[item]
			end
			if (not item) then
				return
			end
			-- Permission check with inventory. Or, if no inventory exists,
			-- the player has no way of accessing the item.
			local inventory = nut.inventory.instances[item.invID]
			local context = {
				client = client, item = item, entity = entity, action = action
			}
			if (
				inventory and not inventory:canAccess("item", context)
			) then
				return
			end

			item:interact(action, client, entity, data)
		end)
	end

	-- Instances and spawns a given item type.
	function nut.item.spawn(uniqueID, position, callback, angles, data)
		nut.item.instance(0, uniqueID, data or {}, 1, 1, function(item)
			if (item.isStackable) then
				item:setQuantity(item:getMaxQuantity())
			end

			local entity = item:spawn(position, angles)

			if (callback) then
				callback(item, entity)
			end
		end)
	end
end

nut.char.registerVar("inv", {
	noNetworking = true,
	noDisplay = true,
	onGet = function(character, index)
		if (index and type(index) != "number") then
			return character.vars.inv or {}
		end

		return character.vars.inv and character.vars.inv[index or 1]
	end,
	onSync = function(character, recipient)
		net.Start("nutCharacterInvList")
			net.WriteUInt(character:getID(), 32)
			net.WriteUInt(#character.vars.inv, 32)
			
			for i = 1, #character.vars.inv do
				net.WriteType(character.vars.inv[i].id)
			end
		if (recipient == nil) then
			net.Broadcast()
		else
			net.Send(recipient)
		end
	end
})
