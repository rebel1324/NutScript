NS_ICON_SIZE = 64

-- The queue for the rendered icons.
renderedIcons = renderedIcons or {}

-- To make making inventory variant, This must be followed up.
function renderNewIcon(panel, itemTable)
	-- re-render icons
	if ((itemTable.iconCam and !renderedIcons[string.lower(itemTable.model)]) or itemTable.forceRender) then
		local iconCam = itemTable.iconCam
		iconCam = {
			cam_pos = iconCam.pos,
			cam_ang = iconCam.ang,
			cam_fov = iconCam.fov,
		}
		renderedIcons[string.lower(itemTable.model)] = true
		
		panel.Icon:RebuildSpawnIconEx(
			iconCam
		)
	end
end

local function drawIcon(mat, self, x, y)
	surface.SetDrawColor(color_white)
	surface.SetMaterial(mat)
	surface.DrawTexturedRect(0, 0, x, y)
end

local PANEL = {}

function PANEL:setItemType(itemTypeOrID)
	local item = nut.item.list[itemTypeOrID]
	if (type(itemTypeOrID) == "number") then
		item = nut.item.instances[itemTypeOrID]
		self.itemID = itemTypeOrID
	end
	assert(item, "invalid item type or ID "..tostring(item))

	self.nutToolTip = true
	self.itemTable = item
	self:SetModel(item.model, item.skin)
	self:updateTooltip()

	if (item.exRender) then
		self.Icon:SetVisible(false)
		self.ExtraPaint = function(self, x, y)
			local paintFunc = item.paintIcon

			if (paintFunc and type(paintFunc) == "function") then
				paintFunc(item, self)
			else
				local exIcon = ikon:getIcon(item.uniqueID)
				if (exIcon) then
					surface.SetMaterial(exIcon)
					surface.SetDrawColor(color_white)
					surface.DrawTexturedRect(0, 0, x, y)
				else
					ikon:renderIcon(
						item.uniqueID,
						item.width,
						item.height,
						item.model,
						item.iconCam
					)
				end
			end
		end
	elseif (item.icon) then
		self.Icon:SetVisible(false)
		self.ExtraPaint = function(self, w, h)
			drawIcon(item.icon, self, w, h)
		end
	else
		renderNewIcon(self, item)
	end
end

function PANEL:updateTooltip()
	self:SetTooltip(
		"<font=nutItemBoldFont>"..self.itemTable:getName().."</font>\n"..
		"<font=nutItemDescFont>"..self.itemTable:getDesc()
	)
end

function PANEL:getItem()
	return self.itemTable
end

-- Updates the parts of the UI that could be changed by data changes.
function PANEL:ItemDataChanged(key, oldValue, newValue)
	self:updateTooltip()
end

function PANEL:Init()
	self:Droppable("inv")
	self:SetSize(NS_ICON_SIZE, NS_ICON_SIZE)
end

function PANEL:PaintOver(w, h)
	local itemTable = nut.item.instances[self.itemID]

	if (itemTable and itemTable.paintOver) then
		local w, h = self:GetSize()

		itemTable.paintOver(self, itemTable, w, h)
	end
end

function PANEL:PaintBehind(w, h)
	surface.SetDrawColor(0, 0, 0, 85)
	surface.DrawRect(2, 2, w - 4, h - 4)
end

function PANEL:ExtraPaint(w, h)
end

function PANEL:Paint(w, h)
	self:PaintBehind(w, h)
	self:ExtraPaint(w, h)
end

