function PLUGIN:VendorOpened(vendor)
	vgui.Create("nutVendor")
	hook.Run("OnOpenVendorMenu", self) -- mostly for sound or welcome stuffs
end

function PLUGIN:VendorExited()
	if (IsValid(nut.gui.vendor)) then
		nut.gui.vendor:Remove()
	end
end

function PLUGIN:LoadFonts(font)
	surface.CreateFont("nutVendorButtonFont", {
		font = font,
		weight = 200,
		size = 40
	})

	surface.CreateFont("nutVendorSmallFont", {
		font = font,
		weight = 500,
		size = 22
	})

	surface.CreateFont("nutVendorLightFont", {
		font = font,
		weight = 200,
		size = 22
	})
end
