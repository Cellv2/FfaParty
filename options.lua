-- options.lua
local addonName, addon = ...
addon.DebugPrint("options.lua loaded for " .. addonName)

local MAIN_WIDTH, MAIN_HEIGHT = 360, 520

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

    local enabledCB = CreateCheckbox(panel, "Enable addon functionality", 0, -40, FFAPartyDB and FFAPartyDB.enabled,
        function(self)
            FFAPartyDB.enabled = self:GetChecked()
            local status = FFAPartyDB.enabled and "|cff00ff00enabled|r" or "|cffff0000disabled|r"
            print("FFA Party: " .. status)
            if FFAPartyDB.enabled and addon.UpdateLootMethod then
                addon.UpdateLootMethod()
            end
        end)

    local showMessagesCB = CreateCheckbox(panel, "Show chat messages", 0, -70, FFAPartyDB and FFAPartyDB.showMessages,
        function(self)
            FFAPartyDB.showMessages = self:GetChecked()
        end)

    local debugCB = CreateCheckbox(panel, "Enable debug logging", 0, -100, FFAPartyDB and FFAPartyDB.debug,
        function(self)
            FFAPartyDB.debug = self:GetChecked()
        end)

    local hideMinimapCB = CreateCheckbox(panel, "Hide minimap icon", 0, -130, FFAPartyDB and FFAPartyDB.minimap and FFAPartyDB.minimap.hide,
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
    lootFriendsLabel:SetPoint("TOPLEFT", leftPad, contentTop - 170)
    lootFriendsLabel:SetText("Loot with friends:")
    lootFriendsLabel:SetTextColor(1, 1, 1, 1)

    local lootFriendsDD = CreateDropdown(addonName .. "LootFriendsDD", panel, 0, -194,
        FFAPartyDB and FFAPartyDB.lootWithFriends or "freeforall", function(value)
            FFAPartyDB.lootWithFriends = value
        end)

    --------------------------------------------------------
    -- Loot with others
    --------------------------------------------------------
    local lootOthersLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lootOthersLabel:SetPoint("TOPLEFT", leftPad, contentTop - 270)
    lootOthersLabel:SetText("Loot with others:")
    lootOthersLabel:SetTextColor(1, 1, 1, 1)

    local lootOthersDD = CreateDropdown(addonName .. "LootOthersDD", panel, 0, -294,
        FFAPartyDB and FFAPartyDB.lootWithOthers or "group", function(value)
            FFAPartyDB.lootWithOthers = value
        end)

    --------------------------------------------------------
    -- Raid icon marking
    --------------------------------------------------------
    local raidIconLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    raidIconLabel:SetPoint("TOPLEFT", leftPad, contentTop - 350)
    raidIconLabel:SetText("Mark friends with raid icons (when not in raid):")
    raidIconLabel:SetTextColor(1, 1, 1, 1)

    -- Table of raid icons with input fields
    local iconInputs = {}
    local function UpdateRaidIconInput(iconIndex, friendName)
        -- Clear all raid icon friends and rebuild from current input values
        FFAPartyDB.raidIconFriends = {}
        for i = 1, 8 do
            local input = iconInputs[i]
            local newName = input:GetText():gsub("^%s+", ""):gsub("%s+$", "")
            if newName and newName ~= "" then
                FFAPartyDB.raidIconFriends[newName] = i
            end
        end
        -- Apply raid icons immediately to current group
        if addon.UpdateRaidIcon then
            addon.UpdateRaidIcon()
        end
    end

    local listBorder = CreateFrame("Frame", nil, panel, "BackdropTemplate")
    listBorder:SetPoint("TOPLEFT", leftPad, contentTop - 375)
    listBorder:SetSize(MAIN_WIDTH - 2 * leftPad, 160)
    listBorder:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    listBorder:SetBackdropColor(0, 0, 0, 0.4)
    listBorder:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

    local raidIconList = CreateFrame("Frame", nil, panel)
    raidIconList:SetSize(MAIN_WIDTH - 2 * leftPad - 30, 150)
    raidIconList:SetPoint("TOPLEFT", listBorder, 6, -6)

    for i = 8, 1, -1 do
        -- Icon name label
        local iconNameLabel = raidIconList:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        iconNameLabel:SetPoint("TOPLEFT", 0, -(8 - i) * 18)
        iconNameLabel:SetSize(90, 18)
        iconNameLabel:SetJustifyH("LEFT")
        iconNameLabel:SetText(addon.raidIconNames[i])
        iconNameLabel:SetTextColor(0.9, 0.9, 0.9, 1)

        -- Input field for player name
        local input = CreateFrame("EditBox", nil, raidIconList, "InputBoxTemplate")
        input:SetSize(130, 18)
        input:SetPoint("LEFT", iconNameLabel, "RIGHT", 10, 0)
        input:SetAutoFocus(false)
        input:SetFontObject("GameFontHighlightSmall")
        
        -- Load existing value
        local existingName = nil
        for friendName, iconIdx in pairs(FFAPartyDB.raidIconFriends or {}) do
            if iconIdx == i then
                existingName = friendName
                break
            end
        end
        if existingName then
            input:SetText(existingName)
        end

        -- Save on edit
        input:SetScript("OnEditFocusLost", function(self)
            UpdateRaidIconInput(i, nil)
        end)
        input:SetScript("OnEnterPressed", function(self)
            UpdateRaidIconInput(i, nil)
            self:ClearFocus()
        end)

        iconInputs[i] = input
    end

    --------------------------------------------------------
    -- Manage friends button
    --------------------------------------------------------
    local friendsBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    friendsBtn:SetSize(180, 24)
    friendsBtn:SetPoint("TOPLEFT", leftPad, contentTop - 420)
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
    hint:SetText("LMB: Toggle enable/disable | Ctrl + RMB: Force refresh")
    hint:SetTextColor(0.9, 0.9, 0.9, 1)

    --------------------------------------------------------
    -- Slash commands
    --------------------------------------------------------
    SLASH_FFAPARTY1 = "/fp"
    SLASH_FFAPARTY2 = "/ffap"
    SLASH_FFAPARTY3 = "/ffaparty"
    SlashCmdList.FFAPARTY = function(msg)
        msg = msg:lower():trim()
        
        if msg == "enable" then
            FFAPartyDB.enabled = true
            print("FFA Party: |cff00ff00enabled|r")
            if addon.UpdateLootMethod then
                addon.UpdateLootMethod()
            end
        elseif msg == "disable" then
            FFAPartyDB.enabled = false
            print("FFA Party: |cffff0000disabled|r")
        elseif msg == "debug" or msg == "debug toggle" then
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
