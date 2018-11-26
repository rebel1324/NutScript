local entityMeta = FindMetaTable("Entity")

-- Make a cache of chairs on start.
local CHAIR_CACHE = {}

-- Add chair models to the cache by checking if its vehicle category is a class.
for k, v in pairs(list.Get("Vehicles")) do
	if (v.Category == "Chairs") then
		CHAIR_CACHE[v.Model] = true
	end
end

-- Whether or not a vehicle is a chair by checking its model with the chair list.
function entityMeta:isChair()
	-- Micro-optimization in-case this gets used a lot.
	return CHAIR_CACHE[self.GetModel(self)]
end
