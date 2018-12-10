function GM:LoadFonts(font, genericFont)
	surface.CreateFont("nut3D2DFont", {
		font = font,
		size = 2048,
		extended = true,
		weight = 1000
	})

	surface.CreateFont("nutTitleFont", {
		font = font,
		size = ScreenScale(30),
		extended = true,
		weight = 1000
	})

	surface.CreateFont("nutSubTitleFont", {
		font = font,
		size = ScreenScale(18),
		extended = true,
		weight = 500
	})

	surface.CreateFont("nutMenuButtonFont", {
		font = font,
		size = ScreenScale(14),
		extended = true,
		weight = 1000
	})

	surface.CreateFont("nutMenuButtonLightFont", {
		font = font,
		size = ScreenScale(14),
		extended = true,
		weight = 200
	})

	surface.CreateFont("nutToolTipText", {
		font = font,
		size = 20,
		extended = true,
		weight = 500
	})

	surface.CreateFont("nutDynFontSmall", {
		font = font,
		size = ScreenScale(22),
		extended = true,
		weight = 1000
	})

	surface.CreateFont("nutDynFontMedium", {
		font = font,
		size = ScreenScale(28),
		extended = true,
		weight = 1000
	})

	surface.CreateFont("nutDynFontBig", {
		font = font,
		size = ScreenScale(48),
		extended = true,
		weight = 1000
	})

	-- The more readable font.
	font = genericFont

	surface.CreateFont("nutCleanTitleFont", {
		font = font,
		size = 200,
		extended = true,
		weight = 1000
	})

	surface.CreateFont("nutHugeFont", {
		font = font,
		size = 72,
		extended = true,
		weight = 1000
	})

	surface.CreateFont("nutBigFont", {
		font = font,
		size = 36,
		extended = true,
		weight = 1000
	})

	surface.CreateFont("nutMediumFont", {
		font = font,
		size = 25,
		extended = true,
		weight = 1000
	})

	surface.CreateFont("nutMediumLightFont", {
		font = font,
		size = 25,
		extended = true,
		weight = 200
	})

	surface.CreateFont("nutGenericFont", {
		font = font,
		size = 20,
		extended = true,
		weight = 1000
	})

	surface.CreateFont("nutGenericLightFont", {
		font = font,
		size = 20,
		extended = true,
		weight = 500
	})

	surface.CreateFont("nutChatFont", {
		font = font,
		size = math.max(ScreenScale(7), 17),
		extended = true,
		weight = 200
	})

	surface.CreateFont("nutChatFontItalics", {
		font = font,
		size = math.max(ScreenScale(7), 17),
		extended = true,
		weight = 200,
		italic = true
	})

	surface.CreateFont("nutChatFontBold", {
		font = font,
		size = math.max(ScreenScale(7), 17),
		extended = true,
		weight = 800,
	})

	surface.CreateFont("nutSmallFont", {
		font = font,
		size = math.max(ScreenScale(6), 17),
		extended = true,
		weight = 500
	})

	surface.CreateFont("nutItemDescFont", {
		font = font,
		size = math.max(ScreenScale(6), 17),
		extended = true,
		shadow = true,
		weight = 500
	})

	surface.CreateFont("nutSmallBoldFont", {
		font = font,
		size = math.max(ScreenScale(8), 20),
		extended = true,
		weight = 800
	})

	surface.CreateFont("nutItemBoldFont", {
		font = font,
		shadow = true,
		size = math.max(ScreenScale(8), 20),
		extended = true,
		weight = 800
	})

	surface.CreateFont("nutIconsSmall", {
		font = "fontello",
		size = 22,
		extended = true,
		weight = 500
	})

	surface.CreateFont("nutIconsMedium", {
		font = "fontello",
		extended = true,
		size = 28,
		weight = 500
	})

	surface.CreateFont("nutIconsBig", {
		font = "fontello",
		extended = true,
		size = 48,
		weight = 500
	})

	surface.CreateFont("nutIconsSmallNew", {
		font = "nsicons",
		size = 22,
		extended = true,
		weight = 500
	})

	surface.CreateFont("nutIconsMediumNew", {
		font = "nsicons",
		extended = true,
		size = 28,
		weight = 500
	})

	surface.CreateFont("nutIconsBigNew", {
		font = "nsicons",
		extended = true,
		size = 48,
		weight = 500
	})

	surface.CreateFont("nutNoticeFont", {
		font = genericFont,
		size = 16,
		weight = 500,
		extended = true,
		antialias = true
	})
