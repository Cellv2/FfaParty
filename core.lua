-- core.lua - Core utilities and shared functions
local addonName, addon = ...

------------------------------------------------------------
-- Default settings
------------------------------------------------------------
addon.defaults = {
    lootWithFriends = "freeforall",
    lootWithOthers = "group",
    ignoreRaids = true,
    showMessages = true,
    debug = false,
    customWhitelist = {},
    customBlacklist = {},
    minimap = { hide = false, minimapPos = 45 }
}

------------------------------------------------------------
-- Debug print helper
------------------------------------------------------------
function addon.DebugPrint(msg)
    if FFAPartyDB and FFAPartyDB.debug then
        print("|cff00ff00[FFA Party DEBUG]|r " .. msg)
    end
end

------------------------------------------------------------
-- Initialize saved variables with defaults
------------------------------------------------------------
function addon.InitializeDB()
    FFAPartyDB = FFAPartyDB or {}
    for k, v in pairs(addon.defaults) do
        if FFAPartyDB[k] == nil then
            FFAPartyDB[k] = v
        end
    end
    addon.DebugPrint("Database initialized with defaults")
end

------------------------------------------------------------
-- Utility: normalize names (strip realm if present)
------------------------------------------------------------
function addon.NormalizeName(name)
    if not name then
        return nil
    end
    local base = name:match("^(.-)%-.+$")
    return base or name
end

------------------------------------------------------------
-- Loot method mapping
------------------------------------------------------------
addon.lootMethodMap = {
    freeforall = 0,
    roundrobin = 1,
    master = 2,
    group = 3,
    needbeforegreed = 4
}

function addon.NormalizeLootMethod(method)
    if type(method) == "string" then
        return addon.lootMethodMap[method]
    end
    return method
end

addon.DebugPrint("core.lua loaded")
