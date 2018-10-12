NS_ICON_SIZE = 64
_NUT_INV_PANEL_ID = _NUT_INV_PANEL_ID or 0

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

	self.itemTable = item
	self:SetModel(item.model, item.skin)
	self:SetToolTip(item:getDesc())

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

function PANEL:getItem()
	return self.itemTable
end

-- Updates the parts of the UI that could be changed by data changes.
function PANEL:ItemDataChanged(key, oldValue, newValue)
	self:SetToolTip(self:getItem():getDesc())
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

function PANEL:ExtraPaint(w, h)
end

function PANEL:Paint(w, h)
	surface.SetDrawColor(0, 0, 0, 85)
	surface.DrawRect(2, 2, w - 4, h - 4)

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
		if (isfunction(v.onCanRun) and v.onCanRun(itemTable) == false) then
			itemTable.player = nil
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

					if (v.sound) then
						surface.PlaySound(v.sound)
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

						if (v.sound) then
							surface.PlaySound(v.sound)
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

					if (v.sound) then
						surface.PlaySound(v.sound)
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
		self.toRemoveHooks = {}
		self.hookID = ""
	end

	-- Sets which inventory this panel is representing.
	function PANEL:setInventory(inventory)
		self.inventory = inventory
		self:listenForInventoryChanges()
	end

	-- Make it so the panel hooks below run when the inventory hooks do.
	function PANEL:listenForInventoryChanges()
		assert(self.inventory, "No inventory has been set!")
		local id = self.inventory:getID()

		-- Clean up old hooks
		self:deleteInventoryHooks()

		_NUT_INV_PANEL_ID = _NUT_INV_PANEL_ID + 1
		local hookID = "nutInventoryListener".._NUT_INV_PANEL_ID
		self.hookID = hookID

		-- For each relevant inventory/item hook, add a listener that will
		-- trigger the associated panel hook.
		local function listenForInventoryChange(name, panelHook)
			panelHook = panelHook or name
			hook.Add(name, hookID, function(inventory, ...)
				if (not IsValid(self) or self.inventory ~= inventory) then
					return
				end
				self[panelHook](self, ...)

				if (name == "InventoryDeleted") then
					self.inventory = nil
					self:deleteInventoryHooks()
				end
			end)
			self.toRemoveHooks[#self.toRemoveHooks + 1] = name
		end

		listenForInventoryChange("InventoryInitialized")
		listenForInventoryChange("InventoryDeleted")
		listenForInventoryChange("InventoryDataChanged")
		listenForInventoryChange("InventoryItemAdded")
		listenForInventoryChange("InventoryItemRemoved")

		hook.Add(
			"ItemDataChanged",
			hookID,
			function(item, key, oldValue, newValue)
				if (not IsValid(self) or not self.inventory) then return end
				if (not self.inventory.items[item:getID()]) then
					return
				end
				self:InventoryItemDataChanged(item, key, oldValue, newValue)
			end
		)
		self.toRemoveHooks[#self.toRemoveHooks + 1] = "ItemDataChanged"
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
	function PANEL:InventoryDeleted()
		self:Remove()
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

	-- Cleans up all the hooks created by listenForInventoryChanges()
	function PANEL:deleteInventoryHooks()
		for i = 1, #self.toRemoveHooks do
			hook.Remove(self.toRemoveHooks[i], self.hookID)
		end
		self.toRemoveHooks = {}
	end

	-- Make sure to clean up hooks before removing the panel.
	function PANEL:OnRemove()
		self:deleteInventoryHooks()
	end
vgui.Register("nutInventory", PANEL, "DFrame")

hook.Add("CreateMenuButtons", "nutInventory", function(tabs)
	if (hook.Run("CanPlayerViewInventory") != false) then
		tabs["inv"] = function(panel)
			local inventory = LocalPlayer():getChar():getInv()

			if (inventory) then
				inventory:show(panel)
			end
		end
	end
end)

hook.Add("PostRenderVGUI", "nutInvHelper", function()
	local pnl = nut.gui.inv1

	hook.Run("PostDrawInventory", pnl)
end)
