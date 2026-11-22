-- main.lua
local addonName, addon = ...

local f = CreateFrame("Frame")

-- Set to true for verbose debug logging (not exposed in UI)
local VERBOSE_DEBUG = false

------------------------------------------------------------
-- Collect WoW friends
------------------------------------------------------------
local function GetWoWFriends()
    local friends = {}
    if C_FriendList and C_FriendList.GetNumFriends then
        for i = 1, C_FriendList.GetNumFriends() do
            local info = C_FriendList.GetFriendInfoByIndex(i)
            if info and info.name then
                friends[info.name:lower()] = true
                friends[addon.NormalizeName(info.name):lower()] = true
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
    if C_BattleNet and C_BattleNet.GetFriendAccountInfo and BNGetNumFriends then
        local numFriends = BNGetNumFriends()
        for i = 1, numFriends do
            local accountInfo = C_BattleNet.GetFriendAccountInfo(i)
            if accountInfo then
                -- Add Battle.net account name if available
                if accountInfo.accountName then
                    friends[accountInfo.accountName:lower()] = true
                    friends[addon.NormalizeName(accountInfo.accountName):lower()] = true
                end
                
                -- Add all their game accounts (characters)
                if accountInfo.gameAccountInfo then
                    local characterName = accountInfo.gameAccountInfo.characterName
                    local realmName = accountInfo.gameAccountInfo.realmName
                    
                    if characterName then
                        local full = realmName and (characterName .. "-" .. realmName) or characterName
                        friends[full:lower()] = true
                        friends[addon.NormalizeName(full):lower()] = true
                    end
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
            t[name:lower()] = true
            t[addon.NormalizeName(name):lower()] = true
        end
    end
    return t
end

local function GetCustomBlacklist()
    local t = {}
    if FFAPartyDB and FFAPartyDB.customBlacklist then
        for _, name in ipairs(FFAPartyDB.customBlacklist) do
            t[name:lower()] = true
            t[addon.NormalizeName(name):lower()] = true
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
                local name = addon.UnitCharacterName(unit)
                if name then
                    table.insert(members, name)
                end
            end
        end
        -- In parties, player may not be in party1..n
        if not IsInRaid() then
            local name = addon.UnitCharacterName("player")
            if name then
                table.insert(members, name)
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
    if blacklist[fullName:lower()] or blacklist[baseName:lower()] then
        return false
    end

    -- whitelist overrides everything else
    if whitelist[fullName:lower()] or whitelist[baseName:lower()] then
        return true
    end

    -- auto-friends (WoW + BNet)
    if autoFriends[fullName:lower()] or autoFriends[baseName:lower()] then
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

    local playerFull = addon.UnitCharacterName("player")

    local num = GetNumGroupMembers()
    if num > 0 then
        local prefix = IsInRaid() and "raid" or "party"
        for i = 1, num do
            local unit = prefix .. i
            if UnitExists(unit) then
                local full = addon.UnitCharacterName(unit)
                if full then
                    if full ~= playerFull then
                        local base = addon.NormalizeName(full)
                        
                        if not IsFriend(full, base, whitelist, blacklist, autoFriends) then
                            addon.DebugPrint("Non-friend detected in group: " .. (full or "unknown"))
                            return false
                        else
                            if VERBOSE_DEBUG then
                                addon.DebugPrint("Friend matched: " .. (full or "unknown"))
                            end
                        end
                    end
                end
            end
        end
    end

    return true
end

