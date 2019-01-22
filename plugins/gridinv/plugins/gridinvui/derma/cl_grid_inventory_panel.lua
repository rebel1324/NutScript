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

	self.occupied = {}
end

function PANEL:computeOccupied()
	if (not self.inventory) then return end

	for y = 0, self.gridH do
		self.occupied[y] = {}
		for x = 0, self.gridW do
			self.occupied[y][x] = false
		end
	end

	for _, item in pairs(self.inventory:getItems(true)) do
		local x, y = item:getData("x"), item:getData("y")
		if (not x) then continue end

		for offsetX = 0, (item.width or 1) - 1 do
			for offsetY = 0, (item.height or 1) - 1 do
				self.occupied[y + offsetY - 1][x + offsetX - 1] = true
			end
		end
	end
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
	if (hook.Run("InterceptClickItemIcon", self, itemIcon, keyCode) != true) then
		if (keyCode == MOUSE_RIGHT) then
			itemIcon:openActionMenu()
		elseif (keyCode == MOUSE_LEFT) then
			itemIcon:DragMousePress(keyCode)
			itemIcon:MouseCapture(true)
			nut.item.held = itemIcon
			nut.item.heldPanel = self
		end
	end
end

function PANEL:onItemReleased(itemIcon, keyCode)
	local item = itemIcon.itemTable
	if (not item) then return end
	local x, y = self:LocalCursorPos()
	local size = self.size + PADDING
	local itemW = (item.width or 1) * size - PADDING
	local itemH = (item.height or 1) * size - PADDING
	x = math.Round((x - (itemW * 0.5)) / size) + 1
	y = math.Round((y - (itemH * 0.5)) / size) + 1

	self.inventory:requestTransfer(item:getID(), self.inventory:getID(), x, y)
	hook.Run("OnRequestItemTransfer", self, item:getID(), self.inventory:getID(), x, y) -- mostly for sound for bag/inventory/storage etc..
end

function PANEL:populateItems()
	for key, icon in pairs(self.icons) do
		if (IsValid(icon)) then
			icon:Remove()
		end
		self.icons[key] = nil
	end
	for _, item in pairs(self.inventory:getItems(true)) do
		self:addItem(item)
	end
	self:computeOccupied()
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
	icon.OnMouseReleased = function(icon, keyCode)
		local heldPanel = nut.item.heldPanel
		if (IsValid(heldPanel)) then
			heldPanel:onItemReleased(icon, keyCode)
		end
		icon:DragMouseRelease(keyCode)
		icon:MouseCapture(false)
		nut.item.held = nil
		nut.item.heldPanel = nil
	end
	self.icons[id] = icon
end

local COLOR_OCCUPIED = Color(231, 76, 60, 25)
local COLOR_UNOCCUPIED = Color(46, 204, 113, 25)
local COLOR_COMBINE = Color(241, 196, 15, 25)

function PANEL:drawHeldItemRectangle()
	local heldItem = nut.item.held
	if (not IsValid(heldItem) or not heldItem.itemTable) then return end
	local item = heldItem.itemTable

	local size = self.size + PADDING
	local itemW = (item.width or 1) * size - PADDING
	local itemH = (item.height or 1) * size - PADDING
	local x, y = self:LocalCursorPos()
	x = math.Round((x - (itemW * 0.5)) / size)
	y = math.Round((y - (itemH * 0.5)) / size)

	local trimX, trimY
	local maxOffsetY = (item.height or 1) - 1
	local maxOffsetX = (item.width or 1) - 1
	local drawTarget = nil 
	for itemID, invItem in pairs(self.inventory.items) do
		if (item:getID() == itemID) then continue end

		local targetX, targetY = invItem:getData("x") - 1, invItem:getData("y") - 1
		local targetW, targetH = invItem.width - 1, invItem.height - 1

		if (
			x + (item.width - 1) >= targetX and x <= targetX + targetW and
			y + (item.height - 1) >= targetY and y <= targetY + targetH and 
			(invItem.onCombine or item.onCombineTo)
		) then
			drawTarget = {
				x = targetX, y = targetY, w = invItem.width, h = invItem.height
			}
			break
		end
	end

	if (drawTarget) then
		surface.SetDrawColor(
			COLOR_COMBINE
		)
		surface.DrawRect(
			drawTarget.x * size,
			drawTarget.y * size,
			drawTarget.w * size - PADDING,
			drawTarget.h * size - PADDING
		)
	else
		for offsetY = 0, maxOffsetY do
			trimY = 0
			for offsetX = 0, maxOffsetX do
				trimX = 0
				if (offsetY == maxOffsetY) then
					trimY = PADDING
				end
				if (offsetX == maxOffsetX) then
					trimX = PADDING
				end

				local realX, realY = x + offsetX, y + offsetY
				if (
					realX >= self.gridW or realY >= self.gridH
					or realX < 0 or realY < 0
				) then
					continue
				end

				surface.SetDrawColor(
					self.occupied[y + offsetY][x + offsetX]
					and COLOR_OCCUPIED
					or COLOR_UNOCCUPIED
				)
				surface.DrawRect(
					(x + offsetX) * size,
					(y + offsetY) * size,
					size - trimX,
					size - trimY
				)
			end
		end
	end
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

function PANEL:computeHeldPanel()
	if (not nut.item.held or nut.item.held == self) then return end
	local cursorX, cursorY = self:LocalCursorPos()
	if (
		cursorX < 0 or cursorY < 0 or
		cursorX > self:GetWide() or cursorY > self:GetTall()
	) then
		return
	end

	nut.item.heldPanel = self
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

	self:drawHeldItemRectangle()
	-- Hack to figure out which panel is being hovered while ignoring Z axis.
	self:computeHeldPanel()
end

function PANEL:OnCursorMoved(x, y)
end

function PANEL:OnCursorExited()
	if (nut.item.heldPanel == self) then
		nut.item.heldPanel = nil
	end
end

vgui.Register("nutGridInventoryPanel", PANEL, "DPanel")
