local PANEL = {}
	function PANEL:Init()
		self:SetSize(ScrW() * 0.45, ScrH() * 0.65)
		self:SetTitle("")
		self:MakePopup()
		self:Center()

		local header = self:Add("DPanel")
		header:SetTall(34)
		header:Dock(TOP)

		self.vendorName = header:Add("DLabel")
		self.vendorName:Dock(LEFT)
		self.vendorName:SetWide(self:GetWide() * 0.5 - 7)
		self.vendorName:SetText("John Doe")
		self.vendorName:SetTextInset(4, 0)
		self.vendorName:SetTextColor(color_white)
		self.vendorName:SetFont("nutMediumFont")

		self.ourName = header:Add("DLabel")
		self.ourName:Dock(RIGHT)
		self.ourName:SetWide(self:GetWide() * 0.5 - 7)
		self.ourName:SetText(L"you".." ("..nut.currency.get(LocalPlayer():getChar():getMoney())..")")
		self.ourName:SetTextInset(0, 0)
		self.ourName:SetTextColor(color_white)
		self.ourName:SetFont("nutMediumFont")

		local footer = self:Add("DPanel")
		footer:SetTall(34)
		footer:Dock(BOTTOM)
		footer:SetDrawBackground(false)

		self.vendorSell = footer:Add("DButton")
		self.vendorSell:SetFont("nutMediumFont")
		self.vendorSell:SetWide(self.vendorName:GetWide())
		self.vendorSell:Dock(LEFT)
		self.vendorSell:SetContentAlignment(5)
		-- The text says purchase but the vendor is selling it to us.
		self.vendorSell:SetText(L"purchase")
		self.vendorSell:SetTextColor(color_white)
		self.vendorSell.DoClick = function(this)
			if (IsValid(self.activeSell)) then
				netstream.Start("vendorTrade", self.activeSell.item)
			end
		end

		self.vendorBuy = footer:Add("DButton")
		self.vendorBuy:SetFont("nutMediumFont")
		self.vendorBuy:SetWide(self.ourName:GetWide())
		self.vendorBuy:Dock(RIGHT)
		self.vendorBuy:SetContentAlignment(5)
		self.vendorBuy:SetText(L"sell")
		self.vendorBuy:SetTextColor(color_white)
		self.vendorBuy.DoClick = function(this)
			if (IsValid(self.activeBuy)) then
				self.toRemove = self.activeBuy
				netstream.Start("vendorTrade", self.activeBuy.item, true)
			end
		end

		self.selling = self:Add("DScrollPanel")
		self.selling:SetWide(self:GetWide() * 0.5 - 7)
		self.selling:Dock(LEFT)
		self.selling:DockMargin(0, 4, 0, 4)
		self.selling:SetDrawBackground(true)

		self.sellingItems = self.selling:Add("DListLayout")
		self.sellingItems:SetSize(self.selling:GetSize())
		self.sellingItems:DockPadding(0, 0, 0, 4)
		self.sellingItems:SetTall(ScrH())

		self.buying = self:Add("DScrollPanel")
		self.buying:SetWide(self:GetWide() * 0.5 - 7)
		self.buying:Dock(RIGHT)
		self.buying:DockMargin(0, 4, 0, 4)
		self.buying:SetDrawBackground(true)

		self.buyingItems = self.buying:Add("DListLayout")
		self.buyingItems:SetSize(self.buying:GetSize())
		self.buyingItems:DockPadding(0, 0, 0, 4)

		self.sellingList = {}
		self.buyingList = {}
	end

	function PANEL:addItem(uniqueID, parent)
		local entity = self.entity
		local items = entity.items
		local data = items[uniqueID]

		if (not data) then
			return
		end
		local vendorMode = data[VENDOR_MODE]
		if (
			(vendorMode == VENDOR_BUYONLY and parent == self.sellingItems) or
			(vendorMode == VENDOR_SELLONLY and parent == self.buyingItems)
		) then
			return
		end
		local isSelling = parent == self.sellingItems
		if (
			(isSelling and IsValid(self.sellingList[uniqueID])) or
			(not isSelling and IsValid(self.buyingList[uniqueID]))
		) then
			return
		end

		local item = parent:Add("nutVendorItem")
		item:setup(uniqueID)
		parent:InvalidateLayout()

		if (isSelling) then
			self.sellingList[uniqueID] = item
		else
			item.isLocal = true
			item:setQuantity(self:getLocalInventoryQuantity(uniqueID))
			self.buyingList[uniqueID] = item
		end
	end

	function PANEL:getLocalInventoryQuantity(itemType)
		local character = LocalPlayer():getChar()
		if (not character) then return 0 end
		local inventory = character:getInv()
		if (not inventory) then return 0 end
		return inventory:getItemCount(itemType)
	end

	function PANEL:removeItem(uniqueID, parent)
		local itemList = parent == self.buyingItems
			and self.buyingList
			or self.sellingList
		if (IsValid(itemList[uniqueID])) then
			local listParent = itemList[uniqueID]:GetParent()
			itemList[uniqueID]:Remove()

			if (IsValid(listParent)) then
				listParent:InvalidateLayout()
			end
		end
	end

	function PANEL:setup(entity)
		self.entity = entity
		self:SetTitle(entity:getNetVar("name", ""))
		self.vendorName:SetText(entity:getNetVar("name", "")..(entity.money and " ("..entity.money..")" or ""))

		for k, v in SortedPairs(entity.items) do
			self:addItem(k, self.sellingItems)
		end

		local character = LocalPlayer():getChar()
		if (not character) then
			return self:Remove()
		end
		local inventory = character:getInv()
		if (not inventory) then
			return self:Remove()
		end
		local items = inventory:getItems()
		for k, v in SortedPairsByMemberValue(items, "uniqueID") do
			self:addItem(v.uniqueID, self.buyingItems)
		end

		self:nutListenForInventoryChanges(inventory)
	end

	function PANEL:InventoryItemAdded(item)
		local itemType = item.uniqueID
		local panel = self.buyingList[itemType]
		if (IsValid(panel)) then
			panel:addQuantity(1)
		else
			self:addItem(itemType, self.buyingItems)
		end
	end

	function PANEL:InventoryItemRemoved(item)
		local itemType = item.uniqueID
		local panel = self.buyingList[itemType]
		if (IsValid(panel)) then
			panel:removeQuantity(1)
		end
	end

	function PANEL:OnRemove()
		netstream.Start("vendorExit")

		if (IsValid(nut.gui.vendorEditor)) then
			nut.gui.vendorEditor:Remove()
		end

		self:nutDeleteInventoryHooks()
	end

	function PANEL:Think()
		local entity = self.entity

		if (!IsValid(entity)) then
			self:Remove()

			return
		end

		if ((self.nextUpdate or 0) < CurTime()) then
			self:SetTitle(self.entity:getNetVar("name"))
			self.vendorName:SetText(entity:getNetVar("name", "")..(entity.money and " ("..nut.currency.get(entity.money)..")" or ""))
			self.ourName:SetText(L"you".." ("..nut.currency.get(LocalPlayer():getChar():getMoney())..")")

			self.nextUpdate = CurTime() + 0.25
		end
	end

	function PANEL:onItemSelected(panel)
		local itemTable = panel.itemTable
		local price = self.entity:getPrice(panel.item, panel.isLocal)

		if (panel.isLocal) then
			self.vendorBuy:SetText(L"sell".." ("..nut.currency.get(price)..")")
		else
			self.vendorSell:SetText(L"purchase".." ("..nut.currency.get(price)..")")
		end
	end
