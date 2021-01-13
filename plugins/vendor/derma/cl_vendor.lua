local PANEL = {}

local PADDING = 64
local PADDING_HALF = PADDING / 2

function PANEL:Init()
	if (IsValid(nut.gui.vendor)) then
		nut.gui.vendor.noSendExit = true
		nut.gui.vendor:Remove()
	end
	nut.gui.vendor = self

	self:SetSize(ScrW(), ScrH())
	self:MakePopup()
	self:SetAlpha(0)
	self:AlphaTo(255, 0.2, 0)

	self.buttons = self:Add("DPanel")
	self.buttons:DockMargin(0, 32, 0, 0)
	self.buttons:Dock(TOP)
	self.buttons:SetPaintBackground(false)
	self.buttons:SetTall(36)

	self.leave = self.buttons:Add("DButton")
	self.leave:SetFont("nutVendorButtonFont")
	self.leave:SetText(L("leave"):upper())
	self.leave:SetTextColor(color_white)
	self.leave:SetContentAlignment(9)
	self.leave:SetExpensiveShadow(2, color_black)
	self.leave.DoClick = function(button)
		self:Remove()
	end
	self.leave:SizeToContents()
	self.leave:SetPaintBackground(false)
	self.leave.x = ScrW() * 0.5 - (self.leave:GetWide() * 0.5)

	if (LocalPlayer():IsAdmin()) then
		self.editor = self.buttons:Add("DButton")
		self.editor:SetFont("nutVendorButtonFont")
		self.editor:SetText(L("editor"):upper())
		self.editor:SetTextColor(color_white)
		self.editor:SetContentAlignment(9)
		self.editor:SetExpensiveShadow(2, color_black)
		self.editor.DoClick = function(button)
			vgui.Create("nutVendorEditor"):SetZPos(99)
		end
		self.editor:SizeToContents()
		self.editor:SetPaintBackground(false)
		self.leave.x = self.leave.x + 16 + self.leave:GetWide() * 0.5
		self.editor.x = ScrW() * 0.5 - 16 - self.editor:GetWide()
	end

	self.vendor = self:Add("nutVendorTrader")
	self.vendor:SetWide(math.max(ScrW() * 0.25, 220))
	self.vendor:SetPos(
		ScrW() * 0.5 - self.vendor:GetWide() - PADDING_HALF,
		PADDING + self.leave:GetTall()
	)
	self.vendor:SetTall(ScrH() - self.vendor.y - PADDING)
	self.vendor:setName(nutVendorEnt:getNetVar("name"))
	self.vendor:setMoney(nutVendorEnt:getMoney())

	self.me = self:Add("nutVendorTrader")
	self.me:SetSize(self.vendor:GetSize())
	self.me:SetPos(ScrW() * 0.5 + PADDING_HALF, self.vendor.y)
	self.me:setName(L"you")
	self.me:setMoney(LocalPlayer():getChar():getMoney())

	self:listenForChanges()
	self:nutListenForInventoryChanges(LocalPlayer():getChar():getInv())

	self.items = {
		[self.vendor] = {},
		[self.me] = {}
	}

	self:initializeItems()
end

function PANEL:buyItemFromVendor(itemType)
	net.Start("nutVendorTrade")
		net.WriteString(itemType)
		net.WriteBool(false)
	net.SendToServer()
end

function PANEL:sellItemToVendor(itemType)
	net.Start("nutVendorTrade")
		net.WriteString(itemType)
		net.WriteBool(true)
	net.SendToServer()
end

function PANEL:initializeItems()
	for itemType in SortedPairs(nutVendorEnt.items) do
		local mode = nutVendorEnt:getTradeMode(itemType)
		if (not mode) then continue end

		if (mode ~= VENDOR_SELLONLY) then
			self:updateItem(itemType, self.me):setIsSelling(true)
		end

		if (mode ~= VENDOR_BUYONLY) then
			self:updateItem(itemType, self.vendor)
		end
	end
end

function PANEL:shouldItemBeVisible(itemType, parent)
	local mode = nutVendorEnt:getTradeMode(itemType)

	if (parent == self.me and mode == VENDOR_SELLONLY) then
		return false
	end

	if (parent == self.vendor and mode == VENDOR_BUYONLY) then
		return false
	end

	return mode ~= nil
