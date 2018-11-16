function GM:SetupBotCharacter(client)
	local botID = os.time()
	local index = math.random(1, table.Count(nut.faction.indices))
	local faction = nut.faction.indices[index]

	local character = nut.char.new({
		name = client:Name(),
		faction = faction and faction.uniqueID or "unknown",
		model = faction and table.Random(faction.models) or "models/gman.mdl"
	}, botID, client, client:SteamID64())
	character.isBot = true
	character.vars.inv = {}

	nut.char.loaded[os.time()] = character

	character:setup()
	client:Spawn()
end

-- When the player first joins, send all important NutScript data.
function GM:PlayerInitialSpawn(client)
	client.nutJoinTime = RealTime()

	if (client:IsBot()) then
		return hook.Run("SetupBotCharacter", client)
	end

	-- Send server related data.
	nut.config.send(client)
	nut.date.send(client)

	-- Load and send the NutScript data for the player.
	client:loadNutData(function(data)
		if (!IsValid(client)) then return end

		local address = nut.util.getAddress()			
		client:setNutData("lastIP", address)

		netstream.Start(
			client,
			"nutDataSync",
			data, client.firstJoin, client.lastJoin
		)
		hook.Run("PlayerNutDataLoaded", client)
	end)

	-- Allow other things to use PlayerInitialSpawn via a hook that runs later.
	hook.Run("PostPlayerInitialSpawn", client)
end

function GM:PlayerUse(client, entity)
	if (client:getNetVar("restricted")) then
		return false
	end

	if (entity:isDoor()) then
		local result = hook.Run("CanPlayerUseDoor", client, entity)

		if (result == false) then
			return false
		else
			hook.Run("PlayerUseDoor", client, entity)
		end
	end

	return true
end

function GM:KeyPress(client, key)
	if (key == IN_USE) then
		local data = {}
			data.start = client:GetShootPos()
			data.endpos = data.start + client:GetAimVector()*96
			data.filter = client
		local entity = util.TraceLine(data).Entity

		if (IsValid(entity) and entity:isDoor() or entity:IsPlayer()) then
			hook.Run("PlayerUse", client, entity)
		end
	end
end

function GM:KeyRelease(client, key)
	if (key == IN_RELOAD) then
		timer.Remove("nutToggleRaise"..client:SteamID())
	end
end

function GM:CanPlayerInteractItem(client, action, item)
	if (client:getNetVar("restricted")) then
		return false
	end

	if (action == "drop" and hook.Run("CanPlayerDropItem", client, item) == false) then
		return false
	end

	if (action == "take" and hook.Run("CanPlayerTakeItem", client, item) == false) then
		return false
	end

	return client:Alive() and not client:getLocalVar("ragdoll")
end

function GM:CanPlayerTakeItem(client, item)
	if (type(item) == "Entity") then
		local char = client:getChar()

		if (item.nutSteamID and item.nutSteamID == client:SteamID() and item.nutCharID != char:getID()) then
			client:notifyLocalized("playerCharBelonging")

			return false
		end
	end
end

function GM:PlayerShouldTakeDamage(client, attacker)
	return client:getChar() != nil
end

function GM:GetFallDamage(client, speed)
	return (speed - 580) * (100 / 444)
end

function GM:EntityTakeDamage(entity, dmgInfo)
	if (IsValid(entity.nutPlayer)) then
		if (dmgInfo:IsDamageType(DMG_CRUSH)) then
			if ((entity.nutFallGrace or 0) < CurTime()) then
				if (dmgInfo:GetDamage() <= 10) then
					dmgInfo:SetDamage(0)
				end

				entity.nutFallGrace = CurTime() + 0.5
			else
				return
			end
		end

		entity.nutPlayer:TakeDamageInfo(dmgInfo)
	end
end

function GM:PrePlayerLoadedChar(client, character, lastChar)
	-- Remove all skins
	client:SetBodyGroups("000000000")
	client:SetSkin(0)
end

