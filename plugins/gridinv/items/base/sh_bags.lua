local INVENTORY_TYPE_ID = "grid"

ITEM.name = "Bag"
ITEM.desc = "A bag to hold more items."
ITEM.model = "models/props_c17/suitcase001a.mdl"
ITEM.category = "Storage"
ITEM.isBag = true

ITEM.functions.View = {
	icon = "icon16/briefcase.png",
	onClick = function(item)
		local inventory = item:getInv()
		if (not inventory) then return false end

		local panel = nut.gui["inv"..inventory:getID()]
		local parent = item.invID and nut.gui["inv"..item.invID] or nil

		if (IsValid(panel)) then
			panel:Remove()
		end

		if (inventory) then
			local panel = nut.inventory.show(inventory, parent)
			if (IsValid(panel)) then
				panel:ShowCloseButton(true)
				panel:SetTitle(item:getName())
			end
		else
			local itemID = item:getID()
			local index = item:getData("id", "nil")
			ErrorNoHalt(
				"Invalid inventory "..index.." for bag item "..itemID.."\n"
			)
		end
		return false
	end,
	onCanRun = function(item)
		return !IsValid(item.entity) and item:getInv()
	end
}

-- The size of the inventory held by this item.
ITEM.invWidth = 1
ITEM.invHeight = 1

-- Inventories associated with a bag item can only be accessed if the
-- inventory of the bag item can be accessed.
local function CanAccessIfPlayerHasAccessToBag(inventory, action, context)
	-- Bag inventories without an item should not exist.
	local bagItemID = inventory:getData("item")
	if (not bagItemID) then return false end
	local bagItem = nut.item.instances[bagItemID]
	if (not bagItem) then return false end

	-- If there is a parent inventory (inventory of the bag item), then defer
	-- access decision to that.
	local parentInv = nut.inventory.instances[bagItem.invID]
	local contextWithBagInv = table.Copy(context)
	contextWithBagInv.bagInv = inventory
	return parentInv
		and parentInv:canAccess(action, contextWithBagInv)
		or false
end

function ITEM:onInstanced(id)
	local data = {
		item = id,
		w = self.invWidth,
		h = self.invHeight
	}
	nut.inventory.instance(INVENTORY_TYPE_ID, data)
		:next(function(inventory)
			self:setData("id", inventory:getID())
			inventory:addAccessRule(CanAccessIfPlayerHasAccessToBag)
			inventory:sync()
		end)
end

function ITEM:onRestored()
	local invID = self:getData("id")
	if (invID) then
		nut.inventory.loadByID(invID)
			:next(function(inventory)
				inventory:addAccessRule(CanAccessIfPlayerHasAccessToBag)
			end)
	end
end

function ITEM:onRemoved()
	local invID = self:getData("id")
	if (invID) then
		nut.inventory.deleteByID(invID)
	end
end

function ITEM:getInv()
	return nut.inventory.instances[self:getData("id")]
end

function ITEM:onSync(recipient)
	local inventory = self:getInv()
	if (inventory) then
		inventory:sync(recipient)
	end
end