end

function PANEL:updateItem(itemType, parent, quantity)
	assert(isstring(itemType), "itemType must be a string")

	if (not self.items[parent]) then return end
	local panel = self.items[parent][itemType]

	if (not self:shouldItemBeVisible(itemType, parent)) then
		if (IsValid(panel)) then
			panel:Remove()
		end
		return
	end
	
	if (not IsValid(panel)) then
		panel = parent.items:Add("nutVendorItem")
		panel:setItemType(itemType)
		panel:setIsSelling(parent == self.me)
		self.items[parent][itemType] = panel
	end

	if (not isnumber(quantity)) then
		quantity = parent == self.me
			and LocalPlayer():getChar():getInv():getItemCount(itemType)
			or  nutVendorEnt:getStock(itemType)
	end

	panel:setQuantity(quantity)

	return panel
end

function PANEL:onVendorPropEdited(vendor, key)
	if (key == "name") then
		self.vendor:setName(vendor:getName())
	elseif (key == "scale") then
		for _, panel in pairs(self.items[self.vendor]) do
			if (not IsValid(panel)) then continue end
			panel:updatePrice()
		end
		for _, panel in pairs(self.items[self.me]) do
			if (not IsValid(panel)) then continue end
			panel:updatePrice()
		end
	end
end

function PANEL:onVendorMoneyUpdated(vendor, money)
	self.vendor:setMoney(money)
end

function PANEL:onVendorPriceUpdated(vendor, itemType, value)
	local panel = self.items[self.vendor][itemType]
	if (IsValid(panel)) then panel:updatePrice() end

	panel = self.items[self.me][itemType]
	if (IsValid(panel)) then panel:updatePrice() end
end

function PANEL:onVendorModeUpdated(vendor, itemType, mode)
	self:updateItem(itemType, self.vendor)
	self:updateItem(itemType, self.me)
end

function PANEL:onItemStockUpdated(vendor, itemType)
	self:updateItem(itemType, self.vendor)
end

function PANEL:onCharVarChanged(character, key, oldValue, newValue)
	if (character ~= LocalPlayer():getChar()) then return end

	if (key == "money") then
		self.me:setMoney(newValue)
	end
end

function PANEL:listenForChanges()
	-- Money changes.
	hook.Add("VendorMoneyUpdated", self, self.onVendorMoneyUpdated)
	hook.Add("OnCharVarChanged", self, self.onCharVarChanged)

	-- Price change.
	hook.Add("VendorItemPriceUpdated", self, self.onVendorPriceUpdated)

	-- Item stock changes.
	hook.Add("VendorItemStockUpdated", self, self.onItemStockUpdated)
	hook.Add("VendorItemMaxStockUpdated", self, self.onItemStockUpdated)

	-- Item mode change.
	hook.Add("VendorItemModeUpdated", self, self.onVendorModeUpdated)

	-- Name change.
	hook.Add("VendorEdited", self, self.onVendorPropEdited)
end

function PANEL:InventoryItemAdded(item)
	self:updateItem(item.uniqueID, self.me)
end

function PANEL:InventoryItemRemoved(item)
	-- Really we're just updating the quantity.
	self:InventoryItemAdded(item)
end

function PANEL:Paint(w, h)
	nut.util.drawBlur(self, 10)

	surface.SetDrawColor(0, 0, 0, 100)
	surface.DrawRect(0, 0, w, h)
end

function PANEL:OnRemove()
	if (not self.noSendExit) then
		net.Start("nutVendorExit")
		net.SendToServer()
		self.noSendExit = true
	end

	if (IsValid(nut.gui.vendorEditor)) then
		nut.gui.vendorEditor:Remove()
	end

	if (IsValid(nut.gui.vendorFactionEditor)) then
		nut.gui.vendorFactionEditor:Remove()
	end

	self:nutDeleteInventoryHooks()
end

function PANEL:OnKeyCodePressed(keyCode)
	local useKey = input.LookupBinding("+use", true)

	if (useKey) then
		self:Remove()
	end
end


vgui.Register("nutVendor", PANEL, "EditablePanel")

if (IsValid(nut.gui.vendor)) then
	vgui.Create("nutVendor")
end
