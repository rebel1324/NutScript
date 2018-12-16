local PANEL = {}
	local gradient = nut.util.getMaterial("vgui/gradient-u")
	local gradient2 = nut.util.getMaterial("vgui/gradient-d")

	function PANEL:Init()
		self:SetTall(20)

		self.add = self:Add("DImageButton")
		self.add:SetSize(16, 16)
		self.add:Dock(RIGHT)
		self.add:DockMargin(2, 2, 2, 2)
		self.add:SetImage("icon16/add.png")
		self.add.OnMousePressed = function()
			self.pressing = 1
			self:doChange()
			self.add:SetAlpha(150)
		end
		self.add.OnMouseReleased = function()
			if (self.pressing) then
				self.pressing = nil
				self.add:SetAlpha(255)
			end
		end
		self.add.OnCursorExited = self.add.OnMouseReleased

		self.sub = self:Add("DImageButton")
		self.sub:SetSize(16, 16)
		self.sub:Dock(LEFT)
		self.sub:DockMargin(2, 2, 2, 2)
		self.sub:SetImage("icon16/delete.png")
		self.sub.OnMousePressed = function()
			self.pressing = -1
			self:doChange()
			self.sub:SetAlpha(150)
		end
		self.sub.OnMouseReleased = function()
			if (self.pressing) then
				self.pressing = nil
				self.sub:SetAlpha(255)
			end
		end
		self.sub.OnCursorExited = self.sub.OnMouseReleased

		self.t = 0
		self.value = 0
		self.deltaValue = self.value
		self.max = 10

		self.bar = self:Add("DPanel")
		self.bar:Dock(FILL)
		self.bar:DockMargin(2, 2, 2, 2)
		self.bar.Paint = function(this, w, h)
			self.t = Lerp(FrameTime() * 10, self.t, 1)

			local value = (self.value / self.max) * self.t
			local boostedValue = self.boostValue or 0
			local barWidth = w * value

			if (value > 0) then
				local color = nut.config.get("color")

				-- your stat
				surface.SetDrawColor(color)
				surface.DrawRect(0, 0, barWidth, h)

			end

			-- boosted stat
			if (boostedValue ~= 0) then
				local boostW = math.Clamp(
					math.abs(boostedValue / self.max),
					0, 1
				) * w * self.t + 1
				if (boostedValue < 0) then
					surface.SetDrawColor(200, 80, 80, 200)
					surface.DrawRect(barWidth - boostW, 0, boostW, h)
				else
					surface.SetDrawColor(80, 200, 80, 200)
					surface.DrawRect(barWidth, 0, boostW, h)
				end
			end
		end

		self.label = self.bar:Add("DLabel")
		self.label:Dock(FILL)
		self.label:SetExpensiveShadow(1, Color(0, 0, 60))
		self.label:SetContentAlignment(5)
	end

	function PANEL:Think()
		if (self.pressing) then
			if ((self.nextPress or 0) < CurTime()) then
				self:doChange()
			end
		end

		self.deltaValue = math.Approach(self.deltaValue, self.value, FrameTime() * 15)
	end

	function PANEL:doChange()
		if ((self.value == 0 and self.pressing == -1) or (self.value == self.max and self.pressing == 1)) then
			return
		end
		
		self.nextPress = CurTime() + 0.2
		
		if (self:onChanged(self.pressing) != false) then
			self.value = math.Clamp(self.value + self.pressing, 0, self.max)
		end
	end

	function PANEL:onChanged(difference)
	end

	function PANEL:getValue()
		return self.value
	end

	function PANEL:setValue(value)
		self.value = value
	end

	function PANEL:setBoost(value)
		self.boostValue = value
	end

	function PANEL:setMax(max)
		self.max = max
	end

	function PANEL:setText(text)
		self.label:SetText(text)
	end

	function PANEL:setReadOnly()
		self.sub:Remove()
		self.add:Remove()
	end
	
	function PANEL:Paint(w, h)
		surface.SetDrawColor(0, 0, 0, 200)
		surface.DrawRect(0, 0, w, h)
	end
vgui.Register("nutAttribBar", PANEL, "DPanel")
