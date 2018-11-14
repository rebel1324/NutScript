local PANEL = {}

PANEL.isCharCreateStep = true

function PANEL:Init()
	self:Dock(FILL)
	self:DockMargin(0, 0, 0, 0)
	self:SetDrawBackground(false)
	self:SetVisible(false)
end

function PANEL:onDisplay()
end

function PANEL:next()
	nut.gui.charCreate:nextStep()
end

function PANEL:previous()
	nut.gui.charCreate:previousStep()
end

function PANEL:validateCharVar(name)
	local charVar = nut.char.vars[name]
	assert(charVar, "invalid character variable "..tostring(name))

	if (isfunction(charVar.onValidate)) then
		return charVar.onValidate(
			self:getContext(name),
			self:getContext(),
			LocalPlayer()
		)
	end
	return true
end

function PANEL:validate()
	return true
end

function PANEL:setContext(key, value)
	nut.gui.charCreate.context[key] = value
end

function PANEL:clearContext()
	nut.gui.charCreate.context = {}
end

function PANEL:getContext(key, default)
	if (key == nil) then
		return nut.gui.charCreate.context
	end
	local value = nut.gui.charCreate.context[key]
	if (value == nil) then
		return default
	end
	return value
end

function PANEL:getModelPanel()
	return nut.gui.charCreate.model
end

function PANEL:updateModelPanel()
	nut.gui.charCreate:updateModel()
end

function PANEL:shouldSkip()
	return false
end

function PANEL:onSkip()
end

function PANEL:addLabel(text)
	local label = self:Add("DLabel")
	label:SetFont("nutCharButtonFont")
	label:SetText(L(text):upper())
	label:SizeToContents()
	label:Dock(TOP)
	return label
end

vgui.Register("nutCharacterCreateStep", PANEL, "DScrollPanel")