vgui.Register("nutVendor", PANEL, "DFrame")

PANEL = {}
	function PANEL:Init()
		self:SetTall(36)
		self:DockMargin(4, 4, 4, 0)

		self.icon = self:Add("nutItemIcon")
		self.icon:SetPos(2, 2)
		self.icon:SetSize(32, 32)
		self.icon:SetModel("models/error.mdl")

		self.name = self:Add("DLabel")
		self.name:Dock(FILL)
		self.name:DockMargin(42, 0, 0, 0)
		self.name:SetFont("nutChatFont")
		self.name:SetTextColor(color_white)
		self.name:SetExpensiveShadow(1, Color(0, 0, 0, 200))

		self.click = self:Add("DButton")
		self.click:Dock(FILL)
		self.click:SetText("")
		self.click.Paint = function() end
		self.click.DoClick = function(this)
			if (self.isLocal) then
				nut.gui.vendor.activeBuy = self
			else
				nut.gui.vendor.activeSell = self
			end

			nut.gui.vendor:onItemSelected(self)
		end

		self.quantity = 1
	end

	function PANEL:setCallback(callback)
		self.click.DoClick = function(this)
			callback()
			self.selected = true
		end
	end

	function PANEL:setup(uniqueID)
		local item = istable(uniqueID) and uniqueID or nut.item.list[uniqueID]

		if (item) then
			self.item = istable(uniqueID) and uniqueID.uniqueID or uniqueID
			self.icon:setItemType(uniqueID)
			self.name:SetText(L(item.name))
			self.itemName = L(item.name)

			if (item.id != 0) then
				self.itemID = item.id
				self.itemTable = item
			end
		end
	end

	function PANEL:Paint(w, h)
		if (nut.gui.vendor.activeBuy == self or nut.gui.vendor.activeSell == self) then
			surface.SetDrawColor(nut.config.get("color"))
		else
			surface.SetDrawColor(0, 0, 0, 100)
		end

		surface.DrawRect(0, 0, w, h)
	end

	function PANEL:setQuantity(quantity)
		self.quantity = quantity
		if (quantity <= 0) then
			return self:Remove()
		end

		if (self.isLocal) then
			self.name:SetText(self.itemName.." ("..quantity..")")
			return
		end

		local vendorItem = entity.items[self.item]
		if (not vendorItem or not vendorItem[VENDOR_MAXSTOCK]) then
			return
		end

		local stock = vendorItem[VENDOR_STOCK]
		local maxStock = vendorItem[VENDOR_MAXSTOCK]
		self.name:SetText(
			string.format("%s (%d/%d)", self.itemName, stock, maxStock)
		)
	end

	function PANEL:getQuantity()
		return self.quantity
	end

	function PANEL:addQuantity(quantity)
		self:setQuantity(self:getQuantity() + quantity)
	end

	function PANEL:removeQuantity(quantity)
		self:setQuantity(self:getQuantity() - quantity)
	end
vgui.Register("nutVendorItem", PANEL, "DPanel")
