local addonName, addon = ...

addon.name = addonName

local defaults = {
	minimap = { hide = false },
}

local function InitializeDB()
	FortunesFontDB = FortunesFontDB or {}
	for k, v in pairs(defaults) do
		if FortunesFontDB[k] == nil then
			FortunesFontDB[k] = v
		end
	end
	addon.db = FortunesFontDB
end

local eventFrame = CreateFrame("Frame")
addon.eventFrame = eventFrame

eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
eventFrame:RegisterEvent("BAG_UPDATE_DELAYED")

eventFrame:SetScript("OnEvent", function(self, event, ...)
	if event == "ADDON_LOADED" then
		local loadedAddon = ...
		if loadedAddon == addonName then
			InitializeDB()
			addon.Pool:Init()
			addon.Minimap:Init()
		end
	elseif event == "PLAYER_ENTERING_WORLD" then
		addon.Pool:RefreshOwnKey()
	elseif event == "GROUP_ROSTER_UPDATE" then
		if not IsInGroup() then
			addon.Pool:Clear()
		end
	elseif event == "BAG_UPDATE_DELAYED" then
		addon.Pool:RefreshOwnKey()
	end
end)

SLASH_FORTUNESFONT1 = "/fortunesfont"
SLASH_FORTUNESFONT2 = "/ff"
SlashCmdList["FORTUNESFONT"] = function(msg)
	msg = strtrim(strlower(msg or ""))
	if msg == "spin" then
		addon.Wheel:Spin()
	elseif msg == "clear" then
		addon.Pool:Clear()
	else
		addon.MainWindow:Toggle()
	end
end
