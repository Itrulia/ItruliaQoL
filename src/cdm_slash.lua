local addonName, namespace = ...

local ItruliaQoL = LibStub("AceAddon-3.0"):GetAddon(addonName)
local CDMSlash = ItruliaQoL:NewModule("CDMSlash")

local InCombatLockdown = InCombatLockdown
local CooldownViewerSettings = _G.CooldownViewerSettings

local frame  = CreateFrame("frame", addonName .. "CDMSlash")
frame:EnableKeyboard(true)
frame:SetPropagateKeyboardInput(true)

function frame:toggleCDM()
	if InCombatLockdown() or not CooldownViewerSettings then 
        return 
    end

	if not CooldownViewerSettings:IsShown() then
		CooldownViewerSettings:Show()
	else
		CooldownViewerSettings:Hide()
	end
end

function frame:closeCDM()
	if InCombatLockdown() or not CooldownViewerSettings then 
        return 
    end

	CooldownViewerSettings:Hide()
end

function CDMSlash:OnEnable() 
    frame:SetScript("OnKeyDown", function(self, key) 
        if InCombatLockdown() then
            return
        end

        if key == "ESCAPE" and CooldownViewerSettings:IsShown() then
            frame:closeCDM()
            self:SetPropagateKeyboardInput(false)
        else
            self:SetPropagateKeyboardInput(true)
        end
    end)

    SLASH_CDMSC1 = "/cd"
    SLASH_CDMSC2 = "/cdm"
    SLASH_CDMSC3 = "/wa"

    function SlashCmdList.CDMSC(msg, editbox)
        frame:toggleCDM()
    end
end
