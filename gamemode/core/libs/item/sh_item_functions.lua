NUT_ITEM_DEFAULT_FUNCTIONS = {
	drop = {
		tip = "dropTip",
		icon = "icon16/world.png",
		onRun = function(item)
			local client = item.player
			item:removeFromInventory(true)
				:next(function() item:spawn(client) end)
			nut.log.add(item.player, "itemDrop", item.name, 1)

			return false
		end,
		onCanRun = function(item)
			return item.entity == nil
				and not IsValid(item.entity)
				and not item.noDrop
		end
	},
	take = {
		tip = "takeTip",
		icon = "icon16/box.png",
		onRun = function(item)
			local client = item.player
			local inventory = client:getChar():getInv()
			local entity = item.entity

			if (not inventory) then return false end
			inventory:add(item)
				:next(function(res)
					if (IsValid(entity)) then
						entity.nutIsSafe = true
						entity:Remove()
					end
					if (not IsValid(client)) then return end
					nut.log.add(client, "itemTake", item.name, 1)
				end)
				:catch(function(err)
					client:notifyLocalized(err)
				end)

			return false
		end,
		onCanRun = function(item)
			return IsValid(item.entity)
		end
	},
}
