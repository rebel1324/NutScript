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

			if (client.itemTakeTransaction and client.itemTakeTransactionTimeout > RealTime()) then
				return false
			end

			client.itemTakeTransaction = true
			client.itemTakeTransactionTimeout = RealTime()

			if (not inventory) then return false end

			local d = deferred.new()

			inventory:add(item)
				:next(function(res)
					client.itemTakeTransaction = nil

					if (IsValid(entity)) then
						entity.nutIsSafe = true
						entity:Remove()
					end

					if (not IsValid(client)) then return end
					nut.log.add(client, "itemTake", item.name, 1)

					d:resolve()
				end)
				:catch(function(err)
					client.itemTakeTransaction = nil

					client:notifyLocalized(err)

					d:reject()
				end)

			return d
		end,
		onCanRun = function(item)
			return IsValid(item.entity)
		end
	},
}
