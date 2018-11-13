local PANEL = {}
	local MODEL_ANGLE = Angle(0, 45, 0)

	function PANEL:Init()
		self.brightness = 1

		self:SetCursor("none")
		self.OldSetModel = self.SetModel
		self.SetModel = function(self, model)
			self:OldSetModel(model)

			local entity = self.Entity

			if (IsValid(entity)) then
				local sequence = entity:SelectWeightedSequence(ACT_IDLE)

				if (sequence <= 0) then
					sequence = entity:LookupSequence("idle_unarmed")
				end

				if (sequence > 0) then
					entity:ResetSequence(sequence)
				else
					local found = false

					for k, v in ipairs(entity:GetSequenceList()) do
						if ((v:lower():find("idle") or v:lower():find("fly")) and v != "idlenoise") then
							entity:ResetSequence(v)
							found = true

							break
						end
					end

					if (!found) then
						entity:ResetSequence(4)
					end
				end

				entity:SetIK(false)
			end
		end
	end

	function PANEL:LayoutEntity()
		local scrW, scrH = ScrW(), ScrH()
		local xRatio = gui.MouseX() / scrW
		local yRatio = gui.MouseY() / scrH
		local x, y = self:LocalToScreen(self:GetWide() / 2)
		local xRatio2 = x / scrW
		local entity = self.Entity

		entity:SetPoseParameter("head_pitch", yRatio*90 - 30)
		entity:SetPoseParameter("head_yaw", (xRatio - xRatio2)*90 - 5)
		entity:SetAngles(MODEL_ANGLE)
		entity:SetIK(false)

		if (self.copyLocalSequence) then
			entity:SetSequence(LocalPlayer():GetSequence())
		 	entity:SetPoseParameter("move_yaw", 360 * LocalPlayer():GetPoseParameter("move_yaw") - 180)
		end

		self:RunAnimation()
	end

	function PANEL:PreDrawModel(entity)
		-- Excecute Some stuffs
		if (self.enableHook) then
			hook.Run("DrawNutModelView", self, entity)
		end

		return true
	end

	function PANEL:OnMousePressed()
	end

	function PANEL:fitFOV()
		local entity = self:GetEntity()
		if (not IsValid(entity)) then return end

		local mins, maxs = entity:GetRenderBounds()
		local height = math.abs(maxs.z) + math.abs(mins.z) + 8
		local distance = self:GetCamPos():Length()
		self:SetFOV(math.deg(2 * math.atan(height / (2 * distance))))
	end
vgui.Register("nutModelPanel", PANEL, "DModelPanel")
