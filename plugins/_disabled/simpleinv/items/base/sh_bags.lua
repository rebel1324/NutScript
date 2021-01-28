ITEM.name = "Bag"
ITEM.desc = "A bag to hold more items."
ITEM.model = "models/props_c17/suitcase001a.mdl"
ITEM.category = "Storage"
ITEM.weight = -5

function ITEM:onRegistered()
	if (
		type(self.invWidth) == "number" and
		type(self.invHeight) == "number"
	) then
		self.weight = -1 * self.invWidth * self.invHeight
	end
end
