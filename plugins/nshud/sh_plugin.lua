PLUGIN.name = "NS HUD"
PLUGIN.author = "Cheesenut"
PLUGIN.desc = "The default NutScript HUD."

if (SERVER) then return end

local hidden = {}
hidden["CHudHealth"] = true
hidden["CHudBattery"] = true
hidden["CHudAmmo"] = true
hidden["CHudSecondaryAmmo"] = true
hidden["CHudHistoryResource"] = true

local nextUpdate = 0
local lastTrace = {}
local lastEntity
local mathApproach = math.Approach
local surface = surface
local hookRun = hook.Run
local toScreen = FindMetaTable("Vector").ToScreen

function PLUGIN:CanDrawAmmoHUD(weapon)
	return IsValid(weapon) and weapon.DrawAmmo ~= false
end

function PLUGIN:DrawAmmoHUD(weapon)
	local localPlayer = LocalPlayer()
	local clip = weapon:Clip1()
	local count = localPlayer:GetAmmoCount(weapon:GetPrimaryAmmoType())
	local secondary = localPlayer:GetAmmoCount(weapon:GetSecondaryAmmoType())
	local x, y = ScrW() - 80, ScrH() - 80

	if (secondary > 0) then
		nut.util.drawBlurAt(x, y, 64, 64)

		surface.SetDrawColor(255, 255, 255, 5)
		surface.DrawRect(x, y, 64, 64)
		surface.SetDrawColor(255, 255, 255, 3)
		surface.DrawOutlinedRect(x, y, 64, 64)

		nut.util.drawText(secondary, x + 32, y + 32, nil, 1, 1, "nutBigFont")
	end

	if (weapon.GetClass(weapon) ~= "weapon_slam" and clip > 0 or count > 0) then
		x = x - (secondary > 0 and 144 or 64)

		nut.util.drawBlurAt(x, y, 128, 64)

		surface.SetDrawColor(255, 255, 255, 5)
		surface.DrawRect(x, y, 128, 64)
		surface.SetDrawColor(255, 255, 255, 3)
		surface.DrawOutlinedRect(x, y, 128, 64)

		nut.util.drawText(
			clip == -1 and count or clip.."/"..count,
			x + 64,
			y + 32,
			nil,
			1, 1,
			"nutBigFont"
		)
	end
end

local injTextTable = {
	[.3] = {"injMajor", Color(192, 57, 43)},
	[.6] = {"injLittle", Color(231, 76, 60)},
}

function PLUGIN:GetInjuredText(client)
	local health = client:Health()

	for k, v in pairs(injTextTable) do
		if ((health / LocalPlayer():GetMaxHealth()) < k) then
			return v[1], v[2]
		end
	end
end

local colorAlpha = ColorAlpha
local teamGetColor = team.GetColor
local drawText = nut.util.drawText

