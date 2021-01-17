local playerMeta = FindMetaTable("Player")

-- Performs a delayed action on a player.
function playerMeta:setAction(text, time, callback, startTime, finishTime)
	if (time and time <= 0) then
		if (callback) then
			callback(self)
		end

		return
	end

	-- Default the time to five seconds.
	time = time or 5
	startTime = startTime or CurTime()
	finishTime = finishTime or (startTime + time)

	if (text == false) then
		timer.Remove("nutAct" .. self:UniqueID())
		netstream.Start(self, "actBar")

		return
	end

	-- Tell the player to draw a bar for the action.
	netstream.Start(self, "actBar", startTime, finishTime, text)

	-- If we have provided a callback, run it delayed.
	if (callback) then
		-- Create a timer that runs once with a delay.
		timer.Create("nutAct" .. self:UniqueID(), time, 1, function()
			-- Call the callback if the player is still valid.
			if (IsValid(self)) then
				callback(self)
			end
		end)
	end
end

-- Do an action that requires the player to stare at something.
function playerMeta:doStaredAction(entity, callback, time, onCancel, distance)
	local uniqueID = "nutStare" .. self:UniqueID()
	local data = {}
	data.filter = self

	timer.Create(uniqueID, 0.1, time / 0.1, function()
		if (IsValid(self) and IsValid(entity)) then
			data.start = self:GetShootPos()
			data.endpos = data.start + self:GetAimVector() * (distance or 96)

			local targetEntity = util.TraceLine(data).Entity
			if (
				IsValid(targetEntity) and
				targetEntity:GetClass() == "prop_ragdoll" and
				IsValid(targetEntity:getNetVar("player"))
			) then
				targetEntity = targetEntity:getNetVar("player")
			end
			if (targetEntity != entity) then
				timer.Remove(uniqueID)

				if (onCancel) then
					onCancel()
				end
			elseif (callback and timer.RepsLeft(uniqueID) == 0) then
				callback()
			end
		else
			timer.Remove(uniqueID)
			if (onCancel) then
				onCancel()
			end
		end
	end)
end
