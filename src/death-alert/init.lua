local addonName, ItruliaQoL = ...
local moduleName = "DeathAlert"

local LSM = ItruliaQoL.LSM
local LEM = ItruliaQoL.LEM
local E = ItruliaQoL.E

local DeathAlert = ItruliaQoL:NewModule(moduleName)

local frame = CreateFrame("frame", addonName .. moduleName, UIParent)
frame:SetPoint("CENTER", 0, 300)
frame:SetSize(28, 28)
frame.lastSoundPlayedAt = nil

frame.text = frame:CreateFontString(nil, "OVERLAY")
frame.text:SetPoint("CENTER")
frame.text:SetFont(LSM:Fetch("font", "Expressway"), 28, "OUTLINE")
frame.text:SetTextColor(1, 1, 1)
frame.text:SetJustifyH("CENTER")

frame.text.anim = frame.text:CreateAnimationGroup()
frame.text.anim:SetScript("OnFinished", function() 
    frame.text:SetText("") 
end)
frame.alpha = frame.text.anim:CreateAnimation("Alpha")
frame.alpha:SetFromAlpha(1)
frame.alpha:SetToAlpha(0)
frame.alpha:SetDuration(1)
frame.alpha:SetStartDelay(4)

function frame:UpdateStyles()
    if not self:HasAnySecretAspect() and not self.text:HasAnySecretAspect() then
        if not E then
            self:ClearAllPoints()
            self:SetPoint(DeathAlert.db.point.point, DeathAlert.db.point.x, DeathAlert.db.point.y)
        end

        self:SetFrameStrata(DeathAlert.db.font.frameStrata or "BACKGROUND")
        self:SetFrameLevel(DeathAlert.db.font.frameLevel or 1)
        self.text:SetJustifyH(DeathAlert.db.font.justifyH or "CENTER")
        self.text:SetTextColor(DeathAlert.db.color.r, DeathAlert.db.color.g, DeathAlert.db.color.b, DeathAlert.db.color.a)
        self.text:SetFont(LSM:Fetch("font", DeathAlert.db.font.fontFamily), DeathAlert.db.font.fontSize, DeathAlert.db.font.fontOutline)
        self.text:SetShadowColor(DeathAlert.db.font.fontShadowColor.r, DeathAlert.db.font.fontShadowColor.g, DeathAlert.db.font.fontShadowColor.b, DeathAlert.db.font.fontShadowColor.a)
        self.text:SetShadowOffset(DeathAlert.db.font.fontShadowXOffset, DeathAlert.db.font.fontShadowYOffset)
        self.alpha:SetStartDelay(DeathAlert.db.messageDuration)
        self:SetSize(frame.text:GetStringWidth(), frame.text:GetStringHeight())
    end
end

