ENT.Type = "anim"
ENT.PrintName = "Vendor"
ENT.Category = "NutScript"
ENT.Spawnable = true
ENT.AdminOnly = true
ENT.isVendor = true

NUT_VENDORS = NUT_VENDORS or {}

function ENT:setupVars()
	if (SERVER) then
		self:setNetVar("name", "John Doe")
		self:setNetVar("desc", "")

		self.receivers = {}
	end

	self.items = {}
	self.factions = {}
	self.messages = {}
	self.classes = {}
	self.hasSetupVars = true
end

function ENT:Initialize()
	if (CLIENT) then
		timer.Simple(1, function()
			if (not IsValid(self)) then return end
			self:setAnim()
		end)
		return
	end

	self:SetModel("models/mossman.mdl")
	self:SetUseType(SIMPLE_USE)
	self:SetMoveType(MOVETYPE_NONE)
	self:DrawShadow(true)
	self:SetSolid(SOLID_BBOX)
	self:PhysicsInit(SOLID_BBOX)
	self:setupVars()

	local physObj = self:GetPhysicsObject()

	if (IsValid(physObj)) then
		physObj:EnableMotion(false)
		physObj:Sleep()
	end

	NUT_VENDORS[self:EntIndex()] = self
end

function ENT:getMoney()
	return self.money
end

function ENT:hasMoney(amount)
	local moeny = self:getMoney()

	-- Vendor not using money system so they can always afford it.
	if (not money) then
		return true
	end

	return money >= amount
end

-- Return how much stock for an item the vendor has. If the stock
-- is not applicable, nil is returned.
function ENT:getStock(uniqueID)
	if (
		self.items[uniqueID] and
		self.items[uniqueID][VENDOR_MAXSTOCK]
	) then
		return self.items[uniqueID][VENDOR_STOCK] or 0,
			self.items[uniqueID][VENDOR_MAXSTOCK]
	end
end

-- Returns the maximum number of stock for an item if applicable.
function ENT:getMaxStock(itemType)
	if (self.items[itemType]) then
		return self.items[itemType][VENDOR_MAXSTOCK]
	end
end

-- Returns true if the given item is in stock.
function ENT:isItemInStock(itemType, amount)
	amount = amount or 1
	assert(isnumber(amount), "amount must be a number")

	local info = self.items[itemType]
	if (not info) then
		return false
	end
	if (not info[VENDOR_MAXSTOCK]) then
		return true
	end
	return info[VENDOR_STOCK] >= amount
end

-- Returns the price for an item. If isSellingToVendor, then the price is
-- the amount the player receives for selling the item. That is, it is scaled.
function ENT:getPrice(uniqueID, isSellingToVendor)
	local price = nut.item.list[uniqueID]
		and self.items[uniqueID]
		and self.items[uniqueID][VENDOR_PRICE]
		or nut.item.list[uniqueID]:getPrice()

	-- If selling to the vendor, scale the price down since it is "used".
	if (isSellingToVendor) then
		price = math.floor(price * self:getSellScale())
	end

	return price
end

function ENT:getTradeMode(itemType)
	if (self.items[itemType]) then
		return self.items[itemType][VENDOR_MODE]
	end
end

function ENT:isClassAllowed(classID)
	local class = nut.class.list[classID]
	if (not class) then return false end
	local faction = nut.faction.indices[class.faction]
	if (faction and self:isFactionAllowed(faction.index)) then
		return true
	end
	return self.classes[classID] == true
end

function ENT:isFactionAllowed(factionID)
	return self.factions[factionID] == true
end

function ENT:getSellScale()
	return self:getNetVar("scale", 0.5)
end

function ENT:getName()
	return self:getNetVar("name", "")
end

function ENT:getDesc()
	return self:getNetVar("desc", "")
end

function ENT:getNoBubble()
	return self:getNetVar("noBubble") == true
end

function ENT:setAnim()
	for k, v in ipairs(self:GetSequenceList()) do
		if (v:lower():find("idle") and v != "idlenoise") then
			return self:ResetSequence(k)
		end
	end

	self:ResetSequence(4)
end
