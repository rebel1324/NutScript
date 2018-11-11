local PANEL = {}

function PANEL:canCreateCharacter()
	local count = 0
	for k, v in pairs(nut.faction.teams) do
		if (nut.faction.hasWhitelist(v.index)) then
			count = count + 1
		end
	end
	if (count == 0) then
		return false, "You are unable to join any factions"
	end

	local maxChars = hook.Run("GetMaxPlayerCharacter", LocalPlayer())
		or nut.config.get("maxChars", 5)
	if (nut.characters and #nut.characters >= maxChars) then
		return false, "You have reached the maximum number of characters"
	end

	local canCreate, reason = hook.Run("ShouldMenuButtonShow", "create")
	if (canCreate == false) then
		return false, reason
	end

	return true
end

function PANEL:showMessage(message)
	message = L(message)
	if (message == "") then
		if (IsValid(self.message)) then self.message:Remove() end
		return
	end

	if (IsValid(self.message)) then
		self.message:SetText(message)
	end

	self.message = self:Add("DLabel")
	self.message:Dock(FILL)
	self.message:SetContentAlignment(5)
	self.message:SetFont("nutCharButtonFont")
	self.message:SetText(message)
	self.message:SetTextColor(nut.gui.character.WHITE)
end

function PANEL:Init()
	self:Dock(FILL)
	local canCreate, reason = self:canCreateCharacter()
	if (not canCreate) then
		return self:showMessage(reason)
	end
	self:showMessage("You cannot do this right now.")
end

vgui.Register("nutCharacterCreation", PANEL, "EditablePanel")
