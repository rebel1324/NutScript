local PANEL = {}

local EDITOR = include(PLUGIN.path.."/cl_editor.lua")
local PRICE_UPDATE_DELAY = 0.5

local COLS_NAME = 1
local COLS_MODE = 2
local COLS_PRICE = 3
local COLS_STOCK = 4

function PANEL:Init()
	if (IsValid(nut.gui.vendorEditor)) then
		nut.gui.vendorEditor:Remove()
	end
	nut.gui.vendorEditor = self

	local entity = nutVendorEnt

	local width = math.min(ScrW() * 0.75, 480)
	local height = math.min(ScrH() * 0.75, 640)

	self:SetSize(width, height)
	self:MakePopup()
	self:Center()
	self:SetTitle(L"vendorEditor")

	self.name = self:Add("DTextEntry")
	self.name:Dock(TOP)
	self.name:SetToolTip(L"name")
	self.name:SetText(entity:getName())
	self.name.OnEnter = function(this)
		if (entity:getNetVar("name") ~= this:GetText()) then
			EDITOR.name(this:GetText())
		end
	end

	self.desc = self:Add("DTextEntry")
	self.desc:Dock(TOP)
	self.desc:SetToolTip(L"desc")
	self.desc:DockMargin(0, 4, 0, 0)
	self.desc:SetText(entity:getDesc())
	self.desc.OnEnter = function(this)
		if (entity:getNetVar("desc") ~= this:GetText()) then
			EDITOR.desc(this:GetText())
		end
	end

	self.model = self:Add("DTextEntry")
	self.model:Dock(TOP)
	self.model:SetToolTip(L"model")
	self.model:DockMargin(0, 4, 0, 0)
	self.model:SetText(entity:GetModel())
	self.model.OnEnter = function(this)
		local model = this:GetText():lower()
		if (entity:GetModel():lower() ~= model) then
			EDITOR.model(model)
		end
	end

	local useMoney = tonumber(entity:getMoney()) ~= nil

	self.money = self:Add("DTextEntry")
	self.money:Dock(TOP)
	self.money:SetToolTip(nut.currency.plural)
	self.money:DockMargin(0, 4, 0, 0)
	self.money:SetNumeric(true)
	self.money.OnEnter = function(this)
		local value = tonumber(this:GetText()) or entity:getMoney()
		value = math.Round(value)
		value = math.max(value, 0)

		if (value ~= entity:getMoney()) then
			EDITOR.money(value)
		end
	end

	self.bubble = self:Add("DCheckBoxLabel")
	self.bubble:SetText(L"vendorNoBubble")
	self.bubble:Dock(TOP)
	self.bubble:DockMargin(0, 4, 0, 0)
	self.bubble:SetValue(entity:getNetVar("noBubble") and 1 or 0)
	self.bubble.OnChange = function(this, value)
		EDITOR.bubble(value)
	end

	self.useMoney = self:Add("DCheckBoxLabel")
	self.useMoney:SetText(L"vendorUseMoney")
	self.useMoney:Dock(TOP)
	self.useMoney:DockMargin(0, 4, 0, 0)
	self.useMoney.OnChange = function(this, value)
		EDITOR.useMoney(value)
	end

	self.sellScale = self:Add("DNumSlider")
	self.sellScale:Dock(TOP)
	self.sellScale:DockMargin(0, 4, 0, 0)
	self.sellScale:SetText(L"vendorSellScale")
	self.sellScale.Label:SetTextColor(color_white)
	self.sellScale.TextArea:SetTextColor(color_white)
	self.sellScale:SetDecimals(2)
	self.sellScale.OnValueChanged = function(this, value)
		timer.Create("nutVendorScale", PRICE_UPDATE_DELAY, 1, function()
			if (IsValid(self) and IsValid(self.sellScale)) then
				value = self.sellScale:GetValue()

				local diff = math.abs(value - entity:getSellScale())
				if (diff > 0.05) then
					EDITOR.scale(value)
				end
			end
		end)
	end

	self.faction = self:Add("DButton")
	self.faction:SetText(L"vendorFaction")
	self.faction:Dock(TOP)
	self.faction:SetTextColor(color_white)
	self.faction:DockMargin(0, 4, 0, 0)
	self.faction.DoClick = function(this)
		vgui.Create("nutVendorFactionEditor"):MoveLeftOf(self, 4)
	end

	local menu

	self.items = self:Add("DListView")
	self.items:Dock(FILL)
	self.items:DockMargin(0, 4, 0, 0)
	self.items:AddColumn(L"name").Header:SetTextColor(color_black)	
	self.items:AddColumn(L"mode").Header:SetTextColor(color_black)
	self.items:AddColumn(L"price").Header:SetTextColor(color_black)
	self.items:AddColumn(L"stock").Header:SetTextColor(color_black)
	self.items:SetMultiSelect(false)
	self.items.OnRowRightClick = function(this, index, line)
		if (IsValid(menu)) then
			menu:Remove()
		end

		local uniqueID = line.item
		local itemTable = nut.item.list[uniqueID]

		menu = DermaMenu()
			-- Modes of the item.
			local mode, panel = menu:AddSubMenu(L"mode")
			panel:SetImage("icon16/key.png")

			-- Disable buying/selling of the item.
			mode:AddOption(L"none", function()
				EDITOR.mode(uniqueID, nil)
			end):SetImage("icon16/cog_error.png")

			-- Allow the vendor to sell and buy this item.
			mode:AddOption(L"vendorBoth", function()
				EDITOR.mode(uniqueID, VENDOR_SELLANDBUY)
			end):SetImage("icon16/cog.png")

			-- Only allow the vendor to buy this item from players.
			mode:AddOption(L"vendorBuy", function()
				EDITOR.mode(uniqueID, VENDOR_BUYONLY)
			end):SetImage("icon16/cog_delete.png")

			-- Only allow the vendor to sell this item to players.
			mode:AddOption(L"vendorSell", function()
				EDITOR.mode(uniqueID, VENDOR_SELLONLY)
			end):SetImage("icon16/cog_add.png")

			-- Set the price of the item.
			menu:AddOption(L"price", function()
				Derma_StringRequest(
					itemTable:getName(),
					L"vendorPriceReq",
					entity:getPrice(uniqueID),
					function(text)
						text = tonumber(text)
						EDITOR.price(uniqueID, text)
					end
				)
			end):SetImage("icon16/coins.png")

			-- Set the stock of the item or disable it.
			local stock, panel = menu:AddSubMenu(L"stock")
			panel:SetImage("icon16/table.png")

			-- Disable the use of stocks for this item.
			stock:AddOption(L"disable", function()
				EDITOR.stockDisable(uniqueID)
			end):SetImage("icon16/table_delete.png")

			-- Edit the maximum stock for this item.
			stock:AddOption(L"edit", function()
				local _, max = entity:getStock(uniqueID)

				Derma_StringRequest(
					itemTable:getName(),
					L"vendorStockReq",
					max or 1,
					function(text)
						text = math.max(math.Round(tonumber(text) or 1), 1)
						EDITOR.stockMax(uniqueID, text)
					end
				)
			end):SetImage("icon16/table_edit.png")

			-- Edit the current stock of this item.
			stock:AddOption(L"vendorEditCurStock", function()
				Derma_StringRequest(
					itemTable:getName(),
					L"vendorStockCurReq",
					entity:getStock(uniqueID) or 0,
					function(text)
						text = math.Round(tonumber(text) or 0)
						EDITOR.stock(uniqueID, text)
					end
				)
			end):SetImage("icon16/table_edit.png")
		menu:Open()
	end

	self.lines = {}

	for k, v in SortedPairsByMemberValue(nut.item.list, "name") do
		local mode = entity.items[k] and entity.items[k][VENDOR_MODE]
		local current, max = entity:getStock(k)
		local panel = self.items:AddLine(
			v:getName(),
			self:getModeText(mode),
			entity:getPrice(k),
			max and current.."/"..max or "-"
		)
		panel.item = k
		self.lines[k] = panel
	end

	self:listenForUpdates()
	self:updateMoney()
	self:updateSellScale()
