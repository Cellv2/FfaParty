-- options.lua
local addonName, addon = ...
addon = addon or {}
_G[addonName] = addon
print("FFA Party: options.lua loaded for", addonName, "addon table:", addon)

function addon.CreateOptionsPanel()
    local panel = CreateFrame("Frame")
    panel.name = "FFA Party" -- force a nice display name

    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("FFA Party Options")

    --------------------------------------------------------
    -- Ignore raids checkbox
    --------------------------------------------------------
    local ignoreRaidsCB = CreateFrame("CheckButton", nil, panel, "InterfaceOptionsCheckButtonTemplate")
    ignoreRaidsCB:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)
    ignoreRaidsCB.Text:SetText("Ignore raids")
    ignoreRaidsCB:SetChecked(FFAPartyDB.ignoreRaids)
    ignoreRaidsCB:SetScript("OnClick", function(self)
        FFAPartyDB.ignoreRaids = self:GetChecked()
    end)

    --------------------------------------------------------
    -- Show messages checkbox
    --------------------------------------------------------
    local showMessagesCB = CreateFrame("CheckButton", nil, panel, "InterfaceOptionsCheckButtonTemplate")
    showMessagesCB:SetPoint("TOPLEFT", ignoreRaidsCB, "BOTTOMLEFT", 0, -10)
    showMessagesCB.Text:SetText("Show chat messages")
    showMessagesCB:SetChecked(FFAPartyDB.showMessages)
    showMessagesCB:SetScript("OnClick", function(self)
        FFAPartyDB.showMessages = self:GetChecked()
    end)

    --------------------------------------------------------
    -- Debug mode checkbox
    --------------------------------------------------------
    local debugCB = CreateFrame("CheckButton", nil, panel, "InterfaceOptionsCheckButtonTemplate")
    debugCB:SetPoint("TOPLEFT", showMessagesCB, "BOTTOMLEFT", 0, -10)
    debugCB.Text:SetText("Enable debug logging")
    debugCB:SetChecked(FFAPartyDB.debug)
    debugCB:SetScript("OnClick", function(self)
        FFAPartyDB.debug = self:GetChecked()
    end)

    --------------------------------------------------------
    -- Loot with friends dropdown
    --------------------------------------------------------
    local lootFriendsLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lootFriendsLabel:SetPoint("TOPLEFT", debugCB, "BOTTOMLEFT", 0, -20)
    lootFriendsLabel:SetText("Loot with friends:")

    local lootFriendsDD = CreateFrame("Frame", addonName .. "LootFriendsDD", panel, "UIDropDownMenuTemplate")
    lootFriendsDD:SetPoint("TOPLEFT", lootFriendsLabel, "BOTTOMLEFT", -16, -5)

    local lootMethods = {{
        value = "freeforall",
        text = "Free-for-all"
    }, {
        value = "group",
        text = "Group Loot"
    }, {
        value = "needbeforegreed",
        text = "Need Before Greed"
    }}

    UIDropDownMenu_SetWidth(lootFriendsDD, 150)
    UIDropDownMenu_Initialize(lootFriendsDD, function(self, level)
        for _, option in ipairs(lootMethods) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = option.text
            info.func = function()
                FFAPartyDB.lootWithFriends = option.value
                UIDropDownMenu_SetSelectedValue(lootFriendsDD, option.value)
            end
            UIDropDownMenu_AddButton(info)
        end
    end)
    UIDropDownMenu_SetSelectedValue(lootFriendsDD, FFAPartyDB.lootWithFriends)

    --------------------------------------------------------
    -- Loot with others dropdown
    --------------------------------------------------------
    local lootOthersLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lootOthersLabel:SetPoint("TOPLEFT", lootFriendsDD, "BOTTOMLEFT", 16, -20)
    lootOthersLabel:SetText("Loot with others:")

    local lootOthersDD = CreateFrame("Frame", addonName .. "LootOthersDD", panel, "UIDropDownMenuTemplate")
    lootOthersDD:SetPoint("TOPLEFT", lootOthersLabel, "BOTTOMLEFT", -16, -5)

    UIDropDownMenu_SetWidth(lootOthersDD, 150)
    UIDropDownMenu_Initialize(lootOthersDD, function(self, level)
        for _, option in ipairs(lootMethods) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = option.text
            info.func = function()
                FFAPartyDB.lootWithOthers = option.value
                UIDropDownMenu_SetSelectedValue(lootOthersDD, option.value)
            end
            UIDropDownMenu_AddButton(info)
        end
    end)
    UIDropDownMenu_SetSelectedValue(lootOthersDD, FFAPartyDB.lootWithOthers)

    --------------------------------------------------------
    -- Register panel
    --------------------------------------------------------
    if InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(panel)
    end

    --------------------------------------------------------
    -- Slash commands to open panel
    --------------------------------------------------------
    SLASH_FFAPARTY1 = "/fp"
    SLASH_FFAPARTY2 = "/ffap"
    SLASH_FFAPARTY3 = "/ffaparty"
    SlashCmdList.FFAPARTY = function()
        if InterfaceOptionsFrame then
            InterfaceOptionsFrame:Show()
            print("Open Interface Options → AddOns → FFA Party to configure settings.")
        end
    end
end
