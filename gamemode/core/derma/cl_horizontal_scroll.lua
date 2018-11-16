local PANEL = {}

AccessorFunc(PANEL, "padding", "Padding")
AccessorFunc(PANEL, "canvas", "Canvas")

function PANEL:Init()
	self.canvas = self:Add("Panel")
	self.canvas.OnMousePressed = function(canvas, code)
		self:OnMousePressed(code)
	end
	self.canvas:SetMouseInputEnabled(true)
	self.canvas.PerformLayout = function(canvas)
		self:PerformLayout()
		self:InvalidateParent()
	end

	self.bar = self:Add("nutHorizontalScrollBar")
	self.bar:Dock(BOTTOM)

	self:SetPadding(0)
	self:SetMouseInputEnabled(true)
	self:SetPaintBackgroundEnabled(false)
	self:SetPaintBorderEnabled(false)
	self:SetPaintBackground(false)
end

function PANEL:AddItem(panel)
	panel:SetParent(self:GetCanvas())
end

function PANEL:OnChildAdded(child)
	self:AddItem(child)
end

function PANEL:SizeToContents()
	self:SetSize(self:GetCanvas():GetSize())
end

function PANEL:GetHBar()
	return self.bar
end

function PANEL:Rebuild()
	self:GetCanvas():SizeToChildren(true, false)
	self:CenterHorizontal()
end

function PANEL:OnMouseWheeled(delta)
	self:GetHBar():OnMouseWheeled(delta)
end

function PANEL:OnHScroll(offset)
	self:GetCanvas():SetPos(offset, 0)
end

function PANEL:ScrollToChild(child)
	self:PerformLayout()
	local x = self:GetCanvas():GetChildPosition(child)
	local w = child:GetSize()
	x = x + ((w - self:GetWide()) * 0.5)

	self:GetHBar():AnimateTo(x, 0.5, 0, 0.5)
end

function PANEL:PerformLayout()
	local canvasWide = self:GetCanvas():GetWide()
	local wide, tall = self:GetSize()
	local x = 0
	local bar = self:GetHBar()

	self:Rebuild()

	bar:SetUp(wide, canvasWide)
	x = bar:GetOffset()

	if (bar.Enabled) then
		tall = tall - bar:GetTall()
	end

	local canvas = self:GetCanvas()
	canvas:SetPos(x, 0)
	canvas:SetTall(tall)

	self:Rebuild()

	if (canvasWide ~= canvas:GetWide()) then
		bar:SetScroll(bar:GetScroll())
	end
end

function PANEL:Clear()
	self:GetCanvas():Clear()
end

vgui.Register("nutHorizontalScroll", PANEL, "DPanel")
