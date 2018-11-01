
netstream.Hook("vendorOpen", function(index, items, money, messages, factions, classes)
	local entity = Entity(index)

	if (!IsValid(entity)) then
		return
	end

	entity.money = money
	entity.items = items
	entity.messages = messages
	entity.factions = factions
	entity.classes = classes

	nut.gui.vendor = vgui.Create("nutVendor")
	nut.gui.vendor:setup(entity)

	if (LocalPlayer():IsAdmin() and messages) then
		nut.gui.vendorEditor = vgui.Create("nutVendorEditor")
	end
end)

netstream.Hook("vendorEdit", function(key, data)
	local panel = nut.gui.vendor

	if (!IsValid(panel)) then
		return
	end

	local entity = panel.entity

	if (!IsValid(entity)) then
		return
	end

	if (key == "mode") then
		local itemType, mode = data[1], data[2]
		entity.items[itemType] = entity.items[itemType] or {}
		entity.items[itemType][VENDOR_MODE] = mode

		if (not mode) then
			panel:removeItem(itemType)
		elseif (mode == VENDOR_SELLANDBUY) then
			panel:addItem(itemType, panel.buyingItems)
			panel:addItem(itemType, panel.sellingItems)
		else
			local isSellOnly = mode == VENDOR_SELLONLY
			panel:addItem(
				itemType,
				isSellOnly and panel.sellingItems or panel.buyingItems
			)
			panel:removeItem(
				itemType,
				isSellOnly and panel.buyingItems or panel.sellingItems
			)
		end
	elseif (key == "price") then
		local uniqueID = data[1]

		entity.items[uniqueID] = entity.items[uniqueID] or {}
		entity.items[uniqueID][VENDOR_PRICE] = tonumber(data[2])
	elseif (key == "stockDisable") then
		if (entity.items[data]) then
			entity.items[data][VENDOR_MAXSTOCK] = nil
		end
	elseif (key == "stockMax") then
		local uniqueID = data[1]
		local value = data[2]
		local current = data[3]

		entity.items[uniqueID] = entity.items[uniqueID] or {}
		entity.items[uniqueID][VENDOR_MAXSTOCK] = value
		entity.items[uniqueID][VENDOR_STOCK] = current
	elseif (key == "stock") then
		local uniqueID = data[1]
		local value = data[2]

		entity.items[uniqueID] = entity.items[uniqueID] or {}

		if (!entity.items[uniqueID][VENDOR_MAXSTOCK]) then
			entity.items[uniqueID][VENDOR_MAXSTOCK] = value
		end

		entity.items[uniqueID][VENDOR_STOCK] = value
	end
end)

netstream.Hook("vendorEditFinish", function(key, data)
	local panel = nut.gui.vendor
	local editor = nut.gui.vendorEditor

	if (!IsValid(panel) or !IsValid(editor)) then
		return
	end

	local entity = panel.entity

	if (!IsValid(entity)) then
		return
	end

	if (key == "name") then
		editor.name:SetText(entity:getNetVar("name"))
	elseif (key == "desc") then
		editor.desc:SetText(entity:getNetVar("desc"))
	elseif (key == "bubble") then
		editor.bubble.noSend = true
		editor.bubble:SetValue(data and 1 or 0)
	elseif (key == "mode") then
		if (data[2] == nil) then
			editor.lines[data[1]]:SetValue(2, L"none")
		else
			editor.lines[data[1]]:SetValue(2, L(VENDOR_TEXT[data[2]]))
		end
	elseif (key == "price") then
		editor.lines[data]:SetValue(3, entity:getPrice(data))
	elseif (key == "stockDisable") then
		editor.lines[data]:SetValue(4, "-")
	elseif (key == "stockMax" or key == "stock") then
		local current, max = entity:getStock(data)

		editor.lines[data]:SetValue(4, current.."/"..max)
	elseif (key == "faction") then
		local uniqueID = data[1]
		local state = data[2]
		local panel = nut.gui.editorFaction

		entity.factions[uniqueID] = state

		if (IsValid(panel) and IsValid(panel.factions[uniqueID])) then
			panel.factions[uniqueID]:SetChecked(state == true)
		end
	elseif (key == "class") then
		local uniqueID = data[1]
		local state = data[2]
		local panel = nut.gui.editorFaction

		entity.classes[uniqueID] = state

		if (IsValid(panel) and IsValid(panel.classes[uniqueID])) then
			panel.classes[uniqueID]:SetChecked(state == true)
		end
	elseif (key == "model") then
		editor.model:SetText(entity:GetModel())
	elseif (key == "scale") then
		editor.sellScale.noSend = true
		editor.sellScale:SetValue(data)
	end

	surface.PlaySound("buttons/button14.wav")
end)

netstream.Hook("vendorMoney", function(value)
	local panel = nut.gui.vendor

	if (!IsValid(panel)) then
		return
	end

	local entity = panel.entity

	if (!IsValid(entity)) then
		return
	end

	entity.money = value

	local editor = nut.gui.vendorEditor

	if (IsValid(editor)) then
		local useMoney = tonumber(value) != nil

		editor.money:SetDisabled(!useMoney)
		editor.money:SetEnabled(useMoney)
		editor.money:SetText(useMoney and value or "∞")
	end
end)

netstream.Hook("vendorStock", function(uniqueID, amount)
	local panel = nut.gui.vendor

	if (!IsValid(panel)) then
		return
	end

	local entity = panel.entity

	if (!IsValid(entity)) then
		return
	end

	entity.items[uniqueID] = entity.items[uniqueID] or {}
	entity.items[uniqueID][VENDOR_STOCK] = amount

	local editor = nut.gui.vendorEditor

	if (IsValid(editor)) then
		local _, max = entity:getStock(uniqueID)

		editor.lines[uniqueID]:SetValue(4, amount.."/"..max)
	end
end)
