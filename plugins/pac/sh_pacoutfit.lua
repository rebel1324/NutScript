-- Store pac data from pacoutfit items.
function PLUGIN:setupPACDataFromItems()
	for itemType, item in pairs(nut.item.list) do
		if (istable(item.pacData)) then
			self.partData[itemType] = item.pacData
		end
	end
end

function PLUGIN:InitializedPlugins()
	timer.Simple(1, function()
		self:setupPACDataFromItems()
	end)
end
