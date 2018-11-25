net.Receive("nutStringReq", function()
	local id = net.ReadUInt(32)
	local title = net.ReadString()
	local subTitle = net.ReadString()
	local default = net.ReadString()

	if (title:sub(1, 1) == "@") then
		title = L(title:sub(2))
	end

	if (subTitle:sub(1, 1) == "@") then
		subTitle = L(subTitle:sub(2))
	end

	Derma_StringRequest(title, subTitle, default, function(text)
		net.Start("nutStringReq")
			net.WriteUInt(id, 32)
			net.WriteString(text)
		net.SendToServer()
	end)
end)
