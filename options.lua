-- local name,addon=...;
-- print(addon.myvar)

local panel = CreateFrame("Frame")
panel.name = "FFA Party"

local title = panel:CreateFontString("ARTWORK", nil, "GameFontNormalLarge")
title:SetPoint("TOP")
title:SetText("FFA Party")

InterfaceOptions_AddCategory(panel)

SLASH_FFAPARTY1 = "/fp"
SLASH_FFAPARTY2 = "/ffap"
SLASH_FFAPARTY3 = "/ffaparty"

SlashCmdList.FFAPARTY = function(msg, editBox)
	InterfaceOptionsFrame_OpenToCategory(panel)
end