function GM:PlayerLoadedChar(client, character, lastChar)
	local timeStamp = os.date("%Y-%m-%d %H:%M:%S", os.time())
	nut.db.updateTable({_lastJoinTime = timeStamp}, nil, "characters", "_id = "..character:getID())

	if (lastChar) then
		local charEnts = lastChar:getVar("charEnts") or {}

		for k, v in ipairs(charEnts) do
			if (v and IsValid(v)) then
				v:Remove()
			end
		end

		lastChar:setVar("charEnts", nil) 
	end

	if (character) then
		for k, v in pairs(nut.class.list) do
			if (v.faction == client:Team()) then
				if (v.isDefault) then
					character:setClass(v.index)

					break
				end
			end
		end
	end

	if (IsValid(client.nutRagdoll)) then
		client.nutRagdoll.nutNoReset = true
		client.nutRagdoll.nutIgnoreDelete = true
		client.nutRagdoll:Remove()
	end

	local faction = nut.faction.indices[character:getFaction()]

	if (faction and faction.pay and faction.pay > 0) then
		timer.Create("nutSalary"..client:UniqueID(), faction.payTime or 300, 0, function()
			local pay = hook.Run("GetSalaryAmount", client, faction) or faction.pay

			character:giveMoney(pay)
			client:notifyLocalized("salary", nut.currency.get(pay))
		end)
	end


	hook.Run("PlayerLoadout", client)
end

function GM:CharacterLoaded(id)
	local character = nut.char.loaded[id]

	if (character) then
		local client = character:getPlayer()

		if (IsValid(client)) then
			local uniqueID = "nutSaveChar"..client:SteamID()

			timer.Create(uniqueID, nut.config.get("saveInterval"), 0, function()
				if (IsValid(client) and client:getChar()) then
					client:getChar():save()
				else
					timer.Remove(uniqueID)
				end
			end)
		end
	end
end

function GM:PlayerSay(client, message)
	local chatType, message, anonymous = nut.chat.parse(client, message, true)

	if (chatType == "ic") then
		if (nut.command.parse(client, message)) then
			return ""
		end
	end

	nut.chat.send(client, chatType, message, anonymous)
	nut.log.add(client, "chat", chatType and chatType:upper() or "??", message)

	hook.Run("PostPlayerSay", client, message, chatType, anonymous)

	return ""
end

function GM:PlayerSpawn(client)
	client:SetNoDraw(false)
	client:UnLock()
	client:SetNotSolid(false)
	client:setAction()

	hook.Run("PlayerLoadout", client)
end

-- Shortcuts for (super)admin only things.
local IsAdmin = function(_, client) return client:IsAdmin() end

-- Set the gamemode hooks to the appropriate shortcuts.
GM.PlayerGiveSWEP = IsAdmin
GM.PlayerSpawnEffect = IsAdmin
GM.PlayerSpawnSENT = IsAdmin

function GM:PlayerSpawnNPC(client, npcType, weapon)
	return client:IsAdmin() or client:getChar():hasFlags("n")
end

function GM:PlayerSpawnSWEP(client, weapon, info)
	return client:IsAdmin()
end

function GM:PlayerSpawnProp(client)
	if (client:getChar() and client:getChar():hasFlags("e")) then
		return true
	end

	return false
end

function GM:PlayerSpawnRagdoll(client)
	if (client:getChar() and client:getChar():hasFlags("r")) then
		return true
	end

	return false
end

function GM:PlayerSpawnVehicle(client, model, name, data)
	if (client:getChar()) then
		if (data.Category == "Chairs") then
			return client:getChar():hasFlags("c")
		else
			return client:getChar():hasFlags("C")
		end
	end
	
	return false
end

-- Called when weapons should be given to a player.
function GM:PlayerLoadout(client)
	if (client.nutSkipLoadout) then
		client.nutSkipLoadout = nil

		return
	end
	
	client:SetWeaponColor(Vector(client:GetInfo("cl_weaponcolor")))
	client:StripWeapons()
	client:setLocalVar("blur", nil)

	local character = client:getChar()

	-- Check if they have loaded a character.
	if (character) then
		client:SetupHands()
		-- Set their player model to the character's model.
		client:SetModel(character:getModel())
		client:Give("nut_hands")
		client:SetWalkSpeed(nut.config.get("walkSpeed"))
		client:SetRunSpeed(nut.config.get("runSpeed"))
		
		local faction = nut.faction.indices[client:Team()]

		if (faction) then
			-- If their faction wants to do something when the player spawns, let it.
			if (faction.onSpawn) then
				faction:onSpawn(client)
			end

			-- If the faction has default weapons, give them to the player.
			if (faction.weapons) then
				for k, v in ipairs(faction.weapons) do
					client:Give(v)
				end
			end
		end

		-- Ditto, but for classes.
		local class = nut.class.list[client:getChar():getClass()]

		if (class) then
			if (class.onSpawn) then
				class:onSpawn(client)
			end

			if (class.weapons) then
				for k, v in ipairs(class.weapons) do
					client:Give(v)
				end
			end
		end

		-- Apply any flags as needed.
		nut.flag.onSpawn(client)
		nut.attribs.setup(client)

		hook.Run("PostPlayerLoadout", client)

		client:SelectWeapon("nut_hands")
	else
		client:SetNoDraw(true)
		client:Lock()
		client:SetNotSolid(true)
	end
