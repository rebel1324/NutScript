local itemWidth = ScrW()*.15

local PADDING = 12
local PADDING_HALF = PADDING * 0.5

hook.Add("TooltipInitialize", "nutItemTooltip", function(self, panel)
	if (panel.nutToolTip or panel.itemID) then
		self.markupObject = nut.markup.parse(self:GetText(), itemWidth)
		self:SetText("")
		self:SetWide(math.max(itemWidth, 200) + PADDING)
		self:SetHeight(self.markupObject:getHeight() + PADDING)
		self:SetAlpha(0)
		self:AlphaTo(255, 0.2, 0)
		self.isItemTooltip = true
	end
end)

hook.Add("TooltipPaint", "nutItemTooltip", function(self, w, h)
	if (self.isItemTooltip) then
		nut.util.drawBlur(self, 2, 2)
		surface.SetDrawColor(0, 0, 0, 230)
		surface.DrawRect(0, 0, w, h)

		if (self.markupObject) then
			self.markupObject:draw(PADDING_HALF, PADDING_HALF + 2)
		end

		return true
	end
end)

hook.Add("TooltipLayout", "nutItemTooltip", function(self)
	if (self.isItemTooltip) then
		return true
	end
end)

local tooltip_delay = 0.01

local PANEL = {}

function PANEL:Init()
	self:SetDrawOnTop(true)
	self.DeleteContentsOnClose = false
	self:SetText("")
	self:SetFont("nutToolTipText")
end

function PANEL:UpdateColours(skin)
	return self:SetTextStyleColor(color_black)
end

function PANEL:SetContents(panel, bDelete)
	panel:SetParent(self)

	self.Contents = panel
	self.DeleteContentsOnClose = bDelete or false
	self.Contents:SizeToContents()
	self:InvalidateLayout(true)

	self.Contents:SetVisible(false)
end

function PANEL:PerformLayout()
	local override = hook.Run("TooltipLayout", self)

	if (not override) then
		if (self.Contents) then
			self:SetWide(self.Contents:GetWide() + 8)
			self:SetTall(self.Contents:GetTall() + 8)
			self.Contents:SetPos(4, 4)
		else
			local w, h = self:GetContentSize()
			self:SetSize(w + 8, h + 6)
			self:SetContentAlignment(5)
		end
	end
end

function PANEL:PositionTooltip()
	if (!IsValid(self.TargetPanel)) then
		self:Remove()
		return
	end

	self:PerformLayout()

	local x, y = input.GetCursorPos()
	local w, h = self:GetSize()

	local lx, ly = self.TargetPanel:LocalToScreen(0, 0)

	y = y - 50

	y = math.min(y, ly - h * 1.5)
	if (y < 2) then y = 2 end

	-- Fixes being able to be drawn off screen
	self:SetPos(math.Clamp(x - w * 0.5, 0, ScrW() - self:GetWide()), math.Clamp(y, 0, ScrH() - self:GetTall()))
end

function PANEL:Paint( w, h )
	self:PositionTooltip()

	local override = hook.Run("TooltipPaint", self, w, h)

	if (not override) then
		derma.SkinHook("Paint", "Tooltip", self, w, h)
	end
end

function PANEL:OpenForPanel(panel)
	self.TargetPanel = panel
	self:PositionTooltip()

	hook.Run("TooltipInitialize", self, panel)

	if (tooltip_delay > 0) then
		self:SetVisible(false)

		timer.Simple(tooltip_delay, function()
			if (!IsValid(self)) then return end
			if (!IsValid(panel)) then return end

			self:PositionTooltip()
			self:SetVisible(true)
		end)
	end
end

function PANEL:Close()
	if (!self.DeleteContentsOnClose and self.Contents) then
		self.Contents:SetVisible(false)
		self.Contents:SetParent(nil)
	end

	self:Remove()
end

derma.DefineControl("DTooltip", "", PANEL, "DLabel")
