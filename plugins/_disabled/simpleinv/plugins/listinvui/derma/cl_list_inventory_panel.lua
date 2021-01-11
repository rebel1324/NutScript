local PLUGIN = PLUGIN

local PANEL = {}

local PADDING = 2
local HEADER_HEIGHT = 22
local WEIGHT_PANEL_HEIGHT = 32
local BORDER_FIX_W = 8
local BORDER_FIX_H = 14

local SHADOW_COLOR = Color(0, 0, 0, 100)

function PANEL:Init()
	self:SetPaintBackground(false)

	self.weight = self:Add("DPanel")
	self.weight:SetTall(WEIGHT_PANEL_HEIGHT + PADDING)
	self.weight:Dock(TOP)
	self.weight:DockMargin(0, 0, 0, PADDING)
	self.weight:InvalidateLayout(true)

	self.weightBar = self.weight:Add("DPanel")
	self.weightBar:Dock(FILL)
	self.weightBar:DockMargin(PADDING, PADDING, PADDING, PADDING)
	self.weightBar.Paint = function(this, w, h) self:paintWeightBar(w, h) end
	
	self.weightLabel = self.weight:Add("DLabel")
	self.weightLabel:SetText("WEIGHT: 0/10KG")
	self.weightLabel:SetFont("nutChatFont")
	self.weightLabel:Dock(FILL)
	self.weightLabel:SetContentAlignment(5)
	self.weightLabel:SetExpensiveShadow(1, SHADOW_COLOR)

	self.scroll = self:Add("DScrollPanel")
	self.scroll:Dock(FILL)
	self.scroll.VBar:SetWide(0)

	self.content = self.scroll:Add("DGrid")
	self.content:Dock(FILL)
	self.content:SetCols(1)
	self.content:SetColWide(NS_ICON_SIZE + PADDING)
	self.content:SetRowHeight(NS_ICON_SIZE + PADDING)

	self.icons = {}
end

function PANEL:setInventory(inventory)
	self:nutListenForInventoryChanges(inventory)
	self.inventory = inventory
	self:populateItems()
	self:updateWeight()
end


function PANEL:setColumns(numColumns, iconSideLength)
	iconSideLength = iconSideLength or (NS_ICON_SIZE + PADDING)
	self.content:SetCols(numColumns)
	self.content:SetColWide(iconSideLength)
	self.content:SetRowHeight(iconSideLength)
	self.scroll:InvalidateLayout(true)
end

function PANEL:getIcons()
	return self.icons
end

function PANEL:removeIcon(icon)
	self.content:RemoveItem(icon)
end

function PANEL:addStack(key, stack)
	if (IsValid(self.icons[key]) or #stack == 0) then
		return
	end

	local icon = self.content:Add("nutItemIcon")
	icon:setItemType(stack[1]:getID())
	icon.PaintBehind = self.itemPaintBehind
	icon.OnMousePressed = function(itemIcon, keyCode)
		self:onItemPressed(itemIcon, keyCode)
	end

	local quantity = icon:Add("DLabel")
	quantity:SetPos(PADDING, PADDING)
	quantity:SetFont("nutChatFont")
	quantity:SetText(#stack)
	quantity:SetExpensiveShadow(1, SHADOW_COLOR)
	quantity:SizeToContents()

	self.icons[key] = icon
	self.content:AddItem(icon)

	self.scroll:InvalidateLayout()
end

function PANEL:onItemPressed(itemIcon, keyCode)
	itemIcon:openActionMenu()
end

function PANEL:populateItems()
	for _, icon in pairs(self.icons) do
		self.content:RemoveItem(icon)
	end
	local stacks = PLUGIN:getItemStacks(self.inventory)
	for key, stack in SortedPairs(stacks) do
		self:addStack(key, stack)
	end
	self.content:InvalidateLayout(true)
end

function PANEL:updateWeight()
	local inventory = self.inventory
	if (not inventory) then return end

	self.weightLabel:SetText(
		L"weight":upper()..": "..
		inventory:getWeight().."/"..inventory:getMaxWeight()..
		nut.config.get("invWeightUnit", "KG")
	)
end

function PANEL:Center()
	local parent = self:GetParent()
	local centerX, centerY = ScrW() * 0.5, ScrH() * 0.5
	
	self:SetPos(
		centerX - (self:GetWide() * 0.5),
		centerY - (self:GetTall() * 0.5)
	)
end

function PANEL:paintWeightBar(w, h)
	if (not self.inventory) then return end

	local weight = self.inventory:getWeight()
	local maxWeight = self.inventory:getMaxWeight()
	local percentage = math.Clamp(weight / maxWeight, 0, 1)
	surface.SetDrawColor(nut.config.get("color"))
	surface.DrawRect(0, 0, w * percentage, h)
end

-- self actually refers to the icon
function PANEL:itemPaintBehind(w, h)
	surface.SetDrawColor(0, 0, 0, 50)
	surface.DrawRect(0, 0, w, h)
	surface.SetDrawColor(0, 0, 0, 150)
	surface.DrawOutlinedRect(0, 0, w, h)
end

-- Called when a data value has been changed for the inventory.
function PANEL:InventoryDataChanged(key, oldValue, newValue)
	if (key == "maxWeight") then
		self:updateWeight()
	end
end

-- Called when the given item has been added to the inventory.
function PANEL:InventoryItemAdded(item)
	self:populateItems()
	self:updateWeight()
end

-- Called when the given item has been removed from the inventory.
function PANEL:InventoryItemRemoved(item)
	self:populateItems()
	self:updateWeight()
end

-- Called when an item within this inventory has its data changed.
function PANEL:InventoryItemDataChanged(item, key, oldValue, newValue)
	self:populateItems()
	self:updateWeight()
end

vgui.Register("nutListInventoryPanel", PANEL, "DPanel")
