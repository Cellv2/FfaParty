-- friends_ui.lua
local addonName, addon = ...
addon.DebugPrint("friends_ui.lua loaded for " .. addonName)

local WIDTH, HEIGHT = 420, 400

local function CreateBorderedPanel(name, parent, width, height, titleText)
    local panel = CreateFrame("Frame", name, parent or UIParent)
    panel:SetSize(width, height)
    panel:SetPoint("CENTER")
    panel:SetFrameStrata("DIALOG")
    panel:Hide()

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

    local headerHeight = 40
    local header = CreateFrame("Frame", nil, panel)
    header:SetSize(width - 24, headerHeight)
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

    local title = header:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("CENTER", header, "CENTER", -8, 4)
    title:SetText(titleText or "Friends Manager")
    title:SetTextColor(1, 0.82, 0, 1)

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

    panel.Header = header
    return panel
end

local function RefreshList(listFrame, data)
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

local function SortList(list)
    table.sort(list, function(a, b)
        return a:lower() < b:lower()
    end)
end

local function CreateList(parent, width, height, labelText)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(width, height)

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

        -- Highlight texture
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
            -- Clear highlights on all buttons
            for _, b in ipairs(buttons) do
                b.highlight:Hide()
            end

            -- Highlight this one
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
    frame.Refresh = RefreshList

    scrollFrame:SetScript("OnVerticalScroll", function(self, offset)
        FauxScrollFrame_OnVerticalScroll(self, offset, 16, function()
            if frame.Refresh and frame.data then
                frame.Refresh(frame, frame.data)
            end
        end)
    end)

    return frame
end

function addon.InitFriendsUI()
    if addon.FriendsPanel then
        return
    end

    local panel = CreateBorderedPanel("FfaPartyFriendsPanel", UIParent, WIDTH, HEIGHT, "FFA Party Friends")
    addon.FriendsPanel = panel

    local contentTop = -40
    local leftPad = 16

    local info = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    info:SetPoint("TOPLEFT", leftPad, contentTop)
    info:SetWidth(WIDTH - 2 * leftPad)
    info:SetJustifyH("LEFT")
    info:SetText(
        "Whitelist: always treated as friends.\nBlacklist: never treated as friends, even if on your friends list.\nYou can use Name or Name-Realm.")

    --------------------------------------------------------
    -- Lists
    --------------------------------------------------------
    local whitelistFrame = CreateList(panel, 180, 160, "Whitelist")
    whitelistFrame:SetPoint("TOPLEFT", leftPad, contentTop - 50)

    local blacklistFrame = CreateList(panel, 180, 160, "Blacklist")
    blacklistFrame:SetPoint("TOPRIGHT", -leftPad, contentTop - 50)

    panel.whitelistFrame = whitelistFrame
    panel.blacklistFrame = blacklistFrame

    --------------------------------------------------------
    -- Remove buttons under lists
    --------------------------------------------------------
    local removeWhitelistBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    removeWhitelistBtn:SetSize(120, 22)
    removeWhitelistBtn:SetPoint("TOP", whitelistFrame, "BOTTOM", 0, -8)
    removeWhitelistBtn:SetText("Remove selected")

    local removeBlacklistBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    removeBlacklistBtn:SetSize(120, 22)
    removeBlacklistBtn:SetPoint("TOP", blacklistFrame, "BOTTOM", 0, -8)
    removeBlacklistBtn:SetText("Remove selected")

    --------------------------------------------------------
    -- Input + buttons
    --------------------------------------------------------
    local inputLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    inputLabel:SetPoint("TOPLEFT", leftPad, contentTop - 260)
    inputLabel:SetText("Add player name:")
    inputLabel:SetTextColor(1, 1, 1, 1)

    local input = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
    input:SetSize(240, 24)
    input:SetPoint("TOPLEFT", leftPad, contentTop - 282)
    input:SetAutoFocus(false)

    -- Radio buttons for whitelist/blacklist selection
    local whitelistRadio = CreateFrame("CheckButton", nil, panel, "UIRadioButtonTemplate")
    whitelistRadio:SetPoint("LEFT", input, "RIGHT", 12, 0)
    whitelistRadio.text = whitelistRadio:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    whitelistRadio.text:SetPoint("LEFT", whitelistRadio, "RIGHT", 2, 0)
    whitelistRadio.text:SetText("Whitelist")
    whitelistRadio:SetChecked(true)

    local blacklistRadio = CreateFrame("CheckButton", nil, panel, "UIRadioButtonTemplate")
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

    local addBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    addBtn:SetSize(80, 22)
    addBtn:SetPoint("TOPLEFT", input, "BOTTOMLEFT", 0, -8)
    addBtn:SetText("Add")

    --------------------------------------------------------
    -- Data helpers (defined before use)
    --------------------------------------------------------
    local function EnsureLists()
        FFAPartyDB.customWhitelist = FFAPartyDB.customWhitelist or {}
        FFAPartyDB.customBlacklist = FFAPartyDB.customBlacklist or {}
    end

    local function AddToList(list, name)
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

    local function RemoveFromList(list, index)
        if not index or not list[index] then
            return
        end
        table.remove(list, index)
    end

    local function RefreshAll()
        EnsureLists()

        SortList(FFAPartyDB.customWhitelist)
        SortList(FFAPartyDB.customBlacklist)

        whitelistFrame.data = FFAPartyDB.customWhitelist
        blacklistFrame.data = FFAPartyDB.customBlacklist

        whitelistFrame:Refresh(whitelistFrame.data)
        blacklistFrame:Refresh(blacklistFrame.data)
    end

    whitelistFrame.OnSelect = function(index)
        whitelistFrame.selectedIndex = index
    end

    blacklistFrame.OnSelect = function(index)
        blacklistFrame.selectedIndex = index
    end

    --------------------------------------------------------
    -- Add button handler
    --------------------------------------------------------
    local function DoAdd()
        local text = input:GetText()
        if not text or text == "" then
            return
        end

        EnsureLists()

        if blacklistRadio:GetChecked() then
            AddToList(FFAPartyDB.customBlacklist, text)
        else
            AddToList(FFAPartyDB.customWhitelist, text)
        end

        RefreshAll()
        input:SetText("")
        input:ClearFocus()
    end

    input:SetScript("OnEnterPressed", DoAdd)
    addBtn:SetScript("OnClick", DoAdd)

    removeWhitelistBtn:SetScript("OnClick", function()
        EnsureLists()
        if whitelistFrame.selectedIndex then
            RemoveFromList(FFAPartyDB.customWhitelist, whitelistFrame.selectedIndex)
            whitelistFrame.selectedIndex = nil
            RefreshAll()
        end
    end)

    removeBlacklistBtn:SetScript("OnClick", function()
        EnsureLists()
        if blacklistFrame.selectedIndex then
            RemoveFromList(FFAPartyDB.customBlacklist, blacklistFrame.selectedIndex)
            blacklistFrame.selectedIndex = nil
            RefreshAll()
        end
    end)

    panel:SetScript("OnShow", RefreshAll)
    
    addon.DebugPrint("Friends UI panel created")
    return panel
end

function addon.ShowFriendsManager()
    if not addon.FriendsPanel then
        if addon.InitFriendsUI then
            addon.InitFriendsUI()
        end
    end
    if addon.FriendsPanel then
        addon.FriendsPanel:Show()
        addon.FriendsPanel:Raise()
    end
end
