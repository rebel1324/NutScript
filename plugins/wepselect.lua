local PLUGIN = PLUGIN
PLUGIN.name = "Weapon Select"
PLUGIN.author = "Chessnut"
PLUGIN.desc = "A replacement for the default weapon selection."

local IsValid, tonumber, FrameTime, Lerp, ScrW, ScrH, CurTime, ipairs = IsValid, tonumber, FrameTime, Lerp, ScrW, ScrH, CurTime, ipairs
local RunConsoleCommand, LocalPlayer, math, color_white, surface = RunConsoleCommand, LocalPlayer, math, color_white, surface
local pi = math.pi

if (CLIENT) then

	PLUGIN.index = PLUGIN.index or 1
	PLUGIN.deltaIndex = PLUGIN.deltaIndex or PLUGIN.index
	PLUGIN.infoAlpha = PLUGIN.infoAlpha or 0
	PLUGIN.alpha = PLUGIN.alpha or 0
	PLUGIN.alphaDelta = PLUGIN.alphaDelta or PLUGIN.alpha
	PLUGIN.fadeTime = PLUGIN.fadeTime or 0

	-- Player.GetWeapons may not be sequential, so this gives us the weapon
	-- as if we had sequential indices.
	function PLUGIN:getWeaponFromIndex(i)
		local index = 1
		for k, v in pairs(LocalPlayer():GetWeapons()) do
			if (index == i) then
				return v
			end
			index = index + 1
		end
		return NULL
	end

	function PLUGIN:HUDPaint()
		local frameTime = FrameTime()

		local fraction = self.alphaDelta
		if (fraction <= 0.01 and self.alpha == 0) then
			self.alphaDelta = 0	
			return
		else
			self.alphaDelta = Lerp(frameTime * 10, self.alphaDelta, self.alpha)
		end

		local shiftX = ScrW()*.02

		local client = LocalPlayer()
		local weapons = client:GetWeapons()
		local x, y = ScrW() * 0.5, ScrH() * 0.5
		local spacing = math.pi * 0.85
		local radius = 240 * self.alphaDelta

		self.deltaIndex = Lerp(frameTime * 12, self.deltaIndex, self.index)
		local index = self.deltaIndex
		local realIndex = 1

		for _, v in pairs(weapons) do
			local theta = (realIndex - index) * 0.1
			local color = ColorAlpha(
				realIndex == self.index
				and nut.config.get("color")
				or color_white, (255 - math.abs(theta * 3) * 255) * fraction
			)
			local lastY = 0

			if (self.markup and (realIndex == 1 or realIndex < self.index)) then
				local w, h = self.markup:Size()
				lastY = (h * fraction)
				if (realIndex == self.index - 1 or realIndex == 1) then
					self.infoAlpha = Lerp(frameTime * 5, self.infoAlpha, 255)
					self.markup:Draw(
						x + 6 + shiftX, y + 30,
						0, 0,
						self.infoAlpha * fraction
					)
				end

				if (self.index == 1) then
					lastY = 0
				end
			end

			surface.SetFont("nutSubTitleFont")
			
			local name = hook.Run("GetWeaponName", v) or v:GetPrintName():upper()
			local tx, ty = surface.GetTextSize(name)
			local scale = (1 - math.abs(theta*2))
			local matrix = Matrix()
			matrix:Translate(Vector(
				shiftX + x + math.cos(theta * spacing + pi) * radius + radius,
				y + lastY + math.sin(theta * spacing + pi) * radius - ty/2 ,
				1))
			matrix:Scale(Vector(1, 1, 0) * scale)
			cam.PushModelMatrix(matrix)
				nut.util.drawText(
					name,
					2, ty/2,
					color,
					0, 1,
					"nutSubTitleFont"
				)
			cam.PopModelMatrix()

			realIndex = realIndex + 1
		end

		if (self.fadeTime < CurTime() and self.alpha > 0) then
			self.alpha = 0
		end
	end

	local weaponInfo = {
		"Author",
		"Contact",
		"Purpose",
		"Instructions"
	}

	function PLUGIN:onIndexChanged()
		self.alpha = 1
		self.fadeTime = CurTime() + 5
		
		local client = LocalPlayer()
		local weapon
		local index = 1
		for k, v in pairs(client:GetWeapons()) do
			if (index == self.index) then
				weapon = v
				break
			end
			index = index + 1
		end

		self.markup = nil
		self.infoAlpha = 0

		if (IsValid(weapon)) then
			local text = ""

			for k, v in ipairs(weaponInfo) do
				if (weapon[v] and weapon[v]:find("%S")) then
					local color = nut.config.get("color")
					text = text
						.."<font=nutItemBoldFont><color="
						..color.r..","..color.g..","..color.b..">"
						..L(v)..
						"</font></color>\n"..weapon[v].."\n"
				end
			end

			if (text ~= "") then
				self.markup = markup.Parse(
					"<font=nutItemDescFont>"..text,
					ScrW() * 0.3
				)
			end

			local source, pitch = hook.Run("WeaponCycleSound")
				or "common/talk.wav"
			client:EmitSound(source or "common/talk.wav", 45, pitch or 180)
		end
	end

	function PLUGIN:PlayerBindPress(client, bind, pressed)
		local weapon = client:GetActiveWeapon()
		local lPly = LocalPlayer()
		if (client:InVehicle()) then return end
		if (
			IsValid(weapon) and
			weapon:GetClass() == "weapon_physgun" and
			client:KeyDown(IN_ATTACK)
		) then return end
		if (hook.Run("CanPlayerChooseWeapon") == false) then return end
		if (not pressed) then return end

		bind = bind:lower()

		local total = table.Count(client:GetWeapons())

		if (bind:find("invprev")) then
			self.index = self.index - 1
			if (self.index < 1) then
				self.index = total
			end

			self:onIndexChanged()
			return true
		elseif (bind:find("invnext")) then
			self.index = self.index + 1
			if (self.index > total) then
				self.index = 1
			end

			self:onIndexChanged()
			return true
		elseif (bind:find("slot")) then
			self.index = math.Clamp(
				tonumber(bind:match("slot(%d)")) or 1,
				1, total
			)
			self:onIndexChanged()
			return true
		elseif (bind:find("attack") and self.alpha > 0) then
			local weapon = self:getWeaponFromIndex(self.index)
			if (not IsValid(weapon)) then
				self.alpha = 0
				self.infoAlpha = 0
				return
			end

			local source, pitch = hook.Run("WeaponSelectSound", weapon)
				or "common/talk.wav"
			lPly:EmitSound(source, 45, pitch or 200)
			lPly:SelectWeapon(weapon:GetClass())

			self.alpha = 0
			self.infoAlpha = 0
			return true
		end
	end
end

local meta = FindMetaTable("Player")

function meta:SelectWeapon(class)
	if (!self:HasWeapon(class)) then return end
	
	self.doWeaponSwitch = self:GetWeapon(class);
end

function PLUGIN:StartCommand(client, cmd)
	if (!IsValid(client.doWeaponSwitch)) then return end

	cmd:SelectWeapon(client.doWeaponSwitch)

	if ( client:GetActiveWeapon() == client.doWeaponSwitch ) then
		client.doWeaponSwitch = nil
	end
end
