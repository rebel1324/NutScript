
local PANEL = {}

AccessorFunc(PANEL, "m_bHangOpen", "HangOpen")

function PANEL:Init()
	self:SetWorldClicker(true)

	self.Canvas = vgui.Create("DCategoryList", self)
	self.m_bHangOpen = false
end

function PANEL:Open()
	self:SetHangOpen(false)

	if (g_SpawnMenu:IsVisible()) then
		g_SpawnMenu:Close(true)
	end

	if (self:IsVisible()) then return end

	CloseDermaMenus()

	self:MakePopup()
	self:SetVisible(true)
	self:SetKeyboardInputEnabled(false)
	self:SetMouseInputEnabled(true)

	RestoreCursorPosition()

	local bShouldShow = true

	if (bShouldShow && IsValid(spawnmenu.ActiveControlPanel())) then
		self.OldParent = spawnmenu.ActiveControlPanel():GetParent()
		self.OldPosX, self.OldPosY = spawnmenu.ActiveControlPanel():GetPos()
		spawnmenu.ActiveControlPanel():SetParent(self)
		self.Canvas:Clear()
		self.Canvas:AddItem(spawnmenu.ActiveControlPanel())
		self.Canvas:Rebuild()
		self.Canvas:SetVisible(true)
	else
		self.Canvas:SetVisible(false)
	end

	self:InvalidateLayout( true )
end


function PANEL:Close(bSkipAnim)
	if (self:GetHangOpen()) then
		self:SetHangOpen(false)
		return
	end

	RememberCursorPosition()

	CloseDermaMenus()

	self:SetKeyboardInputEnabled(false)
	self:SetMouseInputEnabled(false)

	self:SetAlpha(255)
	self:SetVisible(false)
	self:RestoreControlPanel()
end

function PANEL:PerformLayout()
	self:SetPos(0, -32)
	self:SetSize(ScrW(), ScrH())

	self.Canvas:SetWide(311)
	self.Canvas:SetPos(ScrW() - self.Canvas:GetWide() - 50, self.y)
	
	if (IsValid( spawnmenu.ActiveControlPanel())) then
		spawnmenu.ActiveControlPanel():InvalidateLayout(true)

		local tall = spawnmenu.ActiveControlPanel():GetTall() + 10
		local maxTall = ScrH() * 0.8
		if (tall > maxTall) then tall = maxTall end

		self.Canvas:SetTall(tall)
		self.Canvas.y = ScrH() - 50 - tall
	end
	
	self.Canvas:InvalidateLayout(true)
end

function PANEL:StartKeyFocus(pPanel)
	self:SetKeyboardInputEnabled(true)
	self:SetHangOpen(true)
end

function PANEL:EndKeyFocus(pPanel)
	self:SetKeyboardInputEnabled(false)
end

function PANEL:RestoreControlPanel()
	-- Restore the active panel
	if (!spawnmenu.ActiveControlPanel()) then return end
	if (!self.OldParent) then return end

	spawnmenu.ActiveControlPanel():SetParent(self.OldParent)
	spawnmenu.ActiveControlPanel():SetPos(self.OldPosX, self.OldPosY)

	self.OldParent = nil
end

-- Note here: EditablePanel is important! Child panels won't be able to get
-- keyboard input if it's a DPanel or a Panel. You need to either have an EditablePanel
-- or a DFrame (which is derived from EditablePanel) as your first panel attached to the system.
vgui.Register("ContextMenu", PANEL, "EditablePanel")


function CreateContextMenu()
	if (IsValid(g_ContextMenu)) then
		g_ContextMenu:Remove()
		g_ContextMenu = nil
	end

	g_ContextMenu = vgui.Create("ContextMenu")
	g_ContextMenu:SetVisible(false)

	-- We're blocking clicks to the world - but we don't want to
	-- so feed clicks to the proper functions..
	g_ContextMenu.OnMousePressed = function(p, code)
		hook.Run("GUIMousePressed", code, gui.ScreenToVector(gui.MousePos()))
	end
	g_ContextMenu.OnMouseReleased = function(p, code)
		hook.Run("GUIMouseReleased", code, gui.ScreenToVector(gui.MousePos()))
	end

	hook.Run("ContextMenuCreated", g_ContextMenu)

	local IconLayout = g_ContextMenu:Add("DIconLayout")
	IconLayout:Dock(LEFT)
	IconLayout:SetWorldClicker(true)
	IconLayout:SetBorder(8)
	IconLayout:SetSpaceX(8)
	IconLayout:SetSpaceY(8)
	IconLayout:SetWide(200)
	IconLayout:SetLayoutDir(LEFT)
end


function GM:OnContextMenuOpen()
	if (!hook.Call("ContextMenuOpen", GAMEMODE)) then return end

	if (IsValid(g_ContextMenu) && !g_ContextMenu:IsVisible()) then
		g_ContextMenu:Open()

		vgui.Create("nutQuick")

		menubar.ParentTo(g_ContextMenu)
	end
end


function GM:OnContextMenuClose()
	if (IsValid(g_ContextMenu)) then
		g_ContextMenu:Close()
	end

	if (IsValid(nut.gui.quick)) then
		nut.gui.quick:Remove()
	end
end

DMenuBar.AddMenu = function(self, label)
	local m = DermaMenu()
		m:SetDeleteSelf(false)
		m:SetDrawColumn(true)
		m:Hide()
	self.Menus[label] = m
	
	local b = self:Add("DButton")
	b:SetText(label)
	b:Dock(LEFT)
	b:SetTextColor(color_black)
	b:DockMargin(5, 0, 0, 0)
	b:SetIsMenu(true)
	b:SetDrawBackground(false)
	b:SizeToContentsX(16)
	b.DoClick = function()
		if (m:IsVisible()) then
			m:Hide()
			return
		end

		local x, y = b:LocalToScreen(0, 0)
		m:Open(x, y + b:GetTall(), false, b)
	end

	b.OnCursorEntered = function()
		local opened = self:GetOpenMenu()
		if (!IsValid(opened) || opened == m) then return end
		opened:Hide()
		b:DoClick()
	end
	
	return m
end