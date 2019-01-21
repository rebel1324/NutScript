function GM:PlayerNoClip(client)
	return client:IsAdmin()
end

HOLDTYPE_TRANSLATOR = HOLDTYPE_TRANSLATOR or {}
HOLDTYPE_TRANSLATOR[""] = "normal"
HOLDTYPE_TRANSLATOR["physgun"] = "smg"
HOLDTYPE_TRANSLATOR["ar2"] = "smg"
HOLDTYPE_TRANSLATOR["crossbow"] = "shotgun"
HOLDTYPE_TRANSLATOR["rpg"] = "shotgun"
HOLDTYPE_TRANSLATOR["slam"] = "normal"
HOLDTYPE_TRANSLATOR["grenade"] = "grenade"
HOLDTYPE_TRANSLATOR["melee2"] = "melee"
HOLDTYPE_TRANSLATOR["passive"] = "smg"
HOLDTYPE_TRANSLATOR["knife"] = "melee"
HOLDTYPE_TRANSLATOR["duel"] = "pistol"
HOLDTYPE_TRANSLATOR["camera"] = "smg"
HOLDTYPE_TRANSLATOR["magic"] = "normal"
HOLDTYPE_TRANSLATOR["revolver"] = "pistol"

PLAYER_HOLDTYPE_TRANSLATOR = PLAYER_HOLDTYPE_TRANSLATOR or {}
PLAYER_HOLDTYPE_TRANSLATOR[""] = "normal"
PLAYER_HOLDTYPE_TRANSLATOR["normal"] = "normal"
PLAYER_HOLDTYPE_TRANSLATOR["revolver"] = "normal"
PLAYER_HOLDTYPE_TRANSLATOR["fist"] = "normal"
PLAYER_HOLDTYPE_TRANSLATOR["pistol"] = "normal"
PLAYER_HOLDTYPE_TRANSLATOR["grenade"] = "normal"
PLAYER_HOLDTYPE_TRANSLATOR["melee"] = "normal"
PLAYER_HOLDTYPE_TRANSLATOR["slam"] = "normal"
PLAYER_HOLDTYPE_TRANSLATOR["melee2"] = "normal"
PLAYER_HOLDTYPE_TRANSLATOR["knife"] = "normal"
PLAYER_HOLDTYPE_TRANSLATOR["duel"] = "normal"
PLAYER_HOLDTYPE_TRANSLATOR["bugbait"] = "normal"

local getModelClass = nut.anim.getModelClass
local IsValid = IsValid
local string = string
local type = type

local PLAYER_HOLDTYPE_TRANSLATOR = PLAYER_HOLDTYPE_TRANSLATOR
local HOLDTYPE_TRANSLATOR = HOLDTYPE_TRANSLATOR

function GM:TranslateActivity(client, act)
	local model = string.lower(client.GetModel(client))
	local class = getModelClass(model) or "player"
	local weapon = client.GetActiveWeapon(client)
	if (class == "player") then
		if (
			not nut.config.get("wepAlwaysRaised") and
			IsValid(weapon) and
			(client.isWepRaised and not client.isWepRaised(client)) and
			client:OnGround()
		) then
			if (string.find(model, "zombie")) then
				local tree = nut.anim.zombie

				if (string.find(model, "fast")) then
					tree = nut.anim.fastZombie
				end

				if (tree[act]) then
					return tree[act]
				end
			end

			local holdType = IsValid(weapon)
				and (weapon.HoldType or weapon.GetHoldType(weapon))
				or "normal"
			holdType = PLAYER_HOLDTYPE_TRANSLATOR[holdType] or "passive"

			local tree = nut.anim.player[holdType]

			if (tree and tree[act]) then
				if (type(tree[act]) == "string") then
					client.CalcSeqOverride = client.LookupSequence(tree[act])
					return
				else
					return tree[act]
				end
			end
		end

		return self.BaseClass.TranslateActivity(self.BaseClass, client, act)
	end

	local tree = nut.anim[class]

	if (tree) then
		local subClass = "normal"

		if (client.InVehicle(client)) then
			local vehicle = client.GetVehicle(client)
			local class = vehicle:isChair() and "chair" or vehicle:GetClass()

			if (tree.vehicle and tree.vehicle[class]) then
				local act = tree.vehicle[class][1]
				local fixvec = tree.vehicle[class][2]

				if (fixvec) then
					client:SetLocalPos(Vector(16.5438, -0.1642, -20.5493))
				end

				if (type(act) == "string") then
					client.CalcSeqOverride = client.LookupSequence(client, act)

					return
				else
					return act
				end
			else
				act = tree.normal[ACT_MP_CROUCH_IDLE][1]

				if (type(act) == "string") then
					client.CalcSeqOverride = client:LookupSequence(act)
				end

				return
			end
		elseif (client.OnGround(client)) then
			client.ManipulateBonePosition(client, 0, vector_origin)

			if (IsValid(weapon)) then
				subClass = weapon.HoldType or weapon.GetHoldType(weapon)
				subClass = HOLDTYPE_TRANSLATOR[subClass] or subClass
			end

			if (tree[subClass] and tree[subClass][act]) then
				local index = (not client.isWepRaised or client:isWepRaised())
					and 2
					or 1
				local act2 = tree[subClass][act][index]

				if (type(act2) == "string") then
					client.CalcSeqOverride = client.LookupSequence(client, act2)

					return
				end

				return act2
			end
		elseif (tree.glide) then
			return tree.glide
		end
	end
