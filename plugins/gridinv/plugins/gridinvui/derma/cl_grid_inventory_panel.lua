local PLUGIN = PLUGIN

local PANEL = {}

local PADDING = 2
local HEADER_HEIGHT = 22
local WEIGHT_PANEL_HEIGHT = 32
local BORDER_FIX_W = 8
local BORDER_FIX_H = 14

local SHADOW_COLOR = Color(0, 0, 0, 100)

function PANEL:Init()
	self:SetDrawBackground(false)

	self.icons = {}
	self:setGridSize(1, 1)
end

function PANEL:setInventory(inventory)
	self:nutListenForInventoryChanges(inventory)
	self.inventory = inventory
	self:populateItems()
end

function PANEL:setGridSize(width, height, iconSize)
	self.size = iconSize or NS_ICON_SIZE
	self.gridW = width
	self.gridH = height
end

function PANEL:getIcons()
	return self.icons
end

function PANEL:removeIcon(icon)
	self.content:RemoveItem(icon)
end

function PANEL:onItemPressed(itemIcon, keyCode)
	if (keyCode == MOUSE_RIGHT) then
		itemIcon:openActionMenu()
	end
end

function PANEL:populateItems()
	for key, icon in pairs(self.icons) do
		if (IsValid(icon)) then
			icon:Remove()
		end
		self.icons[key] = nil
	end
	for _, item in pairs(self.inventory:getItems()) do
		self:addItem(item)
	end
end

function PANEL:addItem(item)
	local id = item:getID()
	local x, y = item:getData("x"), item:getData("y")
	if (not x or not y) then return end

	if (IsValid(self.icons[id])) then
		self.icons[id]:Remove()
	end
	local size = self.size + PADDING
	local icon = self:Add("nutGridInvItem")
	icon:setItem(item)
	icon:SetPos((x - 1) * size, (y - 1) * size)
	icon:SetSize(
		(item.width or 1) * size - PADDING,
		(item.height or 1) * size - PADDING
	)
	icon:InvalidateLayout(true)
	icon.OnMousePressed = function(icon, keyCode)
		self:onItemPressed(icon, keyCode)
	end
	self.icons[id] = icon
end

function PANEL:Center()
	local parent = self:GetParent()
	local centerX, centerY = ScrW() * 0.5, ScrH() * 0.5
	
	self:SetPos(
		centerX - (self:GetWide() * 0.5),
		centerY - (self:GetTall() * 0.5)
	)
end

-- Called when the given item has been added to the inventory.
function PANEL:InventoryItemAdded(item)
	self:populateItems()
end

-- Called when the given item has been removed from the inventory.
function PANEL:InventoryItemRemoved(item)
	self:populateItems()
end

-- Called when an item within this inventory has its data changed.
function PANEL:InventoryItemDataChanged(item, key, oldValue, newValue)
	self:populateItems()
end

function PANEL:Paint(w, h)
	surface.SetDrawColor(0, 0, 0, 100)

	local size = self.size
	for y = 0, self.gridH - 1 do
		for x = 0, self.gridW - 1 do
			surface.DrawRect(
				x * (size + PADDING),
				y * (size + PADDING),
				size,
				size
			)
		end
	end
end
vgui.Register("nutGridInventoryPanel", PANEL, "DPanel")
