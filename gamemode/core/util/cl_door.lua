local entityMeta = FindMetaTable("Entity")

-- Checks if an entity is a door by comparing its class.
function entityMeta:isDoor()
	return self:GetClass():find("door")
end

-- Returns the door's slave entity.
function entityMeta:getDoorPartner()
	local owner = self:GetOwner() or self.nutDoorOwner

	if (IsValid(owner) and owner:isDoor()) then
		return owner
	end

	for k, v in ipairs(ents.FindByClass("prop_door_rotating")) do
		if (v:GetOwner() == self) then
			self.nutDoorOwner = v

			return v
		end
	end
end