end

function GM:DoAnimationEvent(client, event, data)
	local class = nut.anim.getModelClass(client:GetModel())

	if (class == "player") then
		return self.BaseClass:DoAnimationEvent(client, event, data)
	else
		local weapon = client:GetActiveWeapon()

		if (IsValid(weapon)) then
			local holdType = weapon.HoldType or weapon:GetHoldType()
			holdType = HOLDTYPE_TRANSLATOR[holdType] or holdType

			local animation = nut.anim[class][holdType]

			if (event == PLAYERANIMEVENT_ATTACK_PRIMARY) then
				client:AnimRestartGesture(GESTURE_SLOT_ATTACK_AND_RELOAD, animation.attack or ACT_GESTURE_RANGE_ATTACK_SMG1, true)

				return ACT_VM_PRIMARYATTACK
			elseif (event == PLAYERANIMEVENT_ATTACK_SECONDARY) then
				client:AnimRestartGesture(GESTURE_SLOT_ATTACK_AND_RELOAD, animation.attack or ACT_GESTURE_RANGE_ATTACK_SMG1, true)

				return ACT_VM_SECONDARYATTACK
			elseif (event == PLAYERANIMEVENT_RELOAD) then
				client:AnimRestartGesture(GESTURE_SLOT_ATTACK_AND_RELOAD, animation.reload or ACT_GESTURE_RELOAD_SMG1, true)

				return ACT_INVALID
			elseif (event == PLAYERANIMEVENT_JUMP) then
				client.m_bJumping = true
				client.m_bFistJumpFrame = true
				client.m_flJumpStartTime = CurTime()

				client:AnimRestartMainSequence()

				return ACT_INVALID
			elseif (event == PLAYERANIMEVENT_CANCEL_RELOAD) then
				client:AnimResetGestureSlot(GESTURE_SLOT_ATTACK_AND_RELOAD)

				return ACT_INVALID
			end
		end
	end

	return ACT_INVALID
end

function GM:EntityEmitSound(data)
	if (data.Entity.nutIsMuted) then
		return false
	end
end

local vectorAngle = FindMetaTable("Vector").Angle
local normalizeAngle = math.NormalizeAngle
local oldCalcSeqOverride

function GM:HandlePlayerLanding(client, velocity, wasOnGround)
	if (client:GetMoveType() == MOVETYPE_NOCLIP) then return end

	if (client:IsOnGround() and not wasOnGround) then
		local length = (client.lastVelocity or velocity):LengthSqr()
		local animClass = nut.anim.getModelClass(client:GetModel())
		if (animClass ~= "player" and length < 100000) then return end

		client:AnimRestartGesture(GESTURE_SLOT_JUMP, ACT_LAND, true)
		return true
	end
end

function GM:CalcMainActivity(client, velocity)
	client.CalcIdeal = ACT_MP_STAND_IDLE
	
	oldCalcSeqOverride = client.CalcSeqOverride
	client.CalcSeqOverride = -1

	local animClass = nut.anim.getModelClass(client:GetModel())

	if (animClass ~= "player") then
		local eyeAngles = client.EyeAngles(client)
		local yaw = vectorAngle(velocity)[2]
		local normalized = normalizeAngle(yaw - eyeAngles[2])

		client.SetPoseParameter(client, "move_yaw", normalized)
	end

	if (
		self:HandlePlayerLanding(client, velocity, client.m_bWasOnGround) or
		self:HandlePlayerNoClipping(client, velocity) or
		self:HandlePlayerDriving(client) or
		self:HandlePlayerVaulting(client, velocity) or
		(usingPlayerAnims and self:HandlePlayerJumping(client, velocity)) or
		self:HandlePlayerSwimming(client, velocity) or
		self:HandlePlayerDucking(client, velocity)
	) then
	else
		local len2D = velocity:Length2DSqr()
		if (len2D > 22500) then
			client.CalcIdeal = ACT_MP_RUN
		elseif (len2D > 0.25) then
			client.CalcIdeal = ACT_MP_WALK
		end
	end

	client.m_bWasOnGround = client:IsOnGround()
	client.m_bWasNoclipping = client:GetMoveType() == MOVETYPE_NOCLIP
		and not client:InVehicle()
	client.lastVelocity = velocity

	if (CLIENT) then
		client:SetIK(false)
	end

	return client.CalcIdeal, client.nutForceSeq or oldCalcSeqOverride
