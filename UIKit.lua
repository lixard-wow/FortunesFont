local _, addon = ...

-- A small from-scratch skin so Fortune's Font doesn't look like stock
-- Blizzard dialog chrome. Flat colored panels/buttons in a red-and-gold
-- game-show palette instead of BasicFrameTemplateWithInset / UIPanelButtonTemplate.
local UIKit = {}
addon.UIKit = UIKit

local WHITE8X8 = "Interface\\BUTTONS\\WHITE8X8"

UIKit.COLOR_BG = { 0.05, 0.04, 0.08, 0.95 }
UIKit.COLOR_PANEL = { 0.12, 0.10, 0.16, 0.98 }
UIKit.COLOR_GOLD = { 0.83, 0.68, 0.21, 1 }
UIKit.COLOR_GOLD_BRIGHT = { 1, 0.85, 0.35, 1 }
UIKit.COLOR_RED = { 0.50, 0.08, 0.10, 1 }
UIKit.COLOR_RED_BRIGHT = { 0.75, 0.15, 0.18, 1 }
UIKit.COLOR_CREAM = { 0.96, 0.92, 0.82, 1 }

local function SetColor(tex, c)
	tex:SetColorTexture(c[1], c[2], c[3], c[4])
end
UIKit.SetColor = SetColor

function UIKit.CreateFlatTexture(parent, layer, color)
	local tex = parent:CreateTexture(nil, layer or "ARTWORK")
	tex:SetTexture(WHITE8X8)
	SetColor(tex, color)
	return tex
end

function UIKit.CreatePanel(parent, width, height, name)
	local panel = CreateFrame("Frame", name, parent, "BackdropTemplate")
	panel:SetSize(width, height)

	panel.bg = UIKit.CreateFlatTexture(panel, "BACKGROUND", UIKit.COLOR_BG)
	panel.bg:SetAllPoints()

	local thickness = 2
	panel.borderTop = UIKit.CreateFlatTexture(panel, "BORDER", UIKit.COLOR_GOLD)
	panel.borderTop:SetPoint("TOPLEFT")
	panel.borderTop:SetPoint("TOPRIGHT")
	panel.borderTop:SetHeight(thickness)

	panel.borderBottom = UIKit.CreateFlatTexture(panel, "BORDER", UIKit.COLOR_GOLD)
	panel.borderBottom:SetPoint("BOTTOMLEFT")
	panel.borderBottom:SetPoint("BOTTOMRIGHT")
	panel.borderBottom:SetHeight(thickness)

	panel.borderLeft = UIKit.CreateFlatTexture(panel, "BORDER", UIKit.COLOR_GOLD)
	panel.borderLeft:SetPoint("TOPLEFT")
	panel.borderLeft:SetPoint("BOTTOMLEFT")
	panel.borderLeft:SetWidth(thickness)

	panel.borderRight = UIKit.CreateFlatTexture(panel, "BORDER", UIKit.COLOR_GOLD)
	panel.borderRight:SetPoint("TOPRIGHT")
	panel.borderRight:SetPoint("BOTTOMRIGHT")
	panel.borderRight:SetWidth(thickness)

	return panel
end

function UIKit.CreateTitleBar(parent, text)
	local bar = CreateFrame("Frame", nil, parent)
	bar:SetPoint("TOPLEFT", 2, -2)
	bar:SetPoint("TOPRIGHT", -2, -2)
	bar:SetHeight(30)

	bar.bg = UIKit.CreateFlatTexture(bar, "ARTWORK", UIKit.COLOR_RED)
	bar.bg:SetAllPoints()

	bar.underline = UIKit.CreateFlatTexture(bar, "OVERLAY", UIKit.COLOR_GOLD)
	bar.underline:SetPoint("BOTTOMLEFT")
	bar.underline:SetPoint("BOTTOMRIGHT")
	bar.underline:SetHeight(1)

	bar.text = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	bar.text:SetPoint("CENTER")
	bar.text:SetTextColor(UIKit.COLOR_GOLD_BRIGHT[1], UIKit.COLOR_GOLD_BRIGHT[2], UIKit.COLOR_GOLD_BRIGHT[3])
	bar.text:SetText(text)

	return bar
end

function UIKit.CreateCloseButton(parent, size)
	size = size or 20
	local btn = CreateFrame("Button", nil, parent)
	btn:SetSize(size, size)

	btn.bg = UIKit.CreateFlatTexture(btn, "ARTWORK", UIKit.COLOR_GOLD)
	btn.bg:SetAllPoints()

	btn.label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	btn.label:SetPoint("CENTER")
	btn.label:SetText("X")
	btn.label:SetTextColor(0.12, 0.06, 0.06)

	btn:SetScript("OnEnter", function()
		SetColor(btn.bg, UIKit.COLOR_GOLD_BRIGHT)
	end)
	btn:SetScript("OnLeave", function()
		SetColor(btn.bg, UIKit.COLOR_GOLD)
	end)

	return btn
end

function UIKit.CreateButton(parent, text, width, height)
	local btn = CreateFrame("Button", nil, parent)
	btn:SetSize(width, height)

	btn.border = UIKit.CreateFlatTexture(btn, "BORDER", UIKit.COLOR_GOLD)
	btn.border:SetAllPoints()

	btn.bg = UIKit.CreateFlatTexture(btn, "ARTWORK", UIKit.COLOR_RED)
	btn.bg:SetPoint("TOPLEFT", 1, -1)
	btn.bg:SetPoint("BOTTOMRIGHT", -1, 1)

	btn.label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	btn.label:SetPoint("CENTER")
	btn.label:SetTextColor(UIKit.COLOR_CREAM[1], UIKit.COLOR_CREAM[2], UIKit.COLOR_CREAM[3])
	btn.label:SetText(text)

	btn:SetScript("OnEnter", function()
		SetColor(btn.bg, UIKit.COLOR_RED_BRIGHT)
	end)
	btn:SetScript("OnLeave", function()
		SetColor(btn.bg, UIKit.COLOR_RED)
	end)
	btn:SetScript("OnMouseDown", function()
		btn.label:SetPoint("CENTER", 1, -1)
	end)
	btn:SetScript("OnMouseUp", function()
		btn.label:SetPoint("CENTER", 0, 0)
	end)

	return btn
end

-- Lays out dots to exactly fill `width`, so the strip can never spill past
-- its holder regardless of dot size (each dot's pitch was previously
-- dotSize+spacing, not spacing, which overflowed the frame).
function UIKit.CreateMarquee(parent, width, dotSize)
	dotSize = dotSize or 5
	local pitch = dotSize + 6
	local count = math.max(2, math.floor(width / pitch))
	local usedWidth = (count - 1) * pitch + dotSize
	local startX = (width - usedWidth) / 2

	local dots = {}
	for i = 1, count do
		local dot = UIKit.CreateFlatTexture(parent, "OVERLAY", UIKit.COLOR_GOLD_BRIGHT)
		dot:SetSize(dotSize, dotSize)
		dot:SetPoint("LEFT", parent, "LEFT", startX + (i - 1) * pitch, 0)
		dots[i] = dot
	end
	return dots
end