end

function GM:PostPlayerLoadout(client)
	-- Reload All Attrib Boosts
	local char = client:getChar()

	if (char:getInv()) then
		for k, v in pairs(char:getInv():getItems()) do
			v:call("onLoadout", client)

			if (v:getData("equip")) then
				if (v.attribBoosts) then
					for k, v in pairs(v.attribBoosts) do
						char:addBoost(v.uniqueID, k, v)
					end
				end
			end
		end
	end
end

function GM:PlayerDeath(client, inflictor, attacker)
	if (not client:getChar()) then return end
	if (IsValid(client.nutRagdoll)) then
		client.nutRagdoll.nutIgnoreDelete = true
		client.nutRagdoll:Remove()
		client:setLocalVar("blur", nil)
	end

	client:setNetVar("deathStartTime", CurTime())
	client:setNetVar("deathTime", CurTime() + nut.config.get("spawnTime", 5))
end

function GM:PlayerHurt(client, attacker, health, damage)
	nut.log.add(
		client,
		"playerHurt",
		attacker:IsPlayer() and attacker:Name() or attacker:GetClass(),
		damage,
		health
	)
end

function GM:PlayerDeathThink(client)
	if (client:getChar()) then
		local deathTime = client:getNetVar("deathTime")

		if (deathTime and deathTime <= CurTime()) then
			client:Spawn()
		end
	end

	return false
end

function GM:PlayerDisconnected(client)
	client:saveNutData()

	local character = client:getChar()

	if (character) then
		local charEnts = character:getVar("charEnts") or {}

		for k, v in ipairs(charEnts) do
			if (v and IsValid(v)) then
				v:Remove()
			end
		end

		nut.log.add(client, "playerDisconnected")

		hook.Run("OnCharDisconnect", client, character)
		character:save()
	end

	nut.char.cleanUpForPlayer(client)
end

function GM:PlayerAuthed(client, steamID, uniqueID)
	nut.log.add(client, "playerConnected", client, steamID)
end
	
function GM:InitPostEntity()
	local doors = ents.FindByClass("prop_door_rotating")

	for k, v in ipairs(doors) do
		local parent = v:GetOwner()

		if (IsValid(parent)) then
			v.nutPartner = parent
			parent.nutPartner = v
		else
			for k2, v2 in ipairs(doors) do
				if (v2:GetOwner() == v) then
					v2.nutPartner = v
					v.nutPartner = v2

					break
				end
			end
		end
	end

	timer.Simple(2, function()
		nut.entityDataLoaded = true
	end)

	hook.Run("LoadData")
	hook.Run("PostLoadData")
end

function GM:ShutDown()
	if (hook.Run("ShouldDataBeSaved") == false) then return end

	nut.shuttingDown = true
	nut.config.save()

	hook.Run("SaveData")

	for k, v in ipairs(player.GetAll()) do
		v:saveNutData()

		if (v:getChar()) then
			v:getChar():save()
		end
	end
end

function GM:GetGameDescription()
	return "NS - "..(SCHEMA and SCHEMA.name or "Unknown")
end

function GM:PlayerDeathSound()
	return true
end

function GM:InitializedSchema()
	if (!nut.data.get("date", nil, false, true)) then
		nut.data.set("date", os.time(), false, true)
	end

	nut.date.start = nut.data.get("date", os.time(), false, true)

	game.ConsoleCommand("sbox_persist ns_"..SCHEMA.folder.."\n")
end

function GM:PlayerCanHearPlayersVoice(listener, speaker)
	local allowVoice = nut.config.get("allowVoice")
	
	if (!allowVoice) then
		return false, false
	end
	
	if (listener:GetPos():DistToSqr(speaker:GetPos()) > nut.config.squaredVoiceDistance) then
		return false, false
	end
	
	return true, true
end

function GM:OnPhysgunFreeze(weapon, physObj, entity, client)
	-- Object is already frozen (!?)
	if (!physObj:IsMoveable()) then return false end
	if (entity:GetUnFreezable()) then return false end

	physObj:EnableMotion(false)

	-- With the jeep we need to pause all of its physics objects
	-- to stop it spazzing out and killing the server.
	if (entity:GetClass() == "prop_vehicle_jeep") then
		local objects = entity:GetPhysicsObjectCount()

		for i = 0, objects - 1 do
			entity:GetPhysicsObjectNum(i):EnableMotion(false)
		end
	end

	-- Add it to the player's frozen props
	client:AddFrozenPhysicsObject(entity, physObj)
	client:SendHint("PhysgunUnfreeze", 0.3)
	client:SuppressHint("PhysgunFreeze")

	return true
