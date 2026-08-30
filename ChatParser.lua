local _, addon = ...

local ChatParser = {}
addon.ChatParser = ChatParser

local CHAT_EVENTS = {
	"CHAT_MSG_PARTY",
	"CHAT_MSG_PARTY_LEADER",
	"CHAT_MSG_RAID",
	"CHAT_MSG_RAID_LEADER",
	"CHAT_MSG_INSTANCE_CHAT",
	"CHAT_MSG_INSTANCE_CHAT_LEADER",
}

-- Keystone item links look like: |Hkeystone:<itemID>:<mapID>:<level>:...|h[Keystone: Dungeon (level)]|h
-- We only need the mapID and level out of the middle.
local function ParseKeystoneLink(message)
	if type(message) ~= "string" then
		return nil, nil
	end

	local linkData = message:match("|Hkeystone:([^|]+)|h")
	if not linkData then
		return nil, nil
	end

	local _, mapIDText, levelText = linkData:match("^(%d+):(%d+):(%d+)")
	local mapID = tonumber(mapIDText)
	local level = tonumber(levelText)

	if mapID and level and mapID > 0 and level > 0 then
		return mapID, level
	end

	return nil, nil
end
addon.ParseKeystoneLink = ParseKeystoneLink

local chatFrame = CreateFrame("Frame")
for _, event in ipairs(CHAT_EVENTS) do
	chatFrame:RegisterEvent(event)
end

chatFrame:SetScript("OnEvent", function(self, _event, message, sender)
	local mapID, level = ParseKeystoneLink(message)
	if not mapID or not level then
		return
	end

	local shortName = Ambiguate(sender, "short")
	addon.Pool:AddOrUpdate(shortName, mapID, level, "chat-link")
end)