------------------------------------------------------------
-- Enforce loot method
------------------------------------------------------------
function addon.UpdateLootMethod()
    if not FFAPartyDB.enabled then
        if VERBOSE_DEBUG then
            addon.DebugPrint("Addon disabled; skipping loot enforcement")
        end
        return
    end
    if not IsInGroup() then
        if VERBOSE_DEBUG then
            addon.DebugPrint("Not in group; skipping loot enforcement")
        end
        return
    end
    if not UnitIsGroupLeader("player") then
        if VERBOSE_DEBUG then
            addon.DebugPrint("Not group leader; skipping loot enforcement")
        end
        return
    end
    if IsInRaid() and FFAPartyDB.ignoreRaids then
        addon.DebugPrint("In raid, ignoring loot enforcement")
        return
    end

    local desiredLootKey = IsGroupOnlyFriends() and FFAPartyDB.lootWithFriends or FFAPartyDB.lootWithOthers
    local desiredLoot = addon.lootMethodMap[desiredLootKey]

    local currentMethod
    if C_PartyInfo and C_PartyInfo.GetLootMethod then
        currentMethod = C_PartyInfo.GetLootMethod()
    else
        currentMethod = select(1, GetLootMethod())
    end
    currentMethod = addon.NormalizeLootMethod(currentMethod)

    if currentMethod ~= desiredLoot then
        if C_PartyInfo and C_PartyInfo.SetLootMethod then
            C_PartyInfo.SetLootMethod(desiredLoot)
        elseif SetLootMethod then
            SetLootMethod(desiredLoot)
        end

        if FFAPartyDB.showMessages then
            print("FFA Party: loot set to " .. desiredLootKey)
        end
        addon.DebugPrint("Loot method updated to " .. desiredLootKey)
    else
        addon.DebugPrint("Loot method already " .. desiredLootKey .. ", no change")
    end
end

------------------------------------------------------------
-- Force refresh helper (exposed)
------------------------------------------------------------
function addon.ForceRefresh()
    addon.DebugPrint("Force refresh requested")
    addon.UpdateLootMethod()
    if FFAPartyDB.showMessages then
        print("FFA Party: forced refresh complete")
    end
end

------------------------------------------------------------
-- Debounced friend-list handling
------------------------------------------------------------
local friendUpdatePending = false
local friendUpdateCount = 0
local function HandleFriendUpdate()
    friendUpdateCount = friendUpdateCount + 1
    
    if friendUpdatePending then
        -- Already scheduled, just increment counter
        return
    end
    
    friendUpdatePending = true
    if VERBOSE_DEBUG then
        addon.DebugPrint("Friend-list event received, scheduling recheck")
    end
    
    C_Timer.After(1.5, function()
        local eventCount = friendUpdateCount
        friendUpdateCount = 0
        friendUpdatePending = false
        
        if VERBOSE_DEBUG then
            addon.DebugPrint("Running friend-list recheck (" .. eventCount .. " event(s) triggered this)")
        end
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
            -- Initialize database with defaults
            addon.InitializeDB()

            -- Create UI components and store references
            if addon.CreateOptionsPanel then
                local optionsPanel = addon.CreateOptionsPanel()
                addon.DebugPrint("Options panel created: " .. tostring(optionsPanel ~= nil))
            end

            if addon.CreateMinimapButton then
                local minimapButton = addon.CreateMinimapButton()
                addon.DebugPrint("Minimap button created: " .. tostring(minimapButton ~= nil))
            end

            addon.DebugPrint("FFA Party loaded and tabbed options panel initialized")
            addon.DebugPrint("main.lua loaded for " .. addonName)
        end

    elseif event == "GROUP_ROSTER_UPDATE" or event == "PARTY_LEADER_CHANGED" or event == "PLAYER_ENTERING_WORLD" then
        addon.DebugPrint("Group/leader/world event: " .. event)
        addon.UpdateLootMethod()

    elseif event == "FRIENDLIST_UPDATE" then
        -- Don't log every FRIENDLIST_UPDATE as it fires very frequently
        HandleFriendUpdate()

    elseif event == "BN_FRIEND_ACCOUNT_ONLINE" or event == "BN_FRIEND_ACCOUNT_OFFLINE" then
        addon.DebugPrint("Received Battle.net friend event: " .. event)
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
