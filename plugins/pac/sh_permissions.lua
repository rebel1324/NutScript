nut.config.add(
	"pacGroups",
	"superadmin, admin",
	"Comma separated list of user groups (case sensitive!) for PAC.",
	nil,
	{category = PLUGIN.name}
)

nut.config.add(
	"pacFlag",
	"P",
	"The flag for using PAC. Leave blank to not use the flag.",
	nil,
	{category = PLUGIN.name}
)

-- Set up the flag corresponding to pacFlag config.
local flag = nut.config.get("pacFlag")
if (flag ~= "") then
	nut.flag.add(flag, "Access to PAC3.")
end

-- Get all user groups from the pacGroups config.
function PLUGIN:getAllowedUserGroups()
	local allowed = {}
	local groups = nut.config.get("pacGroups", "")
	for _, group in ipairs(string.Explode(",", groups)) do
		if (group ~= "") then
			group = string.Trim(group)
			allowed[group] = true
		end
	end
	return allowed
end

-- A user is allowed to use PAC if they have the flag or is in an allowed group.
function PLUGIN:isAllowedToUsePAC(client)
	local flag = nut.config.get("pacFlag", "")
	if (
		client:getChar() and
		flag ~= "" and
		client:getChar():hasFlags(flag)
	) then
		return true
	end

	local allowed = self:getAllowedUserGroups()
	if (allowed.admin and client:IsAdmin()) then return true end
	if (allowed.superadmin and client:IsSuperAdmin()) then return true end
	return allowed[client:GetUserGroup()] == true
end

-- Only allow PAC using the above function.
function PLUGIN:CanWearParts(client, file)
	return self:isAllowedToUsePAC(client)
end

function PLUGIN:PrePACEditorOpen(client)
	return self:isAllowedToUsePAC(client)
end

function PLUGIN:PrePACConfigApply(client)
	return self:isAllowedToUsePAC(client)
end
