PLUGIN.name = "Vendors"
PLUGIN.author = "Chessnut"
PLUGIN.desc = "Adds NPC vendors that can sell things."

nut.util.include("sv_logging.lua")
nut.util.include("sh_enums.lua")
nut.util.include("sv_networking.lua")
nut.util.include("cl_networking.lua")

if (SERVER) then
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

	function PLUGIN:CanVendorSellItem(client, vendor, itemID)
		local tradeData = vendor.items[itemID]
		local char = client:getChar()

		if (!tradeData or !char) then
			print("Not Valid Item or Client Char.")
			return false
		end

		if (!char:hasMoney(tradeData[1] or 0)) then
			print("Insufficient Fund.")
			return false
		end

		return true
	end
end
