local addonName, ItruliaQoL = ...
local moduleName = "PreventRelease"

local PreventRelease = ItruliaQoL:NewModule(moduleName)

local frame = CreateFrame("frame", addonName .. moduleName, UIParent)

frame.hiddenButton = nil
frame.activePopup = nil

function frame:Cleanup()
    if frame.hiddenButton then
        frame.hiddenButton:Enable()
        frame.hiddenButton = nil
    end

    if frame.activePopup then
        frame.activePopup:SetScript("OnUpdate", nil)
        frame.activePopup = nil
    end
end

function frame:SetupPopup()
    if UnitIsGhost("player") then
        frame:Cleanup()
        return
    end

    C_Timer.After(0, function()
        for i = 1, 4 do
            local popup = _G["StaticPopup" .. i]

            if popup and popup:IsShown() and popup.which == "DEATH" then
                for j = 1, 3 do
                    local button = popup.GetButton and popup:GetButton(j) or popup["button" .. j]

                    if button and button:GetText() == _G["DEATH_RELEASE"] then
                        frame.hiddenButton = button
                        button:Disable()

                        break
                    end
                end

                if frame.hiddenButton then
                    frame.activePopup = popup

                    popup:SetScript("OnUpdate", function(self)
                        if self.which ~= "DEATH" then
                            frame:Cleanup()
                            return
                        end

                        if IsControlKeyDown() then
                            frame.hiddenButton:Enable()
                        else
                            frame.hiddenButton:Disable()
                        end
                    end)
                end

                break
            end
        end
    end)
end

local function OnEvent(self)
    self:Cleanup()
end

frame:RegisterEvent("PLAYER_ALIVE")
frame:RegisterEvent("PLAYER_UNGHOST")

function PreventRelease:OnInitialize()
    local profile = ItruliaQoL.db.profile
    profile.PreventRelease = profile.PreventRelease or PreventRelease:GetDefaults()
    self.db = profile.PreventRelease
end

function PreventRelease:RefreshConfig()
    local profile = ItruliaQoL.db.profile
    profile.PreventRelease = profile.PreventRelease or PreventRelease:GetDefaults()
    self.db = profile.PreventRelease

    if self.db.enabled then
        frame:SetScript("OnEvent", OnEvent)
        OnEvent(frame)
    else
        frame:SetScript("OnEvent", nil)
        frame:SetScript("OnUpdate", nil)
    end
end

function PreventRelease:OnEnable()
    frame:SetScript("OnEvent", OnEvent)

    hooksecurefunc("StaticPopup_Show", function(which)
        if which == "DEATH" and self.db.enabled then
            frame:SetupPopup()
        end
    end)
end

function PreventRelease:RegisterOptions(parentOptions)
    parentOptions.args[moduleName] = self:GetOptions(function()
    end);
end
