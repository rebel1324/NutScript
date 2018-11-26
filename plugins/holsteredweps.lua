PLUGIN.name = "Holstered Weapons"
PLUGIN.author = "Black Tea"
PLUGIN.desc = "Shows holstered weapons on players."

nut.config.add(
	"showHolsteredWeps",
	true,
	"Whether or not holstered weapons show on players.",
	nil,
	{category = PLUGIN.name}
)

if (SERVER) then return end

-- To add your own holstered weapon model, add a new entry to HOLSTER_DRAWINFO
-- in *your* code (not here) where the key is the weapon class and the value
-- is a table that contains:
--   1. pos: a vector offset
--   2. ang: the angle of the model
--   3. bone: the bone to attach the model to
--   4. model: the model to show
HOLSTER_DRAWINFO = HOLSTER_DRAWINFO or {}

HOLSTER_DRAWINFO["weapon_pistol"] = {
	pos = Vector(4, -8, -1),
	ang = Angle(0, 90, 0),
	bone = "ValveBiped.Bip01_Pelvis",
	model = "models/weapons/w_pistol.mdl"
}
HOLSTER_DRAWINFO["weapon_357"] = {
	pos = Vector(-2, -8, -4),
	ang = Angle(0, -90, 0),
	bone = "ValveBiped.Bip01_Pelvis",
	model = "models/weapons/w_357.mdl"
}
HOLSTER_DRAWINFO["weapon_frag"] ={
	pos = Vector(4, 8, 0),
	ang = Angle(15, 0, 270),
	bone = "ValveBiped.Bip01_Pelvis",
	model = "models/items/grenadeammo.mdl"
}
HOLSTER_DRAWINFO["weapon_slam"] ={
	pos = Vector(4, 8, 0),
	ang = Angle(-90, 0, 180),
	bone = "ValveBiped.Bip01_Pelvis",
	model = "models/weapons/w_slam.mdl"
}
HOLSTER_DRAWINFO["weapon_crowbar"] = {
	pos = Vector(4, 8, 0),
	ang = Angle(45, 180, 0),
	bone = "ValveBiped.Bip01_Spine",
	model = "models/weapons/w_crowbar.mdl"
}
HOLSTER_DRAWINFO["weapon_ar2"] = {
	pos = Vector(4, 16, 0),
	ang = Angle(-45, 180, 0),
	bone = "ValveBiped.Bip01_Spine",
	model = "models/weapons/w_irifle.mdl"
}
HOLSTER_DRAWINFO["weapon_shotgun"] = {
	pos = Vector(4, 16, 0),
	ang = Angle(-45, 180, 0),
	bone = "ValveBiped.Bip01_Spine",
	model = "models/weapons/w_shotgun.mdl"
}
HOLSTER_DRAWINFO["weapon_rpg"] = {
	pos = Vector(4, 24, 8),
	ang = Angle(-45, 180, 0),
	bone = "ValveBiped.Bip01_Spine",
	model = "models/weapons/w_rocket_launcher.mdl"
}
HOLSTER_DRAWINFO["weapon_crossbow"] = {
	pos = Vector(0, -2, -2),
	ang = Angle(0, 0, 90),
	bone = "ValveBiped.Bip01_Spine",
	model = "models/weapons/w_crossbow.mdl"
}
HOLSTER_DRAWINFO["weapon_smg1"] = {
	pos = Vector(4, 8, 0),
	ang = Angle(135, 180, 0),
	bone = "ValveBiped.Bip01_Spine",
	model = "models/weapons/w_smg1.mdl"
}

function PLUGIN:PostPlayerDraw(client)
	if (not nut.config.get("showHolsteredWeps")) then return end
	if (not client:getChar()) then return end
	if (client == LocalPlayer() and not client:ShouldDrawLocalPlayer()) then
		return
	end

	local wep = client:GetActiveWeapon()
	local curClass = ((wep and wep:IsValid()) and wep:GetClass():lower() or "")

	client.holsteredWeapons = client.holsteredWeapons or {}

	-- Clean up old, invalid holstered weapon models.
	for k, v in pairs(client.holsteredWeapons) do
		local weapon = client:GetWeapon(k)
		if (not IsValid(weapon)) then
			v:Remove()
		end
	end

	-- Create holstered models for each weapon.
	for k, v in ipairs(client:GetWeapons()) do
		local class = v:GetClass():lower()
		local drawInfo = HOLSTER_DRAWINFO[class]
		if (not drawInfo or not drawInfo.model) then continue end

		if (not IsValid(client.holsteredWeapons[class])) then
			local model =
				ClientsideModel(drawInfo.model, RENDERGROUP_TRANSLUCENT)
			model:SetNoDraw(true)
			client.holsteredWeapons[class] = model
		end

		local drawModel = client.holsteredWeapons[class]
		local boneIndex = client:LookupBone(drawInfo.bone)

		if (not boneIndex or boneIndex < 0) then continue end
		local bonePos, boneAng = client:GetBonePosition(boneIndex)

		if (curClass ~= class and IsValid(drawModel)) then
			local right = boneAng:Right()
			local up = boneAng:Up()
			local forward = boneAng:Forward()	

			boneAng:RotateAroundAxis(right, drawInfo.ang[1])
			boneAng:RotateAroundAxis(up, drawInfo.ang[2])
			boneAng:RotateAroundAxis(forward, drawInfo.ang[3])

			bonePos = bonePos
				+ drawInfo.pos[1] * right
				+ drawInfo.pos[2] * forward
				+ drawInfo.pos[3] * up

			drawModel:SetRenderOrigin(bonePos)
			drawModel:SetRenderAngles(boneAng)
			drawModel:DrawModel()
		end
	end
end

function PLUGIN:EntityRemoved(entity)
	if (entity.holsteredWeapons) then
		for k, v in pairs(entity.holsteredWeapons) do
			v:Remove()
		end
	end
end

for k, v in ipairs(player.GetAll()) do
	for k2, v2 in ipairs(v.holsteredWeapons or {}) do
		v2:Remove()
	end
	v.holsteredWeapons = nil

end
