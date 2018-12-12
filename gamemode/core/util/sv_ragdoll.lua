local playerMeta = FindMetaTable("Player")

function nut.util.findEmptySpace(
	entity,
	filter,
	spacing,
	size,
	height,
	tolerance
)
	spacing = spacing or 32
	size = size or 3
	height = height or 36
	tolerance = tolerance or 5

	local position = entity:GetPos()
	local angles = Angle(0, 0, 0)
	local mins = Vector(-spacing * 0.5, -spacing * 0.5, 0)
	local maxs = Vector(spacing * 0.5, spacing * 0.5, height)
	local output = {}

	for x = -size, size do
		for y = -size, size do
			local origin = position + Vector(x * spacing, y * spacing, 0)
			local color = green
			local i = 0

			local data = {}
				data.start = origin + mins + Vector(0, 0, tolerance)
				data.endpos = origin + maxs
				data.filter = filter or entity
			local trace = util.TraceLine(data)

			data.start = origin + Vector(-maxs.x, -maxs.y, tolerance)
			data.endpos = origin + Vector(mins.x, mins.y, height)

			local trace2 = util.TraceLine(data)

			if (
				trace.StartSolid or
				trace.Hit or
				trace2.StartSolid or
				trace2.Hit or
				not util.IsInWorld(origin)
			) then
				continue
			end

			output[#output + 1] = origin
		end
	end

	table.sort(output, function(a, b)
		return a:Distance(position) < b:Distance(position)
	end)

	return output
end

function playerMeta:isStuck()
	return util.TraceEntity({
		start = self:GetPos(),
		endpos = self:GetPos(),
		filter = self
	}, self).StartSolid
end

function playerMeta:createRagdoll(freeze)
	local entity = ents.Create("prop_ragdoll")
	entity:SetPos(self:GetPos())
	entity:SetAngles(self:EyeAngles())
	entity:SetModel(self:GetModel())
	entity:SetSkin(self:GetSkin())
	entity:Spawn()
	entity:SetCollisionGroup(COLLISION_GROUP_WEAPON)
	entity:Activate()

	local velocity = self:GetVelocity()

	for i = 0, entity:GetPhysicsObjectCount() - 1 do
		local physObj = entity:GetPhysicsObjectNum(i)
		if (IsValid(physObj)) then
			local index = entity:TranslatePhysBoneToBone(i)
			if (index) then
				local position, angles = self:GetBonePosition(index)

				physObj:SetPos(position)
				physObj:SetAngles(angles)
			end
			if (freeze) then
				physObj:EnableMotion(false)
			else
				physObj:SetVelocity(velocity)
			end
		end
	end

	return entity
end

function playerMeta:setRagdolled(state, time, getUpGrace)
	getUpGrace = getUpGrace or time or 5

	if (state) then
		if (IsValid(self.nutRagdoll)) then
			self.nutRagdoll:Remove()
		end

		local entity = self:createRagdoll()
		entity:setNetVar("player", self)
		entity:CallOnRemove("fixer", function()
			if (IsValid(self)) then
				self:setLocalVar("blur", nil)
				self:setLocalVar("ragdoll", nil)

				if (!entity.nutNoReset) then
					self:SetPos(entity:GetPos())
				end

				self:SetNoDraw(false)
				self:SetNotSolid(false)
				self:Freeze(false)
				self:SetMoveType(MOVETYPE_WALK)
				self:SetLocalVelocity(
					IsValid(entity)
					and entity.nutLastVelocity
					or vector_origin
				)
			end

			if (IsValid(self) and !entity.nutIgnoreDelete) then
				if (entity.nutWeapons) then
					for k, v in ipairs(entity.nutWeapons) do
						self:Give(v)
						if (entity.nutAmmo) then
							for k2, v2 in ipairs(entity.nutAmmo) do
								if v == v2[1] then
									self:SetAmmo(v2[2], tostring(k2))
								end
							end
						end
					end
					for k, v in ipairs(self:GetWeapons()) do
						v:SetClip1(0)
					end
				end

				if (self:isStuck()) then
					entity:DropToFloor()
					self:SetPos(entity:GetPos() + Vector(0, 0, 16))

					local positions = nut.util.findEmptySpace(
						self,
						{entity, self}
					)
					for k, v in ipairs(positions) do
						self:SetPos(v)

						if (!self:isStuck()) then
							return
						end
					end
				end
			end
		end)

		self:setLocalVar("blur", 25)
		self.nutRagdoll = entity

		entity.nutWeapons = {}
		entity.nutAmmo = {}
		entity.nutPlayer = self

		if (getUpGrace) then
			entity.nutGrace = CurTime() + getUpGrace
		end

		if (time and time > 0) then
			entity.nutStart = CurTime()
			entity.nutFinish = entity.nutStart + time

			self:setAction(
				"@wakingUp",
				nil, nil,
				entity.nutStart, entity.nutFinish
			)
		end

		for k, v in ipairs(self:GetWeapons()) do
			entity.nutWeapons[#entity.nutWeapons + 1] = v:GetClass()
			local clip = v:Clip1()
			local reserve = self:GetAmmoCount(v:GetPrimaryAmmoType())
			local ammo = clip + reserve
			entity.nutAmmo[v:GetPrimaryAmmoType()] = {v:GetClass(), ammo}
		end

		self:GodDisable()
		self:StripWeapons()
		self:Freeze(true)
		self:SetNoDraw(true)
		self:SetNotSolid(true)
		self:SetMoveType(MOVETYPE_NONE)

		if (time) then
			local time2 = time
			local uniqueID = "nutUnRagdoll"..self:SteamID()

			timer.Create(uniqueID, 0.33, 0, function()
				if (IsValid(entity) and IsValid(self)) then
					local velocity = entity:GetVelocity()
					entity.nutLastVelocity = velocity

					self:SetPos(entity:GetPos())

					if (velocity:Length2D() >= 8) then
						if (!entity.nutPausing) then
							self:setAction()
							entity.nutPausing = true
						end

						return
					elseif (entity.nutPausing) then
						self:setAction("@wakingUp", time)
						entity.nutPausing = false
					end

					time = time - 0.33

					if (time <= 0) then
						entity:Remove()
					end
				else
					timer.Remove(uniqueID)
				end
			end)
		end

		self:setLocalVar("ragdoll", entity:EntIndex())
		hook.Run("OnCharFallover", self, entity, true)
	elseif (IsValid(self.nutRagdoll)) then
		self.nutRagdoll:Remove()

		hook.Run("OnCharFallover", self, entity, false)
	end
end
