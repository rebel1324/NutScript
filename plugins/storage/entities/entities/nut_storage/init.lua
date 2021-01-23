local PLUGIN = PLUGIN

include("shared.lua")

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

local DEFAULT_LOCK_SOUND = "doors/default_locked.wav"
local DEFAULT_OPEN_SOUND = "items/ammocrate_open.wav"
local OPEN_TIME = 0.7

function ENT:Initialize()
	self:SetModel("models/props_junk/watermelon01.mdl")
	self:SetSolid(SOLID_VPHYSICS)
	self:SetUseType(SIMPLE_USE)
	self.receivers = {}
	
	if (isfunction(self.PostInitialize)) then
		self:PostInitialize()
	end

	self:PhysicsInit(SOLID_VPHYSICS)
	local physObj = self:GetPhysicsObject()

	if (IsValid(physObj)) then
		physObj:EnableMotion(true)
		physObj:Wake()
	end
end

function ENT:setInventory(inventory)
	assert(inventory, "Storage setInventory called without an inventory!")
	self:setNetVar("id", inventory:getID())

	hook.Run("StorageInventorySet", self, inventory)
end

function ENT:deleteInventory()
	local inventory = self:getInv()
	if (inventory) then
		inventory:delete()

		if (not self.nutForceDelete) then
			hook.Run("StorageEntityRemoved", self, inventory)
		end

		self:setNetVar("id", nil)
	end
end

function ENT:OnRemove()
	if (not self.nutForceDelete) then
		if (not nut.entityDataLoaded or not PLUGIN.loadedData) then return end
		if (self.nutIsSafe) then return end
		if (nut.shuttingDown) then return end
	end
	self:deleteInventory()
	PLUGIN:saveStorage()
end

function ENT:openInv(activator)
	local inventory = self:getInv()
	local storage = self:getStorageInfo()
	if (isfunction(storage.onOpen)) then
		storage.onOpen(self, activator)
	end
	activator:setAction(L("Opening...", activator), OPEN_TIME, function()
		if (activator:GetPos():Distance(self:GetPos()) > 96) then
			activator.nutStorageEntity = nil
			return
		end

		self.receivers[activator] = true
		inventory:sync(activator)

		net.Start("nutStorageOpen")
			net.WriteEntity(self)
		net.Send(activator)

		local openSound = self:getStorageInfo().openSound
		self:EmitSound(openSound or DEFAULT_OPEN_SOUND)
	end)
end

function ENT:Use(activator)
	if (not activator:getChar()) then return end
	if ((activator.nutNextOpen or 0) > CurTime()) then return end
	if (IsValid(activator.nutStorageEntity) and (activator.nutNextOpen or 0) <= CurTime()) then
		activator.nutStorageEntity = nil
	end
	local inventory = self:getInv()
	if (not inventory) then return end

	activator.nutStorageEntity = self


	if (self:getNetVar("locked")) then
		local lockSound = self:getStorageInfo().lockSound
		self:EmitSound(lockSound or DEFAULT_LOCK_SOUND)

		if (self.keypad) then
			client.nutStorageEntity = nil
		else
			net.Start("nutStorageUnlock")
				net.WriteEntity(self)
			net.Send(activator)
		end
	else
		self:openInv(activator)
	end

	activator.nutNextOpen = CurTime() + OPEN_TIME * 1.5
end
