local PLUGIN = PLUGIN

local PANEL = {}

local PADDING = 2
local WEIGHT_PANEL_HEIGHT = 32
local HEADER_FIX = 22
local BORDER_FIX_H = 9 + PADDING

local SHADOW_COLOR = Color(0, 0, 0, 100)

function PANEL:Init()
	self.gridW = nut.config.get("invW", 5)
	self.gridH = nut.config.get("invH", 5)

	self:SetSize(
		self.gridW * (NS_ICON_SIZE + PADDING*2) - PADDING*2,
		self.gridH * (NS_ICON_SIZE + PADDING*2) + HEADER_FIX - PADDING
	)
	self:MakePopup()
	self:InvalidateLayout(true)

	self.content = self:Add("nutGridInventoryPanel")
	self.content:Dock(FILL)
	self.content:setGridSize(self.gridW, self.gridH)
end

function PANEL:setInventory(inventory)
	self.content:setInventory(inventory)
end

function PANEL:Center()
	local parent = self:GetParent()
	local centerX, centerY = ScrW() * 0.5, ScrH() * 0.5
	
	self:SetPos(
		centerX - (self:GetWide() * 0.5),
		centerY - (self:GetTall() * 0.5)
	)
end

vgui.Register("nutGridInventory", PANEL, "nutInventory")
