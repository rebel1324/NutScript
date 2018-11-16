local PANEL = {}

function PANEL:Init()
	self:SetFont("nutCharButtonFont")
	self:SizeToContentsY()
	self:SetTextColor(nut.gui.character.WHITE)
	self:SetDrawBackground(false)
end

function PANEL:OnCursorEntered()
	nut.gui.character:hoverSound()
	self:SetTextColor(nut.gui.character.HOVERED)
end

function PANEL:OnCursorExited()
	self:SetTextColor(nut.gui.character.WHITE)
end

function PANEL:OnMousePressed()
	nut.gui.character:clickSound()
	DButton.OnMousePressed(self)
end

vgui.Register("nutCharButton", PANEL, "DButton")