end

function GM:CreateLoadingScreen()
	if (IsValid(nut.gui.loading)) then
		nut.gui.loading:Remove()
	end

	local loader = vgui.Create("EditablePanel")
	loader:ParentToHUD()
	loader:Dock(FILL)
	loader.Paint = function(this, w, h)
		surface.SetDrawColor(0, 0, 0)
		surface.DrawRect(0, 0, w, h)
	end

	local label = loader:Add("DLabel")
	label:Dock(FILL)
	label:SetText(L"loading")
	label:SetFont("nutNoticeFont")
	label:SetContentAlignment(5)
	label:SetTextColor(color_white)
	label:InvalidateLayout(true)
	label:SizeToContents()

	timer.Simple(5, function()
		if (IsValid(nut.gui.loading)) then
			local fault = getNetVar("dbError")

			if (fault) then
				label:SetText(fault and L"dbError" or L"loading")

				local label = loader:Add("DLabel")
				label:DockMargin(0, 64, 0, 0)
				label:Dock(TOP)
				label:SetFont("nutSubTitleFont")
				label:SetText(fault)
				label:SetContentAlignment(5)
				label:SizeToContentsY()
				label:SetTextColor(Color(255, 50, 50))
			end
		end
	end)

	nut.gui.loading = loader
end

function GM:ShouldCreateLoadingScreen()
	return not IsValid(nut.gui.loading)
end

function GM:InitializedConfig()
	hook.Run("LoadFonts", nut.config.get("font"), nut.config.get("genericFont"))

	if (not nut.config.loaded) then
		if (hook.Run("ShouldCreateLoadingScreen") ~= false) then
			hook.Run("CreateLoadingScreen")
		end
		nut.config.loaded = true
	end
end

function GM:CharacterListLoaded()
	local hasNotSeenIntro = not nut.localData.intro
	timer.Create("nutWaitUntilPlayerValid", 0.5, 0, function()
		if (not IsValid(LocalPlayer())) then return end
		timer.Remove("nutWaitUntilPlayerValid")

		-- Remove the loading indicator.
		if (IsValid(nut.gui.loading)) then
			nut.gui.loading:Remove()
		end

		-- Show the intro if needed, then show the character menu.
		local intro =
			hasNotSeenIntro and hook.Run("CreateIntroduction") or nil
		if (IsValid(intro)) then
			intro.nutLoadOldRemove = intro.OnRemove
			intro.OnRemove = function(panel)
				panel:nutLoadOldRemove()
				hook.Run("NutScriptLoaded")
			end
			nut.gui.intro = intro
		else
			hook.Run("NutScriptLoaded")
		end
	end)
end

function GM:InitPostEntity()
	nut.joinTime = RealTime() - 0.9716
end

function GM:CalcView(client, origin, angles, fov)
	local view = self.BaseClass:CalcView(client, origin, angles, fov)
	local entity = Entity(client:getLocalVar("ragdoll", 0))
	local ragdoll = client:GetRagdollEntity()

	if (client:GetViewEntity() ~= client) then return view end
	
	if (
		-- First person if the player has fallen over.
		(
			not client:ShouldDrawLocalPlayer()
			and IsValid(entity)
			and entity:IsRagdoll()
		)
		or
		-- Also first person if the player is dead.
		(not LocalPlayer():Alive() and IsValid(ragdoll))
	) then
	 	local ent = LocalPlayer():Alive() and entity or ragdoll
		local index = ent:LookupAttachment("eyes")

		if (index) then
			local data = ent:GetAttachment(index)

			if (data) then
				view = view or {}
				view.origin = data.Pos
				view.angles = data.Ang
			end
			
			return view
		end
	end

	return view
end

local blurGoal = 0
local blurValue = 0
local mathApproach = math.Approach

function GM:HUDPaintBackground()
	local localPlayer = LocalPlayer()
	local frameTime = FrameTime()
	local scrW, scrH = ScrW(), ScrH()

	-- Make screen blurry if blur local var is set.
	blurGoal = localPlayer:getLocalVar("blur", 0)
		+ (hook.Run("AdjustBlurAmount", blurGoal) or 0)
	if (blurValue ~= blurGoal) then
		blurValue = mathApproach(blurValue, blurGoal, frameTime * 20)
	end
	if (blurValue > 0 and not localPlayer:ShouldDrawLocalPlayer()) then
		nut.util.drawBlurAt(0, 0, scrW, scrH, blurValue)
	end

	self.BaseClass.PaintWorldTips(self.BaseClass)

	nut.menu.drawAll()
