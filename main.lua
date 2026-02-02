-- FFAParty.lua
-- main.lua
local addonName, addon = ...
addon = addon or {}
_G[addonName] = addon
print("FFA Party: main.lua loaded for", addonName, "addon table:", addon)

local f = CreateFrame("Frame")

------------------------------------------------------------
-- Default settings
------------------------------------------------------------
local defaults = {
    lootWithFriends = "freeforall",
    lootWithOthers = "group",
    ignoreRaids = true,
    showMessages = true,
    debug = false,
    customFriends = {} -- manual whitelist
}

------------------------------------------------------------
-- Loot method mapping
------------------------------------------------------------
local lootMethodMap = {
    freeforall = 0,
    roundrobin = 1,
    master = 2,
    group = 3,
    needbeforegreed = 4
}

------------------------------------------------------------
-- Utility: normalize names (strip realm if present)
------------------------------------------------------------
local function NormalizeName(name)
    if not name then
        return nil
    end
    local base = name:match("^(.-)%-.+$")
    return base or name
end

------------------------------------------------------------
-- Debug print helper
------------------------------------------------------------
local function DebugPrint(msg)
    -- if FFAPartyDB and FFAPartyDB.debug then
    print("|cff00ff00[FFA Party DEBUG]|r " .. msg)
    -- end
end

------------------------------------------------------------
-- Collect WoW friends
------------------------------------------------------------
local function GetWoWFriends()
    local friends = {}
    if C_FriendList and C_FriendList.GetNumFriends then
        for i = 1, C_FriendList.GetNumFriends() do
            local info = C_FriendList.GetFriendInfoByIndex(i)
            if info and info.name then
                friends[NormalizeName(info.name)] = true
            end
        end
    end
    return friends
end

------------------------------------------------------------
-- Collect Battle.net friends (not available in TBC Classic)
------------------------------------------------------------
local function GetBNetFriends()
    return {}
end

------------------------------------------------------------
-- Collect custom friends (manual whitelist)
------------------------------------------------------------
local function GetCustomFriends()
    local friends = {}
    if FFAPartyDB and FFAPartyDB.customFriends then
        for _, name in ipairs(FFAPartyDB.customFriends) do
            friends[NormalizeName(name)] = true
        end
    end
    return friends
end

------------------------------------------------------------
-- Collect current group members
------------------------------------------------------------
local function GetGroupMembers()
    local members = {}
    local num = GetNumGroupMembers()
    if num > 0 then
        local prefix = IsInRaid() and "raid" or "party"
        for i = 1, num do
            local unit = prefix .. i
            if UnitExists(unit) then
                local name = UnitName(unit)
                if name then
                    table.insert(members, NormalizeName(name))
                end
            end
        end
        table.insert(members, NormalizeName(UnitName("player")))
    end
    return members
end

------------------------------------------------------------
-- Check if group is only friends
------------------------------------------------------------
local function IsGroupOnlyFriends()
    local friends = {}
    for k in pairs(GetWoWFriends()) do
        friends[k] = true
    end
    for k in pairs(GetBNetFriends()) do
        friends[k] = true
    end
    for k in pairs(GetCustomFriends()) do
        friends[k] = true
    end

    for _, member in ipairs(GetGroupMembers()) do
        -- Skip the player themselves
        if member ~= NormalizeName(UnitName("player")) then
            if not friends[member] then
                DebugPrint("Non-friend detected in group: " .. (member or "unknown"))
                return false
            else
                DebugPrint("Friend matched: " .. (member or "unknown"))
            end
        end
    end

    return true
end

------------------------------------------------------------
-- Enforce loot method
------------------------------------------------------------
local function UpdateLootMethod()
    if not IsInGroup() then
        return
    end
    if not UnitIsGroupLeader("player") then
        return
    end
    if IsInRaid() and FFAPartyDB.ignoreRaids then
        DebugPrint("In raid, ignoring loot enforcement")
        return
    end

    local desiredLootKey = IsGroupOnlyFriends() and FFAPartyDB.lootWithFriends or FFAPartyDB.lootWithOthers
    local desiredLoot = lootMethodMap[desiredLootKey]

    local currentMethod = nil
    if C_PartyInfo and C_PartyInfo.GetLootMethod then
        currentMethod = C_PartyInfo.GetLootMethod()
    elseif GetLootMethod then
        currentMethod = GetLootMethod()
    end

    if currentMethod ~= desiredLoot then
        if C_PartyInfo and C_PartyInfo.SetLootMethod then
            C_PartyInfo.SetLootMethod(desiredLoot)
        elseif SetLootMethod then
            SetLootMethod(desiredLoot)
        end

        if FFAPartyDB.showMessages then
            print("Loot set to " .. desiredLootKey)
        end
        DebugPrint("Loot method updated to " .. desiredLootKey)
    else
        DebugPrint("Loot method already " .. desiredLootKey .. ", no change")
    end
end

------------------------------------------------------------
-- Event handling
------------------------------------------------------------
function f:OnEvent(event, ...)
    if event == "ADDON_LOADED" then
        local loadedAddon = ...
        if loadedAddon == addonName then
            if not FFAPartyDB then
                FFAPartyDB = {}
            end
            for k, v in pairs(defaults) do
                if FFAPartyDB[k] == nil then
                    FFAPartyDB[k] = v
                end
            end

            print("FFA Party: about to call CreateOptionsPanel; value is", addon.CreateOptionsPanel)
            if addon.CreateOptionsPanel then
                addon.CreateOptionsPanel()
            else
                print("FFA Party: CreateOptionsPanel is nil at ADDON_LOADED")
            end
            DebugPrint("FFA Party loaded and options initialized")
        end
    elseif event == "GROUP_ROSTER_UPDATE" or event == "PARTY_LEADER_CHANGED" or event == "PLAYER_ENTERING_WORLD" then
        UpdateLootMethod()
    end
end

f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("GROUP_ROSTER_UPDATE")
f:RegisterEvent("PARTY_LEADER_CHANGED")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:SetScript("OnEvent", f.OnEvent)
