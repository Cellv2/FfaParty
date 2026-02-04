-- options.lua
local addonName, addon = ...
addon.DebugPrint("options.lua loaded for " .. addonName)

local MAIN_WIDTH, MAIN_HEIGHT = 360, 460

local function ForceTextColor(obj)
    if not obj then
        return
    end
    if obj.SetTextColor then
        obj:SetTextColor(1, 1, 1, 1)
    elseif obj.Text and obj.Text.SetTextColor then
        obj.Text:SetTextColor(1, 1, 1, 1)
    end
end

function addon.CreateOptionsPanel()
    if FfaPartyOptionsPanel then
        return
    end

    --------------------------------------------------------
    -- Main panel
    --------------------------------------------------------
    local panel = CreateFrame("Frame", "FfaPartyOptionsPanel", UIParent)
    panel:SetSize(MAIN_WIDTH, MAIN_HEIGHT)
    panel:SetPoint("CENTER")
    panel:Hide()
    panel:SetFrameStrata("DIALOG")

    panel:EnableMouse(true)
    panel:SetMovable(true)
    panel:RegisterForDrag("LeftButton")
    panel:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)
    panel:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
    end)
    panel:SetClampedToScreen(true)

    local bg = panel:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(panel)
    bg:SetColorTexture(0, 0, 0, 0.08)

    local border = panel:CreateTexture(nil, "BORDER")
    border:SetPoint("TOPLEFT", -6, 6)
    border:SetPoint("BOTTOMRIGHT", 6, -6)
    border:SetColorTexture(0, 0, 0, 0.6)

    local edge = panel:CreateTexture(nil, "ARTWORK")
    edge:SetPoint("TOPLEFT", -4, 4)
    edge:SetPoint("BOTTOMRIGHT", 4, -4)
    edge:SetColorTexture(0.06, 0.06, 0.06, 0.6)

    --------------------------------------------------------
    -- Header
    --------------------------------------------------------
    local headerHeight = 40
    local header = CreateFrame("Frame", "FfaPartyOptionsHeader", panel)
    header:SetSize(MAIN_WIDTH - 24, headerHeight)
    header:SetPoint("TOP", panel, "TOP", 0, 12)
    header:SetFrameStrata("DIALOG")
    header:SetFrameLevel(panel:GetFrameLevel() + 5)

    local headerBg = header:CreateTexture(nil, "BACKGROUND")
    headerBg:SetAllPoints(header)
    headerBg:SetColorTexture(0.06, 0.06, 0.06, 0.92)

    local headerInner = header:CreateTexture(nil, "ARTWORK")
    headerInner:SetPoint("TOPLEFT", 6, -6)
    headerInner:SetPoint("BOTTOMRIGHT", -6, 6)
    headerInner:SetColorTexture(0, 0, 0, 0.45)

    local headerBorder = header:CreateTexture(nil, "OVERLAY")
    headerBorder:SetPoint("TOPLEFT", -2, 2)
    headerBorder:SetPoint("BOTTOMRIGHT", 2, -2)
    headerBorder:SetColorTexture(0, 0, 0, 0.95)

    local headerTitle = header:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    headerTitle:SetPoint("CENTER", header, "CENTER", -8, 4)
    headerTitle:SetText("FFA Party Options")
    headerTitle:SetTextColor(1, 0.82, 0, 1)

    local close = CreateFrame("Button", nil, header, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -6, -6)
    close:SetScript("OnClick", function()
        panel:Hide()
    end)

    header:SetScript("OnEnter", function()
        headerInner:SetColorTexture(0, 0, 0, 0.55)
    end)
    header:SetScript("OnLeave", function()
        headerInner:SetColorTexture(0, 0, 0, 0.45)
    end)

    header:EnableMouse(true)
    header:RegisterForDrag("LeftButton")
    header:SetScript("OnDragStart", function()
        panel:StartMoving()
    end)
    header:SetScript("OnDragStop", function()
        panel:StopMovingOrSizing()
    end)

    --------------------------------------------------------
    -- Content
    --------------------------------------------------------
    local contentTop = -36
    local leftPad = 18

    local function CreateCheckbox(parent, label, x, y, initial, onClick)
        local cb = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
        cb:SetPoint("TOPLEFT", leftPad + x, contentTop + y)
        cb.Text:SetText(label)
        cb:SetChecked(initial)
        cb:SetScript("OnClick", function(self)
            if onClick then
                onClick(self)
            end
        end)
        ForceTextColor(cb)
        return cb
    end

    local ignoreRaidsCB = CreateCheckbox(panel, "Ignore raids", 0, -10, FFAPartyDB and FFAPartyDB.ignoreRaids,
        function(self)
            FFAPartyDB.ignoreRaids = self:GetChecked()
        end)

    local showMessagesCB = CreateCheckbox(panel, "Show chat messages", 0, -40, FFAPartyDB and FFAPartyDB.showMessages,
        function(self)
            FFAPartyDB.showMessages = self:GetChecked()
        end)

    local debugCB = CreateCheckbox(panel, "Enable debug logging", 0, -70, FFAPartyDB and FFAPartyDB.debug,
        function(self)
            FFAPartyDB.debug = self:GetChecked()
        end)

    local hideMinimapCB = CreateCheckbox(panel, "Hide minimap icon", 0, -100, FFAPartyDB and FFAPartyDB.minimap and FFAPartyDB.minimap.hide,
        function(self)
            if FFAPartyDB and FFAPartyDB.minimap then
                FFAPartyDB.minimap.hide = self:GetChecked()
                local LDBIcon = LibStub and LibStub("LibDBIcon-1.0", true)
                if LDBIcon and LDBIcon.registry and LDBIcon.registry[addonName] then
                    if self:GetChecked() then
                        if LDBIcon.registry[addonName].frame then
                            LDBIcon.registry[addonName].frame:Hide()
                        end
                    else
                        if LDBIcon.registry[addonName].frame then
                            LDBIcon.registry[addonName].frame:Show()
                        end
                    end
                end
            end
        end)

    --------------------------------------------------------
    -- Dropdown helper
    --------------------------------------------------------
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

    local function CreateDropdown(name, parent, x, y, initialValue, onSelect)
        local dd = CreateFrame("Frame", name, parent, "UIDropDownMenuTemplate")
        dd:SetPoint("TOPLEFT", leftPad + x, contentTop + y)
        UIDropDownMenu_SetWidth(dd, 160)
        UIDropDownMenu_Initialize(dd, function(self, level)
            for _, option in ipairs(lootMethods) do
                local info = UIDropDownMenu_CreateInfo()
                info.text = option.text
                info.arg1 = option.value
                info.func = function(_, value)
                    if onSelect then
                        onSelect(value)
                    end
                    UIDropDownMenu_SetSelectedValue(dd, value)
                    UIDropDownMenu_SetText(dd, option.text)
                end
                UIDropDownMenu_AddButton(info)
            end
        end)

        local initialText = nil
        for _, option in ipairs(lootMethods) do
            if option.value == initialValue then
                initialText = option.text
                break
            end
        end
        UIDropDownMenu_SetSelectedValue(dd, initialValue)
        if initialText then
            UIDropDownMenu_SetText(dd, initialText)
        end

        return dd
    end

    --------------------------------------------------------
    -- Loot with friends
    --------------------------------------------------------
    local lootFriendsLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lootFriendsLabel:SetPoint("TOPLEFT", leftPad, contentTop - 140)
    lootFriendsLabel:SetText("Loot with friends:")
    lootFriendsLabel:SetTextColor(1, 1, 1, 1)

    local lootFriendsDD = CreateDropdown(addonName .. "LootFriendsDD", panel, 0, -164,
        FFAPartyDB and FFAPartyDB.lootWithFriends or "freeforall", function(value)
            FFAPartyDB.lootWithFriends = value
        end)

    --------------------------------------------------------
    -- Loot with others
    --------------------------------------------------------
    local lootOthersLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lootOthersLabel:SetPoint("TOPLEFT", leftPad, contentTop - 240)
    lootOthersLabel:SetText("Loot with others:")
    lootOthersLabel:SetTextColor(1, 1, 1, 1)

    local lootOthersDD = CreateDropdown(addonName .. "LootOthersDD", panel, 0, -264,
        FFAPartyDB and FFAPartyDB.lootWithOthers or "group", function(value)
            FFAPartyDB.lootWithOthers = value
        end)

    --------------------------------------------------------
    -- Manage friends button
    --------------------------------------------------------
    local friendsBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    friendsBtn:SetSize(180, 24)
    friendsBtn:SetPoint("TOPLEFT", leftPad, contentTop - 330)
    friendsBtn:SetText("Manage whitelist / blacklist")
    friendsBtn:SetScript("OnClick", function()
        if addon.ShowFriendsManager then
            addon.ShowFriendsManager()
        end
    end)

    --------------------------------------------------------
    -- Footer hint
    --------------------------------------------------------
    local hint = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hint:SetPoint("BOTTOMLEFT", 14, 12)
    hint:SetText("Ctrl + Right-click the minimap icon to force a refresh.")
    hint:SetTextColor(0.9, 0.9, 0.9, 1)

    --------------------------------------------------------
    -- Slash commands
    --------------------------------------------------------
    SLASH_FFAPARTY1 = "/fp"
    SLASH_FFAPARTY2 = "/ffap"
    SLASH_FFAPARTY3 = "/ffaparty"
    SlashCmdList.FFAPARTY = function(msg)
        msg = msg:lower():trim()
        
        if msg == "debug" or msg == "debug toggle" then
            FFAPartyDB.debug = not FFAPartyDB.debug
            print("FFA Party: debug logging " .. (FFAPartyDB.debug and "enabled" or "disabled"))
        elseif msg == "debug on" or msg == "debug enable" then
            FFAPartyDB.debug = true
            print("FFA Party: debug logging enabled")
        elseif msg == "debug off" or msg == "debug disable" then
            FFAPartyDB.debug = false
            print("FFA Party: debug logging disabled")
        else
            if FfaPartyOptionsPanel and FfaPartyOptionsPanel:IsShown() then
                FfaPartyOptionsPanel:Hide()
            else
                if FfaPartyOptionsPanel then
                    FfaPartyOptionsPanel:Show()
                end
            end
        end
    end

    addon.OptionsPanel = panel
    return panel
end