function PANEL:openActionMenu()
	local itemTable = self.itemTable

	assert(itemTable, "attempt to open action menu for invalid item")
	itemTable.player = LocalPlayer()

	local menu = DermaMenu()
	local override = hook.Run("OnCreateItemInteractionMenu", panel, menu, itemTable)
	if (override) then
		if (IsValid(menu)) then
			menu:Remove()
		end
		return
	end

	for k, v in SortedPairs(itemTable.functions) do
		if (isfunction(v.onCanRun) and not v.onCanRun(itemTable)) then
			continue
		end

		-- TODO: refactor custom menu options as a method for items
		if (v.isMulti) then
			local subMenu, subMenuOption =
				menu:AddSubMenu(L(v.name or k), function()
					itemTable.player = LocalPlayer()
					local send = true

					if (v.onClick) then
						send = v.onClick(itemTable)
					end

					local snd = v.sound or SOUND_INVENTORY_INTERACT
					if (snd) then
						if (type(snd) == 'table') then
							LocalPlayer():EmitSound(unpack(snd))
						elseif (type(snd) == 'string') then
							surface.PlaySound(snd)
						end
					end

					if (send != false) then
						netstream.Start("invAct", k, itemTable.id, self.invID)
					end
					itemTable.player = nil
				end)
			subMenuOption:SetImage(v.icon or "icon16/brick.png")

			if (not v.multiOptions) then return end

			local options = isfunction(v.multiOptions)
				and v.multiOptions(itemTable, LocalPlayer())
				or v.multiOptions
			for _, sub in pairs(options) do
				subMenu:AddOption(L(sub.name or "subOption"), function()
					itemTable.player = LocalPlayer()
						local send = true

						if (v.onClick) then
							send = v.onClick(itemTable, sub.data)
						end

						local snd = v.sound or SOUND_INVENTORY_INTERACT
						if (snd) then
							if (type(snd) == 'table') then
								LocalPlayer():EmitSound(unpack(snd))
							elseif (type(snd) == 'string') then
								surface.PlaySound(snd)
							end
						end

						if (send != false) then
							netstream.Start(
								"invAct",
								k,
								itemTable.id,
								self.invID,
								sub.data
							)
						end
					itemTable.player = nil
				end)
			end
		else
			menu:AddOption(L(v.name or k), function()
				-- TODO: refactor this action click function
				itemTable.player = LocalPlayer()
					local send = true

					if (v.onClick) then
						send = v.onClick(itemTable)
					end

					local snd = v.sound or SOUND_INVENTORY_INTERACT
					if (snd) then
						if (type(snd) == 'table') then
							LocalPlayer():EmitSound(unpack(snd))
						elseif (type(snd) == 'string') then
							surface.PlaySound(snd)
						end
					end

					if (send != false) then
						netstream.Start("invAct", k, itemTable.id, self.invID)
					end
				itemTable.player = nil
			end):SetImage(v.icon or "icon16/brick.png")
		end
	end

	menu:Open()
	itemTable.player = nil
end

vgui.Register("nutItemIcon", PANEL, "SpawnIcon")

PANEL = {}
	function PANEL:Init()
		self:MakePopup()
		self:Center()
		self:ShowCloseButton(false)
		self:SetDraggable(true)
		self:SetTitle(L"inv")
	end

	-- Sets which inventory this panel is representing.
	function PANEL:setInventory(inventory)
		self.inventory = inventory
		self:nutListenForInventoryChanges(inventory)
	end

	-- Called when the data for the local inventory has been initialized.
	-- This shouldn't run unless the inventory got resync'd.
	function PANEL:InventoryInitialized()
	end

	-- Called when a data value has been changed for the inventory.
	function PANEL:InventoryDataChanged(key, oldValue, newValue)
	end

	-- Called when the inventory for this panel has been deleted. This may
	-- be because the local player no longer has access to the inventory!
	function PANEL:InventoryDeleted(inventory)
		if (self.inventory == inventory) then
			self:Remove()
		end
	end

	-- Called when the given item has been added to the inventory.
	function PANEL:InventoryItemAdded(item)
	end

	-- Called when the given item has been removed from the inventory.
	function PANEL:InventoryItemRemoved(item)
	end

	-- Called when an item within this inventory has its data changed.
	function PANEL:InventoryItemDataChanged(item, key, oldValue, newValue)
	end

	-- Make sure to clean up hooks before removing the panel.
	function PANEL:OnRemove()
		self:nutDeleteInventoryHooks()
	end
vgui.Register("nutInventory", PANEL, "DFrame")

hook.Add("CreateMenuButtons", "nutInventory", function(tabs)
	if (hook.Run("CanPlayerViewInventory") != false) then
		tabs["inv"] = function(panel)
			local inventory = LocalPlayer():getChar():getInv()

			if (inventory) then
				local mainPanel = inventory:show(panel)
				
				hook.Add("PostRenderVGUI", mainPanel, function()
					hook.Run("PostDrawInventory", mainPanel)
				end)
			end
		end
	end
end)