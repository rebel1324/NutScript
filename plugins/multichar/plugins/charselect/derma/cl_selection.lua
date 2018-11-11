local PANEL = {}

function PANEL:Init()
	self:Dock(FILL)
	self:DockMargin(0, 64, 0, 0)
	self:InvalidateLayout(true)
	self.panels = {}

	self.scroll = self:Add("nutHorizontalScroll")
	self.scroll:Dock(FILL)

	local scrollBar = self.scroll:GetHBar()
	scrollBar:SetTall(8)
	scrollBar:SetHideButtons(true)
	scrollBar.Paint = function(scroll, w, h)
		surface.SetDrawColor(255, 255, 255, 10)
		surface.DrawRect(0, 0, w, h)
	end
	scrollBar.btnGrip.Paint = function(grip, w, h)
		local alpha = 50
		if (scrollBar.Dragging) then
			alpha = 150
		elseif (grip:IsHovered()) then
			alpha = 100
		end
		surface.SetDrawColor(255, 255, 255, alpha)
		surface.DrawRect(0, 0, w, h)
	end

	self:createCharacterSlots()
	hook.Add("CharacterListUpdated", self, function()
		self:createCharacterSlots()
	end)
end

function PANEL:createCharacterSlots()
	self.scroll:Clear()
	if (#nut.characters == 0) then
		return vgui.Create("nutCharacter")
	end
	for _, id in ipairs(nut.characters) do
		local character = nut.char.loaded[id]
		if (not character) then continue end

		local panel = self.scroll:Add("nutCharacterSlot")
		panel:Dock(LEFT)
		panel:DockMargin(0, 0, 8, 8)
		panel:setCharacter(character)
		panel.onSelected = function(panel)
			self:onCharacterSelected(character)
		end
	end
end

function PANEL:onCharacterSelected(character)
	nut.gui.character:setFadeToBlack(true)
		:next(function()
			return nutMultiChar:chooseCharacter(character:getID())
		end)
		:next(function()
			if (IsValid(nut.gui.character)) then
				nut.gui.character:setFadeToBlack(false)
				nut.gui.character:Remove()
			end
		end, function(err)
			nut.util.notify(err)
		end)
end

vgui.Register("nutCharacterSelection", PANEL, "EditablePanel")