local name,addon=...;
addon.myvar = "test"


local optedOut = GetOptOutOfLoot()
print(optedOut)



local f = CreateFrame("Frame")
-- function f:GROUP_ROSTER_UPDATE(event, addonName)
--     print("thething")
-- end

function f:OnEvent(event, ...)
    self[event](self, event, ...)
end

function f:PLAYER_ENTERING_WORLD(event, isLogin, isReload)
    -- SetOptOutOfLoot(false)
    print(event, isLogin, isReload)
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


-- function f:GOSSIP_SHOW(event, addOnName)
--     local currentCharacterName = UnitName("player")
--     local allowedCharacterNames = { "Boboboy" }
--     -- local currentGroupCharacterNames = { currentCharacterName, "Boboboy", "123" }
--     local currentGroupCharacterNames = GetHomePartyInfo()

--     local inGroup = IsInGroup()
--     if inGroup ~= true then
--         -- print("No actions taken, not in group")
--         return
--     end
    
--     local isLeader = UnitIsGroupLeader("player")
--     if isLeader ~= true then
--         -- print("No actions taken, not group leader")
--         return
--     end

--     -- for _, v in ipairs(currentGroupCharacterNames) do
--     --     print("groupCharName: ", v)
--     -- end

--     -- ensure_loot_type(LOOT_TYPE_FFA)

--     local disallowedCharacterInGroup = false
--     for _, v in pairs(currentGroupCharacterNames) do
--         if table_has_value(allowedCharacterNames, v) then
--             --
--         else
--             -- print("BAD TOYS", v)
--             disallowedCharacterInGroup = true
--             break
--         end
--     end

--     if disallowedCharacterInGroup then
--         local isInRaid = IsInRaid()
--         if isInRaid then
--             local currentLootMethod = GetLootMethod()
--             if currentLootMethod == LOOT_TYPE_FFA then
--                 print("In raid and loot type is FFA, you might want to switch to something else")
--                 -- print("In raid and loot type is FFA, switching to group loot")
--                 -- SetLootMethod(LOOT_TYPE_GROUP)
--             end
--         end

--         -- print("Found character in group which is not in allowed list")
--         -- print(allowedCharacterNames)
--         -- for _, v in ipairs(allowedCharacterNames) do
--         --     print("groupCharName: ", v)
--         -- end

--         if GetLootMethod() ~= LOOT_TYPE_GROUP then
--             print("Setting group loot")
--             SetLootMethod(LOOT_TYPE_GROUP)
--         end
--         return
--     end

--     -- print("All characters in group are on the allowed list")
--     if GetLootMethod() ~= LOOT_TYPE_FFA then
--         print("Setting FFA loot")
--         SetLootMethod(LOOT_TYPE_FFA)
--     end

--     -- print(currentCharacterName)
--     -- SetOptOutOfLoot(true)
--     -- print(event, addOnName)
-- end

function f:GROUP_ROSTER_UPDATE()
    local currentCharacterName = UnitName("player")
    local allowedCharacterNames = { "Boboboy" }
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

    -- for _, v in ipairs(currentGroupCharacterNames) do
    --     print("groupCharName: ", v)
    -- end

    -- ensure_loot_type(LOOT_TYPE_FFA)

    local disallowedCharacterInGroup = false
    for _, v in pairs(currentGroupCharacterNames) do
        if table_has_value(allowedCharacterNames, v) then
            --
        else
            -- print("BAD TOYS", v)
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

        -- print("Found character in group which is not in allowed list")
        -- print(allowedCharacterNames)
        -- for _, v in ipairs(allowedCharacterNames) do
        --     print("groupCharName: ", v)
        -- end

        if GetLootMethod() ~= LOOT_TYPE_GROUP then
            print("Setting group loot")
            SetLootMethod(LOOT_TYPE_GROUP)
        end
        return
    end

    -- print("All characters in group are on the allowed list")
    if GetLootMethod() ~= LOOT_TYPE_FFA then
        print("Setting FFA loot")
        SetLootMethod(LOOT_TYPE_FFA)
    end

    -- print(currentCharacterName)
    -- SetOptOutOfLoot(true)
    -- print(event, addOnName)
end

-- function ensure_loot_type(val)
--     local currentLootType = GetLootMethod()
--     print(currentLootType)
--     if (currentLootType ~= val) then
--         SetLootMethod(val)
--     end
-- end



f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("GOSSIP_SHOW")
f:RegisterEvent("GROUP_ROSTER_UPDATE")
f:SetScript("OnEvent", f.OnEvent)


-- local f = CreateFrame("Frame")

-- function f:OnEvent(event, ...)
-- 	self[event](self, event, ...)
-- end

-- function f:ADDON_LOADED(event, addOnName)
-- 	print(event, addOnName)
-- end

-- function f:PLAYER_ENTERING_WORLD(event, isLogin, isReload)
-- 	print(event, isLogin, isReload)
-- end

-- function f:CHAT_MSG_CHANNEL(event, text, playerName, _, channelName)
-- 	print(event, text, playerName, channelName)
-- end

-- f:RegisterEvent("ADDON_LOADED")
-- f:RegisterEvent("PLAYER_ENTERING_WORLD")
-- f:RegisterEvent("CHAT_MSG_CHANNEL")
-- f:SetScript("OnEvent", f.OnEvent)
