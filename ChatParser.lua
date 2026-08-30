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

local chatFrame = CreateFrame("Frame")
for _, event in ipairs(CHAT_EVENTS) do
	chatFrame:RegisterEvent(event)
end

chatFrame:SetScript("OnEvent", function(self, event, message, sender)
	local mapID, level = ParseKeystoneLink(message)
	if not mapID or not level then
		addon:Debug(("%s from %s did not contain a keystone link: %s"):format(event, tostring(sender), tostring(message)))
		return
	end

	local shortName = Ambiguate(sender, "short")
	addon:Debug(("parsed keystone from %s: mapID=%d level=%d"):format(shortName, mapID, level))
	addon.Pool:AddOrUpdate(shortName, mapID, level, "chat-link")
end)

function ChatParser:RequestKeys()
	local channel = nil
	if IsInRaid() then
		channel = "RAID"
	elseif IsInGroup() then
		channel = "PARTY"
	end

	if not channel then
		addon:Print("You're not in a group.")
		return
	end

	SendChatMessage("Fortune's Font: shift-click your Mythic+ keystone here so it goes in the wheel!", channel)
end
