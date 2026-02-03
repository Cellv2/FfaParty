-- minimap.lua
local addonName, addon = ...

------------------------------------------------------------
-- Create Minimap Button
------------------------------------------------------------
function addon.CreateMinimapButton()
    if not FFAPartyMinimap then
        FFAPartyMinimap = {
            angle = 45
        } -- default position
    end

    if FFAPartyMinimapButton then
        return
    end

    local button = CreateFrame("Button", "FFAPartyMinimapButton", Minimap)
    button:SetSize(32, 32)
    button:SetFrameStrata("MEDIUM")
    button:SetClampedToScreen(true)
    button:SetClampRectInsets(0, 0, 0, 0)

    -- Border (standard minimap button border)
    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetSize(56, 56)
    border:SetPoint("CENTER", 0, 0)

    button:SetNormalTexture("Interface\\AddOns\\FfaParty\\minimap-icon.tga")
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
        -- Right-click = force refresh
        if buttonPressed == "RightButton" then
            if addon and addon.ForceRefresh then
                addon.ForceRefresh()
            else
                print("FFA Party: force refresh unavailable")
            end
            return
        end

        -- Shift + Left-click = open friends whitelist/blacklist manager
        if buttonPressed == "LeftButton" and IsShiftKeyDown() then
            if addon.ShowFriendsManager then
                addon.ShowFriendsManager()
            end
            return
        end

        -- Normal Left-click = toggle options panel
        if FfaPartyOptionsPanel and FfaPartyOptionsPanel:IsShown() then
            FfaPartyOptionsPanel:Hide()
        else
            if FfaPartyOptionsPanel then
                FfaPartyOptionsPanel:Show()
            end
        end
    end)

    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("FFA Party", 1, 1, 1)
        GameTooltip:AddLine("LMB: Open options", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("Shift + LMB: Manage whitelist/blacklist", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("RMB: Force refresh", 0.8, 0.8, 0.8)
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
end
