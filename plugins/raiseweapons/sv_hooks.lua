function PLUGIN:KeyPress(client, key)
	if (key == IN_RELOAD) then
		timer.Create("nutToggleRaise"..client:SteamID(), 1, 1, function()
			if (IsValid(client)) then
				client:toggleWepRaised()
			end
		end)
	end
end

function PLUGIN:PlayerSwitchWeapon(client, oldWeapon, newWeapon)
	client:setWepRaised(false)
end
