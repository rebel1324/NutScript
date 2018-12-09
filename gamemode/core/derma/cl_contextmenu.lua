function GM:OnContextMenuOpen()
	self.BaseClass:OnContextMenuOpen()
	vgui.Create("nutQuick")
end

function GM:OnContextMenuClose()
	self.BaseClass:OnContextMenuClose()
	if (IsValid(nut.gui.quick)) then
		nut.gui.quick:Remove()
	end
end
