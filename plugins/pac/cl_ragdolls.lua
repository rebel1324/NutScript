-- Transfer player PAC parts to ragdols.

function PLUGIN:DrawPlayerRagdoll(entity)
	local ply = entity.objCache
	
	if (IsValid(ply) and not entity.overridePAC3) then
		if (ply.pac_outfits) then
			for _, part in pairs(ply.pac_outfits) do
				if (IsValid(part.last_owner)) then
					hook.Run("OnPAC3PartTransfered", part)
					part:SetOwner(entity)
					part.last_owner = entity
				end
			end
		end
		ply.pac_playerspawn = pac.RealTime -- used for events
		entity.overridePAC3 = true
	end
end

function PLUGIN:OnEntityCreated(entity)
	local class = entity:GetClass()
	
	timer.Simple(0, function()
		if (class == "prop_ragdoll") then
			if (entity:getNetVar("player")) then
				entity.RenderOverride = function()
					entity.objCache = entity:getNetVar("player")
					entity:DrawModel()
					
					hook.Run("DrawPlayerRagdoll", entity)
				end
			end
		end

		if (class:find("HL2MPRagdoll")) then
			for k, v in ipairs(player.GetAll()) do
				if (v:GetRagdollEntity() == entity) then
					entity.objCache = v
				end
			end
			
			entity.RenderOverride = function()
				entity:DrawModel()
				
				hook.Run("DrawPlayerRagdoll", entity)
			end
		end
	end)
end
