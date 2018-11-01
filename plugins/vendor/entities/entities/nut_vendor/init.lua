include("shared.lua")

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

local PLUGIN = PLUGIN

function ENT:SpawnFunction(client, trace)
	local angles = (trace.HitPos - client:GetPos()):Angle()
	angles.r = 0
	angles.p = 0
	angles.y = angles.y + 180

	local entity = ents.Create("nut_vendor")
	entity:SetPos(trace.HitPos)
	entity:SetAngles(angles)
	entity:Spawn()

	PLUGIN:saveVendors()

	return entity
end

function ENT:Use(activator)
	if (!self:canAccess(activator) or hook.Run("CanPlayerUseVendor", activator) == false) then
		if (self.messages[VENDOR_NOTRADE]) then
			activator:ChatPrint(self:getNetVar("name")..": "..self.messages[VENDOR_NOTRADE])
		end

		return
	end

	nut.log.add(activator, "vendorAccess", self:getNetVar("name"))

	self.receivers[#self.receivers + 1] = activator

	if (self.messages[VENDOR_WELCOME]) then
		activator:ChatPrint(self:getNetVar("name")..": "..self.messages[VENDOR_WELCOME])
	end

	local items = {}

	-- Only send what is needed.
	for k, v in pairs(self.items) do
		if (table.Count(v) > 0 and (activator:IsAdmin() or v[VENDOR_MODE])) then
			items[k] = v
		end
	end

	local data = {}
	data[1] = items
	data[2] = self.money

	if (activator:IsAdmin()) then
		data[3] = self.messages
		data[4] = self.factions
		data[5] = self.classes
	end

	activator.nutVendor = self
	netstream.Start(activator, "vendorOpen", self:EntIndex(), unpack(data))
end

function ENT:setMoney(value)
	self.money = value

	netstream.Start(self.receivers, "vendorMoney", value)
end

function ENT:giveMoney(value)
	if (self.money) then
		self:setMoney(self:getMoney() + value)
	end
end

function ENT:takeMoney(value)
	if (self.money) then
		self:giveMoney(-value)
	end
end

function ENT:setStock(uniqueID, value)
	if (!self.items[uniqueID][VENDOR_MAXSTOCK]) then
		return
	end

	self.items[uniqueID] = self.items[uniqueID] or {}
	self.items[uniqueID][VENDOR_STOCK] = math.min(value, self.items[uniqueID][VENDOR_MAXSTOCK])

	netstream.Start(self.receivers, "vendorStock", uniqueID, value)
end

function ENT:addStock(uniqueID, value)
	if (!self.items[uniqueID][VENDOR_MAXSTOCK]) then
		return
	end

	self:setStock(uniqueID, self:getStock(uniqueID) + (value or 1))
end

function ENT:takeStock(uniqueID, value)
	if (!self.items[uniqueID][VENDOR_MAXSTOCK]) then
		return
	end

	self:addStock(uniqueID, -(value or 1))
end

function ENT:OnRemove()
	NUT_VENDORS[self:EntIndex()] = nil
	if (not nut.shuttingDown) then
		PLUGIN:saveVendors()
	end
end
