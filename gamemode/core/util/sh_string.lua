-- Returns whether or a not a string matches.
function nut.util.stringMatches(a, b)
	if (a and b) then
		local a2, b2 = a:lower(), b:lower()

		-- Check if the actual letters match.
		if (a == b) then return true end
		if (a2 == b2) then return true end

		-- Be less strict and search.
		if (a:find(b)) then return true end
		if (a2:find(b2)) then return true end
	end

	return false
end
