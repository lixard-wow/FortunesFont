local _, addon = ...

local KeystoneSync = {}
addon.KeystoneSync = KeystoneSync

-- Shared BigWigs-ecosystem library (also embedded in KeyMaster, and often
-- pulled in transitively by other addons like BigWigs). Anyone in the party
-- running ANY addon that embeds LibKeystone will answer our Request(),
-- whether or not they have Fortune's Font installed.
local LKS = LibStub("LibKeystone")

local function OnKeystoneInfo(keyLevel, keyChallengeMapID, playerRating, senderName, channel)
	addon:Debug(
		("LibKeystone: %s -> level=%d map=%d rating=%d (%s)"):format(
			tostring(senderName),
			keyLevel or -1,
			keyChallengeMapID or -1,
			playerRating or -1,
			tostring(channel)
		)
	)

	if keyLevel and keyChallengeMapID and keyLevel > 0 and keyChallengeMapID > 0 then
		addon.Pool:AddOrUpdate(senderName, keyChallengeMapID, keyLevel, "libkeystone")
	end
end

LKS.Register(KeystoneSync, OnKeystoneInfo)

function KeystoneSync:Request()
	LKS.Request("PARTY")
end
