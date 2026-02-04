-- minimap.lua
local addonName, addon = ...
addon.DebugPrint("minimap.lua loaded for " .. addonName)

------------------------------------------------------------
-- Create Minimap Button
------------------------------------------------------------
function addon.CreateMinimapButton()
    if not FFAPartyMinimap then
        FFAPartyMinimap = {
            angle = 45
        } -- default position
    end

    -- Prefer LibDBIcon (via LibDataBroker) when available
    local LDB = LibStub and LibStub("LibDataBroker-1.1", true)
    local LDBIcon = LibStub and LibStub("LibDBIcon-1.0", true)
    if LDB and LDBIcon then
        if FFAPartyMinimapButton then
            return
        end

        if not FFAPartyDB then
            FFAPartyDB = {}
        end
        if not FFAPartyDB.minimap then
            FFAPartyDB.minimap = { hide = false, minimapPos = FFAPartyMinimap.angle or 45 }
        end

        local dataobj = LDB:NewDataObject(addonName, {
            type = "launcher",
            icon = "Interface\\AddOns\\FfaParty\\minimap-icon.tga",
            OnClick = function(_, buttonPressed)
                if buttonPressed == "LeftButton" then
                    FFAPartyDB.enabled = not FFAPartyDB.enabled
                    local status = FFAPartyDB.enabled and "|cff00ff00enabled|r" or "|cffff0000disabled|r"
                    print("FFA Party: " .. status)
                    if FFAPartyDB.enabled then
                        addon.UpdateLootMethod()
                    end
                    return
                end

                if buttonPressed == "RightButton" and IsControlKeyDown() then
                    if addon and addon.ForceRefresh then
                        addon.ForceRefresh()
                    else
                        print("FFA Party: force refresh unavailable")
                    end
                    return
                end

                if buttonPressed == "RightButton" and IsShiftKeyDown() then
                    if addon.FriendsPanel then
                        if addon.FriendsPanel:IsShown() then
                            addon.FriendsPanel:Hide()
                        else
                            addon.FriendsPanel:Show()
                        end
                    elseif addon.ShowFriendsManager then
                        addon.ShowFriendsManager()
                    end
                    return
                end

                if buttonPressed == "RightButton" then
                    if FfaPartyOptionsPanel and FfaPartyOptionsPanel:IsShown() then
                        FfaPartyOptionsPanel:Hide()
                    else
                        if FfaPartyOptionsPanel then
                            FfaPartyOptionsPanel:Show()
                        end
                    end
                end
            end,
            OnTooltipShow = function(tt)
                if not tt or not tt.AddLine then return end
                local status = FFAPartyDB and FFAPartyDB.enabled and "|cff00ff00Enabled|r" or "|cffff0000Disabled|r"
                tt:AddLine("FFA Party", 1, 1, 1)
                tt:AddLine("Status: " .. status, 0.8, 0.8, 0.8)
                tt:AddLine(" ", 0.8, 0.8, 0.8)
                tt:AddLine("LMB: Toggle enable/disable", 0.8, 0.8, 0.8)
                tt:AddLine("RMB: Open options", 0.8, 0.8, 0.8)
                tt:AddLine("Shift + RMB: Manage whitelist/blacklist", 0.8, 0.8, 0.8)
                tt:AddLine("Ctrl + RMB: Force refresh", 0.8, 0.8, 0.8)
            end,
        })

        LDBIcon:Register(addonName, dataobj, FFAPartyDB.minimap)
        addon.MinimapButton = dataobj
        FFAPartyMinimapButton = dataobj
        addon.DebugPrint("Minimap icon created (LibDBIcon)")
        return dataobj
    end

    local button = CreateFrame("Button", "FFAPartyMinimapButton", Minimap)
    button:SetSize(32, 32)
    button:SetFrameStrata("MEDIUM")
    button:SetClampedToScreen(true)
    button:SetClampRectInsets(0, 0, 0, 0)

    -- -- Border (standard minimap button border)
    -- local border = button:CreateTexture(nil, "OVERLAY")
    -- border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    -- border:SetSize(56, 56)
    -- border:SetPoint("CENTER", 0, 0)

    --------------------------------------------------------
    -- Icon (your 64x64 file scaled to 32x32)
    --------------------------------------------------------
    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetTexture("Interface\\AddOns\\FfaParty\\minimap-icon.tga")
    icon:SetSize(32, 32)
    icon:SetPoint("CENTER", 0, 0)
    button.icon = icon

    --------------------------------------------------------
    -- Blizzard-style border (56x56)
    --------------------------------------------------------
    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetSize(56, 56)
    border:SetPoint("CENTER", 0, 0)

    --------------------------------------------------------
    -- Highlight (fits inside border) 
    --------------------------------------------------------
    local hl = button:CreateTexture(nil, "HIGHLIGHT")
    hl:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    hl:SetSize(32, 32)
    hl:SetPoint("CENTER", 0, 0)

    -- button:SetNormalTexture("Interface\\AddOns\\FfaParty\\minimap-icon.tga")
    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    local function UpdatePosition()
        local angle = FFAPartyMinimap.angle or 45
        local x = 52 * math.cos(math.rad(angle))
        local y = 52 * math.sin(math.rad(angle))
        button:SetPoint("CENTER", Minimap, "CENTER", x, y)
    end

    UpdatePosition()

    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    button:SetScript("OnClick", function(self, buttonPressed)
        -- Left-click = toggle enabled/disabled
        if buttonPressed == "LeftButton" then
            FFAPartyDB.enabled = not FFAPartyDB.enabled
            local status = FFAPartyDB.enabled and "|cff00ff00enabled|r" or "|cffff0000disabled|r"
            print("FFA Party: " .. status)
            if FFAPartyDB.enabled then
                addon.UpdateLootMethod()
            end
            return
        end

        -- Ctrl + Right-click = force refresh
        if buttonPressed == "RightButton" and IsControlKeyDown() then
            if addon and addon.ForceRefresh then
                addon.ForceRefresh()
            else
                print("FFA Party: force refresh unavailable")
            end
            return
        end

        -- Shift + Right-click = toggle friends whitelist/blacklist manager
        if buttonPressed == "RightButton" and IsShiftKeyDown() then
            if addon.FriendsPanel then
                if addon.FriendsPanel:IsShown() then
                    addon.FriendsPanel:Hide()
                else
                    addon.FriendsPanel:Show()
                end
            elseif addon.ShowFriendsManager then
                addon.ShowFriendsManager()
            end
            return
        end

        -- Normal Right-click = toggle options panel
        if buttonPressed == "RightButton" then
            if FfaPartyOptionsPanel and FfaPartyOptionsPanel:IsShown() then
                FfaPartyOptionsPanel:Hide()
            else
                if FfaPartyOptionsPanel then
                    FfaPartyOptionsPanel:Show()
                end
            end
        end
    end)

    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        local status = FFAPartyDB and FFAPartyDB.enabled and "|cff00ff00Enabled|r" or "|cffff0000Disabled|r"
        GameTooltip:AddLine("FFA Party", 1, 1, 1)
        GameTooltip:AddLine("Status: " .. status, 0.8, 0.8, 0.8)
        GameTooltip:AddLine(" ", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("LMB: Toggle enable/disable", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("RMB: Open options", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("Shift + RMB: Manage whitelist/blacklist", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("Ctrl + RMB: Force refresh", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)

    button:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)

    button:RegisterForDrag("LeftButton")
    button:SetScript("OnDragStart", function(self)
        self:SetScript("OnUpdate", function(self)
            local mx, my = Minimap:GetCenter()
            local px, py = GetCursorPosition()
            local scale = UIParent:GetEffectiveScale()

            px = px / scale
            py = py / scale

            local angle = math.deg(math.atan2(py - my, px - mx))
            FFAPartyMinimap.angle = angle
            UpdatePosition()
        end)
    end)

    button:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
    end)

    addon.MinimapButton = button
    addon.DebugPrint("Minimap icon created (fallback button)")
    return button
end