end

function GM:OnCharVarChanged(char, varName, oldVar, newVar)
	if (nut.char.varHooks[varName]) then
		for k, v in pairs(nut.char.varHooks[varName]) do
			v(char, oldVar, newVar)
		end
	end
end

function GM:GetDefaultCharName(client, faction)
	local info = nut.faction.indices[faction]

	if (info and info.onGetDefaultName) then
		return info:onGetDefaultName(client)
	end
end

function GM:CanPlayerUseChar(client, char)
	local banned = char:getData("banned")

	if (banned) then
		if (type(banned) == "number" and banned < os.time()) then
			return
		end

		return false, "@charBanned"
	end

	local faction = nut.faction.indices[char:getFaction()]
	if (
		faction and
		hook.Run("CheckFactionLimitReached", faction, char, client)
	) then
		return false, "@limitFaction"
	end
end

-- Whether or not more players are not allowed to load a character of
-- a specific faction since the faction is full.
function GM:CheckFactionLimitReached(faction, character, client)
	if (isfunction(faction.onCheckLimitReached)) then
		return faction:onCheckLimitReached(character, client)
	end

	if (not isnumber(faction.limit)) then return false end

	-- By default, the limit is the number of players allowed in that faction.
	local maxPlayers = faction.limit
	
	-- If some number less than 1, treat it as a percentage of the player count.
	if (faction.limit < 1) then
		maxPlayers = math.Round(#player.GetAll() * faction.limit)
	end

	return team.NumPlayers(faction.index) >= maxPlayers
end

function GM:CanProperty(client, property, entity)
	if (client:IsAdmin()) then
		return true
	end

	if (CLIENT and (property == "remover" or property == "collision")) then
		return true
	end

	return false
end

function GM:PhysgunPickup(client, entity)
	if (client:IsSuperAdmin()) then
		return true
	end
	
	if (client:IsAdmin() and !(entity:IsPlayer() and entity:IsSuperAdmin())) then
		return true
	end

	if (self.BaseClass:PhysgunPickup(client, entity) == false) then
		return false
	end

	return false
end

local TOOL_SAFE = {}
TOOL_SAFE["lamp"] = true
TOOL_SAFE["camera"] = true

local TOOL_DANGEROUS = {}
TOOL_DANGEROUS["dynamite"] = true

function GM:CanTool(client, trace, tool)
	if (client:IsAdmin()) then
		return true
	end

	if (TOOL_DANGEROUS[tool]) then
		return false
	end
	
	local entity = trace.Entity

	if (IsValid(entity)) then
		if (TOOL_SAFE[tool]) then
			return true
		end
	else
		return true
	end

	return false
end

function GM:Move(client, moveData)
	local char = client:getChar()

	if (char) then
		if (client:getNetVar("actAng")) then
			moveData:SetForwardSpeed(0)
			moveData:SetSideSpeed(0)
		end

		if (client:GetMoveType() == MOVETYPE_WALK and moveData:KeyDown(IN_WALK)) then
			local mf, ms = 0, 0
			local speed = client:GetWalkSpeed()
			local ratio = nut.config.get("walkRatio")

			if (moveData:KeyDown(IN_FORWARD)) then
				mf = ratio
			elseif (moveData:KeyDown(IN_BACK)) then
				mf = -ratio
			end

			if (moveData:KeyDown(IN_MOVELEFT)) then
				ms = -ratio
			elseif (moveData:KeyDown(IN_MOVERIGHT)) then
				ms = ratio
			end

			moveData:SetForwardSpeed(mf * speed) 
			moveData:SetSideSpeed(ms * speed) 
		end
	end
end

function GM:CanItemBeTransfered(itemObject, curInv, inventory)
	if (itemObject.onCanBeTransfered) then
		local itemHook = itemObject:onCanBeTransfered(curInv, inventory)
		
		return (itemHook != false)
	end
end
