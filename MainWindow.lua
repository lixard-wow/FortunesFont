local _, addon = ...

local MainWindow = {}
addon.MainWindow = MainWindow

local ROW_HEIGHT = 24
local MAX_ROWS = 8

local frame
local rows = {}
local nameInput, linkInput

local function CreateRow(parent, index)
	local row = CreateFrame("Frame", nil, parent)
	row:SetSize(260, ROW_HEIGHT)
	row:SetPoint("TOPLEFT", 10, -(index - 1) * ROW_HEIGHT - 36)

	row.nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	row.nameText:SetPoint("LEFT", 4, 0)
	row.nameText:SetWidth(90)
	row.nameText:SetJustifyH("LEFT")

	row.keyText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	row.keyText:SetPoint("LEFT", row.nameText, "RIGHT", 4, 0)
	row.keyText:SetWidth(130)
	row.keyText:SetJustifyH("LEFT")

	row.removeButton = CreateFrame("Button", nil, row, "UIPanelCloseButton")
	row.removeButton:SetSize(18, 18)
	row.removeButton:SetPoint("RIGHT", -4, 0)

	return row
end

local function BuildFrame()
	frame = CreateFrame("Frame", "FortunesFontMainWindow", UIParent, "BasicFrameTemplateWithInset")
	frame:SetSize(300, 340)
	frame:SetPoint("CENTER")
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
	frame:SetFrameStrata("HIGH")
	tinsert(UISpecialFrames, "FortunesFontMainWindow")

	frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	frame.title:SetPoint("TOP", 0, -8)
	frame.title:SetText("Fortune's Font")

	for i = 1, MAX_ROWS do
		rows[i] = CreateRow(frame, i)
		rows[i]:Hide()
	end

	local addLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	addLabel:SetPoint("BOTTOMLEFT", 16, 90)
	addLabel:SetText("Name, then shift-click a keystone to add manually")

	nameInput = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
	nameInput:SetSize(80, 20)
	nameInput:SetAutoFocus(false)
	nameInput:SetPoint("BOTTOMLEFT", 20, 66)

	linkInput = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
	linkInput:SetSize(140, 20)
	linkInput:SetAutoFocus(false)
	linkInput:SetPoint("LEFT", nameInput, "RIGHT", 14, 0)

	local addButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	addButton:SetSize(70, 22)
	addButton:SetPoint("TOPLEFT", nameInput, "BOTTOMLEFT", 0, -6)
	addButton:SetText("Add")
	addButton:SetScript("OnClick", function()
		local pname = strtrim(nameInput:GetText() or "")
		local link = linkInput:GetText() or ""
		local mapID, level = addon.ParseKeystoneLink(link)
		if pname ~= "" and mapID and level then
			addon.Pool:AddOrUpdate(pname, mapID, level, "manual")
			nameInput:SetText("")
			linkInput:SetText("")
		else
			UIErrorsFrame:AddMessage("Fortune's Font: enter a name and shift-click a keystone link.", 1, 0.2, 0.2)
		end
	end)

	local spinButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	spinButton:SetSize(90, 24)
	spinButton:SetPoint("BOTTOMLEFT", 20, 16)
	spinButton:SetText("Spin")
	spinButton:SetScript("OnClick", function()
		addon.Wheel:Spin()
	end)

	local clearButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	clearButton:SetSize(90, 24)
	clearButton:SetPoint("LEFT", spinButton, "RIGHT", 10, 0)
	clearButton:SetText("Clear")
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
		self:Refresh()
		frame:Show()
	end
end

function MainWindow:Show()
	if not frame then
		BuildFrame()
	end
	addon.Pool:RefreshOwnKey()
	self:Refresh()
	frame:Show()
end
