local addonName, ItruliaQoL = ...
local moduleName = "PreventRelease"

local PreventRelease = ItruliaQoL:NewModule(moduleName)


local function OnEvent(self)
    self:Cleanup()
end

function PreventRelease:GenerateFrame(name, parent)
    local f = CreateFrame("frame", name, parent or UIParent)

    f.hiddenButton = nil
    f.activePopup = nil

    function f:Cleanup()
        if self.hiddenButton then
            self.hiddenButton:Enable()
            self.hiddenButton = nil
        end

        if self.activePopup then
            self.activePopup:SetScript("OnUpdate", nil)
            self.activePopup = nil
        end
    end

    function f:SetupPopup()
        if UnitIsGhost("player") then
            self:Cleanup()
            return
        end

        C_Timer.After(0, function()
            for i = 1, 4 do
                local popup = _G["StaticPopup" .. i]

                if popup and popup:IsShown() and popup.which == "DEATH" then
                    for j = 1, 3 do
                        local button = popup.GetButton and popup:GetButton(j) or popup["button" .. j]

                        if button and button:GetText() == _G["DEATH_RELEASE"] then
                            f.hiddenButton = button
                            button:Disable()

                            break
                        end
                    end

                    if f.hiddenButton then
                        f.activePopup = popup

                        popup:SetScript("OnUpdate", function(shown)
                            if shown.which ~= "DEATH" then
                                f:Cleanup()
                                return
                            end

                            if IsControlKeyDown() then
                                f.hiddenButton:Enable()
                            else
                                f.hiddenButton:Disable()
                            end
                        end)
                    end

                    break
                end
            end
        end)
    end

    return f
end

function PreventRelease:EnsureFrame()
    if self.frame then
        return self.frame
    end

    local f = self:GenerateFrame(addonName .. moduleName)
    self.frame = f

    f:RegisterEvent("PLAYER_ALIVE")
    f:RegisterEvent("PLAYER_UNGHOST")

    return f
end

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
        local f = self:EnsureFrame()

        f:SetScript("OnEvent", OnEvent)
        OnEvent(f)
    elseif self.frame then
        self.frame:Cleanup()
        self.frame:SetScript("OnEvent", nil)
        self.frame:SetScript("OnUpdate", nil)
    end
end

function PreventRelease:OnEnable()
    hooksecurefunc("StaticPopup_Show", function(which)
        if which == "DEATH" and self.db.enabled then
            self:EnsureFrame():SetupPopup()
        end
    end)

    self:RefreshConfig()
end

function PreventRelease:RegisterOptions(parentOptions)
    parentOptions.args[moduleName] = self:GetOptions(function()
    end);
end
