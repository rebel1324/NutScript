local PANEL = {}

function PANEL:Init()
	self.title = self:addLabel("Select a model")

	self.models = self:Add("DIconLayout")
	self.models:Dock(FILL)
	self.models:SetSpaceX(4)
	self.models:SetSpaceY(4)
	self.models:SetPaintBackground(false)
	self.models:SetStretchWidth(true)
	self.models:SetStretchHeight(true)
	self.models:StretchToParent(0, 0, 0, 0)
end

function PANEL:onDisplay()
	local oldChildren = self.models:GetChildren()
	self.models:InvalidateLayout(true)

	local faction = nut.faction.indices[self:getContext("faction")]
	if (not faction) then return end

	local function paintIcon(icon, w, h)
		self:paintIcon(icon, w, h)
	end

	for k, v in SortedPairs(faction.models) do
		local icon = self.models:Add("SpawnIcon")
		icon:SetSize(64, 128)
		icon:InvalidateLayout(true)
		icon.DoClick = function(icon)
			self:onModelSelected(icon)
		end
		icon.PaintOver = paintIcon

		if (isstring(v)) then
			icon:SetModel(v)
			icon.model = v
			icon.skin = 0
			icon.bodyGroups = {}
		else
			icon:SetModel(v[1], v[2] or 0, v[3])
			icon.model = v[1]
			icon.skin = v[2] or 0
			icon.bodyGroups = v[3]
		end
		icon.index = k

		if (self:getContext("model") == k) then
			self:onModelSelected(icon, true)
		end
	end

	self.models:Layout()
	self.models:InvalidateLayout()
	for _, child in pairs(oldChildren) do
		child:Remove()
	end
end

function PANEL:paintIcon(icon, w, h)
	if (self:getContext("model") ~= icon.index) then return end
	local color = nut.config.get("color", color_white)

	surface.SetDrawColor(color.r, color.g, color.b, 200)

	local i2
	for i = 1, 3 do
		i2 = i * 2
		surface.DrawOutlinedRect(i, i, w - i2, h - i2)
	end
end

function PANEL:onModelSelected(icon, noSound)
	self:setContext("model", icon.index or 1)
	if (not noSound) then
		nut.gui.character:clickSound()
	end
	self:updateModelPanel()
end

function PANEL:shouldSkip()
	local faction = nut.faction.indices[self:getContext("faction")]
	return faction and #faction.models == 1 or false
end

function PANEL:onSkip()
	self:setContext("model", 1)
end

vgui.Register("nutCharacterModel", PANEL, "nutCharacterCreateStep")
