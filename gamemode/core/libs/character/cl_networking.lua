netstream.Hook("charInfo", function(data, id, client)
	nut.char.loaded[id] = nut.char.new(data, id, client == nil and LocalPlayer() or client)
end)

netstream.Hook("charSet", function(key, value, id)
	id = id or (LocalPlayer():getChar() and LocalPlayer():getChar().id)
	
	local character = nut.char.loaded[id]

	if (character) then
		character.vars[key] = value
	end
end)

netstream.Hook("charVar", function(key, value, id)
	id = id or (LocalPlayer():getChar() and LocalPlayer():getChar().id)

	local character = nut.char.loaded[id]

	if (character) then
		local oldVar = character:getVar()[key]
		character:getVar()[key] = value

		hook.Run("OnCharVarChanged", character, key, oldVar, value)
	end
end)

netstream.Hook("charMenu", function(data, openNext)
	local oldCharList = nut.characters
	if (data) then
		nut.characters = data
		if (not oldCharList) then
			return hook.Run("CharacterListLoaded", data)
		end
		hook.Run("CharacterListUpdated", oldCharList, data)
	end

	OPENNEXT = openNext
	vgui.Create("nutCharMenu")
end)

netstream.Hook("charData", function(id, key, value)
	local character = nut.char.loaded[id]

	if (character) then
		character.vars.data = character.vars.data or {}
		character:getData()[key] = value
	end
end)

netstream.Hook("charDel", function(id)
	local isCurrentChar = LocalPlayer():getChar() and LocalPlayer():getChar():getID() == id

	nut.char.loaded[id] = nil

	for k, v in ipairs(nut.characters) do
		if (v == id) then
			table.remove(nut.characters, k)

			if (IsValid(nut.gui.char) and nut.gui.char.setupCharList) then
				nut.gui.char:setupCharList()
			end
		end
	end

	if (isCurrentChar and !IsValid(nut.gui.char)) then
		vgui.Create("nutCharMenu")
	end
end)

netstream.Hook("charKick", function(id, isCurrentChar)
	if (nut.gui.menu and nut.gui.menu:IsVisible()) then
		nut.gui.menu:Remove()
	end

	if (isCurrentChar and !IsValid(nut.gui.char)) then
		vgui.Create("nutCharMenu")
	end
end)
