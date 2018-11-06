local DEATH_SOUNDS = {
	Sound("vo/npc/male01/pain07.wav"),
	Sound("vo/npc/male01/pain08.wav"),
	Sound("vo/npc/male01/pain09.wav")
}

local PAIN_SOUNDS = {
	Sound("vo/npc/male01/pain01.wav"),
	Sound("vo/npc/male01/pain02.wav"),
	Sound("vo/npc/male01/pain03.wav"),
	Sound("vo/npc/male01/pain04.wav"),
	Sound("vo/npc/male01/pain05.wav"),
	Sound("vo/npc/male01/pain06.wav")
}

local DROWN_SOUNDS = {
	Sound("player/pl_drown1.wav"),
	Sound("player/pl_drown2.wav"),
	Sound("player/pl_drown3.wav"),
}

LIMB_GROUPS = LIMB_GROUPS or {}
LIMB_GROUPS[HITGROUP_LEFTARM] = true
LIMB_GROUPS[HITGROUP_RIGHTARM] = true
LIMB_GROUPS[HITGROUP_LEFTLEG] = true
LIMB_GROUPS[HITGROUP_RIGHTLEG] = true
LIMB_GROUPS[HITGROUP_GEAR] = true

function PLUGIN:ScalePlayerDamage(client, hitGroup, dmgInfo)
	dmgInfo:ScaleDamage(nut.config.get("dmgScale"))

	if (hitGroup == HITGROUP_HEAD) then
		dmgInfo:ScaleDamage(nut.config.get("dmgScaleHead"))
	elseif (LIMB_GROUPS[hitGroup]) then
		dmgInfo:ScaleDamage(nut.config.get("dmgScaleLimb"))
	end
end

function PLUGIN:PlayerDeath(client)
	local deathSound = hook.Run("GetPlayerDeathSound", client)
		or table.Random(DEATH_SOUNDS)
	if (client:isFemale() and !deathSound:find("female")) then
		deathSound = deathSound:gsub("male", "female")
	end

	client:EmitSound(deathSound)
end

function PLUGIN:GetPlayerPainSound(client)
	if (client:WaterLevel() >= 3) then
		return table.Random(DROWN_SOUNDS)
	end
end

function PLUGIN:PlayerHurt(client, attacker, health, damage)
	if ((client.nutNextPain or 0) < CurTime() and health > 0) then
		local painSound = hook.Run("GetPlayerPainSound", client)
			or table.Random(PAIN_SOUNDS)
		if (client:isFemale() and !painSound:find("female")) then
			painSound = painSound:gsub("male", "female")
		end

		client:EmitSound(painSound)
		client.nutNextPain = CurTime() + 0.33
	end
end

function PLUGIN:GetFallDamage(client, speed)
	return (speed - 580) * (100 / 444)
end
