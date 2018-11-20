PLUGIN.name = "Stamina"
PLUGIN.author = "Chessnut"
PLUGIN.desc = "Adds a stamina system to limit running."

if (SERVER) then
	function PLUGIN:PostPlayerLoadout(client)
		client:setLocalVar("stm", 100)

		local uniqueID = "nutStam"..client:SteamID()
		local offset = 0
		local runSpeed = client:GetRunSpeed() - 5

		timer.Create(uniqueID, 0.25, 0, function()
			if (not IsValid(client)) then
				timer.Remove(uniqueID)
				return
			end
			local character = client:getChar()
			if (client:GetMoveType() == MOVETYPE_NOCLIP or not character) then
				return
			end

			local bonus = character.getAttrib 
				and character:getAttrib("stm", 0)
				or 0
			runSpeed = nut.config.get("runSpeed") + bonus

			if (client:WaterLevel() > 1) then
				runSpeed = runSpeed * 0.775
			end

			if (client:IsSprinting()) then
				local bonus = character.getAttrib
					and character:getAttrib("end", 0)
					or 0
				offset = -2 + (bonus / 60)
			elseif (offset > 0.5) then
				offset = 1
			else
				offset = 1.75
			end

			if (client:Crouching()) then
				offset = offset + 1
			end

			local current = client:getLocalVar("stm", 0)
			local value = math.Clamp(current + offset, 0, 100)

			if (current != value) then
				client:setLocalVar("stm", value)

				if (value == 0 and !client:getNetVar("brth", false)) then
					client:SetRunSpeed(nut.config.get("walkSpeed"))
					client:setNetVar("brth", true)

					hook.Run("PlayerStaminaLost", client)
				elseif (value >= 50 and client:getNetVar("brth", false)) then
					client:SetRunSpeed(runSpeed)
					client:setNetVar("brth", nil)
				end
			end
		end)
	end

	local playerMeta = FindMetaTable("Player")

	function playerMeta:restoreStamina(amount)
		local current = self:getLocalVar("stm", 0)
		local value = math.Clamp(current + amount, 0, 100)

		self:setLocalVar("stm", value)
	end
elseif (nut.bar) then
	nut.bar.add(function()
		return LocalPlayer():getLocalVar("stm", 0) / 100
	end, Color(200, 200, 40), nil, "stm")
end
