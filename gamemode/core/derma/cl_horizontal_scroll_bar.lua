local PANEL = {}

function PANEL:Init()
	-- Aliases for sanity.
	self.btnLeft = self.btnUp
	self.btnRight = self.btnDown

	self.btnLeft.Paint = function(panel, w, h)
		derma.SkinHook("Paint", "ButtonLeft", panel, w, h)
	end
	self.btnRight.Paint = function(panel, w, h)
		derma.SkinHook("Paint", "ButtonRight", panel, w, h)
	end
end

function PANEL:SetScroll(offset)
	if (not self.Enabled) then
		self.Scroll = 0
		return
	end

	self.Scroll = math.Clamp(offset, 0, self.CanvasSize)
	self:InvalidateLayout()

	local parent = self:GetParent()
	local onHScroll = parent.OnHScroll
	if (onHScroll) then
		onHScroll(parent, self:GetOffset())
	else
		parent:InvalidateLayout()
	end
end

function PANEL:OnCursorMoved(x, y)
	if (not self.Enabled or not self.Dragging) then return end
	local x = self:ScreenToLocal(gui.MouseX(), 0)
	x = x - self.btnLeft:GetWide() - self.HoldPos

	local height = self:GetHideButtons() and 0 or self:GetTall()
	local trackSize = self:GetWide() - (height * 2) - self.btnGrip:GetWide()

	self:SetScroll(x * (self.CanvasSize / trackSize))
end

function PANEL:Grip()
	self.BaseClass.Grip(self)
	self.HoldPos = self.btnGrip:ScreenToLocal(gui.MouseX(), 0)
end

function PANEL:PerformLayout()
	local tall = self:GetTall()
	local btnHeight = self:GetHideButtons() and 0 or tall
	local scroll = self:GetScroll() / self.CanvasSize
	local barSize = math.max(
		self:BarScale() * (self:GetWide() - btnHeight * 2),
		10
	)
	local track = (self:GetWide() - (btnHeight * 2) - barSize) + 1
	scroll = scroll * track

	self.btnGrip:SetPos(btnHeight + scroll, 0)
	self.btnGrip:SetSize(barSize, tall)

	if (btnHeight > 0) then
		self.btnLeft:SetPos(0, 0)
		self.btnLeft:SetSize(btnHeight, tall)
		self.btnLeft:SetVisible(true)

		self.btnRight:SetPos(self:GetWide() - btnHeight, 0)
		self.btnRight:SetSize(btnHeight, tall)
		self.btnRight:SetVisible(true)
	else
		self.btnLeft:SetVisible(false)
		self.btnRight:SetVisible(false)
	end
end

vgui.Register("nutHorizontalScrollBar", PANEL, "DVScrollBar")
