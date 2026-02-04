-- Minimal vendored LibDBIcon-1.0 (guarded)
if LibStub and LibStub("LibDBIcon-1.0", true) then
    return
end

local LibDBIcon = LibStub:NewLibrary("LibDBIcon-1.0", 1)
if not LibDBIcon then return end

LibDBIcon.registry = LibDBIcon.registry or {}

local function placeButton(btn, pos)
    pos = pos or 45
    local radius = 92 -- place outside the minimap ring (tweakable)
    local x = radius * math.cos(math.rad(pos))
    local y = radius * math.sin(math.rad(pos))
    btn:ClearAllPoints()
    btn:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

function LibDBIcon:Register(name, dataobj, db)
    self.registry[name] = self.registry[name] or {}
    local entry = self.registry[name]
    entry.dataobj = dataobj
    entry.db = db or entry.db or { hide = false, minimapPos = 45 }

    if not entry.frame then
        local btn = CreateFrame("Button", "LibDBIcon10_" .. name, Minimap)
        btn:SetSize(56, 56)
        btn:SetFrameStrata("MEDIUM")
        btn:SetFrameLevel((Minimap:GetFrameLevel() or 1) + 5)
        btn:SetClampedToScreen(true)

        -- Icon texture (smaller, centered)
        local tex = btn:CreateTexture(nil, "ARTWORK")
        tex:SetSize(24, 24)
        tex:SetPoint("CENTER", 0, 0)
        if dataobj.icon then
            tex:SetTexture(dataobj.icon)
        end
        btn.icon = tex

        -- Blizzard-style border (tracking ring)
        local border = btn:CreateTexture(nil, "OVERLAY")
        border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
        border:SetSize(56, 56)
        border:SetPoint("CENTER", 0, 0)

        -- Highlight texture
        local hl = btn:CreateTexture(nil, "HIGHLIGHT")
        hl:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
        hl:SetSize(32, 32)
        hl:SetPoint("CENTER", 0, 0)
        btn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

        btn:SetScript("OnClick", function(self, button)
            if dataobj.OnClick then
                dataobj.OnClick(self, button)
            end
        end)

        btn:SetScript("OnEnter", function(self)
            if dataobj.OnTooltipShow and GameTooltip then
                GameTooltip:SetOwner(self, "ANCHOR_LEFT")
                dataobj.OnTooltipShow(GameTooltip)
                GameTooltip:Show()
            end
        end)
        btn:SetScript("OnLeave", function(self)
            if GameTooltip then GameTooltip:Hide() end
        end)

        btn:RegisterForDrag("LeftButton")
        btn:SetScript("OnDragStart", function(self)
            self:SetScript("OnUpdate", function(self)
                local mx, my = Minimap:GetCenter()
                local px, py = GetCursorPosition()
                local scale = UIParent:GetEffectiveScale()
                px = px / scale
                py = py / scale
                local angle = math.deg(math.atan2(py - my, px - mx))
                entry.db.minimapPos = angle
                placeButton(self, angle)
            end)
        end)
        btn:SetScript("OnDragStop", function(self)
            self:SetScript("OnUpdate", nil)
        end)

        entry.frame = btn
    end

    if entry.db.hide then
        entry.frame:Hide()
    else
        placeButton(entry.frame, entry.db.minimapPos)
        entry.frame:Show()
    end
end