end

function GM:ShouldDrawEntityInfo(entity)
	if (entity:IsPlayer() or IsValid(entity:getNetVar("player"))) then
		return entity == LocalPlayer()
			and not LocalPlayer():ShouldDrawLocalPlayer()
	end
	return false
end

function GM:PlayerBindPress(client, bind, pressed)
	bind = bind:lower()
	
	if ((bind:find("use") or bind:find("attack")) and pressed) then
		local menu, callback = nut.menu.getActiveMenu()

		if (menu and nut.menu.onButtonPressed(menu, callback)) then
			return true
		elseif (bind:find("use") and pressed) then
			local data = {}
				data.start = client:GetShootPos()
				data.endpos = data.start + client:GetAimVector()*96
				data.filter = client
			local trace = util.TraceLine(data)
			local entity = trace.Entity

			if (
				IsValid(entity) and
				(entity:GetClass() == "nut_item" or entity.hasMenu == true)
			) then
				hook.Run("ItemShowEntityMenu", entity)
			end
		end
	elseif (bind:find("jump")) then
		nut.command.send("chargetup")
	elseif (bind:find("speed") and client:KeyDown(IN_WALK) and pressed) then
		if (LocalPlayer():Crouching()) then
			RunConsoleCommand("-duck")
		else
			RunConsoleCommand("+duck")
		end
	end
end

-- Called when use has been pressed on an item.
function GM:ItemShowEntityMenu(entity)
	for k, v in ipairs(nut.menu.list) do
		if (v.entity == entity) then
			table.remove(nut.menu.list, k)
		end
	end

	local options = {}
	local itemTable = entity:getItemTable()
	if (!itemTable) then return end -- MARK: This is the where error came from.

	local function callback(index)
		if (IsValid(entity)) then
			netstream.Start("invAct", index, entity)
		end
	end

	itemTable.player = LocalPlayer()
	itemTable.entity = entity

	for k, v in SortedPairs(itemTable.functions) do
		if (k == "combine") then continue end -- yeah, noob protection

		if (v.onCanRun) then
			if (v.onCanRun(itemTable) == false) then
				continue
			end
		end

		options[L(v.name or k)] = function()
			local send = true

			if (v.onClick) then
				send = v.onClick(itemTable)
			end

			if (v.sound) then
				surface.PlaySound(v.sound)
			end

			if (send != false) then
				callback(k)
			end
		end
	end

	if (table.Count(options) > 0) then
		entity.nutMenuIndex = nut.menu.add(options, entity)
	end

	itemTable.player = nil
	itemTable.entity = nil
end

function GM:SetupQuickMenu(menu)
	-- Performance
	menu:addCheck(L"cheapBlur", function(panel, state)
		if (state) then
			RunConsoleCommand("nut_cheapblur", "1")
		else
			RunConsoleCommand("nut_cheapblur", "0")
		end
	end, NUT_CVAR_CHEAP:GetBool())

	-- Language settings
	menu:addSpacer()

	local current

	for k, v in SortedPairs(nut.lang.stored) do
		local name = nut.lang.names[k]
		local name2 = k:sub(1, 1):upper()..k:sub(2)
		local enabled = NUT_CVAR_LANG:GetString():match(k)

		if (name) then
			name = name.." ("..name2..")"
		else
			name = name2
		end

		local button = menu:addCheck(name, function(panel)
			panel.checked = true
			
			if (IsValid(current)) then
				if (current == panel) then
					return
				end

				current.checked = false
			end

			current = panel
			RunConsoleCommand("nut_language", k)
		end, enabled)

		if (enabled and !IsValid(current)) then
			current = button
		end
	end
end

function GM:ShouldDrawLocalPlayer(client)
	if (IsValid(nut.gui.char) and nut.gui.char:IsVisible()) then
		return false
	end
end

function GM:DrawNutModelView(panel, ent)
	if (IsValid(ent.weapon)) then
		ent.weapon:DrawModel()
	end
end

function GM:ScreenResolutionChanged(oldW, oldH)
	RunConsoleCommand("fixchatplz")
	hook.Run("LoadFonts", nut.config.get("font"), nut.config.get("genericFont"))
end
