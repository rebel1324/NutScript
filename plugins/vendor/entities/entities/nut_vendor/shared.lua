ENT.Type = "anim"
ENT.PrintName = "Vendor"
ENT.Category = "NutScript"
ENT.Spawnable = true
ENT.AdminOnly = true
ENT.isVendor = true

NUT_VENDORS = NUT_VENDORS or {}

function ENT:Initialize()
	if (SERVER) then
		self:SetModel("models/mossman.mdl")
		self:SetUseType(SIMPLE_USE)
		self:SetMoveType(MOVETYPE_NONE)
		self:DrawShadow(true)
		self:SetSolid(SOLID_BBOX)
		self:PhysicsInit(SOLID_BBOX)

		self.items = {}
		self.messages = {}
		self.factions = {}
		self.classes = {}

		self:setNetVar("name", "John Doe")
		self:setNetVar("desc", "")

		self.receivers = {}

		local physObj = self:GetPhysicsObject()

		if (IsValid(physObj)) then
			physObj:EnableMotion(false)
			physObj:Sleep()
		end

		NUT_VENDORS[self:EntIndex()] = self
	end

	timer.Simple(1, function()
		if (IsValid(self)) then
			self:setAnim()
		end
	end)
end

function ENT:canAccess(client)
	if (client:IsAdmin()) then
		return true
	end

	local allowed = false
	local factionID = nut.faction.indices[client:Team()].uniqueID

	if (self.factions and table.Count(self.factions) > 0) then
		if (self.factions[uniqueID]) then
			allowed = true
		else
			return false
		end
	end

	if (allowed and self.classes and table.Count(self.classes) > 0) then
		local class = nut.class.list[client:getChar():getClass()]
		local classID = class and class.uniqueID

		if (!self.classes[class]) then
			return false
		end
	end

	return true
end

function ENT:getStock(uniqueID)
	if (self.items[uniqueID] and self.items[uniqueID][VENDOR_MAXSTOCK]) then
		return self.items[uniqueID][VENDOR_STOCK] or 0, self.items[uniqueID][VENDOR_MAXSTOCK]
	end
end

function ENT:getPrice(uniqueID, selling)
	local price = 0

	if (isstring(uniqueID)) then
		price = nut.item.list[uniqueID] and self.items[uniqueID] and self.items[uniqueID][VENDOR_PRICE] or nut.item.list[uniqueID]:getPrice() or 0
	elseif (istable(uniqueID)) then
		price = uniqueID:getPrice()
	elseif (isnumber(uniqueID)) then
		price = nut.item.instances[uniqueID]:getPrice()
	end

	if (selling) then
		price = math.floor(price * (self:getNetVar("scale", 0.5)))
	end

	return price
end

function ENT:canSellToPlayer(client, uniqueID)
	local data = self.items[uniqueID]

	if (!data or !client:getChar() or !nut.item.list[uniqueID]) then
		return false
	end

	if (data[VENDOR_MODE] == VENDOR_BUYONLY) then
		return false
	end

	if (!client:getChar():hasMoney(self:getPrice(uniqueID))) then
		return false
	end

	if (data[VENDOR_STOCK] and data[VENDOR_STOCK] < 1) then
		return false
	end

	return true
end

function ENT:canBuyFromPlayer(client, uniqueID)
	local data = self.items[uniqueID]

	if (!data or !client:getChar() or !nut.item.list[uniqueID]) then
		return false
	end

	if (data[VENDOR_MODE] != VENDOR_SELLONLY) then
		return false
	end

	if (!self:hasMoney(data[VENDOR_PRICE] or nut.item.list[uniqueID].price or 0)) then
		return false
	end

	return true
end

function ENT:hasMoney(amount)
	-- Vendor not using money system so they can always afford it.
	if (!self.money) then
		return true
	end

	return self.money >= amount
end

function ENT:setAnim()
	for k, v in ipairs(self:GetSequenceList()) do
		if (v:lower():find("idle") and v != "idlenoise") then
			return self:ResetSequence(k)
		end
	end

	self:ResetSequence(4)
end

function ENT:getMoney()
	return self.money
end