end

function PANEL:getModeText(mode)
	return L(VENDOR_TEXT[mode] or "none")
end

function PANEL:OnRemove()
	if (IsValid(nut.gui.editorFaction)) then
		nut.gui.editorFaction:Remove()
	end
end

function PANEL:updateVendor(key, value)
	netstream.Start("vendorEdit", key, value)
end

function PANEL:OnFocusChanged(gained)
	if (not gained) then
		timer.Simple(0, function()
			if (not IsValid(self)) then return end
			self:MakePopup()
		end)
	end
end

function PANEL:updateMoney()
	local money = nutVendorEnt:getMoney()
	local useMoney = isnumber(money)

	if (money) then
		self.money:SetText(money)
	else
		self.money:SetText("∞")
	end

	self.money:SetDisabled(not useMoney)
	self.money:SetEnabled(useMoney)
	self.useMoney:SetChecked(useMoney)
end

function PANEL:updateSellScale()
	self.sellScale:SetValue(nutVendorEnt:getSellScale())
end

function PANEL:onNameDescChanged(vendor, key, value)
	local entity = nutVendorEnt

	if (key == "name") then
		self.name:SetText(entity:getName())
	elseif (key == "desc") then
		self.desc:SetText(entity:getDesc())
	elseif (key == "model") then
		self.model:SetText(entity:GetModel())
	elseif (key == "bubble") then
		self.bubble:SetChecked(entity:getNoBubble())
	elseif (key == "scale") then
		self:updateSellScale()
	end
end

function PANEL:onItemModeUpdated(vendor, itemType, value)
	local line = self.lines[itemType]
	if (not IsValid(line)) then return end

	line:SetColumnText(COLS_MODE, self:getModeText(value))
end

function PANEL:onItemPriceUpdated(vendor, itemType, value)
	local line = self.lines[itemType]
	if (not IsValid(line)) then return end

	line:SetColumnText(COLS_PRICE, vendor:getPrice(itemType))
end

function PANEL:onItemStockUpdated(vendor, itemType)
	local line = self.lines[itemType]
	if (not IsValid(line)) then return end

	local current, max = vendor:getStock(itemType)
	line:SetColumnText(COLS_STOCK, max and current.."/"..max or "-")
end

function PANEL:listenForUpdates()
	hook.Add("VendorEdited", self, self.onNameDescChanged)
	hook.Add("VendorMoneyUpdated", self, self.updateMoney)
	hook.Add("VendorItemModeUpdated", self, self.onItemModeUpdated)
	hook.Add("VendorItemPriceUpdated", self, self.onItemPriceUpdated)
	hook.Add("VendorItemStockUpdated", self, self.onItemStockUpdated)
	hook.Add("VendorItemMaxStockUpdated", self, self.onItemStockUpdated)
end

vgui.Register("nutVendorEditor", PANEL, "DFrame")
