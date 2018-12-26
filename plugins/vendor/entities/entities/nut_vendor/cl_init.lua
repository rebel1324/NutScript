include("shared.lua")

function ENT:createBubble()
	self.bubble = ClientsideModel(
		"models/extras/info_speech.mdl",
		RENDERGROUP_OPAQUE
	)
	self.bubble:SetPos(self:GetPos() + Vector(0, 0, 84))
	self.bubble:SetModelScale(0.6, 0)
end

function ENT:Draw()
	local bubble = self.bubble

	if (IsValid(bubble)) then
		local realTime = RealTime()
		local bounce = Vector(0, 0, 84 + math.sin(realTime *3) * 0.05)

		bubble:SetRenderOrigin(self:GetPos() + bounce)
		bubble:SetRenderAngles(Angle(0, realTime * 100, 0))
	end

	self:DrawModel()
end

function ENT:Think()
	if (not self.hasSetupVars) then
		self:setupVars()
	end

	local noBubble = self:getNetVar("noBubble")

	if (IsValid(self.bubble) and noBubble) then
		self.bubble:Remove()
	elseif (!IsValid(self.bubble) and !noBubble) then
		self:createBubble()
	end

	if ((self.nextAnimCheck or 0) < CurTime()) then
		self:setAnim()
		self.nextAnimCheck = CurTime() + 60
	end

	self:SetNextClientThink(CurTime() + 1)

	return true
end

function ENT:OnRemove()
	if (IsValid(self.bubble)) then
		self.bubble:Remove()
	end
end

local TEXT_OFFSET = Vector(0, 0, 20)
local toScreen = FindMetaTable("Vector").ToScreen
local colorAlpha = ColorAlpha
local drawText = nut.util.drawText
local configGet = nut.config.get

ENT.DrawEntityInfo = true

function ENT:onDrawEntityInfo(alpha)
	local position = toScreen(self:LocalToWorld(self:OBBCenter()) + TEXT_OFFSET)
	local x, y = position.x, position.y
	local desc = self.getNetVar(self, "desc")

	-- Draw the name of the vendor.
	drawText(
		self.getNetVar(self, "name", "John Doe"),
		x, y,
		colorAlpha(configGet("color"), alpha),
		1, 1,
		nil,
		alpha * 0.65
	)

	-- Draw the vendor's description below the name.
	if (desc) then
		drawText(
			desc,
			x, y + 16,
			colorAlpha(color_white, alpha),
			1, 1,
			"nutSmallFont",
			alpha * 0.65
		)
	end
end
