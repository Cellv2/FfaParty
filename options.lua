-- options.lua
local addonName, addon = ...
addon.DebugPrint("options.lua loaded for " .. addonName)

local MAIN_WIDTH, MAIN_HEIGHT = 450, 580
local TAB_HEIGHT = 24
local CONTENT_PADDING = 16

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
    -- Tab system
    --------------------------------------------------------
    local tabs = {}
    local currentTab = 0
    local SelectTab
    
    local function CreateTab(index, name)
        local tab = CreateFrame("Button", nil, panel)
        tab:SetSize(140, TAB_HEIGHT)
        tab:SetPoint("TOPLEFT", 18 + (index - 1) * 145, -44)
        
        local tabBg = tab:CreateTexture(nil, "BACKGROUND")
        tabBg:SetAllPoints(tab)
        tabBg:SetColorTexture(0.05, 0.05, 0.05, 0.7)
        tab.tabBg = tabBg
        
        local tabBorder = tab:CreateTexture(nil, "BORDER")
        tabBorder:SetPoint("TOPLEFT", -1, 1)
        tabBorder:SetPoint("BOTTOMRIGHT", 1, -1)
        tabBorder:SetColorTexture(0.2, 0.2, 0.2, 0.8)
        tab.tabBorder = tabBorder
        
        local tabText = tab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        tabText:SetPoint("CENTER", tab, "CENTER", 0, 1)
        tabText:SetText(name)
        tabText:SetTextColor(0.9, 0.9, 0.9, 1)
        tab.tabText = tabText
        
        tab:SetScript("OnClick", function()
            if SelectTab then
                SelectTab(index)
            end
        end)
        
        tab:SetScript("OnEnter", function()
            if currentTab ~= index then
                tabBg:SetColorTexture(0.1, 0.1, 0.1, 0.8)
            end
        end)
        
        tab:SetScript("OnLeave", function()
            if currentTab ~= index then
                tabBg:SetColorTexture(0.05, 0.05, 0.05, 0.7)
            end
        end)
        
        tabs[index] = tab
        return tab
    end
    
    SelectTab = function(tabIndex)
        if currentTab == tabIndex then
            return
        end
        currentTab = tabIndex
        
        -- Update tab visuals
        for i, tab in ipairs(tabs) do
            if i == tabIndex then
                tab.tabBg:SetColorTexture(0.15, 0.15, 0.15, 0.95)
                tab.tabText:SetTextColor(1, 0.82, 0, 1)
                tab.tabBorder:SetColorTexture(0.4, 0.4, 0.4, 1)
            else
                tab.tabBg:SetColorTexture(0.05, 0.05, 0.05, 0.7)
                tab.tabText:SetTextColor(0.9, 0.9, 0.9, 1)
                tab.tabBorder:SetColorTexture(0.2, 0.2, 0.2, 0.8)
            end
        end
        
        -- Show/hide content frames
        if panel.contentFrames then
            for i, frame in ipairs(panel.contentFrames) do
                frame:SetShown(i == tabIndex)
            end
        end
    end
    
    CreateTab(1, "Main Options")
    CreateTab(2, "Raid Markers")
    CreateTab(3, "Filters")

    panel.SelectTab = SelectTab

    --------------------------------------------------------
    -- Content frames for tabs
    --------------------------------------------------------
    panel.contentFrames = {}
    local contentTop = -70
    local leftPad = CONTENT_PADDING

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

    --------------------------------------------------------
    -- TAB 1: MAIN OPTIONS
    --------------------------------------------------------
    local mainContent = CreateFrame("Frame", nil, panel)
    mainContent:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, -70)
    mainContent:SetSize(MAIN_WIDTH - 24, MAIN_HEIGHT - 110)
    panel.contentFrames[1] = mainContent

    local generalHeader = mainContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    generalHeader:SetPoint("TOPLEFT", leftPad, contentTop + 10)
    generalHeader:SetText("General")
    generalHeader:SetTextColor(1, 0.82, 0, 1)

    local ignoreRaidsCB = CreateCheckbox(mainContent, "Ignore raids", 0, -10, FFAPartyDB and FFAPartyDB.ignoreRaids,
        function(self)
            FFAPartyDB.ignoreRaids = self:GetChecked()
        end)

    local enabledCB = CreateCheckbox(mainContent, "Enable addon functionality", 0, -40, FFAPartyDB and FFAPartyDB.enabled,
        function(self)
            FFAPartyDB.enabled = self:GetChecked()
            local status = FFAPartyDB.enabled and "|cff00ff00enabled|r" or "|cffff0000disabled|r"
            print("FFA Party: " .. status)
            if FFAPartyDB.enabled and addon.UpdateLootMethod then
                addon.UpdateLootMethod()
            end
        end)

    local showMessagesCB = CreateCheckbox(mainContent, "Show chat messages", 0, -70, FFAPartyDB and FFAPartyDB.showMessages,
        function(self)
            FFAPartyDB.showMessages = self:GetChecked()
        end)

    local debugCB = CreateCheckbox(mainContent, "Enable debug logging", 0, -100, FFAPartyDB and FFAPartyDB.debug,
        function(self)
            FFAPartyDB.debug = self:GetChecked()
        end)

    local hideMinimapCB = CreateCheckbox(mainContent, "Hide minimap icon", 0, -130, FFAPartyDB and FFAPartyDB.minimap and FFAPartyDB.minimap.hide,
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

    local lootHeader = mainContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lootHeader:SetPoint("TOPLEFT", leftPad, contentTop - 160)
    lootHeader:SetText("Loot Rules")
    lootHeader:SetTextColor(1, 0.82, 0, 1)

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
    local lootFriendsLabel = mainContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lootFriendsLabel:SetPoint("TOPLEFT", leftPad, contentTop - 190)
    lootFriendsLabel:SetText("With friends:")
    lootFriendsLabel:SetTextColor(1, 1, 1, 1)

    local lootFriendsDD = CreateDropdown(addonName .. "LootFriendsDD", mainContent, 0, -214,
        FFAPartyDB and FFAPartyDB.lootWithFriends or "freeforall", function(value)
            FFAPartyDB.lootWithFriends = value
            if addon.UpdateLootMethod then
                addon.UpdateLootMethod()
            end
        end)

    --------------------------------------------------------
    -- Loot with others
    --------------------------------------------------------
    local lootOthersLabel = mainContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lootOthersLabel:SetPoint("TOPLEFT", leftPad, contentTop - 260)
    lootOthersLabel:SetText("With others:")
    lootOthersLabel:SetTextColor(1, 1, 1, 1)

    local lootOthersDD = CreateDropdown(addonName .. "LootOthersDD", mainContent, 0, -284,
        FFAPartyDB and FFAPartyDB.lootWithOthers or "group", function(value)
            FFAPartyDB.lootWithOthers = value
            if addon.UpdateLootMethod then
                addon.UpdateLootMethod()
            end
        end)

    --------------------------------------------------------
    -- TAB 2: CHARACTERS (Whitelist/Blacklist)
    --------------------------------------------------------
    local charactersContent = CreateFrame("Frame", nil, panel)
    charactersContent:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, -70)
    charactersContent:SetSize(MAIN_WIDTH - 24, MAIN_HEIGHT - 110)
    charactersContent:Hide()
    panel.contentFrames[3] = charactersContent

    -- Characters tab info
    local charInfo = charactersContent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    charInfo:SetPoint("TOPLEFT", leftPad, contentTop + 5)
    charInfo:SetWidth(MAIN_WIDTH - 2 * leftPad - 20)
    charInfo:SetJustifyH("LEFT")
    charInfo:SetText(
        "Whitelist: always treated as friends.\nBlacklist: never treated as friends, even if on your friends list.\nYou can use Name or Name-Realm.")

    -- Character list helper functions
    local function CreateCharList(parent, width, height, labelText, position)
        local frame = CreateFrame("Frame", nil, parent)
        frame:SetSize(width, height)
        frame:SetPoint(position.point, position.relTo, position.relPoint, position.x, position.y)

        local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("TOPLEFT", 0, 0)
        label:SetText(labelText)
        label:SetTextColor(1, 1, 1, 1)

        local border = CreateFrame("Frame", nil, frame, "BackdropTemplate")
        border:SetPoint("TOPLEFT", label, "BOTTOMLEFT", -4, -4)
        border:SetPoint("BOTTOMRIGHT", -4, 4)
        border:SetBackdrop({
            bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 12,
            insets = {
                left = 3,
                right = 3,
                top = 3,
                bottom = 3
            }
        })
        border:SetBackdropColor(0, 0, 0, 0.4)
        border:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

        local scrollFrame = CreateFrame("ScrollFrame", nil, border, "FauxScrollFrameTemplate")
        scrollFrame:SetPoint("TOPLEFT", 4, -4)
        scrollFrame:SetPoint("BOTTOMRIGHT", -26, 4)

        local buttons = {}
        local NUM_ROWS = math.floor((height - 40) / 16)

        for i = 1, NUM_ROWS do
            local btn = CreateFrame("Button", nil, border)
            btn:SetHeight(16)
            btn:SetPoint("TOPLEFT", 6, -6 - (i - 1) * 16)
            btn:SetPoint("RIGHT", -6, 0)

            local highlight = btn:CreateTexture(nil, "BACKGROUND")
            highlight:SetAllPoints()
            highlight:SetColorTexture(1, 1, 1, 0.15)
            highlight:Hide()
            btn.highlight = highlight

            local text = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            text:SetPoint("LEFT", 2, 0)
            text:SetJustifyH("LEFT")
            text:SetTextColor(0.9, 0.9, 0.9, 1)

            btn.text = text
            btn.index = nil

            btn:SetScript("OnClick", function(self)
                for _, b in ipairs(buttons) do
                    b.highlight:Hide()
                end

                if self.index then
                    self.highlight:Show()
                end

                if frame.OnSelect and self.index then
                    frame.OnSelect(self.index)
                end
            end)

            buttons[i] = btn
        end

        frame.scrollFrame = scrollFrame
        frame.buttons = buttons

        scrollFrame:SetScript("OnVerticalScroll", function(self, offset)
            FauxScrollFrame_OnVerticalScroll(self, offset, 16, function()
                if frame.Refresh and frame.data then
                    frame.RefreshList(frame, frame.data)
                end
            end)
        end)

        function frame.RefreshList(listFrame, data)
            local buttons = listFrame.buttons
            local offset = FauxScrollFrame_GetOffset(listFrame.scrollFrame)
            local total = #data

            for i, button in ipairs(buttons) do
                local index = i + offset
                if index <= total then
                    button.text:SetText(data[index])
                    button.index = index
                    button:Show()
                else
                    button.text:SetText("")
                    button.index = nil
                    button:Hide()
                end
            end

            FauxScrollFrame_Update(listFrame.scrollFrame, total, #buttons, 16)
        end

        return frame
    end

    local function SortList(list)
        table.sort(list, function(a, b)
            return a:lower() < b:lower()
        end)
    end

    -- Create whitelist and blacklist frames
    local whitelistFrame = CreateCharList(charactersContent, 190, 140, "Whitelist",
        { point = "TOPLEFT", relTo = charactersContent, relPoint = "TOPLEFT", x = leftPad, y = contentTop - 40 })

    local blacklistFrame = CreateCharList(charactersContent, 190, 140, "Blacklist",
        { point = "TOPRIGHT", relTo = charactersContent, relPoint = "TOPRIGHT", x = -leftPad, y = contentTop - 40 })

    charactersContent.whitelistFrame = whitelistFrame
    charactersContent.blacklistFrame = blacklistFrame

    -- Remove buttons under lists
    local removeWhitelistBtn = CreateFrame("Button", nil, charactersContent, "UIPanelButtonTemplate")
    removeWhitelistBtn:SetSize(100, 22)
    removeWhitelistBtn:SetPoint("TOP", whitelistFrame, "BOTTOM", 0, -8)
    removeWhitelistBtn:SetText("Remove")

    local removeBlacklistBtn = CreateFrame("Button", nil, charactersContent, "UIPanelButtonTemplate")
    removeBlacklistBtn:SetSize(100, 22)
    removeBlacklistBtn:SetPoint("TOP", blacklistFrame, "BOTTOM", 0, -8)
    removeBlacklistBtn:SetText("Remove")

    -- Input and add buttons
    local inputLabel = charactersContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    inputLabel:SetPoint("TOPLEFT", leftPad, contentTop - 240)
    inputLabel:SetText("Add player name:")
    inputLabel:SetTextColor(1, 1, 1, 1)

    local charInput = CreateFrame("EditBox", nil, charactersContent, "InputBoxTemplate")
    charInput:SetSize(200, 24)
    charInput:SetPoint("TOPLEFT", leftPad, contentTop - 262)
    charInput:SetAutoFocus(false)

    -- Radio buttons for whitelist/blacklist selection
    local whitelistRadio = CreateFrame("CheckButton", nil, charactersContent, "UIRadioButtonTemplate")
    whitelistRadio:SetPoint("LEFT", charInput, "RIGHT", 12, 0)
    whitelistRadio.text = whitelistRadio:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    whitelistRadio.text:SetPoint("LEFT", whitelistRadio, "RIGHT", 2, 0)
    whitelistRadio.text:SetText("Whitelist")
    whitelistRadio:SetChecked(true)

    local blacklistRadio = CreateFrame("CheckButton", nil, charactersContent, "UIRadioButtonTemplate")
    blacklistRadio:SetPoint("TOP", whitelistRadio, "BOTTOM", 0, -4)
    blacklistRadio.text = blacklistRadio:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    blacklistRadio.text:SetPoint("LEFT", blacklistRadio, "RIGHT", 2, 0)
    blacklistRadio.text:SetText("Blacklist")

    whitelistRadio:SetScript("OnClick", function(self)
        self:SetChecked(true)
        blacklistRadio:SetChecked(false)
    end)

    blacklistRadio:SetScript("OnClick", function(self)
        self:SetChecked(true)
        whitelistRadio:SetChecked(false)
    end)

    local charAddBtn = CreateFrame("Button", nil, charactersContent, "UIPanelButtonTemplate")
    charAddBtn:SetSize(60, 22)
    charAddBtn:SetPoint("TOPLEFT", charInput, "BOTTOMLEFT", 0, -8)
    charAddBtn:SetText("Add")

    -- Character list data helpers
    local function EnsureCharLists()
        FFAPartyDB.customWhitelist = FFAPartyDB.customWhitelist or {}
        FFAPartyDB.customBlacklist = FFAPartyDB.customBlacklist or {}
    end

    local function AddToCharList(list, name)
        name = name and name:gsub("^%s+", ""):gsub("%s+$", "")
        if not name or name == "" then
            return
        end
        for _, v in ipairs(list) do
            if v:lower() == name:lower() then
                return
            end
        end
        table.insert(list, name)
    end

    local function RemoveFromCharList(list, index)
        if not index or not list[index] then
            return
        end
        table.remove(list, index)
    end

    local function RefreshCharLists()
        EnsureCharLists()

        SortList(FFAPartyDB.customWhitelist)
        SortList(FFAPartyDB.customBlacklist)

        whitelistFrame.data = FFAPartyDB.customWhitelist
        blacklistFrame.data = FFAPartyDB.customBlacklist

        whitelistFrame.RefreshList(whitelistFrame, whitelistFrame.data)
        blacklistFrame.RefreshList(blacklistFrame, blacklistFrame.data)
    end

    whitelistFrame.OnSelect = function(index)
        whitelistFrame.selectedIndex = index
    end

    blacklistFrame.OnSelect = function(index)
        blacklistFrame.selectedIndex = index
    end

    -- Add button handler for characters
    local function DoCharAdd()
        local text = charInput:GetText()
        if not text or text == "" then
            return
        end

        EnsureCharLists()

        if blacklistRadio:GetChecked() then
            AddToCharList(FFAPartyDB.customBlacklist, text)
        else
            AddToCharList(FFAPartyDB.customWhitelist, text)
        end

        RefreshCharLists()
        charInput:SetText("")
        charInput:ClearFocus()
        
        if addon.UpdateLootMethod then
            addon.UpdateLootMethod()
        end
    end

    charInput:SetScript("OnEnterPressed", DoCharAdd)
    charAddBtn:SetScript("OnClick", DoCharAdd)

    removeWhitelistBtn:SetScript("OnClick", function()
        EnsureCharLists()
        if whitelistFrame.selectedIndex then
            RemoveFromCharList(FFAPartyDB.customWhitelist, whitelistFrame.selectedIndex)
            whitelistFrame.selectedIndex = nil
            RefreshCharLists()
            if addon.UpdateLootMethod then
                addon.UpdateLootMethod()
            end
        end
    end)

    removeBlacklistBtn:SetScript("OnClick", function()
        EnsureCharLists()
        if blacklistFrame.selectedIndex then
            RemoveFromCharList(FFAPartyDB.customBlacklist, blacklistFrame.selectedIndex)
            blacklistFrame.selectedIndex = nil
            RefreshCharLists()
            if addon.UpdateLootMethod then
                addon.UpdateLootMethod()
            end
        end
    end)

    -- Show on tab select
    panel.RefreshCharLists = RefreshCharLists

    --------------------------------------------------------
    -- TAB 3: RAID MARKERS
    --------------------------------------------------------
    local raidMarkersContent = CreateFrame("Frame", nil, panel)
    raidMarkersContent:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, -70)
    raidMarkersContent:SetSize(MAIN_WIDTH - 24, MAIN_HEIGHT - 110)
    raidMarkersContent:Hide()
    panel.contentFrames[2] = raidMarkersContent

    local raidMarkersHeaderLabel = raidMarkersContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    raidMarkersHeaderLabel:SetPoint("TOPLEFT", leftPad, contentTop + 10)
    raidMarkersHeaderLabel:SetText("Raid Markers Settings")
    raidMarkersHeaderLabel:SetTextColor(1, 0.82, 0, 1)

    local raidMarkersEnabledCB = CreateCheckbox(raidMarkersContent, "Enable raid marker system", 0, -10, FFAPartyDB and FFAPartyDB.raidMarkersEnabled,
        function(self)
            FFAPartyDB.raidMarkersEnabled = self:GetChecked()
            if addon.UpdateRaidIcon then
                addon.UpdateRaidIcon()
            end
        end)

    local raidMarkersRemoveNonFriendCB = CreateCheckbox(raidMarkersContent, "Remove marks if non-friend joins", 0, -40, FFAPartyDB and FFAPartyDB.raidMarkersRemoveOnNonFriend,
        function(self)
            FFAPartyDB.raidMarkersRemoveOnNonFriend = self:GetChecked()
            if addon.UpdateRaidIcon then
                addon.UpdateRaidIcon()
            end
        end)

    local raidIconLabel = raidMarkersContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    raidIconLabel:SetPoint("TOPLEFT", leftPad, contentTop - 80)
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

    local listBorder = CreateFrame("Frame", nil, raidMarkersContent, "BackdropTemplate")
    listBorder:SetPoint("TOPLEFT", leftPad, contentTop - 110)
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

    local raidIconList = CreateFrame("Frame", nil, raidMarkersContent)
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
    -- Footer hint
    --------------------------------------------------------
    local hint = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hint:SetPoint("BOTTOMLEFT", 14, 12)
    hint:SetText("LMB: Toggle enable/disable | Ctrl + RMB: Force refresh")
    hint:SetTextColor(0.9, 0.9, 0.9, 1)

    -- Refresh character lists when panel is shown
    panel:SetScript("OnShow", function()
        if panel.RefreshCharLists then
            panel.RefreshCharLists()
        end
    end)

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

    if panel.SelectTab then
        panel.SelectTab(1)
    end

    addon.OptionsPanel = panel
    return panel
end
