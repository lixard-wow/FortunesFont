local _, addon = ...

local MainWindow = {}
addon.MainWindow = MainWindow

local ROW_HEIGHT = 24
local MAX_ROWS = 5

local frame
local rows = {}

local function CreateRow(parent, index)
	local UIKit = addon.UIKit
	local row = CreateFrame("Frame", nil, parent)
	row:SetSize(240, ROW_HEIGHT - 2)
	row:SetPoint("TOPLEFT", 12, -(index - 1) * ROW_HEIGHT - 40)

	row.bg = UIKit.CreateFlatTexture(row, "BACKGROUND", UIKit.COLOR_PANEL)
	row.bg:SetAllPoints()

	row.nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	row.nameText:SetPoint("LEFT", 6, 0)
	row.nameText:SetWidth(80)
	row.nameText:SetJustifyH("LEFT")
	row.nameText:SetTextColor(UIKit.COLOR_GOLD_BRIGHT[1], UIKit.COLOR_GOLD_BRIGHT[2], UIKit.COLOR_GOLD_BRIGHT[3])

	row.keyText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	row.keyText:SetPoint("LEFT", row.nameText, "RIGHT", 4, 0)
	row.keyText:SetWidth(120)
	row.keyText:SetJustifyH("LEFT")
	row.keyText:SetTextColor(UIKit.COLOR_CREAM[1], UIKit.COLOR_CREAM[2], UIKit.COLOR_CREAM[3])

	row.removeButton = UIKit.CreateCloseButton(row, 16)
	row.removeButton:SetPoint("RIGHT", -3, 0)

	return row
end

local function BuildFrame()
	local UIKit = addon.UIKit

	frame = UIKit.CreatePanel(UIParent, 280, 230)
	frame:SetPoint("CENTER")
	frame:SetName("FortunesFontMainWindow")
	frame:SetFrameStrata("HIGH")
	frame:SetMovable(true)
	frame:EnableMouse(true)

	local titleBar = UIKit.CreateTitleBar(frame, "Fortune's Font")
	titleBar:EnableMouse(true)
	titleBar:RegisterForDrag("LeftButton")
	titleBar:SetScript("OnDragStart", function()
		frame:StartMoving()
	end)
	titleBar:SetScript("OnDragStop", function()
		frame:StopMovingOrSizing()
	end)

	local closeButton = UIKit.CreateCloseButton(titleBar)
	closeButton:SetPoint("RIGHT", -4, 0)
	closeButton:SetScript("OnClick", function()
		frame:Hide()
	end)

	_G.FortunesFontMainWindow = frame
	tinsert(UISpecialFrames, "FortunesFontMainWindow")

	for i = 1, MAX_ROWS do
		rows[i] = CreateRow(frame, i)
		rows[i]:Hide()
	end

	local requestButton = UIKit.CreateButton(frame, "Request", 80, 24)
	requestButton:SetPoint("BOTTOMLEFT", 12, 12)
	requestButton:SetScript("OnClick", function()
		addon.KeystoneSync:Request()
		addon.ChatParser:RequestKeys()
	end)

	local spinButton = UIKit.CreateButton(frame, "Spin", 80, 24)
	spinButton:SetPoint("LEFT", requestButton, "RIGHT", 6, 0)
	spinButton:SetScript("OnClick", function()
		addon.Wheel:Spin()
	end)

	local clearButton = UIKit.CreateButton(frame, "Clear", 80, 24)
	clearButton:SetPoint("LEFT", spinButton, "RIGHT", 6, 0)
	clearButton:SetScript("OnClick", function()
		addon.Pool:Clear()
	end)

	frame:Hide()
end

function MainWindow:Refresh()
	if not frame then
		return
	end

	local entries = addon.Pool:GetEntries()
	for i = 1, MAX_ROWS do
		local entry = entries[i]
		local row = rows[i]
		if entry then
			row.nameText:SetText(entry.name)
			row.keyText:SetText(("%s +%d"):format(entry.dungeonName, entry.keyLevel))
			row.removeButton:SetScript("OnClick", function()
				addon.Pool:Remove(entry.name)
			end)
			row:Show()
		else
			row:Hide()
		end
	end
end

function MainWindow:Toggle()
	if not frame then
		BuildFrame()
	end

	if frame:IsShown() then
		frame:Hide()
	else
		addon.Pool:RefreshOwnKey()
		addon.KeystoneSync:Request()
		self:Refresh()
		frame:Show()
	end
end

function MainWindow:Show()
	if not frame then
		BuildFrame()
	end
	addon.Pool:RefreshOwnKey()
	addon.KeystoneSync:Request()
	self:Refresh()
	frame:Show()
end
