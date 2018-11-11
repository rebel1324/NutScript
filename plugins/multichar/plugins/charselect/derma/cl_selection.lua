local PANEL = {}

function PANEL:Init()
	self:Dock(FILL)
	self:DockMargin(0, 64, 0, 0)
	self:InvalidateLayout(true)
	self.panels = {}

	local lastPanel
	for _, id in ipairs(nut.characters) do
		local character = nut.char.loaded[id]
		if (not character) then continue end

		local panel = self:Add("nutCharacterSlot")
		panel:setCharacter(character)
		panel.onSelected = function(panel)
			self:onCharacterSelected(character)
		end
		self.panels[id] = panel
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