local function OnEvent(self, event, deadGUID, ...)
    if ItruliaQoL.testMode then
        local name = UnitName("player")
        local _, class = UnitClass("player")
        
        local color = C_ClassColor.GetClassColor(class);
        local displayText = CreateColor(
            DeathAlert.db.color.r,
            DeathAlert.db.color.g, 
            DeathAlert.db.color.b, 
            DeathAlert.db.color.a
        ):WrapTextInColorCode(DeathAlert.db.displayText)
        local nameText = color:WrapTextInColorCode(name)

        self.text:SetText(nameText .. " " .. displayText)
        self.text:SetAlpha(1)

        return self:UpdateStyles()
    end

    if event == "UNIT_DIED" then
        if not canaccessvalue(deadGUID) or not canaccessvalue(UnitTokenFromGUID(deadGUID)) then
            return;
        end

        local unitId = UnitTokenFromGUID(deadGUID)

        if not unitId or not UnitIsDead(unitId) then
            -- well hunters in your party feign deathing is causing the event to fire without actually dying
            return 
        end

        if UnitInParty(unitId) or UnitInRaid(unitId) or unitId == "player" then
            local showText = true;
            local sound = DeathAlert.db.sound;
            local playSound = DeathAlert.db.playSound and sound;
            local tts = DeathAlert.db.TTS;
            local playTTS = DeathAlert.db.playTTS and tts;

            local name = UnitName(unitId)

            if canaccessvalue(name) then
                if DeathAlert.db.whitelist and DeathAlert.db.whitelist ~= "" then
                    local allowedNames = ItruliaQoL:SplitAndTrim(DeathAlert.db.whitelist)
                    local found = false

                    for _, v in ipairs(allowedNames) do
                        if v == name then
                            found = true
                            break
                        end
                    end

                    if not found then
                        return
                    end
                elseif DeathAlert.db.blacklist and DeathAlert.db.blacklist ~= "" then
                    local blockedNames = ItruliaQoL:SplitAndTrim(DeathAlert.db.blacklist)
                    local found = false

                    for _, v in ipairs(blockedNames) do
                        if v == name then
                            found = true
                            break
                        end
                    end

                    if found then
                        return
                    end
                end
            end

            -- Only do role based configuration inside a raid
            if ItruliaQoL:InRaid() then
                local role = UnitGroupRolesAssigned(unitId)

                if role == "NONE" then
                    role = "DAMAGER"
                end

                showText = DeathAlert.db.byRole.display[role].enabled
                sound = DeathAlert.db.byRole.sound[role].sound or sound
                playSound = playSound and DeathAlert.db.byRole.sound[role].enabled and sound
                tts = DeathAlert.db.byRole.sound[role].tts or tts
                playTTS = playTTS and DeathAlert.db.byRole.tts[role].enabled and tts
            end

            if showText then
                local name = UnitName(unitId)
                local _, class = UnitClass(unitId)
                local classColor = C_ClassColor.GetClassColor(class)

                local displayText = CreateColor(
                    DeathAlert.db.color.r,
                    DeathAlert.db.color.g, 
                    DeathAlert.db.color.b, 
                    DeathAlert.db.color.a
                ):WrapTextInColorCode(DeathAlert.db.displayText)
                local nameText = classColor:WrapTextInColorCode(name)

                self.text:SetText(nameText .. " " .. displayText)
                self.text:SetAlpha(1)
                self.text.anim:Stop()
                self.text.anim:Play()
            end

            if not self.lastSoundPlayedAt or (GetTime() - self.lastSoundPlayedAt) > 2 then
                if playSound then
                    self.lastSoundPlayedAt = GetTime()
                    PlaySoundFile(LSM:Fetch("sound", sound), "Master")
                elseif playTTS then
                    self.lastSoundPlayedAt = GetTime()
                    C_VoiceChat.SpeakText(0, tts, 1, DeathAlert.db.TTSVolume, true)
                end
            end
        else
            self.text:SetText("")
        end
    else
        self.text:SetText("")
    end

    self:UpdateStyles()
end

frame:RegisterEvent("UNIT_DIED")

function DeathAlert:OnInitialize()
    local profile = ItruliaQoL.db.profile
    profile.DeathAlert = profile.DeathAlert or self:GetDefaults()
    self.db = profile.DeathAlert

    -- Migration
    self.db.byRole = self.db.byRole or self:GetDefaults().byRole
end

function DeathAlert:RefreshConfig()
    local profile = ItruliaQoL.db.profile
    profile.DeathAlert = profile.DeathAlert or self:GetDefaults()
    self.db = profile.DeathAlert

    if self.db.enabled then
        frame:UpdateStyles()
        frame:SetScript("OnEvent", OnEvent)
    else
        frame:SetScript("OnEvent", nil)
        frame:SetScript("OnUpdate", nil)
    end
end

function DeathAlert:ApplyFontSettings(font)
    self.db.font.fontFamily = font.fontFamily
    self.db.font.fontOutline = font.fontOutline
    self.db.font.fontShadowColor = font.fontShadowColor
    self.db.font.fontShadowXOffset = font.fontShadowXOffset
    self.db.font.fontShadowYOffset = font.fontShadowYOffset
    self.db.font.justifyH = font.justifyH
    frame:UpdateStyles()
end

function DeathAlert:OnEnable()
    if self.db.enabled then 
        frame:SetScript("OnEvent", OnEvent) 
    end

    if E then
        E:CreateMover(frame, frame:GetName() .. "Mover", moduleName, nil,
            nil,
            nil,
            "ALL,ITRULIA",
            function()
                return self.db.enable
            end,
            addonName .. "," .. moduleName
        )
    else
        LEM:AddFrame(frame, function(frame, layoutName, point, x, y)
            self.db.point = {point = point, x = x, y = y}
        end, self:GetDefaults().point)
    end
end

function DeathAlert:ToggleTestMode()
    if not self.db.enabled then 
        return
    end

    OnEvent(frame)
end

function DeathAlert:RegisterOptions(parentOptions)
    parentOptions.args[moduleName] = self:GetOptions(function()
        frame:UpdateStyles()
    end)
end