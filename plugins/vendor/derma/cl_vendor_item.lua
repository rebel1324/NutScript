local PANEL = {}

local COLOR_PRICE = Color(255, 255, 255, 75)
local COLOR_CANNOT_AFFORD = Color(255, 100, 100, 75)

local function ignore() end

function PANEL:Init()
	self:Dock(TOP)
	self:SetTall(64)
	self:SetPaintBackground(false)

	self.suffix = ""

	self.icon = self:Add("nutItemIcon")
	self.icon:SetSize(64, 64)
	self.icon.PaintBehind = ignore
	self.icon.OnCursorEntered = function(icon)
		self:OnCursorEntered()
	end

	self.name = self:Add("DLabel")
	self.name:SetPos(self.icon:GetWide() + 8, 8)
	self.name:SetTextColor(color_white)
	self.name:SetExpensiveShadow(1, color_black)
	self.name:SetFont("nutVendorSmallFont")
	self.name:SizeToContents()

	self.price = self:Add("DLabel")
	self.price:SetPos(self.icon:GetWide() + 8, 8 + self.name:GetTall())
	self.price:SetTextColor(Color(255, 255, 255, 75))
	self.price:SetExpensiveShadow(1, color_black)
	self.price:SetFont("nutVendorLightFont")
	self.price:SetText(nut.currency.get(0))
	self.price:SizeToContents()

	self:SetCursor("hand")
	self.isSelling = false
end

function PANEL:updatePrice()
	local price = nutVendorEnt:getPrice(self.item.uniqueID, self.isSelling)
	self.price:SetText(nut.currency.get(price))
	self.price:SizeToContents()
end

function PANEL:setIsSelling(isSelling)
	self.isSelling = isSelling
	self:updatePrice()
end

local function clickEffects()
	LocalPlayer():EmitSound(unpack(SOUND_VENDOR_CLICK))
end

local function sellItemToVendor(panel)
	local item = panel.item
	if (not item) then return end
	
	if (IsValid(nut.gui.vendor)) then
		nut.gui.vendor:sellItemToVendor(item.uniqueID)
		clickEffects()
	end
end

local function buyItemFromVendor(panel)
	local item = panel.item
	if (not item) then return end
	
	if (IsValid(nut.gui.vendor)) then
		nut.gui.vendor:buyItemFromVendor(item.uniqueID)
		clickEffects()
	end
end

function PANEL:showAction()
	if (IsValid(self.action)) then return end

	self.action = self:Add("DButton")
	self.action:Dock(FILL)
	self.action:SetFont("nutVendorSmallFont")
	self.action:SetTextColor(color_white)
	self.action:SetAlpha(0)
	self.action:AlphaTo(255, 0.2, 0)
	self.action.OnCursorExited = function(button)
		button:Remove()
	end
	self.action.Paint = function(button, w, h)
		surface.SetDrawColor(0, 0, 0, 220)
		surface.DrawRect(0, 0, w, h)
	end
	self.action:SetText(L(self.isSelling and "sell" or "buy"):upper())
	self.action.nutToolTip = true
	self.action:SetToolTip(
		"<font=nutItemDescFont>"..self.item:getDesc()
	)
	self.action.item = self.item
	self.action.DoClick = self.isSelling
		and sellItemToVendor
		or buyItemFromVendor

	LocalPlayer():EmitSound("buttons/button15.wav", 25, 200)
end

function PANEL:OnCursorEntered()
	self:showAction()
end

function PANEL:setQuantity(quantity)
	if (not self.item) then return end

	if (quantity) then
		if (quantity <= 0) then
			self:Remove()
			return
		end

		self.suffix = " ("..tostring(quantity)..")"
	else
		self.suffix = ""
	end

	self.name:SetText(self.item:getName()..self.suffix)
	self.name:SizeToContents()
end

function PANEL:setItemType(itemType)
	local item = nut.item.list[itemType]
	assert(item, tostring(itemType).." is not a valid item")

	self.item = item

	self.icon:setItemType(itemType)
	self.name:SetText(item:getName()..self.suffix)
	self.name:SizeToContents()

	self:updatePrice()
end

vgui.Register("nutVendorItem", PANEL, "DPanel")