end

function GM:CanPlayerSuicide(client)
	return false
end

function GM:AllowPlayerPickup(client, entity)
	return false
end

function GM:PreCleanupMap()
	-- Pretend like we're shutting down so stuff gets saved properly.
	nut.shuttingDown = true
	hook.Run("SaveData")
	hook.Run("PersistenceSave")
end

function GM:PostCleanupMap()
	nut.shuttingDown = false
	hook.Run("LoadData")
	hook.Run("PostLoadData")
end

function GM:CharacterPreSave(character)
	local client = character:getPlayer()

	if (not character:getInv()) then
		return
	end
	for k, v in pairs(character:getInv():getItems()) do
		if (v.onSave) then
			v:call("onSave", client)
		end
	end
end

function GM:OnServerLog(client, logType, ...)
	for k, v in pairs(nut.util.getAdmins()) do
		if (hook.Run("CanPlayerSeeLog", v, logType) != false) then
			nut.log.send(v, nut.log.getString(client, logType, ...))
		end
	end
end

netstream.Hook("strReq", function(client, time, text)
	if (client.nutStrReqs and client.nutStrReqs[time]) then
		client.nutStrReqs[time](text)
		client.nutStrReqs[time] = nil
	end
end)

-- this table is based on mdl's prop keyvalue data. FIX IT WILLOX!
local defaultAngleData = {
	["models/items/car_battery01.mdl"] = Angle(-15, 180, 0),
	["models/props_junk/harpoon002a.mdl"] = Angle(0, 0, 0),
	["models/props_junk/propane_tank001a.mdl"] = Angle(-90, 0, 0),
}

function GM:GetPreferredCarryAngles(entity)
	if (entity.preferedAngle) then
		return entity.preferedAngle
	end

	local class = entity:GetClass()
	if (class == "nut_item") then
		local itemTable = entity:getItemTable()

		if (itemTable) then
			local preferedAngle = itemTable.preferedAngle

			if (preferedAngle) then -- I don't want to return something
				return preferedAngle
			end
		end
	elseif (class == "prop_physics") then
		local model = entity:GetModel():lower()

		return defaultAngleData[model]
	end
end

local psaString = [[
/*------------------------------------------------------------

PUBLIC SERVICE ANNOUNCEMENT FOR NUTSCRIPT SERVER OWNERS

There is a ENOURMOUS performance issue with ULX Admin mod.
Nutscript Development Team found ULX is the main issue
that make the server freeze when player count is higher 
than 20-30. The duration of freeze will be increased as you get
more players on your server.

If you're planning to open big server with ULX/ULib, Nutscript
Development Team does not recommend your plan. Server Performance
Issues with ULX/Ulib on your server will be ignored and we're 
going to consider that you're taking the risk of ULX/Ulib's 
critical performance issue.

Nutscript 1.1 only displays this message when you have ULX or
ULib on your server.

                               -Nutscript Development Team

*/------------------------------------------------------------]]
function GM:InitializedPlugins()
	if (ulx or ULib) then
		local psaTable = string.Explode("\n", psaString)

		for k, v in ipairs(psaTable) do
			MsgC(Color(255, 0, 0), v .. "\n")
		end
	end
end

--- Called when a character loads with no inventory and one should be created.
-- Here is where a new inventory instance can be created and set for a character
-- that loads with no inventory. The default implementation is to create an
-- inventory instance whose type is the result of the GetDefaultInventoryType.
-- If nothing is returned, no default inventory is created.
-- hook. The "char" data is set for the instance to the ID of the character.
-- @param character The character that loaded with no inventory
-- @return A promise that resolves to the new inventory
function GM:CreateDefaultInventory(character)
	local invType = hook.Run("GetDefaultInventoryType", character)
	local charID = character:getID()

	if (nut.inventory.types[invType]) then
		return nut.inventory.instance(invType, {char = charID})
	elseif (invType ~= nil) then
		error("Invalid default inventory type "..tostring(invType))
	end
end

function GM:NutScriptTablesLoaded()
	local oldErrorHandler = nut.db.onQueryError
	nut.db.onQueryError = function() end
	-- Add missing NS1.2 columns for nut_player table.
	nut.db.query(
		"ALTER TABLE nut_players ADD COLUMN _firstJoin DATETIME",
		function()
			nut.db.query(
				"ALTER TABLE nut_players ADD COLUMN _lastJoin DATETIME",
				function()
					nut.db.onQueryError = oldErrorHandler
				end
			)
		end
	)
end
