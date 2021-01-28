PLUGIN.name = "F1 Menu"
PLUGIN.author = "Cheesenut"
PLUGIN.desc = "A menu that shows up upon pressing F1."

function PLUGIN:ShowHelp() return false end

if (SERVER) then return end

function PLUGIN:PlayerBindPress(client, bind, pressed)
	if (bind:lower():find("gm_showhelp") and pressed) then
		if (IsValid(nut.gui.menu)) then
			nut.gui.menu:remove()
		elseif (LocalPlayer():getChar()) then
			vgui.Create("nutMenu")
		end

		return true
	end
end

function PLUGIN:OnCharInfoSetup(infoPanel)
	-- Get the model entity from the F1 menu.
	if (not IsValid(infoPanel.model)) then return end
	local mdl = infoPanel.model
	local ent = mdl.Entity
	local client = LocalPlayer()

	-- If the player is alive with a weapon, add a weapon model to the
	-- character model in the F1 menu.
	if (not IsValid(client) or not client:Alive()) then return end
	local weapon = client:GetActiveWeapon()
	if (not IsValid(weapon)) then return end

	local weapModel = ClientsideModel(weapon:GetModel(), RENDERGROUP_BOTH)
	if (not IsValid(weapModel)) then return end

	weapModel:SetParent(ent)
	weapModel:AddEffects(EF_BONEMERGE)
	weapModel:SetSkin(weapon:GetSkin())
	weapModel:SetColor(weapon:GetColor())
	weapModel:SetNoDraw(true)
	ent.weapon = weapModel

	-- Then, change the animation so the character model holds the weapon.
	local act = ACT_MP_STAND_IDLE
	local model = ent:GetModel():lower()
	local class = nut.anim.getModelClass(model)
	local tree = nut.anim[class]

	if (not tree) then return end

	local subClass = weapon.HoldType or weapon:GetHoldType()
	subClass = HOLDTYPE_TRANSLATOR[subClass] or subClass

	if (tree[subClass] and tree[subClass][act]) then
		local branch = tree[subClass][act]
		local act2 = type(branch) == "table" and branch[1] or branch

		if (type(act2) == "string") then
			act2 = ent:LookupSequence(act2)
		else
			act2 = ent:SelectWeightedSequence(act2)
		end

		ent:ResetSequence(act2)
	end
end

