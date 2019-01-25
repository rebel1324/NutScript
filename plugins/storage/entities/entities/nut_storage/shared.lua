local PLUGIN = PLUGIN

ENT.Type = "anim"
ENT.PrintName = "Storage"
ENT.Category = "NutScript"
ENT.Spawnable = false
ENT.isStorageEntity = true

function ENT:getInv()
	return nut.inventory.instances[self:getNetVar("id")]
end

function ENT:getStorageInfo()
	self.lowerModel = self.lowerModel or self:GetModel()
	return PLUGIN.definitions[self.lowerModel]
end
