netstream.Hook("charInfo", function(data, id, client)
	nut.char.loaded[id] = nut.char.new(data, id, client == nil and LocalPlayer() or client)
end)

netstream.Hook("charSet", function(key, value, id)
	id = id or (LocalPlayer():getChar() and LocalPlayer():getChar().id)
	
	local character = nut.char.loaded[id]

	if (character) then
		local oldValue = character.vars[key]
		character.vars[key] = value
		hook.Run("OnCharVarChanged", character, key, oldValue, value)
	end
end)

netstream.Hook("charVar", function(key, value, id)
	id = id or (LocalPlayer():getChar() and LocalPlayer():getChar().id)

	local character = nut.char.loaded[id]

	if (character) then
		local oldVar = character:getVar()[key]
		character:getVar()[key] = value

		hook.Run("OnCharLocalVarChanged", character, key, oldVar, value)
	end
end)

netstream.Hook("charData", function(id, key, value)
	local character = nut.char.loaded[id]

	if (character) then
		character.vars.data = character.vars.data or {}
		character:getData()[key] = value
	end
end)

netstream.Hook("charKick", function(id, isCurrentChar)
	hook.Run("KickedFromCharacter", id, isCurrentChar)
end)
