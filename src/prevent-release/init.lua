local addonName, ItruliaQoL = ...
local moduleName = "PreventRelease"

local PreventRelease = ItruliaQoL:NewModule(moduleName)

local DEATH_RELEASE = _G["DEATH_RELEASE"]
local NUM_DIALOGS = _G["STATICPOPUP_NUMDIALOGS"] or 4

local hookedPopups = {}
local BLOCKED_COLOR = GRAY_FONT_COLOR

local function OnEvent(self, event)
    if event == "GROUP_ROSTER_UPDATE" then
        if not self.watchedButton then
            self:SetupPopup()
        end

        return
    end

    self:Cleanup()
end

function PreventRelease:IsActive()
    if not self.db or not self.db.enabled then
        return false
    end

    return not self.db.raidOnly or IsInRaid()
end

local function GetPopupButton(popup, index)
    if popup.GetButton then
        return popup:GetButton(index)
    end

    return popup["button" .. index]
end

local function OnPopupUpdate(popup)
    local f = PreventRelease.frame

    if not f or f.watchedPopup ~= popup then
        return
    end

    f:Refresh()
end

local function OnPopupHide(popup)
    local f = PreventRelease.frame

    -- Covers the cases that never reach StaticPopup_Hide, such as the dialog being taken over by a resurrect prompt.
    if f and f.watchedPopup == popup then
        f:Cleanup()
    end
end

local function HookPopup(popup)
    if hookedPopups[popup] then
        return
    end

    hookedPopups[popup] = true
    popup:HookScript("OnUpdate", OnPopupUpdate)
    popup:HookScript("OnHide", OnPopupHide)
end

function PreventRelease:GenerateFrame(name, parent)
    local f = CreateFrame("frame", name, parent or UIParent)

    f.watchedPopup = nil
    f.watchedButton = nil
    f.blocked = false
    f.originalColor = nil

    function f:RestoreLabel()
        local button = self.watchedButton
        local color = self.originalColor

        self.originalColor = nil

        if not button or not color then
            return
        end

        local label = button:GetFontString()

        if label then
            label:SetTextColor(color[1], color[2], color[3], color[4])
        end
    end

    function f:EnsureBlocker()
        if self.blocker then
            return self.blocker
        end

        local blocker = CreateFrame("Button", nil, UIParent)
        blocker:Hide()
        blocker:RegisterForClicks("AnyUp")

        blocker:SetScript("OnClick", function(_, mouseButton, down)
            local button = f.watchedButton

            -- Swallow the click unless control is held. Forwarding from inside a real click handler keeps the hardware event intact, so releasing still works.
            if button and IsControlKeyDown() then
                button:Click(mouseButton, down)
            end
        end)

        self.blocker = blocker

        return blocker
    end

    function f:Cleanup()
        if self.blocker then
            self.blocker:Hide()
            self.blocker:ClearAllPoints()
            self.blocker:SetParent(UIParent)
        end

        self:RestoreLabel()

        self.watchedPopup = nil
        self.watchedButton = nil
        self.blocked = false
    end

    function f:IsPopupValid()
        local popup = self.watchedPopup
        local button = self.watchedButton

        return popup ~= nil
            and button ~= nil
            and popup:IsShown()
            and popup.which == "DEATH"
            and button:IsShown()
            and button:GetText() == DEATH_RELEASE
    end

    function f:Refresh()
        if not PreventRelease:IsActive() or UnitIsGhost("player") or not self:IsPopupValid() then
            self:Cleanup()
            return
        end

        local button = self.watchedButton
        local blocker = self.blocker
        local blocked = not IsControlKeyDown()
        local wasBlocked = self.blocked

        self.blocked = blocked

        if blocked then
            if blocker and not blocker:IsShown() then
                blocker:Show()
            end

            local label = button:GetFontString()

            if label then
                local r, g, b, a = label:GetTextColor()

                if r ~= BLOCKED_COLOR.r or g ~= BLOCKED_COLOR.g or b ~= BLOCKED_COLOR.b then
                    if not self.originalColor then
                        self.originalColor = { r, g, b, a }
                    end

                    label:SetTextColor(BLOCKED_COLOR.r, BLOCKED_COLOR.g, BLOCKED_COLOR.b)
                end
            end
        else
            if blocker and blocker:IsShown() then
                blocker:Hide()
            end

            if wasBlocked then
                self:RestoreLabel()
            end
        end
    end

    function f:SetupPopup()
        self:Cleanup()

        if not PreventRelease:IsActive() or UnitIsGhost("player") then
            return
        end

        C_Timer.After(0, function()
            if not PreventRelease:IsActive() or UnitIsGhost("player") then
                return
            end

            for i = 1, NUM_DIALOGS do
                local popup = _G["StaticPopup" .. i]

                if popup and popup:IsShown() and popup.which == "DEATH" then
                    for j = 1, 4 do
                        local button = GetPopupButton(popup, j)

                        if button and button:IsShown() and button:GetText() == DEATH_RELEASE then
                            self.watchedPopup = popup
                            self.watchedButton = button

                            break
                        end
                    end

                    break
                end
            end

            if self.watchedButton then
                local blocker = self:EnsureBlocker()

                blocker:SetParent(self.watchedPopup)
                blocker:SetFrameLevel(self.watchedButton:GetFrameLevel() + 10)
                blocker:SetAllPoints(self.watchedButton)
                blocker:Show()

                HookPopup(self.watchedPopup)
                self:Refresh()
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
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:RegisterEvent("GROUP_ROSTER_UPDATE")

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
        f:SetupPopup()
    elseif self.frame then
        self.frame:Cleanup()
        self.frame:SetScript("OnEvent", nil)
    end
end

function PreventRelease:OnEnable()
    if not self.hooked then
        self.hooked = true

        hooksecurefunc("StaticPopup_Show", function(which)
            if which == "DEATH" and self:IsActive() then
                self:EnsureFrame():SetupPopup()
            end
        end)

        hooksecurefunc("StaticPopup_Hide", function(which)
            if which == "DEATH" and self.frame then
                self.frame:Cleanup()
            end
        end)
    end

    self:RefreshConfig()
end

function PreventRelease:RegisterOptions(parentOptions)
    parentOptions.args[moduleName] = self:GetOptions(function()
    end);
end
