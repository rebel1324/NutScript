local PLUGIN = PLUGIN

local PANEL = {}

local PADDING = 2
local HEADER_HEIGHT = 22
local WEIGHT_PANEL_HEIGHT = 32
local BORDER_FIX_W = 8
local BORDER_FIX_H = 14

local SHADOW_COLOR = Color(0, 0, 0, 100)

function PANEL:Init()
	self.gridW = nut.config.get("invW", 5)
	self.gridH = nut.config.get("invH", 5)

	self:SetSize(
		self.gridW * (NS_ICON_SIZE + PADDING) + BORDER_FIX_W,
		self.gridH * (NS_ICON_SIZE + PADDING) + PADDING + HEADER_HEIGHT
		+ BORDER_FIX_H
		+ WEIGHT_PANEL_HEIGHT
	)
	self:MakePopup()
	self:InvalidateLayout(true)

	self.content = self:Add("nutListInventoryPanel")
	self.content:Dock(FILL)
	self.content:setColumns(self.gridW)
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

vgui.Register("nutListInventory", PANEL, "nutInventory")
