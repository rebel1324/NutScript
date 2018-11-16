local PANEL = {}

function PANEL:Init()
	self:Dock(LEFT)
	self:DockMargin(0, 0, 32, 0)
	self:SetContentAlignment(4)
end

function PANEL:setText(name)
	self:SetText(L(name):upper())
	self:InvalidateLayout(true)
	self:SizeToContentsX()
end

function PANEL:onSelected(callback)
	self.callback = callback
end

function PANEL:setSelected(isSelected)
	if (isSelected == nil) then isSelected = true end
	if (isSelected and self.isSelected) then return end

	local menu = nut.gui.character
	if (isSelected and IsValid(menu)) then
		if (IsValid(menu.lastTab)) then
			menu.lastTab:SetTextColor(nut.gui.character.WHITE)
			menu.lastTab.isSelected = false
		end
		menu.lastTab = self
	end

	self:SetTextColor(
		isSelected
		and nut.gui.character.SELECTED
		or nut.gui.character.WHITE
	)
	self.isSelected = isSelected
	if (isfunction(self.callback)) then
		self:callback()
	end
end

function PANEL:Paint(w, h)
	if (self.isSelected or self:IsHovered()) then
		surface.SetDrawColor(
			self.isSelected
			and nut.gui.character.WHITE
			or nut.gui.character.HOVERED
		)
		surface.DrawRect(0, h - 4, w, 4)
	end
end

vgui.Register("nutCharacterTabButton", PANEL, "nutCharButton")
