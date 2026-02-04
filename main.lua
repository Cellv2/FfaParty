-- main.lua
local addonName, addon = ...

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
    customWhitelist = {}, -- manual whitelist (full or base names)
    customBlacklist = {} -- manual blacklist (full or base names)
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

local function NormalizeLootMethod(method)
    if type(method) == "string" then
        return lootMethodMap[method]
    end
    return method
end

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
    if FFAPartyDB and FFAPartyDB.debug then
        print("|cff00ff00[FFA Party DEBUG]|r " .. msg)
    end
end

-- Expose debug print for other files
addon.DebugPrint = DebugPrint

------------------------------------------------------------
-- Collect WoW friends
------------------------------------------------------------
local function GetWoWFriends()
    local friends = {}
    if C_FriendList and C_FriendList.GetNumFriends then
        for i = 1, C_FriendList.GetNumFriends() do
            local info = C_FriendList.GetFriendInfoByIndex(i)
            if info and info.name then
                friends[info.name] = true
                friends[NormalizeName(info.name)] = true
            end
        end
    end
    return friends
end

------------------------------------------------------------
-- Collect Battle.net friends
------------------------------------------------------------
local function GetBNetFriends()
    local friends = {}
    if BNGetNumFriends then
        for i = 1, BNGetNumFriends() do
            local accountName = select(2, BNGetFriendInfo(i))
            if accountName then
                friends[accountName] = true
                friends[NormalizeName(accountName)] = true
            end
            local numToons = BNGetNumFriendToons and BNGetNumFriendToons(i) or 0
            for t = 1, numToons do
                local toonName, toonRealm = BNGetFriendToonInfo(i, t)
                if toonName then
                    local full = toonRealm and (toonName .. "-" .. toonRealm) or toonName
                    friends[full] = true
                    friends[NormalizeName(full)] = true
                end
            end
        end
    end
    return friends
end

------------------------------------------------------------
-- Custom whitelist / blacklist
------------------------------------------------------------
local function GetCustomWhitelist()
    local t = {}
    if FFAPartyDB and FFAPartyDB.customWhitelist then
        for _, name in ipairs(FFAPartyDB.customWhitelist) do
            t[name] = true
            t[NormalizeName(name)] = true
        end
    end
    return t
end

local function GetCustomBlacklist()
    local t = {}
    if FFAPartyDB and FFAPartyDB.customBlacklist then
        for _, name in ipairs(FFAPartyDB.customBlacklist) do
            t[name] = true
            t[NormalizeName(name)] = true
        end
    end
    return t
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
                local name, realm = UnitName(unit)
                if name then
                    local full = realm and realm ~= "" and (name .. "-" .. realm) or name
                    table.insert(members, full)
                end
            end
        end
        -- In parties, player may not be in party1..n
        if not IsInRaid() then
            local name, realm = UnitName("player")
            if name then
                local full = realm and realm ~= "" and (name .. "-" .. realm) or name
                table.insert(members, full)
            end
        end
    end
    return members
end

------------------------------------------------------------
-- Friend resolution with whitelist/blacklist and realm safety
------------------------------------------------------------
local function IsFriend(fullName, baseName, whitelist, blacklist, autoFriends)
    -- blacklist always wins
    if blacklist[fullName] or blacklist[baseName] then
        return false
    end

    -- whitelist overrides everything else
    if whitelist[fullName] or whitelist[baseName] then
        return true
    end

    -- auto-friends (WoW + BNet)
    if autoFriends[fullName] or autoFriends[baseName] then
        return true
    end

    return false
end

------------------------------------------------------------
-- Check if group is only friends
------------------------------------------------------------
local function IsGroupOnlyFriends()
    local autoFriends = {}

    for k in pairs(GetWoWFriends()) do
        autoFriends[k] = true
    end
    for k in pairs(GetBNetFriends()) do
        autoFriends[k] = true
    end

    local whitelist = GetCustomWhitelist()
    local blacklist = GetCustomBlacklist()

    local playerName, playerRealm = UnitName("player")
    local playerFull = playerRealm and playerRealm ~= "" and (playerName .. "-" .. playerRealm) or playerName

    for _, member in ipairs(GetGroupMembers()) do
        if member ~= playerFull then
            local full = member
            local base = NormalizeName(member)
            if not IsFriend(full, base, whitelist, blacklist, autoFriends) then
                DebugPrint("Non-friend detected in group: " .. (full or "unknown"))
                return false
            else
                DebugPrint("Friend matched: " .. (full or "unknown"))
            end
        end
    end

    return true
