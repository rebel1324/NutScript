local entityMeta = FindMetaTable("Entity")

-- Checks if an entity is a door by comparing its class.
function entityMeta:isDoor()
	return self:GetClass():find("door")
end

-- Returns the door's slave entity.
function entityMeta:getDoorPartner()
	return self.nutPartner
end

-- Returns whether door/button is locked or not.
function entityMeta:isLocked()
	if (self:IsVehicle()) then
		local datatable = self:GetSaveTable()

		if (datatable) then
			return (datatable.VehicleLocked)
		end
	else
		local datatable = self:GetSaveTable()

		if (datatable) then
			return (datatable.m_bLocked)
		end
	end

	return
end

-- Returns the entity that blocking door's sequence.
function entityMeta:getBlocker()
	local datatable = self:GetSaveTable()

	return (datatable.pBlocker)
end

-- Makes a fake door to replace it.
function entityMeta:blastDoor(velocity, lifeTime, ignorePartner)
	if (!self:isDoor()) then
		return
	end

	if (IsValid(self.nutDummy)) then
		self.nutDummy:Remove()
	end

	velocity = velocity or VectorRand()*100
	lifeTime = lifeTime or 120

	local partner = self:getDoorPartner()

	if (IsValid(partner) and !ignorePartner) then
		partner:blastDoor(velocity, lifeTime, true)
	end

	local color = self:GetColor()

	local dummy = ents.Create("prop_physics")
	dummy:SetModel(self:GetModel())
	dummy:SetPos(self:GetPos())
	dummy:SetAngles(self:GetAngles())
	dummy:Spawn()
	dummy:SetColor(color)
	dummy:SetMaterial(self:GetMaterial())
	dummy:SetSkin(self:GetSkin() or 0)
	dummy:SetRenderMode(RENDERMODE_TRANSALPHA)
	dummy:CallOnRemove("restoreDoor", function()
		if (IsValid(self)) then
			self:SetNotSolid(false)
			self:SetNoDraw(false)
			self:DrawShadow(true)
			self.ignoreUse = false
			self.nutIsMuted = false

			for k, v in ipairs(ents.GetAll()) do
				if (v:GetParent() == self) then
					v:SetNotSolid(false)
					v:SetNoDraw(false)

					if (v.onDoorRestored) then
						v:onDoorRestored(self)
					end
				end
			end
		end
	end)
	dummy:SetOwner(self)
	dummy:SetCollisionGroup(COLLISION_GROUP_WEAPON)

	self:Fire("unlock")
	self:Fire("open")
	self:SetNotSolid(true)
	self:SetNoDraw(true)
	self:DrawShadow(false)
	self.ignoreUse = true
	self.nutDummy = dummy
	self.nutIsMuted = true
	self:DeleteOnRemove(dummy)

	for k, v in ipairs(self:GetBodyGroups()) do
		dummy:SetBodygroup(v.id, self:GetBodygroup(v.id))
	end

	for k, v in ipairs(ents.GetAll()) do
		if (v:GetParent() == self) then
			v:SetNotSolid(true)
			v:SetNoDraw(true)

			if (v.onDoorBlasted) then
				v:onDoorBlasted(self)
			end
		end
	end

	dummy:GetPhysicsObject():SetVelocity(velocity)

	local uniqueID = "doorRestore"..self:EntIndex()
	local uniqueID2 = "doorOpener"..self:EntIndex()

	timer.Create(uniqueID2, 1, 0, function()
		if (IsValid(self) and IsValid(self.nutDummy)) then
			self:Fire("open")
		else
			timer.Remove(uniqueID2)
		end
	end)

	timer.Create(uniqueID, lifeTime, 1, function()
		if (IsValid(self) and IsValid(dummy)) then
			uniqueID = "dummyFade"..dummy:EntIndex()
			local alpha = 255

			timer.Create(uniqueID, 0.1, 255, function()
				if (IsValid(dummy)) then
					alpha = alpha - 1
					dummy:SetColor(ColorAlpha(color, alpha))

					if (alpha <= 0) then
						dummy:Remove()
					end
				else
					timer.Remove(uniqueID)
				end
			end)
		end
	end)

	return dummy
end