function PLUGIN:DrawCharInfo(client, character, info)
	local injText, injColor = hookRun("GetInjuredText", client)

	if (injText) then
		info[#info + 1] = {L(injText), injColor}
	end
end

local charInfo = {}

local OFFSET_NORMAL = Vector(0, 0, 80)
local OFFSET_CROUCHING = Vector(0, 0, 48)

paintedEntitiesCache = {}

function PLUGIN:DrawEntityInfo(entity, alpha, position)
	if (not entity.IsPlayer(entity)) then return end
	if (hookRun("ShouldDrawPlayerInfo", entity) == false) then return end

	local localPlayer = LocalPlayer()
	local character = entity.getChar(entity)
	if (not character) then return end

	position = position or toScreen(entity.GetPos(entity)
		+ (entity.Crouching(entity) and OFFSET_CROUCHING or OFFSET_NORMAL))

	local x, y = position.x, position.y
	local ty = 0

	charInfo = {}
	charInfo[1] = {
		hookRun("GetDisplayedName", entity) or character.getName(character),
		teamGetColor(entity.Team(entity))
	}

	local description = character.getDesc(character)
	if (description ~= entity.nutDescCache) then
		entity.nutDescCache = description

		if (description:len() > 250) then
			description = description:sub(1, 250).."..."
		end

		entity.nutDescLines = nut.util.wrapText(
			description,
			ScrW() * 0.5,
			"nutSmallFont"
		)
	end

	for i = 1, #entity.nutDescLines do
		charInfo[#charInfo + 1] = {entity.nutDescLines[i]}
	end

	hookRun("DrawCharInfo", entity, character, charInfo)

	for i = 1, #charInfo do
		local info = charInfo[i]

		_, ty = drawText(
			info[1]:gsub("#", "\226\128\139#"),
			x, y,
			colorAlpha(info[2] or color_white, alpha),
			1, 1,
			"nutSmallFont"
		)
		y = y + ty
	end
end

function PLUGIN:ShouldDrawEntityInfo(entity)
	if (entity.DrawEntityInfo) then
		return true
	end
	if (entity.onShouldDrawEntityInfo) then
		return entity:onShouldDrawEntityInfo()
	end
	if (entity:IsPlayer() and entity:getChar() and entity:GetNoDraw() != true) then
		return true
	end
end

function PLUGIN:HUDPaintBackground()
	local localPlayer = LocalPlayer()

	if (!localPlayer.getChar(localPlayer)) then
		return
	end

	local realTime = RealTime()
	local frameTime = FrameTime()
	local scrW, scrH = ScrW(), ScrH()

	if (nextUpdate < realTime) then
		nextUpdate = realTime + 0.5

		lastTrace.start = localPlayer.GetShootPos(localPlayer)
		lastTrace.endpos = lastTrace.start + localPlayer:GetAimVector() * 160
		lastTrace.filter = localPlayer
		lastTrace.mins = Vector(-4, -4, -4)
		lastTrace.maxs = Vector(4, 4, 4)
		lastTrace.mask = MASK_SHOT_HULL
		lastEntity = util.TraceHull(lastTrace).Entity

		if (
			IsValid(lastEntity) and
			hookRun("ShouldDrawEntityInfo", lastEntity)
	 	) then
			paintedEntitiesCache[lastEntity] = true
		end
	end

	for entity, drawing in pairs(paintedEntitiesCache) do
		if (IsValid(entity)) then
			local goal = drawing and 255 or 0
			local alpha = mathApproach(
				entity.nutAlpha or 0,
				goal,
				frameTime * 1000
			)

			if (lastEntity != entity) then
				paintedEntitiesCache[entity] = false
			end

			if (alpha > 0) then
				local client = entity.getNetVar(entity, "player")

				if (IsValid(client)) then
					local position = toScreen(
						entity.LocalToWorld(entity, entity.OBBCenter(entity))
					)
					hookRun("DrawEntityInfo", client, alpha, position)
				elseif (entity.onDrawEntityInfo) then
					entity.onDrawEntityInfo(entity, alpha)
				else
					hookRun("DrawEntityInfo", entity, alpha)
				end
			end

			entity.nutAlpha = alpha

			if (alpha == 0 and goal == 0) then
				paintedEntitiesCache[entity] = nil
			end
		else
			paintedEntitiesCache[entity] = nil
		end
	end

	local weapon = localPlayer:GetActiveWeapon()
	if (hook.Run("CanDrawAmmoHUD", weapon) ~= false) then
		hook.Run("DrawAmmoHUD", weapon)
	end
	
	if (
		localPlayer.getLocalVar(localPlayer, "restricted") and
		not localPlayer.getLocalVar(localPlayer, "restrictNoMsg")
	) then
		nut.util.drawText(
			L"restricted", scrW * 0.5, scrH * 0.33, nil, 1, 1, "nutBigFont"
		)
	end
end

function PLUGIN:HUDShouldDraw(element)
	if (hidden[element]) then
		return false
	end
end

function PLUGIN:DrawDeathNotice()
	return false
end

function PLUGIN:HUDAmmoPickedUp()
	return false
end

function PLUGIN:HUDDrawPickupHistory()
	return false
end

function PLUGIN:HUDDrawTargetID()
	return false
end
