-- main.lua
local addonName, addon = ...

local f = CreateFrame("Frame")

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
                friends[addon.NormalizeName(info.name)] = true
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
                friends[addon.NormalizeName(accountName)] = true
            end
            local numToons = BNGetNumFriendToons and BNGetNumFriendToons(i) or 0
            for t = 1, numToons do
                local toonName, toonRealm = BNGetFriendToonInfo(i, t)
                if toonName then
                    local full = toonRealm and (toonName .. "-" .. toonRealm) or toonName
                    friends[full] = true
                    friends[addon.NormalizeName(full)] = true
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
            t[addon.NormalizeName(name)] = true
        end
    end
    return t
end

local function GetCustomBlacklist()
    local t = {}
    if FFAPartyDB and FFAPartyDB.customBlacklist then
        for _, name in ipairs(FFAPartyDB.customBlacklist) do
            t[name] = true
            t[addon.NormalizeName(name)] = true
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
            local base = addon.NormalizeName(member)
            if not IsFriend(full, base, whitelist, blacklist, autoFriends) then
                addon.DebugPrint("Non-friend detected in group: " .. (full or "unknown"))
                return false
            else
                addon.DebugPrint("Friend matched: " .. (full or "unknown"))
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
        addon.DebugPrint("Addon disabled; skipping loot enforcement")
        return
    end
    if not IsInGroup() then
        addon.DebugPrint("Not in group; skipping loot enforcement")
        return
    end
    if not UnitIsGroupLeader("player") then
        addon.DebugPrint("Not group leader; skipping loot enforcement")
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
-- Raid icon marking for friends
------------------------------------------------------------
function addon.UpdateRaidIcon()
    if not FFAPartyDB.enabled then
        return
    end
    if IsInRaid() then
        -- Don't overwrite raid icons when in a raid
        return
    end
    if not IsInGroup() then
        return
    end
    
    local raidIconFriends = FFAPartyDB.raidIconFriends or {}
    
    -- Build a table of friends to look for with their normalized names
    local friendsToMark = {}
    for friendName, iconIndex in pairs(raidIconFriends) do
        friendsToMark[friendName] = iconIndex
        friendsToMark[addon.NormalizeName(friendName)] = iconIndex
    end
    
    -- Clear all raid icons first (in case friends were removed)
    local num = GetNumGroupMembers()
    if num > 0 then
        local prefix = "party"
        for i = 1, num do
            local unit = prefix .. i
            if UnitExists(unit) then
                SetRaidTarget(unit, 0)
            end
        end
    end
    
    -- Check all group members and apply configured icons
    if num > 0 then
        local prefix = "party"
        for i = 1, num do
            local unit = prefix .. i
            if UnitExists(unit) then
                local name, realm = UnitName(unit)
                if name then
                    local full = realm and realm ~= "" and (name .. "-" .. realm) or name
                    local base = addon.NormalizeName(full)
                    
                    -- Check if this unit matches any of our configured friends
                    local iconIndex = friendsToMark[full] or friendsToMark[name] or friendsToMark[base]
                    if iconIndex then
                        SetRaidTarget(unit, iconIndex)
                        addon.DebugPrint("Raid icon " .. addon.raidIconNames[iconIndex] .. " set on " .. full)
                    end
                end
            end
        end
        
        -- Also check if the player themselves matches any configured friend
        local playerName, playerRealm = UnitName("player")
        if playerName then
            local playerFull = playerRealm and playerRealm ~= "" and (playerName .. "-" .. playerRealm) or playerName
            local playerBase = addon.NormalizeName(playerFull)
            
            local iconIndex = friendsToMark[playerFull] or friendsToMark[playerName] or friendsToMark[playerBase]
            if iconIndex then
                SetRaidTarget("player", iconIndex)
                addon.DebugPrint("Raid icon " .. addon.raidIconNames[iconIndex] .. " set on player")
            end
        end
    end
end

------------------------------------------------------------
-- Force refresh helper (exposed)
------------------------------------------------------------
function addon.ForceRefresh()
    addon.DebugPrint("Force refresh requested")
    addon.UpdateLootMethod()
    addon.UpdateRaidIcon()
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
        addon.DebugPrint("Friend update already pending; skipping")
        return
    end
    friendUpdatePending = true
    addon.DebugPrint("Scheduling friend-list recheck")
    C_Timer.After(0.5, function()
        friendUpdatePending = false
        addon.DebugPrint("Running friend-list recheck")
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
        addon.UpdateRaidIcon()

    elseif event == "FRIENDLIST_UPDATE" then
        addon.DebugPrint("Received FRIENDLIST_UPDATE")
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
