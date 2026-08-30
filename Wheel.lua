local _, addon = ...

local Wheel = {}
addon.Wheel = Wheel

local SLOT_SPACING = 52
local VIEW_HALF_HEIGHT = 150
local MIN_SCALE = 0.55
local MAX_SCALE = 1.15
local SPIN_DURATION = 3.4
local LOOPS = 5

local frame, viewport, resultText, spinButton
local items = {}
local sequence = {}
local spinning = false
local elapsed = 0
local startPos = 0
local targetPos = 0

local function EaseOutQuart(t)
	local inv = 1 - t
	return 1 - inv * inv * inv * inv
end

local function CreateItemFrame(parent)
	local f = CreateFrame("Frame", nil, parent)
	f:SetSize(220, 40)

	f.bg = f:CreateTexture(nil, "BACKGROUND")
	f.bg:SetAllPoints()
	f.bg:SetColorTexture(0, 0, 0, 0.35)

	f.text = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	f.text:SetPoint("CENTER")
	f.text:SetJustifyH("CENTER")

	return f
end

local function EnsureItemFrames(count)
	for i = #items + 1, count do
		items[i] = CreateItemFrame(viewport)
	end
end

local function BuildFrame()
	frame = CreateFrame("Frame", "FortunesFontWheel", UIParent, "BasicFrameTemplateWithInset")
	frame:SetSize(280, 380)
	frame:SetPoint("CENTER")
	frame:SetFrameStrata("DIALOG")
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
	tinsert(UISpecialFrames, "FortunesFontWheel")

	frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	frame.title:SetPoint("TOP", 0, -8)
	frame.title:SetText("Fortune's Font")

	viewport = CreateFrame("Frame", nil, frame)
	viewport:SetSize(240, VIEW_HALF_HEIGHT * 2)
	viewport:SetPoint("TOP", 0, -34)
	viewport:SetClipsChildren(true)

	local centerLine = viewport:CreateTexture(nil, "ARTWORK")
	centerLine:SetColorTexture(1, 0.82, 0, 0.9)
	centerLine:SetPoint("LEFT", -10, 0)
	centerLine:SetPoint("RIGHT", 10, 0)
	centerLine:SetHeight(2)

	resultText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
	resultText:SetPoint("TOP", viewport, "BOTTOM", 0, -10)
	resultText:SetText("")

	spinButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	spinButton:SetSize(100, 24)
	spinButton:SetPoint("BOTTOM", 0, 16)
	spinButton:SetText("Spin")
	spinButton:SetScript("OnClick", function()
		Wheel:Spin()
	end)

	frame:SetScript("OnUpdate", function(self, dt)
		if not spinning then
			return
		end

		elapsed = elapsed + dt
		local t = math.min(elapsed / SPIN_DURATION, 1)
		local pos = startPos + (targetPos - startPos) * EaseOutQuart(t)
		Wheel:RenderAtPosition(pos)

		if t >= 1 then
			spinning = false
			spinButton:Enable()
			local winner = sequence[targetPos + 1]
			if winner then
				Wheel:AnnounceWinner(winner)
			end
		end
	end)

	frame:Hide()
end

function Wheel:RenderAtPosition(pos)
	local total = #sequence
	for i = 1, total do
		local item = items[i]
		if item then
			local offset = ((i - 1) - pos) * SLOT_SPACING
			if math.abs(offset) > VIEW_HALF_HEIGHT + SLOT_SPACING then
				item:Hide()
			else
				local scale = MAX_SCALE - (math.abs(offset) / VIEW_HALF_HEIGHT) * (MAX_SCALE - MIN_SCALE)
				scale = math.max(MIN_SCALE, math.min(MAX_SCALE, scale))
				local alpha = 1 - math.abs(offset) / (VIEW_HALF_HEIGHT + SLOT_SPACING)

				item:ClearAllPoints()
				item:SetPoint("CENTER", viewport, "CENTER", 0, -offset)
				item:SetScale(scale)
				item:SetAlpha(math.max(0, alpha))
				item:Show()
			end
		end
	end
end

function Wheel:BuildSequence()
	local entries = addon.Pool:GetEntries()
	wipe(sequence)

	if #entries == 0 then
		return nil
	end

	local winnerIndex = math.random(1, #entries)
	local loops = math.max(LOOPS, 3)

	for _ = 1, loops do
		for _, entry in ipairs(entries) do
			table.insert(sequence, entry)
		end
	end

	return (loops - 1) * #entries + winnerIndex
end

function Wheel:AnnounceWinner(entry)
	resultText:SetText(("%s wins the %s +%d!"):format(entry.name, entry.dungeonName, entry.keyLevel))

	local channel = nil
	if IsInRaid() then
		channel = "RAID"
	elseif IsInGroup() then
		channel = "PARTY"
	end

	if channel then
		SendChatMessage(
			("Fortune's Font: %s's key wins the spin - %s +%d!"):format(entry.name, entry.dungeonName, entry.keyLevel),
			channel
		)
	end
end

function Wheel:Spin()
	if spinning then
		return
	end
	if not frame then
		BuildFrame()
	end

	local targetIndex = self:BuildSequence()
	if not targetIndex then
		UIErrorsFrame:AddMessage("Fortune's Font: no keys in the pool yet.", 1, 0.2, 0.2)
		return
	end

	EnsureItemFrames(#sequence)
	for i, entry in ipairs(sequence) do
		local item = items[i]
		item.text:SetText(("%s\n%s +%d"):format(entry.name, entry.dungeonName, entry.keyLevel))
	end
	for i = #sequence + 1, #items do
		items[i]:Hide()
	end

	startPos = 0
	targetPos = targetIndex - 1
	elapsed = 0
	spinning = true
	spinButton:Disable()
	resultText:SetText("")
	frame:Show()
	self:RenderAtPosition(startPos)
end
