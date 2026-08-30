local _, addon = ...

local Pool = {}
addon.Pool = Pool

local entries = {}
local order = {}

local function GetDungeonInfo(mapID)
	if not mapID or mapID == 0 then
		return nil, nil
	end
	local name, _, _, texture = C_ChallengeMode.GetMapUIInfo(mapID)
	return name, texture
end
addon.GetDungeonInfo = GetDungeonInfo

local function NotifyChanged()
	if addon.MainWindow then
		addon.MainWindow:Refresh()
	end
end

function Pool:AddOrUpdate(playerName, mapID, keyLevel, source)
	if not playerName or playerName == "" then
		return
	end
	if not mapID or not keyLevel or mapID <= 0 or keyLevel <= 0 then
		return
	end

	if not entries[playerName] then
		table.insert(order, playerName)
	end

	local dungeonName, dungeonIcon = GetDungeonInfo(mapID)

	entries[playerName] = {
		name = playerName,
		mapID = mapID,
		keyLevel = keyLevel,
		source = source or "unknown",
		dungeonName = dungeonName or ("Unknown Dungeon (" .. mapID .. ")"),
		dungeonIcon = dungeonIcon,
	}

	NotifyChanged()
end

function Pool:Remove(playerName)
	if not entries[playerName] then
		return
	end

	entries[playerName] = nil
	for i, n in ipairs(order) do
		if n == playerName then
			table.remove(order, i)
			break
		end
	end

	NotifyChanged()
end

function Pool:Clear()
	wipe(entries)
	wipe(order)
	NotifyChanged()
end

function Pool:GetEntries()
	local list = {}
	for _, n in ipairs(order) do
		table.insert(list, entries[n])
	end
	return list
end

function Pool:RefreshOwnKey()
	local mapID = C_MythicPlus.GetOwnedKeystoneChallengeMapID()
	local level = C_MythicPlus.GetOwnedKeystoneLevel()
	local playerName = UnitName("player")

	if mapID and level and mapID > 0 and level > 0 then
		self:AddOrUpdate(playerName, mapID, level, "self")
	else
		self:Remove(playerName)
	end
end

function Pool:Init()
	self:RefreshOwnKey()
end
