local playerMeta = FindMetaTable("Player")

-- Returns whether or not the player has their weapon raised.
function playerMeta:isWepRaised()
	local weapon = self.GetActiveWeapon(self)
	local override = hook.Run("ShouldWeaponBeRaised", self, weapon)

	-- Allow the hook to check first.
	if (override ~= nil) then
		return override
	end

	-- Some weapons may have their own properties.
	if (IsValid(weapon)) then
		-- If their weapon is always raised, return true.
		if (
			weapon.IsAlwaysRaised or weapon.AlwaysRaised or
			ALWAYS_RAISED[weapon.GetClass(weapon)]
		) then
			return true
		-- Return false if always lowered.
		elseif (weapon.IsAlwaysLowered or weapon.NeverRaised) then
			return false
		end
	end

	-- If the player has been forced to have their weapon lowered.
	if (self.getNetVar(self, "restricted")) then
		return false
	end

	-- Let the config decide before actual results.
	if (nut.config.get("wepAlwaysRaised")) then
		return true
	end

	-- Returns what the gamemode decides.
	return self.getNetVar(self, "raised", false)
end

if (SERVER) then
	-- Sets whether or not the weapon is raised.
	function playerMeta:setWepRaised(state)
		-- Sets the networked variable for being raised.
		self:setNetVar("raised", state)

		-- Delays any weapon shooting.
		local weapon = self:GetActiveWeapon()

		if (IsValid(weapon)) then
			weapon:SetNextPrimaryFire(CurTime() + 1)
			weapon:SetNextSecondaryFire(CurTime() + 1)
		end
	end

	-- Inverts whether or not the weapon is raised.
	function playerMeta:toggleWepRaised()
		self:setWepRaised(!self:isWepRaised())

		local weapon = self:GetActiveWeapon()

		if (IsValid(weapon)) then
			if (self:isWepRaised() and weapon.OnRaised) then
				weapon:OnRaised()
			elseif (!self:isWepRaised() and weapon.OnLowered) then
				weapon:OnLowered()
			end
		end
	end
end
