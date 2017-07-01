if (SERVER) then
	-- Sends a notification to a specified recipient.
	function nut.util.notify(message, recipient)
		netstream.Start(recipient, "notify", message)
	end

	-- Sends a translated notification.
	function nut.util.notifyLocalized(message, recipient, ...)
		netstream.Start(recipient, "notifyL", message, ...)
	end

	do
		local playerMeta = FindMetaTable("Player")

		-- Utility function to notify a player.
		function playerMeta:notify(message)
			nut.util.notify(message, self)
		end

		-- Utility function to notify a localized message to a player.
		function playerMeta:notifyLocalized(message, ...)
			nut.util.notifyLocalized(message, self, ...)
		end
	end
else
	-- List of notice panels.
	nut.notices = nut.notices or {}

	-- Create a notification panel.
	function nut.util.notify(message)

		local t = nut.config.get("Notifications", 1)

		if (t == 0) then

			local notice = vgui.Create("nutNotice")

			local i = table.insert(nut.notices, notice)
			local scrW = ScrW()

			-- Set up information for the notice.
			notice:SetText(message)
			notice:SetPos(ScrW(), (i - 1) * (notice:GetTall() + 4) + 4)
			notice:SizeToContentsX()
			notice:SetWide(notice:GetWide() + 16)
			notice.start = CurTime() + 0.25
			notice.endTime = CurTime() + 7.75

			-- Move all notices to their proper positions.
			local function OrganizeNotices()
				for k, v in ipairs(nut.notices) do
					v:MoveTo(scrW - (v:GetWide() + 4), (k - 1) * (v:GetTall() + 4) + 4, 0.15, (k / #nut.notices) * 0.25, nil)
				end
			end

			-- Add the notice we made to the list.
			OrganizeNotices()

			-- Show the notification in the console.
			MsgC(Color(0, 255, 255), message.."\n")

			-- Once the notice appears, make a sound and message.
			timer.Simple(0.15, function()
				surface.PlaySound("buttons/button14.wav")
			end)

			-- After the notice has displayed for 7.5 seconds, remove it.
			timer.Simple(7.75, function()
				if (IsValid(notice)) then
					-- Search for the notice to remove.
					for k, v in ipairs(nut.notices) do
						if (v == notice) then
							-- Move the notice off the screen.
							notice:MoveTo(ScrW(), notice.y, 0.15, 0.1, nil, function()
								notice:Remove()
							end)

							-- Remove the notice from the list and move other notices.
							table.remove(nut.notices, k)
							OrganizeNotices()

							break
						end
					end
				end
			end)
		elseif(t == 1) then

			local notice = vgui.Create("nut_Notification")
			--local i = table.insert(nut.notices, notice)
			local scrW = ScrW()

			table.insert(nut.notices, notice)

			notice:SetText(message)
			notice:SetAlpha(0)
			notice:SetPos(ScrW() * 0.3, -24)
			notice:SetWide(ScrW() * 0.4)
			notice:MoveTo(ScrW() * 0.3, ScrH() - ((#nut.notices + 1) * 28), 0.35, 0, 0.25)
			notice:AlphaTo(255, 0.2, 0)
			notice.endTime = CurTime() + 7.75

			notice:CallOnRemove(function()
			for k, v in pairs(nut.notices) do
				if (v == notice) then
					table.remove(nut.notices, k)
				end
			end

			for k, v in pairs(nut.notices) do
				v:MoveTo(ScrW() * 0.3, ScrH() - (k * 28), 0.35, 0, 0.25)
			end

			hook.Run("NoticeRemoved", notice)
		end)

			MsgC(Color(92, 232, 250), message.."\n")

			hook.Run("NoticeCreated", notice)
		else

			return false
		end
	end

	-- Creates a translated notification.
	function nut.util.notifyLocalized(message, ...)
		nut.util.notify(L(message, ...))
	end

	-- Receives a notification from the server.
	netstream.Hook("notify", nut.util.notify)

	-- Receives a notification from the server.
	netstream.Hook("notifyL", nut.util.notifyLocalized)
end
