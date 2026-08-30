local _, addon = ...

local Wheel = {}
addon.Wheel = Wheel

local SLOT_SPACING = 52
local VIEW_HALF_HEIGHT = 150
local MIN_SCALE = 0.55
local MAX_SCALE = 1.15
local SPIN_DURATION = 3.4
local LOOPS = 5
local MARQUEE_WIDTH = 260

local frame, viewport, resultText, spinButton
local items = {}
local sequence = {}
local spinning = false
local elapsed = 0
local startPos = 0
local targetPos = 0
local winnerItem

local function EaseOutQuart(t)
	local inv = 1 - t
	return 1 - inv * inv * inv * inv
end

local function CreateItemFrame(parent)
	local UIKit = addon.UIKit

	local f = CreateFrame("Frame", nil, parent)
	f:SetSize(230, 42)

	f.border = UIKit.CreateFlatTexture(f, "BORDER", UIKit.COLOR_GOLD)
	f.border:SetAllPoints()

	f.bg = UIKit.CreateFlatTexture(f, "ARTWORK", UIKit.COLOR_PANEL)
	f.bg:SetPoint("TOPLEFT", 1, -1)
	f.bg:SetPoint("BOTTOMRIGHT", -1, 1)

	f.glow = UIKit.CreateFlatTexture(f, "OVERLAY", UIKit.COLOR_GOLD_BRIGHT)
	f.glow:SetPoint("TOPLEFT", -3, 3)
	f.glow:SetPoint("BOTTOMRIGHT", 3, -3)
	f.glow:SetAlpha(0)
	f.glow:SetDrawLayer("OVERLAY", 7)

	f.glowAnim = f.glow:CreateAnimationGroup()
	f.glowAnim:SetLooping("BOUNCE")
	local pulse = f.glowAnim:CreateAnimation("Alpha")
	pulse:SetFromAlpha(0)
	pulse:SetToAlpha(0.55)
	pulse:SetDuration(0.35)
	f.pulseAnim = pulse

	f.icon = f:CreateTexture(nil, "ARTWORK", nil, 1)
	f.icon:SetSize(30, 30)
	f.icon:SetPoint("LEFT", 6, 0)
	f.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

	f.text = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	f.text:SetPoint("LEFT", f.icon, "RIGHT", 8, 0)
	f.text:SetPoint("RIGHT", -6, 0)
	f.text:SetJustifyH("LEFT")
	f.text:SetJustifyV("MIDDLE")

	return f
end

local function EnsureItemFrames(count)
	for i = #items + 1, count do
		items[i] = CreateItemFrame(viewport)
	end
end

local function StopWinnerGlow()
	if winnerItem then
		winnerItem.glowAnim:Stop()
		winnerItem.glow:SetAlpha(0)
		winnerItem = nil
	end
end

