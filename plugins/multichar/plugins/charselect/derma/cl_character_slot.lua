local PANEL = {}

local STRIP_HEIGHT = 4

function PANEL:isCursorWithinBounds()
	local x, y = self:LocalCursorPos()
	return x >= 0 and x <= self:GetWide() and y >= 0 and y < self:GetTall()
end

function PANEL:confirmDelete()
	local id = self.character:getID()
	vgui.Create("nutCharacterConfirm")
		:setMessage(L("Deleting a character cannot be undone."))
		:onConfirm(function() print("Delete "..id) end)
end

function PANEL:Init()
	local WIDTH = 240

	self:SetWide(WIDTH)
	self:Dock(LEFT)
	self:SetDrawBackground(false)

	self.faction = self:Add("DPanel")
	self.faction:Dock(TOP)
	self.faction:SetTall(STRIP_HEIGHT)
	self.faction:SetSkin("Default")
	self.faction:SetAlpha(100)

	self.name = self:Add("DLabel")
	self.name:Dock(TOP)
	self.name:SetTall(48)
	self.name:SetContentAlignment(5)
	self.name:SetFont("nutTitle3Font")
	self.name:SetTextColor(nut.gui.character.WHITE)

	self.model = self:Add("nutModelPanel")
	self.model:Dock(FILL)
	self.model:SetFOV(40)

	self.button = self:Add("DButton")
	self.button:SetSize(WIDTH, ScrH())
	self.button:SetDrawBackground(false)
	self.button:SetText("")
	self.button.OnCursorEntered = function(button) self:OnCursorEntered() end
	self.button.DoClick = function(button)
		self:onSelected()
	end

	self.delete = self:Add("DButton")
	self.delete:SetTall(30)
	self.delete:SetFont("nutCharSmallButtonFont")
	self.delete:SetText("✕ "..L("delete"):upper())
	self.delete:SetWide(self:GetWide())
	self.delete.Paint = function(delete, w, h)
		surface.SetDrawColor(255, 0, 0, 50)
		surface.DrawRect(0, 0, w, h)
	end
	self.delete.DoClick = function(delete)
		self:confirmDelete()
	end
	self.delete.y = ScrH()
	self.delete.showY = self.delete.y - self.delete:GetTall()
end

function PANEL:onSelected()
end

function PANEL:setCharacter(character)
	self.character = character

	self.name:SetText(character:getName():upper())
	self.model:SetModel(character:getModel())
	self.faction:SetBackgroundColor(team.GetColor(character:getFaction()))

	local entity = self.model.Entity
	if (IsValid(entity)) then
		-- Match the skin and bodygroups.
		entity:SetSkin(character:getData("skin", 0))
		for k, v in pairs(character:getData("groups", {})) do
			entity:SetBodygroup(k, v)
		end

		-- Approximate the upper body position.
		local mins, maxs = entity:GetRenderBounds()
		local height = math.abs(mins.z) + math.abs(maxs.z)
		local scale = math.max((960 / ScrH()) * 0.5, 0.5)
		self.model:SetLookAt(entity:GetPos() + Vector(0, 0, height * scale))
	end
end

function PANEL:onHoverChanged(isHovered)
	local ANIM_SPEED = nut.gui.character.ANIM_SPEED
	if (self.isHovered == isHovered) then return end
	self.isHovered = isHovered

	local tall = self:GetTall()
	if (isHovered) then
		self.delete.y = tall
		self.delete:MoveTo(0, tall - self.delete:GetTall(), ANIM_SPEED)
	else
		self.delete:MoveTo(0, tall, ANIM_SPEED)
	end

	self.faction:AlphaTo(isHovered and 200 or 100, ANIM_SPEED)
end

function PANEL:Paint(w, h)
	nut.util.drawBlur(self)
	surface.SetDrawColor(0, 0, 0, 100)
	surface.DrawRect(0, STRIP_HEIGHT, w, h)

	if (not self:isCursorWithinBounds() and self.isHovered) then
		self:onHoverChanged(false)
	end
end

function PANEL:OnCursorEntered()
	self:onHoverChanged(true)
end

vgui.Register("nutCharacterSlot", PANEL, "DPanel")
