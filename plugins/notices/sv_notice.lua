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
