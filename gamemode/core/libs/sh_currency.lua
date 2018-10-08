--[[--
This module contains all the functions that handle currency.

You can set your gamemode's currency by using nut.currency.set. If no currency
is set, the framework will use dollar ("$") as the default currency.

]]
-- @module nut.currency

nut.currency = nut.currency or {}
nut.currency.symbol = nut.currency.symbol or "$"
nut.currency.singular = nut.currency.singular or "dollar"
nut.currency.plural = nut.currency.plural or "dollars"

--- Sets the gamemode currency, which is going to be used.
-- This function changes the default values of `nut.currency.symbol`,
-- `nut.currency.singular` and `nut.currency.plural`.
-- @string symbol the currency's symbol.
-- @string singular singular.
-- @string plural plural.
-- @return nothing.
-- @usage nut.currency.set("£", "coin", "coins")

function nut.currency.set(symbol, singular, plural)
	nut.currency.symbol = symbol
	nut.currency.singular = singular
	nut.currency.plural = plural
end

--- Gets the gamemode currency that is currently being used.
-- This functions returns a string with a specific amount along with the symbol
-- and the currency singular or plural.
-- @param amount a number.
-- @return a string.

function nut.currency.get(amount)
	if (amount == 1) then
		return nut.currency.symbol.."1 "..nut.currency.singular
	else
		return nut.currency.symbol..amount.." "..nut.currency.plural
	end
end

--- Spawns a certain amount of money.
-- This function creates a money entity on a certain position and angle.
-- @param pos a vector.
-- @param amount a number.
-- @param angle an angle.
-- @return the entity that was created.

function nut.currency.spawn(pos, amount, angle)
	if (!pos) then
		print("[Nutscript] Can't create currency entity: Invalid Position")
	elseif (!amount or amount < 0) then
		print("[Nutscript] Can't create currency entity: Invalid Amount of money")
	end

	local money = ents.Create("nut_money")
	money:SetPos(pos)
	-- Double check for negative.
	money:setNetVar("amount", math.Round(math.abs(amount)))
	money:SetAngles(angle or Angle(0, 0, 0))
	money:Spawn()
	money:Activate()

	return money
end

function GM:OnPickupMoney(client, moneyEntity)
	if (moneyEntity and moneyEntity:IsValid()) then
		local amount = moneyEntity:getAmount()

		client:getChar():giveMoney(amount)
		client:notifyLocalized("moneyTaken", nut.currency.get(amount))
	end
end

do
	local character = nut.meta.character

	function character:hasMoney(amount)
		if (amount < 0) then
			print("Negative Money Check Received.")	
		end

		return self:getMoney() >= amount
	end

	function character:giveMoney(amount, kek)
		if (!kek) then
			nut.log.add(self:getPlayer(), "money", amount)
		end
		
		self:setMoney(self:getMoney() + amount)

		return true
	end

	function character:takeMoney(amount)
		nut.log.add(self:getPlayer(), "money", -amount)
		amount = math.abs(amount)
		self:giveMoney(-amount, true)

		return true
	end
end