PLUGIN.name = "Voice Overlay"
PLUGIN.author = "Black Tea"
PLUGIN.desc = "This plugin makes voice overlay clear and look nice (really?)"

if (CLIENT) then
	local PANEL = {}
	local nsVoicePanels = {}

	function PANEL:Init()
		local hi = vgui.Create("DLabel", self)
		hi:SetFont("nutIconsMedium")
		hi:Dock(LEFT)
		hi:DockMargin(8, 0, 8, 0)
		hi:SetTextColor(Color(255, 255, 255, 255))
		hi:SetText("i")
		hi:SetWide(30)

		self.LabelName = vgui.Create("DLabel", self)
		self.LabelName:SetFont("nutMediumFont")
		self.LabelName:Dock(FILL)
		self.LabelName:DockMargin(0, 0, 0, 0)
		self.LabelName:SetTextColor(Color(255, 255, 255, 255))

		self.Color = color_transparent

		self:SetSize(280, 32 + 8)
		self:DockPadding(4, 4, 4, 4)
		self:DockMargin(2, 2, 2, 2)
		self:Dock(BOTTOM)
	end

	function PANEL:Setup(client)
		self.client= client
		self.name = hook.Run("ShouldAllowScoreboardOverride", client, "name") and hook.Run("GetDisplayedName", client) or client:Nick()
		self.LabelName:SetText(self.name)
		self:InvalidateLayout()
	end

	function PANEL:Paint(w, h)
		if (!IsValid(self.client)) then return end

		nut.util.drawBlur(self, 1, 2)

		surface.SetDrawColor(0, 0, 0, 50 + self.client:VoiceVolume() * 50)
		surface.DrawRect(0, 0, w, h)

		surface.SetDrawColor(255, 255, 255, 50 + self.client:VoiceVolume() * 120)
		surface.DrawOutlinedRect(0, 0, w, h)
	end

	function PANEL:Think()
		if (IsValid(self.client)) then
			self.LabelName:SetText(self.name)
		end

		if (self.fadeAnim) then
			self.fadeAnim:Run()
		end
	end

	function PANEL:FadeOut(anim, delta, data)
		if (anim.Finished) then
			if (IsValid(nsVoicePanels[self.client])) then
				nsVoicePanels[self.client]:Remove()
				nsVoicePanels[self.client] = nil
				return
			end
		return end

		self:SetAlpha(255 - (255 * (delta * 2)))
	end

	vgui.Register("VoicePanel", PANEL, "DPanel")

	function PLUGIN:PlayerStartVoice(client)
		if (!IsValid(g_VoicePanelList)) then return end

		hook.Run("PlayerEndVoice", client)

		if (IsValid(nsVoicePanels[client])) then
			if (nsVoicePanels[client].fadeAnim) then
				nsVoicePanels[client].fadeAnim:Stop()
				nsVoicePanels[client].fadeAnim = nil
			end

			nsVoicePanels[client]:SetAlpha(255)

			return
		end

		if (!IsValid(client)) then return end

		local pnl = g_VoicePanelList:Add("VoicePanel")
		pnl:Setup(client)

		nsVoicePanels[client] = pnl
	end

	local function VoiceClean()
		for k, v in pairs(nsVoicePanels) do
			if (!IsValid(k)) then
				hook.Run("PlayerEndVoice", k)
			end
		end
	end
	timer.Create("VoiceClean", 10, 0, VoiceClean)

	function PLUGIN:PlayerEndVoice(client)
		if (IsValid(nsVoicePanels[client])) then
			if (nsVoicePanels[client].fadeAnim) then return end

			nsVoicePanels[client].fadeAnim = Derma_Anim("FadeOut", nsVoicePanels[client], nsVoicePanels[client].FadeOut)
			nsVoicePanels[client].fadeAnim:Start(2)
		end
	end

	local function CreateVoiceVGUI()
		gmod.GetGamemode().PlayerStartVoice = function() end
		gmod.GetGamemode().PlayerEndVoice = function() end

		g_VoicePanelList = vgui.Create("DPanel")

		g_VoicePanelList:ParentToHUD()
		g_VoicePanelList:SetSize(270, ScrH() - 200)
		g_VoicePanelList:SetPos(ScrW() - 320, 100)
		g_VoicePanelList:SetPaintBackground(false)
	end

	hook.Add("InitPostEntity", "CreateVoiceVGUI", CreateVoiceVGUI)
end
