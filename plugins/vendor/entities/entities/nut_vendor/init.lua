include("shared.lua")
include("../../../sh_enums.lua")

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
	-- Show an error message if the player is not allowed to use the vendor.
	if (not hook.Run("CanPlayerAccessVendor", activator, self)) then
		if (self.messages[VENDOR_NOTRADE]) then
			activator:ChatPrint(
				self:getNetVar("name")
				..": "
				..L(self.messages[VENDOR_NOTRADE], activator)
			)
		end
		return
	end

	-- Otherwise, add the activator to the list of people trading.
	nut.log.add(activator, "vendorAccess", self:getNetVar("name"))
	self.receivers[#self.receivers + 1] = activator
	activator.nutVendor = self

	-- And show a "welcome" message if applicable.
	if (self.messages[VENDOR_WELCOME]) then
		activator:ChatPrint(
			self:getNetVar("name")
			..": "
			..self.messages[VENDOR_WELCOME]
		)
	end

	-- Finally, send the vendor state to the activator.
	hook.Run("PlayerAccessVendor", activator, self)
end

-- Sets how much money the vendor has.
function ENT:setMoney(value)
	if (not isnumber(value) or value < 0) then value = nil end
	self.money = value
	net.Start("nutVendorMoney")
		net.WriteInt(value or -1, 32)
	net.Send(self.receivers)
end

-- Adds the given value to the amount of money the vendor has.
function ENT:giveMoney(value)
	if (self.money) then
		self:setMoney(self:getMoney() + value)
	end
end

-- Removes the given value from the amount of money the vendor has.
function ENT:takeMoney(value)
	if (self.money) then
		self:giveMoney(-value)
	end
end

-- Sets how many items of the given type the vendor owns.
-- The value can be nil to disable use of stock for the item.
-- This is essentially having unlimited stock.
function ENT:setStock(itemType, value)
	self.items[itemType] = self.items[itemType] or {}

	if (not self.items[itemType][VENDOR_MAXSTOCK]) then
		self:setMaxStock(itemType, value)
	end

	self.items[itemType][VENDOR_STOCK] = math.Clamp(
		value,
		0, self.items[itemType][VENDOR_MAXSTOCK]
	)

	net.Start("nutVendorStock")
		net.WriteString(itemType)
		net.WriteUInt(value, 32)
	net.Send(self.receivers)
end

-- Increments the stock of the specified item by the given value.
-- However, if the item does not have a max stock set, nothing happens.
function ENT:addStock(itemType, value)
	local current = self:getStock(itemType)
	if (not current) then return end

	self:setStock(itemType, self:getStock(itemType) + (value or 1))
end

-- Decrements the stock of the specified item by the given value.
-- However, if the item does not have a max stock set, nothing happens.
function ENT:takeStock(itemType, value)
	if (
		not self.items[itemType] or
		not self.items[itemType][VENDOR_MAXSTOCK]
	) then
		return
	end

	self:addStock(itemType, -(value or 1))
end

-- Sets the maximum stock for a specific item to the given value.
-- If the value is nil or 0, then the vendor will not use the stock system
-- for the item.
function ENT:setMaxStock(itemType, value)
	if (value == 0 or not isnumber(value)) then
		value = nil
	end

	self.items[itemType] = self.items[itemType] or {}
	self.items[itemType][VENDOR_MAXSTOCK] = value

	net.Start("nutVendorMaxStock")
		net.WriteString(itemType)
		net.WriteUInt(value, 32)
	net.Send(self.receivers)
end

-- Sets whether or not members of the given faction are allowed to use this.
function ENT:setFactionAllowed(factionID, isAllowed)
	-- Cast to either true or nil.
	if (isAllowed) then
		self.factions[factionID] = true
	else
		self.factions[factionID] = nil
	end

	net.Start("nutVendorAllowFaction")
		net.WriteUInt(factionID, 8)
		net.WriteBool(self.factions[factionID] == true)
	net.Send(self.receivers)

	-- Kick out people who are no longer allowed to trade.
	for _, client in ipairs(self.receivers) do
		if (not hook.Run("CanPlayerAccessVendor", client, self)) then
			self:removeReceiver(client)
		end
	end
end

-- Set whether or not members of the given class are allowed to use this.
function ENT:setClassAllowed(classID, isAllowed)
	-- Cast to either true or nil.
	if (isAllowed) then
		self.classes[classID] = true
	else
		self.classes[classID] = nil
	end
	net.Start("nutVendorAllowClass")
		net.WriteUInt(classID, 8)
		net.WriteBool(self.classes[classID] == true)
	net.Send(self.receivers)
end

-- Forces a player to leave the trade with this vendor.
function ENT:removeReceiver(client, requestedByPlayer)
	table.RemoveByValue(self.receivers, client)
	if (client.nutVendor == self) then
		client.nutVendor = nil
	end

	if (requestedByPlayer) then return end

	net.Start("nutVendorExit")
	net.Send(client)
end

local ALLOWED_MODES = {
	[VENDOR_SELLANDBUY] = true,
	[VENDOR_SELLONLY] = true,
	[VENDOR_BUYONLY] = true
}

-- Sets the name of the vendor and updates it in the editor.
function ENT:setName(name)
	self:setNetVar("name", name)
	net.Start("nutVendorEdit")
		net.WriteString("name")
	net.Send(self.receivers)
end

-- Sets the description of the vendor and updates it in the editor.
function ENT:setDesc(desc)
	self:setNetVar("desc", desc)
	net.Start("nutVendorEdit")
		net.WriteString("desc")
	net.Send(self.receivers)
end

-- Sets whether or not the bubble should be disabled.
function ENT:setNoBubble(noBubble)
	self:setNetVar("noBubble", noBubble)
	net.Start("nutVendorEdit")
		net.WriteString("bubble")
	net.Send(self.receivers)
end

-- Sets how the item is traded between vendor and player.
function ENT:setTradeMode(itemType, mode)
	if (not ALLOWED_MODES[mode]) then
		mode = nil
	end

	self.items[itemType] = self.items[itemType] or {}
	self.items[itemType][VENDOR_MODE] = mode

	net.Start("nutVendorMode")
		net.WriteString(itemType)
		net.WriteInt(mode or -1, 8)
	net.Send(self.receivers)
end

-- Sets the price for a particular item.
-- If the value is not a number or is negative, then the item's price is used.
function ENT:setItemPrice(itemType, value)
	if (not isnumber(value) or value < 0) then
		value = nil
	end

	self.items[itemType] = self.items[itemType] or {}
	self.items[itemType][VENDOR_PRICE] = value

	net.Start("nutVendorPrice")
		net.WriteString(itemType)
		net.WriteInt(value or -1, 32)
	net.Send(self.receivers)
end

-- Sets the stock for a particular item.
-- If the value is not a number or is negative, then the item's price is used.
function ENT:setItemStock(itemType, value)
	if (not isnumber(value) or value < 0) then
		value = nil
	end

	self.items[itemType] = self.items[itemType] or {}
	self.items[itemType][VENDOR_STOCK] = value

	net.Start("nutVendorStock")
		net.WriteString(itemType)
		net.WriteInt(value, 32)
	net.Send(self.receivers)
end

-- Sets the maximum stock for a particular item.
-- If the value is not a number or is negative, then the item's price is used.
function ENT:setItemMaxStock(itemType, value)
	if (not isnumber(value) or value < 0) then
		value = nil
	end

	self.items[itemType] = self.items[itemType] or {}
	self.items[itemType][VENDOR_MAXSTOCK] = value

	net.Start("nutVendorMaxStock")
		net.WriteString(itemType)
		net.WriteInt(value, 32)
	net.Send(self.receivers)
end

function ENT:OnRemove()
	NUT_VENDORS[self:EntIndex()] = nil

	net.Start("nutVendorExit")
	net.Send(self.receivers)

	if (nut.shuttingDown or self.nutIsSafe) then return end
	PLUGIN:saveVendors()
end

-- Change the model of the vendor and update the editor.
function ENT:setModel(model)
	assert(isstring(model), "model must be a string")
	model = model:lower()

	self:SetModel(model)
	self:setAnim()

	net.Start("nutVendorEdit")
		net.WriteString("model")
	net.Send(self.receivers)
end

-- Sets how much of the original price a player gets back for selling an item.
-- Set the price scaling for when a player is selling an item to the vendor.
function ENT:setSellScale(scale)
	assert(isnumber(scale), "scale must be a number")

	self:setNetVar("scale", scale)
	net.Start("nutVendorEdit")
		net.WriteString("scale")
	net.Send(self.receivers)
end

function ENT:sync(client)
	net.Start("nutVendorSync")
		net.WriteEntity(self)
		net.WriteInt(self:getMoney() or -1, 32)
		net.WriteUInt(table.Count(self.items), 16)
		for itemType, item in pairs(self.items) do
			net.WriteString(itemType)
			net.WriteInt(item[VENDOR_PRICE] or -1, 32)
			net.WriteInt(item[VENDOR_STOCK] or -1, 32)
			net.WriteInt(item[VENDOR_MAXSTOCK] or -1, 32)
			net.WriteInt(item[VENDOR_MODE] or -1, 8)
		end
	net.Send(client)

	if (client:IsAdmin()) then
		for factionID in pairs(self.factions) do
			net.Start("nutVendorAllowFaction")
				net.WriteUInt(factionID, 8)
				net.WriteBool(true)
			net.Send(client)
		end
		for classID in pairs(self.classes) do
			net.Start("nutVendorAllowClass")
				net.WriteUInt(classID, 8)
				net.WriteBool(true)
			net.Send(client)
		end
	end
end

function ENT:addReceiver(client, noSync)
	if (not table.HasValue(self.receivers, client)) then
		self.receivers[#self.receivers + 1] = client
	end

	if (noSync) then return end
	self:sync(client)
end
