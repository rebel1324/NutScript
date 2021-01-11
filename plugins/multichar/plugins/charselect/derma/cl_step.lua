-- This file contains the panel that you should inherit from if you are adding
-- a new step for the character creation process.

local PANEL = {}

PANEL.isCharCreateStep = true

function PANEL:Init()
	self:Dock(FILL)
	self:SetPaintBackground(false)
	self:SetVisible(false)
end

-- Called when this step is made visible.
function PANEL:onDisplay()
end

-- Requests for the next step to be shown, or to finish character creation
-- if this is the final step.
function PANEL:next()
	nut.gui.charCreate:nextStep()
end

-- Requests for the previous step to be shown.
function PANEL:previous()
	nut.gui.charCreate:previousStep()
end

-- Runs the character validation given the name of a character variable.
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

-- Returns whether or not the input for this form is valid. You should override
-- this if you need custom validation.
function PANEL:validate()
	return true
end

-- Sets the value of a character variable corresponding to key for the character
-- that is going to be created.
function PANEL:setContext(key, value)
	nut.gui.charCreate.context[key] = value
end

-- Removes any set character variables for the character that is going to be
-- created.
function PANEL:clearContext()
	nut.gui.charCreate.context = {}
end

-- Returns the set character variable corresponding to key. If it does not
-- exist, then default (which is nil if not set) is returned.
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

-- Returns the model panel to the left of the step view.
function PANEL:getModelPanel()
	return nut.gui.charCreate.model
end

-- Requests that the model panel for the character is updated.
function PANEL:updateModelPanel()
	nut.gui.charCreate:updateModel()
end

-- Return true if this step should be skipped, false otherwise. This should
-- not have any side effects. Side effects go in onSkip.
function PANEL:shouldSkip()
	return false
end

-- Called if this step has been skipped over.
function PANEL:onSkip()
end

-- Helper function to add a label that is docked at the top of the step.
function PANEL:addLabel(text)
	local label = self:Add("DLabel")
	label:SetFont("nutCharButtonFont")
	label:SetText(L(text):upper())
	label:SizeToContents()
	label:Dock(TOP)
	return label
end

function PANEL:onHide()
end

vgui.Register("nutCharacterCreateStep", PANEL, "DScrollPanel")
