timer.Create("nutLifeGuard", 1, 0, function()
	if (not nut.config.get("drownEnabled")) then return end
	for k, v in ipairs(player.GetAll()) do
		if (not v:getChar() or not v:Alive()) then continue end
		if (hook.Run("ShouldPlayerDrown", v) == false) then continue end
		local damage = nut.config.get("drownDamage")

		if (v:WaterLevel() >= 3) then
			if (!v.drowningTime) then
				v.drowningTime = CurTime() + nut.config.get("drownTime")
				v.nextDrowning = CurTime()
				v.drownDamage = v.drownDamage or 0
			end

			if (v.drowningTime < CurTime()) then
				if (v.nextDrowning < CurTime()) then
					v:ScreenFade(1, Color(0, 0, 255, 100), 1, 0)
					v:TakeDamage(damage)
					v.drownDamage = v.drownDamage + damage
					v.nextDrowning = CurTime() + 1
				end
			end
		else
			if (v.drowningTime) then
				v.drowningTime = nil
				v.nextDrowning = nil
				v.nextRecover = CurTime() + 2
			end
			if (
				v.nextRecover and
				v.nextRecover < CurTime() and
				v.drownDamage > 0
			) then
				v.drownDamage = v.drownDamage - damage
				v:SetHealth(
					math.Clamp(v:Health() + damage, 0, v:GetMaxHealth())
				)
				v.nextRecover = CurTime() + 1
			end
		end
	end
end)
