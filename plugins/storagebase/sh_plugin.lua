PLUGIN.name = "Storage Base"
PLUGIN.author = "Cheesenut"
PLUGIN.desc = "Useful things for storage plugins."

STORAGE_DEFINITIONS = STORAGE_DEFINITIONS or {}
PLUGIN.definitions = STORAGE_DEFINITIONS

nut.util.include("sv_storage.lua")
nut.util.include("sv_networking.lua")
nut.util.include("sv_access_rules.lua")
nut.util.include("cl_networking.lua")

nutStorageBase = PLUGIN
