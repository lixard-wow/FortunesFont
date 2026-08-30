local addonName, addon = ...

local Minimap = {}
addon.Minimap = Minimap

function Minimap:Init()
	local ldb = LibStub("LibDataBroker-1.1"):NewDataObject(addonName, {
		type = "launcher",
		text = "Fortune's Font",
		icon = "Interface\\Icons\\INV_Relics_Hourglass",
		OnClick = function(_, button)
			if button == "LeftButton" then
				addon.MainWindow:Toggle()
			elseif button == "RightButton" then
				addon.Pool:Clear()
			end
		end,
		OnTooltipShow = function(tooltip)
			tooltip:AddLine("Fortune's Font")
			tooltip:AddLine("|cffffffffLeft-click:|r Open key wheel")
			tooltip:AddLine("|cffffffffRight-click:|r Clear pool")
		end,
	})

	local ldbi = LibStub("LibDBIcon-1.0")
	ldbi:Register(addonName, ldb, addon.db.minimap)
end
