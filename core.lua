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
    enabled = true,
    customWhitelist = {},
    customBlacklist = {},
    minimap = { hide = false, minimapPos = 45 },
    raidIconFriends = {}, -- map of friendName -> iconIndex (1-8)
    treatOwnBNetAsEligible = true, -- treat your own Battle.net characters as eligible/friends
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

------------------------------------------------------------
-- Raid icon helpers
------------------------------------------------------------
addon.raidIconNames = {
    [1] = "Star",
    [2] = "Circle",
    [3] = "Diamond",
    [4] = "Triangle",
    [5] = "Moon",
    [6] = "Square",
    [7] = "Cross",
    [8] = "Skull",
}

addon.DebugPrint("core.lua loaded")
