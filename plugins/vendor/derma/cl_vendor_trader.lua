local PANEL = {}

function PANEL:Init()
	self.name = self:Add("DLabel")
	self.name:Dock(TOP)
	self.name:SetTall(48)
	self.name:SetContentAlignment(7)
	self.name:SetFont("nutVendorButtonFont")
	self.name:SetTextColor(color_white)
	self.name:SetTextInset(8, 4)
	self.name.Paint = function(name, w, h)
		surface.SetDrawColor(0, 0, 0, 100)
		surface.DrawRect(0, 0, w, h)
	end

	self.money = self:Add("DLabel")
	self.money:Dock(TOP)
	self.money:SetFont("nutVendorSmallFont")
	self.money:SetContentAlignment(7)
	self.money:SetTall(28)
	self.money:SetTextInset(10, 0)
	self.money:SetTextColor(Color(255, 255, 255, 200))
	self.money.Paint = self.name.Paint

	self.items = self:Add("DScrollPanel")
	self.items:Dock(FILL)
end

function PANEL:setName(name)
	self.name:SetText(name)
end

function PANEL:setMoney(money)
	money = money or "∞"
	self.money:SetText(nut.currency.get(money))
end

function PANEL:Paint(w, h)
	surface.SetDrawColor(0, 0, 0, 175)
	surface.DrawRect(0, 0, w, h)
end

vgui.Register("nutVendorTrader", PANEL, "DPanel")