end

------------------------------------------------------------
-- Enforce loot method
------------------------------------------------------------
function addon.UpdateLootMethod()
    if not IsInGroup() then
        DebugPrint("Not in group; skipping loot enforcement")
        return
    end
    if not UnitIsGroupLeader("player") then
        DebugPrint("Not group leader; skipping loot enforcement")
        return
    end
    if IsInRaid() and FFAPartyDB.ignoreRaids then
        DebugPrint("In raid, ignoring loot enforcement")
        return
    end

    local desiredLootKey = IsGroupOnlyFriends() and FFAPartyDB.lootWithFriends or FFAPartyDB.lootWithOthers
    local desiredLoot = lootMethodMap[desiredLootKey]

    local currentMethod
    if C_PartyInfo and C_PartyInfo.GetLootMethod then
        currentMethod = C_PartyInfo.GetLootMethod()
    else
        currentMethod = select(1, GetLootMethod())
    end
    currentMethod = NormalizeLootMethod(currentMethod)

    if currentMethod ~= desiredLoot then
        if C_PartyInfo and C_PartyInfo.SetLootMethod then
            C_PartyInfo.SetLootMethod(desiredLoot)
        elseif SetLootMethod then
            SetLootMethod(desiredLoot)
        end

        if FFAPartyDB.showMessages then
            print("FFA Party: loot set to " .. desiredLootKey)
        end
        DebugPrint("Loot method updated to " .. desiredLootKey)
    else
        DebugPrint("Loot method already " .. desiredLootKey .. ", no change")
    end
end

------------------------------------------------------------
-- Force refresh helper (exposed)
------------------------------------------------------------
function addon.ForceRefresh()
    DebugPrint("Force refresh requested")
    addon.UpdateLootMethod()
    if FFAPartyDB.showMessages then
        print("FFA Party: forced refresh complete")
    end
end

------------------------------------------------------------
-- Debounced friend-list handling
------------------------------------------------------------
local friendUpdatePending = false
local function HandleFriendUpdate()
    if friendUpdatePending then
        DebugPrint("Friend update already pending; skipping")
        return
    end
    friendUpdatePending = true
    DebugPrint("Scheduling friend-list recheck")
    C_Timer.After(0.5, function()
        friendUpdatePending = false
        DebugPrint("Running friend-list recheck")
        addon.UpdateLootMethod()
    end)
end

------------------------------------------------------------
-- Event handling
------------------------------------------------------------
function f:OnEvent(event, ...)
    if event == "ADDON_LOADED" then
        local loadedAddon = ...
        if loadedAddon == addonName then
            FFAPartyDB = FFAPartyDB or {}
            for k, v in pairs(defaults) do
                if FFAPartyDB[k] == nil then
                    FFAPartyDB[k] = v
                end
            end

            if addon.CreateOptionsPanel then
                addon.CreateOptionsPanel()
            end

            if addon.CreateMinimapButton then
                addon.CreateMinimapButton()
            end

            if addon.InitFriendsUI then
                addon.InitFriendsUI()
            end

            DebugPrint("FFA Party loaded and options/minimap/friends UI initialized")
            DebugPrint("main.lua loaded for " .. addonName)
        end

    elseif event == "GROUP_ROSTER_UPDATE" or event == "PARTY_LEADER_CHANGED" or event == "PLAYER_ENTERING_WORLD" then
        DebugPrint("Group/leader/world event: " .. event)
        addon.UpdateLootMethod()

    elseif event == "FRIENDLIST_UPDATE" then
        DebugPrint("Received FRIENDLIST_UPDATE")
        HandleFriendUpdate()

    elseif event == "BN_FRIEND_ACCOUNT_ONLINE" or event == "BN_FRIEND_ACCOUNT_OFFLINE" then
        DebugPrint("Received Battle.net friend event: " .. event)
        HandleFriendUpdate()
    end
end

f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("GROUP_ROSTER_UPDATE")
f:RegisterEvent("PARTY_LEADER_CHANGED")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("FRIENDLIST_UPDATE")
f:RegisterEvent("BN_FRIEND_ACCOUNT_ONLINE")
f:RegisterEvent("BN_FRIEND_ACCOUNT_OFFLINE")

f:SetScript("OnEvent", f.OnEvent)
