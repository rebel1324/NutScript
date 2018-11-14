local PANEL = {}

function PANEL:configureSteps()
	self:addStep(vgui.Create("nutCharacterFaction"))
	self:addStep(vgui.Create("nutCharacterModel"))
	self:addStep(vgui.Create("nutCharacterBiography"))
	self:addStep(vgui.Create("nutCharacterAttribs"))
end

function PANEL:updateModel()
	local faction = nut.faction.indices[self.context.faction]
	assert(faction, "invalid faction when updating model")
	local modelInfo = faction.models[self.context.model or 1]
	assert(modelInfo, "faction "..faction.name.." has no models!")

	local model, skin, groups
	if (istable(modelInfo)) then
		model, skin, groups = unpack(modelInfo)
	else
		model, skin, groups = modelInfo, 1, {}
	end

	self.model:SetModel(model)
	local entity = self.model:GetEntity()
	if (not IsValid(entity)) then return end
	entity:SetSkin(skin)
	for group, value in pairs(groups) do
		entity:SetBodygroup(group, value)
	end
end

function PANEL:canCreateCharacter()
	local validFactions = {}
	for k, v in pairs(nut.faction.teams) do
		if (nut.faction.hasWhitelist(v.index)) then
			validFactions[#validFactions + 1] = v.index
		end
	end

	if (#validFactions == 0) then
		return false, "You are unable to join any factions"
	end
	self.validFactions = validFactions

	local maxChars = hook.Run("GetMaxPlayerCharacter", LocalPlayer())
		or nut.config.get("maxChars", 5)
	if (nut.characters and #nut.characters >= maxChars) then
		return false, "You have reached the maximum number of characters"
	end

	local canCreate, reason = hook.Run("ShouldMenuButtonShow", "create")
	if (canCreate == false) then
		return false, reason
	end

	return true
end

function PANEL:onFinish()
	if (self.creating) then return end

	-- Indicate that the character is being created.
	self.content:SetVisible(false)
	self.buttons:SetVisible(false)
	self:showMessage("creating")

	-- Reset the UI once the server responds.
	local function onResponse()
		if (not IsValid(self)) then return end
		self.creating = false
		self.content:SetVisible(true)
		self.buttons:SetVisible(true)
		self:showMessage()
	end
	local function onFail(err)
		onResponse()
		self:showError(err)
	end

	-- Send the character data and request that a character be made.
	nutMultiChar:createCharacter(self.context)
		:next(function()
			onResponse()
			if (IsValid(nut.gui.character)) then
				vgui.Create("nutCharacter")
			end
		end, onFail)

	-- Show an error if this is taking too long.
	timer.Create("nutFailedToCreate", 60, 1, function()
		if (not IsValid(self) or not self.creating) then return end
		onFail("unknownError")
	end)

	self.creating = true
end

function PANEL:showError(message, ...)
	if (IsValid(self.error)) then
		self.error:Remove()
	end
	if (not message or message == "") then return end
	message = L(message, ...)

	self.error = self.content:Add("DLabel")
	self.error:SetFont("nutTitle3Font")
	self.error:SetText(message)
	self.error:SetTextColor(color_white)
	self.error:Dock(TOP)
	self.error:SetTall(32)
	self.error:DockMargin(0, 0, 0, 8)
	self.error:SetContentAlignment(5)
	self.error.Paint = function(box, w, h)
		nut.util.drawBlur(box)
		surface.SetDrawColor(255, 0, 0, 50)
		surface.DrawRect(0, 0, w, h)
	end
	self.error:SetAlpha(0)
	self.error:AlphaTo(255, nut.gui.character.ANIM_SPEED)

	nut.gui.character:warningSound()
end

function PANEL:showMessage(message, ...)
	if (not message or message == "") then
		if (IsValid(self.message)) then self.message:Remove() end
		return
	end
	message = L(message, ...):upper()

	if (IsValid(self.message)) then
		self.message:SetText(message)
	end

	self.message = self:Add("DLabel")
	self.message:Dock(FILL)
	self.message:SetContentAlignment(5)
	self.message:SetFont("nutCharButtonFont")
	self.message:SetText(message)
	self.message:SetTextColor(nut.gui.character.WHITE)
end

function PANEL:addStep(step, priority)
	assert(IsValid(step), "Invalid panel for step")
	assert(step.isCharCreateStep, "Panel must inherit nutCharacterCreateStep")
	if (isnumber(priority)) then
		table.insert(self.steps, priority, step)
	else
		self.steps[#self.steps + 1] = step
	end
	step:SetParent(self.content)
end

function PANEL:nextStep()
	local curStep = self.steps[self.curStep]
	if (IsValid(curStep)) then
		local res = {curStep:validate()}
		if (res[1] == false) then return self:showError(unpack(res, 2)) end
	end

	-- Clear any error messages.
	self:showError()

	-- Move to the next step. Call onFinish if none exists.
	self.curStep = self.curStep + 1
	local nextStep = self.steps[self.curStep]
	while (IsValid(nextStep) and nextStep:shouldSkip()) do
		self.curStep = self.curStep + 1
		nextStep:onSkip()
		nextStep = self.steps[self.curStep]
	end
	if (not IsValid(nextStep)) then return self:onFinish() end

	-- Transition the view to the next step's view.
	self:onStepChanged(curStep, nextStep)
end

function PANEL:previousStep()
	local curStep = self.steps[self.curStep]
	local newStep = self.curStep - 1
	local prevStep = self.steps[newStep]
	while (IsValid(prevStep) and prevStep:shouldSkip()) do
		prevStep:onSkip()
		newStep = newStep - 1
		prevStep = self.steps[newStep]
	end

	if (not IsValid(prevStep)) then return end
	self.curStep = newStep
	self:onStepChanged(curStep, prevStep)
end

function PANEL:reset()
	self.context = {}

	local curStep = self.steps[self.curStep]
	if (IsValid(curStep)) then
		curStep:SetVisible(false)
	end

	self.curStep = 0
	if (#self.steps == 0) then
		return self:showError("No character creation steps have been set up")
	end
	self:nextStep()
end

function PANEL:getPreviousStep()
	local step = self.curStep - 1
	while (IsValid(self.steps[step])) do
		if (not self.steps[step]:shouldSkip()) then
			hasPrevStep = true
			break
		end
		step = step - 1
	end
	return self.steps[step]
end

function PANEL:onStepChanged(oldStep, newStep)
	local ANIM_SPEED = nut.gui.character.ANIM_SPEED
	local shouldFinish = self.curStep == #self.steps
	local nextStepText = L(shouldFinish and "finish" or "next"):upper()
	local shouldSwitchNextText = nextStepText ~= self.next:GetText()

	-- Change visibility for prev/next if they should not be shown.
	if (IsValid(self:getPreviousStep())) then
		self.prev:AlphaTo(255, ANIM_SPEED)
	else
		self.prev:AlphaTo(0, ANIM_SPEED)
	end
	if (shouldSwitchNextText) then
		self.next:AlphaTo(0, ANIM_SPEED)
	end

	-- Transition the view to the new step view.
	local function showNewStep()
		newStep:SetAlpha(0)
		newStep:SetVisible(true)
		newStep:InvalidateLayout(true)
		newStep:onDisplay()
		newStep:AlphaTo(255, ANIM_SPEED)

		if (shouldSwitchNextText) then
			self.next:SetAlpha(0)
			self.next:SetText(nextStepText)
			self.next:SizeToContentsX()
		end
		self.next:AlphaTo(255, ANIM_SPEED)
	end
	if (IsValid(oldStep)) then
		oldStep:AlphaTo(0, ANIM_SPEED, 0, function()
			self:showError()
			oldStep:SetVisible(false)
			showNewStep()
		end)
	else
		showNewStep()
	end
end

function PANEL:Init()
	self:Dock(FILL)
	local canCreate, reason = self:canCreateCharacter()
	if (not canCreate) then
		return self:showError(reason)
	end

	nut.gui.charCreate = self

	self.content = self:Add("DPanel")
	self.content:Dock(FILL)
	self.content:DockMargin(ScrW() * 0.15, 64, ScrW() * 0.15, 0)
	self.content:SetDrawBackground(false)

	self.model = self.content:Add("nutModelPanel")
	self.model:SetWide(ScrW() * 0.25)
	self.model:Dock(LEFT)
	self.model:SetModel("models/error.mdl")
	self.model.oldSetModel = self.model.SetModel
	self.model.SetModel = function(model, ...)
		model:oldSetModel(...)
		model:fitFOV()
	end

	self.buttons = self:Add("DPanel")
	self.buttons:Dock(BOTTOM)
	self.buttons:SetTall(36)
	self.buttons:SetDrawBackground(false)

	self.prev = self.buttons:Add("nutCharButton")
	self.prev:SetText(L("back"):upper())
	self.prev:Dock(LEFT)
	self.prev:SetWide(96)
	self.prev.DoClick = function(prev) self:previousStep() end
	self.prev:SetAlpha(0)

	self.next = self.buttons:Add("nutCharButton")
	self.next:SetText(L("next"):upper())
	self.next:Dock(RIGHT)
	self.next:SetWide(96)
	self.next.DoClick = function(next) self:nextStep() end

	self.cancel = self.buttons:Add("nutCharButton")
	self.cancel:SetText(L("cancel"):upper())
	self.cancel:SizeToContentsX()
	self.cancel.DoClick = function(cancel) self:reset() end
	self.cancel.x = (ScrW() - self.cancel:GetWide()) * 0.5 - 64

	self.steps = {}
	self.curStep = 0
	self.context = {}
	self:configureSteps()

	if (#self.steps == 0) then
		return self:showError("No character creation steps have been set up")
	end

	self:nextStep()
end

vgui.Register("nutCharacterCreation", PANEL, "EditablePanel")