local function BuildFrame()
	local UIKit = addon.UIKit

	frame = UIKit.CreatePanel(UIParent, 300, 450, "FortunesFontWheel")
	frame:SetPoint("CENTER")
	frame:SetFrameStrata("DIALOG")
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

	-- Lives in the title bar (not the bottom of the window) so it never
	-- competes for space with the winner announcement below the reel.
	spinButton = UIKit.CreateButton(titleBar, "SPIN", 54, 22)
	spinButton:SetPoint("LEFT", 4, 0)
	spinButton:SetScript("OnClick", function()
		Wheel:Spin()
	end)

	tinsert(UISpecialFrames, "FortunesFontWheel")

	local marqueeTopHolder = CreateFrame("Frame", nil, frame)
	marqueeTopHolder:SetSize(MARQUEE_WIDTH, 10)
	marqueeTopHolder:SetPoint("TOP", 0, -38)
	marqueeTopHolder:SetClipsChildren(true)
	UIKit.CreateMarquee(marqueeTopHolder, MARQUEE_WIDTH, 5)

	viewport = UIKit.CreatePanel(frame, MARQUEE_WIDTH, VIEW_HALF_HEIGHT * 2)
	viewport:SetPoint("TOP", marqueeTopHolder, "BOTTOM", 0, -6)
	viewport:SetClipsChildren(true)

	local marqueeBottomHolder = CreateFrame("Frame", nil, frame)
	marqueeBottomHolder:SetSize(MARQUEE_WIDTH, 10)
	marqueeBottomHolder:SetPoint("TOP", viewport, "BOTTOM", 0, -6)
	marqueeBottomHolder:SetClipsChildren(true)
	UIKit.CreateMarquee(marqueeBottomHolder, MARQUEE_WIDTH, 5)

	local glowBar = UIKit.CreateFlatTexture(viewport, "ARTWORK", UIKit.COLOR_GOLD)
	glowBar:SetPoint("LEFT", viewport, "LEFT", 0, 0)
	glowBar:SetPoint("RIGHT", viewport, "RIGHT", 0, 0)
	glowBar:SetHeight(30)
	glowBar:SetAlpha(0.12)

	local centerLine = UIKit.CreateFlatTexture(viewport, "OVERLAY", UIKit.COLOR_GOLD_BRIGHT)
	centerLine:SetPoint("LEFT", viewport, "LEFT", 0, 0)
	centerLine:SetPoint("RIGHT", viewport, "RIGHT", 0, 0)
	centerLine:SetHeight(2)

	-- Plain ASCII, not a Unicode triangle glyph: WoW's default game font has
	-- no glyph for U+25B8/U+25C4, so they rendered as missing-glyph boxes.
	local arrowLeft = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
	arrowLeft:SetPoint("RIGHT", viewport, "LEFT", -2, 0)
	arrowLeft:SetText("|cffd4ae36>|r")

	local arrowRight = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
	arrowRight:SetPoint("LEFT", viewport, "RIGHT", 2, 0)
	arrowRight:SetText("|cffd4ae36<|r")

	resultText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	resultText:SetPoint("TOP", marqueeBottomHolder, "BOTTOM", 0, -14)
	resultText:SetPoint("BOTTOM", frame, "BOTTOM", 0, 16)
	resultText:SetPoint("LEFT", 12, 0)
	resultText:SetPoint("RIGHT", -12, 0)
	resultText:SetJustifyH("CENTER")
	resultText:SetJustifyV("MIDDLE")
	resultText:SetTextColor(UIKit.COLOR_GOLD_BRIGHT[1], UIKit.COLOR_GOLD_BRIGHT[2], UIKit.COLOR_GOLD_BRIGHT[3])
	resultText:SetText("")

	frame:SetScript("OnUpdate", function(self, dt)
		if not spinning then
			return
		end

		elapsed = elapsed + dt
		local t = math.min(elapsed / SPIN_DURATION, 1)
		local pos = startPos + (targetPos - startPos) * EaseOutQuart(t)
		Wheel:RenderAtPosition(pos)

		local pulseSpeed = 0.15 + 0.35 * t
		marqueeTopHolder:SetAlpha(0.5 + 0.5 * math.abs(math.sin(elapsed / pulseSpeed)))
		marqueeBottomHolder:SetAlpha(0.5 + 0.5 * math.abs(math.cos(elapsed / pulseSpeed)))

		if t >= 1 then
			spinning = false
			spinButton:Enable()
			marqueeTopHolder:SetAlpha(1)
			marqueeBottomHolder:SetAlpha(1)
			local winner = sequence[targetPos + 1]
			local winnerFrame = items[targetPos + 1]
			if winner then
				Wheel:AnnounceWinner(winner, winnerFrame)
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
	addon:Debug(("BuildSequence: %d entries in pool, rolled winnerIndex=%d (%s)"):format(
		#entries,
		winnerIndex,
		entries[winnerIndex] and entries[winnerIndex].name or "?"
	))
	local loops = math.max(LOOPS, 3)

	for _ = 1, loops do
		for _, entry in ipairs(entries) do
			table.insert(sequence, entry)
		end
	end

	return (loops - 1) * #entries + winnerIndex
end

function Wheel:AnnounceWinner(entry, winnerFrame)
	resultText:SetText(("|cffffe38a%s|r wins the |cffffe38a%s +%d|r!"):format(entry.name, entry.dungeonName, entry.keyLevel))

	StopWinnerGlow()
	if winnerFrame then
		winnerItem = winnerFrame
		winnerFrame.glow:SetAlpha(0.55)
		winnerFrame.glowAnim:Play()
		C_Timer.After(1.6, function()
			if winnerItem == winnerFrame then
				StopWinnerGlow()
				winnerFrame.glow:SetAlpha(0.2)
			end
		end)
	end

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

	StopWinnerGlow()

	local targetIndex = self:BuildSequence()
	if not targetIndex then
		UIErrorsFrame:AddMessage("Fortune's Font: no keys in the pool yet.", 1, 0.2, 0.2)
		return
	end

	EnsureItemFrames(#sequence)
	for i, entry in ipairs(sequence) do
		local item = items[i]
		item.glow:SetAlpha(0)
		if entry.dungeonIcon then
			item.icon:SetTexture(entry.dungeonIcon)
			item.icon:Show()
		else
			item.icon:Hide()
		end
		item.text:SetText(("|cffd4ae36%s|r\n%s +%d"):format(entry.name, entry.dungeonName, entry.keyLevel))
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
