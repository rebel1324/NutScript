local PANEL = {}
	function PANEL:Init()
		self:SetFont("nutMenuButtonFont")
		self:SetExpensiveShadow(2, Color(0, 0, 0, 200))
		self:SetTextColor(color_white)
		self:SetPaintBackground(false)
		self.OldSetTextColor = self.SetTextColor
		self.SetTextColor = function(this, color)
			this:OldSetTextColor(color)
			this:SetFGColor(color)
		end
	end

	function PANEL:setText(text, noTranslation)
		surface.SetFont("nutMenuButtonFont")

		self:SetText(noTranslation and text:upper() or L(text):upper())

		if (!noTranslation) then
			self:SetTooltip(L(text.."Tip"))
		end

		local w, h = surface.GetTextSize(self:GetText())
		self:SetSize(w + 64, h + 32)
	end

	function PANEL:OnCursorEntered()
		local color = self:GetTextColor()
		self:SetTextColor(Color(math.max(color.r - 25, 0), math.max(color.g - 25, 0), math.max(color.b - 25, 0)))

		surface.PlaySound(SOUND_MENU_BUTTON_ROLLOVER)
	end

	function PANEL:OnCursorExited()
		if (self.color) then
			self:SetTextColor(self.color)
		else
			self:SetTextColor(color_white)
		end
	end

	function PANEL:OnMousePressed(code)
		if (self.color) then
			self:SetTextColor(self.color)
		else
			self:SetTextColor(nut.config.get("color"))
		end

		surface.PlaySound(SOUND_MENU_BUTTON_PRESSED)

		if (code == MOUSE_LEFT and self.DoClick) then
			self:DoClick(self)
		end
	end

	function PANEL:OnMouseReleased(key)
		if (self.color) then
			self:SetTextColor(self.color)
		else
			self:SetTextColor(color_white)
		end
	end
vgui.Register("nutMenuButton", PANEL, "DButton")