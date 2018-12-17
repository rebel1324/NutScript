-- This file contains implementation for the old inventory library functions.
-- But, these really should not be used.

-- Alias to new inventory instance list.
nut.item.inventories = nut.inventory.instances

local function DEPRECATED()
	local warning = debug.getinfo(2, "n").name.." is deprecated"
	local output = debug.traceback(warning, 3)
	local lines = string.Explode("\n", output)
	print("\n"..lines[1].."\n"..lines[3].."\n\n")
end

function nut.item.registerInv(invType, w, h)
	DEPRECATED()

	local GridInv = FindMetaTable("GridInv")
	assert(GridInv, "GridInv not found")

	local inventory = GridInv:extend("GridInv"..invType)
	inventory.invType = invType

	function inventory:getWidth()
		return w
	end

	function inventory:getHeight()
		return h
	end

	inventory:register(invType)
end

function nut.item.newInv(owner, invType, callback)
	DEPRECATED()

	nut.inventory.instance(invType, {char = owner})
		:next(function(inventory)
			inventory.invType = invType
			if (owner and owner > 0) then
				for k, v in ipairs(player.GetAll()) do
					if (v:getChar() and v:getChar():getID() == owner) then
						inventory:sync(v)
						break
					end
				end
			end
			if (callback) then
				callback(inventory)
			end
		end)
end

function nut.item.getInv(invID)
	DEPRECATED()

	return nut.inventory.instances[invID]
end

function nut.item.createInv(w, h, id)
	DEPRECATED()

	local GridInv = FindMetaTable("GridInv")
	assert(GridInv, "GridInv not found")

	local instance = GridInv:new()
	instance.id = id
	instance.data = {w = w, h = h}
	
	nut.inventory.instances[id] = instance
	return instance
end

if (CLIENT) then return end

function nut.item.restoreInv(invID, w, h, callback)
	DEPRECATED()

	nut.inventory.loadByID(invID)
		:next(function(inventory)
			if (not inventory) then return end

			inventory:setData("w", w)
			inventory:setData("h", h)

			if (callback) then
				callback(inventory)
			end
		end)
end

netstream.Hook("invMv", function(client)
	print("Tell the developer that 'invMv' has been deprecated!")
	print("Instead, the nutTransferItem net message should be used.")
	client:ChatPrint("Tell the developer that 'invMv' has been deprecated!")
	client:ChatPrint("Instead, the nutTransferItem net message should be used.")
end)
