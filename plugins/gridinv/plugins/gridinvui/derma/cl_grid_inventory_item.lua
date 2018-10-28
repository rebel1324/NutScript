local PANEL = {}

function PANEL:Init()
	self.size = NS_ICON_SIZE
end

function PANEL:setIconSize(size)
	self.size = size
end

function PANEL:setItem(item)
	self.Icon:SetSize(
		self.size * (item.width or 1),
		self.size * (item.height or 1)
	)
	self.Icon:InvalidateLayout(true)
	self:setItemType(item:getID())
	self:centerIcon()
end

function PANEL:centerIcon(w, h)
	w = w or self:GetWide()
	h = h or self:GetTall()

	local iconW, iconH = self.Icon:GetSize()
	self.Icon:SetPos((w - iconW) * 0.5, (h - iconH) * 0.5)
end

function PANEL:PaintBehind(w, h)
	surface.SetDrawColor(0, 0, 0, 150)
	surface.DrawRect(0, 0, w, h)
	surface.DrawOutlinedRect(0, 0, w, h)
end

function PANEL:PerformLayout(w, h)
	self:centerIcon(w, h)
end

vgui.Register("nutGridInvItem", PANEL, "nutItemIcon")
