local PLUGIN = PLUGIN

function PLUGIN:saveVendors()
	local data = {}
		for k, v in ipairs(ents.FindByClass("nut_vendor")) do
			data[#data + 1] = {
				name = v:getNetVar("name"),
				desc = v:getNetVar("desc"),
				pos = v:GetPos(),
				angles = v:GetAngles(),
				model = v:GetModel(),
				bubble = v:getNetVar("noBubble"),
				items = v.items,
				factions = v.factions,
				classes = v.classes,
				money = v.money,
				scale = v:getNetVar("scale")
			}
		end
	self:setData(data)
end

function PLUGIN:LoadData()
	for k, v in ipairs(ents.FindByClass("nut_vendor")) do
		v.nutIsSafe = true
		v:Remove()
	end

	for k, v in ipairs(self:getData() or {}) do
		local entity = ents.Create("nut_vendor")
		entity:SetPos(v.pos)
		entity:SetAngles(v.angles)
		entity:Spawn()
		entity:SetModel(v.model)
		entity:setNetVar("noBubble", v.bubble)
		entity:setNetVar("name", v.name)
		entity:setNetVar("desc", v.desc)
		entity:setNetVar("scale", v.scale or 0.5)

		entity.items = v.items or {}
		entity.factions = v.factions or {}
		entity.classes = v.classes or {}
		entity.money = v.money
	end
end
