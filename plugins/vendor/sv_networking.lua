local PLUGIN = PLUGIN
local EDITOR = nut.util.include("sv_editor.lua")

util.AddNetworkString("nutVendorAllowClass")
util.AddNetworkString("nutVendorAllowFaction")
util.AddNetworkString("nutVendorExit")
util.AddNetworkString("nutVendorEdit")
util.AddNetworkString("nutVendorMode")
util.AddNetworkString("nutVendorMoney")
util.AddNetworkString("nutVendorOpen")
util.AddNetworkString("nutVendorPrice")
util.AddNetworkString("nutVendorStock")
util.AddNetworkString("nutVendorMaxStock")
util.AddNetworkString("nutVendorSync")
util.AddNetworkString("nutVendorTrade")

net.Receive("nutVendorExit", function(_, client)
	local vendor = client.nutVendor
	if (IsValid(vendor)) then
		vendor:removeReceiver(client, true)
	end
end)

net.Receive("nutVendorEdit", function(_, client)
	local key = net.ReadString()

	if (not client:IsAdmin()) then return end

	local vendor = client.nutVendor
	if (not IsValid(vendor) or not EDITOR[key]) then return end
	EDITOR[key](vendor, client, key)

	PLUGIN:saveVendors()
end)

net.Receive("nutVendorTrade", function(_, client)
	local uniqueID = net.ReadString()
	local isSellingToVendor = net.ReadBool()

	if (not client:getChar() or not client:getChar():getInv()) then return end

	if ((client.nutVendorTry or 0) < CurTime()) then
		client.nutVendorTry = CurTime() + 0.1
	else
		return
	end

	local found
	local entity = client.nutVendor

	if (
		not IsValid(entity) or
		client:GetPos():Distance(entity:GetPos()) > 192
	) then
		return
	end

	if (not hook.Run("CanPlayerAccessVendor", client, entity)) then
		return
	end

	hook.Run("VendorTradeAttempt", client, entity, uniqueID, isSellingToVendor)
end)
