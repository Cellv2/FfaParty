-- local name,addon=...;
-- addon.myvar = "test"

local MY_CHAR_UNIT = "player"
local MY_RAID_TARGET_INDEX = 1
local OTHER_CHAR_UNIT = "Addonmanager"
local OTHER_RAID_TARGET_INDEX = 3


local optedOut = GetOptOutOfLoot()
print(optedOut)



local f = CreateFrame("Frame")

function f:OnEvent(event, ...)
    self[event](self, event, ...)
end

function f:PLAYER_ENTERING_WORLD(event, isLogin, isReload)
    -- SetOptOutOfLoot(false)
    -- print(event, isLogin, isReload)
end



-- TODO:
-- // only attempt actions if we are the group leader
-- also use PLAYER_LOGIN / PLAYER_ENTERING_WORLD to init everything in case we are the party leader but were offline/on a loading screen
-- if group leader changes:
--   check group type
--     if we are leader, update as expected
--     if we are not leader, warn that the type is not as expected?
--       ? maybe make this an option
--     if we are in a raid, do not change lootmethod if others are in the party


local LOOT_TYPE_FFA = "freeforall"
local LOOT_TYPE_GROUP = "group"

local function table_has_value (tab, val)
    for _, value in pairs(tab) do
        if value == val then
            return true
        end
    end

    return false
end

local function ensure_raid_target(unit, raidTargetIndex)
    if GetRaidTargetIndex(unit) ~= raidTargetIndex then
        SetRaidTarget(unit, raidTargetIndex)
    end
end

local function ensure_loot_method(lootMethod)
    if GetLootMethod() ~= lootMethod then
        print("Setting group loot")
        SetLootMethod(lootMethod)
    end
end

local function process_group_loot_type()
    -- local currentCharacterName = UnitName("player")
    -- local allowedCharacterNames = { "Boboboy" }
    local allowedCharacterNames = { OTHER_CHAR_UNIT }
    -- local currentGroupCharacterNames = { currentCharacterName, "Boboboy", "123" }
    local currentGroupCharacterNames = GetHomePartyInfo()

    local inGroup = IsInGroup()
    if inGroup ~= true then
        -- print("No actions taken, not in group")
        return
    end
    
    local isLeader = UnitIsGroupLeader("player")
    if isLeader ~= true then
        -- print("No actions taken, not group leader")
        return
    end

    local disallowedCharacterInGroup = false
    for _, v in pairs(currentGroupCharacterNames) do
        if table_has_value(allowedCharacterNames, v) then
            --
        else
            disallowedCharacterInGroup = true
            break
        end
    end

    if disallowedCharacterInGroup then
        local isInRaid = IsInRaid()
        if isInRaid then
            local currentLootMethod = GetLootMethod()
            if currentLootMethod == LOOT_TYPE_FFA then
                print("In raid and loot type is FFA, you might want to switch to something else")
                -- print("In raid and loot type is FFA, switching to group loot")
                -- SetLootMethod(LOOT_TYPE_GROUP)
            end
        end

        ensure_loot_method(LOOT_TYPE_GROUP)

        return
    end

    ensure_loot_method(LOOT_TYPE_FFA)

    -- print(currentCharacterName)
    -- SetOptOutOfLoot(true)
    -- print(event, addOnName)
end

function f:GOSSIP_SHOW(event, addOnName)
    ensure_raid_target(MY_CHAR_UNIT, MY_RAID_TARGET_INDEX)
    ensure_raid_target(OTHER_CHAR_UNIT, OTHER_RAID_TARGET_INDEX)

    process_group_loot_type()
end

function f:GROUP_ROSTER_UPDATE()
    ensure_raid_target(MY_CHAR_UNIT, MY_RAID_TARGET_INDEX)
    ensure_raid_target(OTHER_CHAR_UNIT, OTHER_RAID_TARGET_INDEX)

    process_group_loot_type()
end



-- f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("ADDON_LOADED")
-- f:RegisterEvent("GOSSIP_SHOW")
f:RegisterEvent("GROUP_ROSTER_UPDATE")
f:SetScript("OnEvent", f.OnEvent)
