local TRANSFER = "transfer"

-- Inventories associated with a bag item can only be accessed if the
-- inventory of the bag item can be accessed.
local function CanAccessIfPlayerHasAccessToBag(inventory, action, context)
	-- Bag inventories without an item should not exist.
	local bagItemID = inventory:getData("item")
	if (not bagItemID) then return end
	local bagItem = nut.item.instances[bagItemID]
	if (not bagItem) then return false, "Invalid bag item" end

	-- If there is a parent inventory (inventory of the bag item), then defer
	-- access decision to that.
	local parentInv = nut.inventory.instances[bagItem.invID]
	if (parentInv == inventory) then return end

	-- Append the bag inventory to the context.
	local contextWithBagInv = {}
	for key, value in pairs(context) do
		contextWithBagInv[key] = value
	end
	contextWithBagInv.bagInv = inventory
	return parentInv
		and parentInv:canAccess(action, contextWithBagInv)
		or false, "noAccess"
end

local function CanNotTransferBagIntoBag(inventory, action, context)
	if (action ~= TRANSFER) then return end

	local item, toInventory = context.item, context.to
	if (toInventory:getData("item") and item.isBag) then
		return false, "A bag cannot be placed into another bag"
	end
end

local function CanNotTransferBagIfNestedItemCanNotBe(inventory, action, context)
	if (action ~= TRANSFER) then return end
	local item = context.item
	if (not item.isBag) then return end

	local bagInventory = item:getInv()
	if (not bagInventory) then return end

	for _, item in pairs(bagInventory:getItems()) do
		local canTransferItem, reason =
			hook.Run("CanItemBeTransfered", item, bagInventory, bagInventory)
		if (canTransferItem == false) then
			return false, reason or "An item in the bag cannot be transfered"
		end
	end
end

function PLUGIN:SetupBagInventoryAccessRules(inventory)
	inventory:addAccessRule(CanNotTransferBagIntoBag)
	inventory:addAccessRule(CanNotTransferBagIfNestedItemCanNotBe)
	inventory:addAccessRule(CanAccessIfPlayerHasAccessToBag)
end
