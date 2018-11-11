local PANEL = {}

surface.CreateFont("nutTitle2Font", {
	font = "Raleway Light",
	weight = 200,
	size = 96,
	additive = true
})
surface.CreateFont("nutTitle3Font", {
	font = "Raleway Light",
	weight = 200,
	size = 24,
	additive = true
})
surface.CreateFont("nutCharButtonFont", {
	font = "Raleway Light",
	weight = 200,
	size = 36,
	additive = true
})
surface.CreateFont("nutCharSmallButtonFont", {
	font = "Raleway Light",
	weight = 200,
	size = 22,
	additive = true
})

local WHITE = Color(255, 255, 255, 150)
local SELECTED = Color(255, 255, 255, 230)

PANEL.WHITE = WHITE
PANEL.SELECTED = SELECTED
PANEL.HOVERED = Color(255, 255, 255, 50)
PANEL.ANIM_SPEED = 0.1
PANEL.FADE_SPEED = 0.5

function PANEL:createTitle()
	self.title = self:Add("DLabel")
	self.title:Dock(TOP)
	self.title:DockMargin(64, 48, 0, 0)
	self.title:SetContentAlignment(1)
	self.title:SetTall(96)
	self.title:SetFont("nutTitle2Font")
	self.title:SetText(L(SCHEMA and SCHEMA.name or "Unknown"):upper())
	self.title:SetTextColor(WHITE)

	self.desc = self:Add("DLabel")
	self.desc:Dock(TOP)
	self.desc:DockMargin(64, 0, 0, 0)
	self.desc:SetTall(32)
	self.desc:SetContentAlignment(7)
	self.desc:SetText(L(SCHEMA and SCHEMA.desc or ""):upper())
	self.desc:SetFont("nutTitle3Font")
	self.desc:SetTextColor(WHITE)
end

function PANEL:addTab(name, callback)
	local button = self.tabs:Add("nutCharacterTabButton")
	button:setText(L(name):upper())
	button.DoClick = function(button)
		button:setSelected(true)
	end
	if (isfunction(callback)) then
		button:onSelected(function()
			callback(self)
		end)
	end
	return button
end

function PANEL:createCharacterSelection()
	self.content:Clear()
	self.content:InvalidateLayout(true)
	self.content:Add("nutCharacterSelection")
end

function PANEL:createCharacterCreation()
	self.content:Clear()
	self.content:InvalidateLayout(true)
	self.content:Add("nutCharacterCreation")
end

function PANEL:Init()
	if (IsValid(nut.gui.loading)) then
		nut.gui.loading:Remove()
	end

	if (IsValid(nut.gui.character)) then
		nut.gui.character:Remove()
	end
	nut.gui.character = self

	self:ParentToHUD()
	self:Dock(FILL)
	self:MakePopup()

	self:createTitle()

	self.tabs = self:Add("DPanel")
	self.tabs:Dock(TOP)
	self.tabs:DockMargin(64, 32, 64, 0)
	self.tabs:SetTall(48)
	self.tabs:SetDrawBackground(false)
	
	self.content = self:Add("DPanel")
	self.content:Dock(FILL)
	self.content:DockMargin(64, 0, 64, 64)
	self.content:SetDrawBackground(false)

	local load, create

	if (nut.characters and #nut.characters > 0) then
		load = self:addTab("continue", self.createCharacterSelection)
	end

	local create = self:addTab("create", self.createCharacterCreation)
	self:addTab("leave", function()
		LocalPlayer():ConCommand("disconnect")
	end)

	if (IsValid(load)) then
		load:setSelected()
	elseif (IsValid(create)) then
		create:setSelected()
	end
end

function PANEL:setFadeToBlack(fade)
	local d = deferred.new()
	if (fade) then
		if (IsValid(self.fade)) then
			self.fade:Remove()
		end
		local fade = vgui.Create("DPanel")
		fade:SetSize(ScrW(), ScrH())
		fade:SetSkin("Default")
		fade:SetBackgroundColor(color_black)
		fade:SetAlpha(0)
		fade:AlphaTo(255, self.FADE_SPEED, 0, function() d:resolve() end)
		self.fade = fade
	elseif (IsValid(self.fade)) then
		local fadePanel = self.fade
		fadePanel:AlphaTo(0, self.FADE_SPEED, 0, function()
			fadePanel:Remove()
			d:resolve()
		end)
	end
	return d
end

function PANEL:Paint(w, h)
	nut.util.drawBlur(self)
end

vgui.Register("nutCharacter", PANEL, "EditablePanel")

if (IsValid(nut.gui.character)) then
	vgui.Create("nutCharacter")
end
